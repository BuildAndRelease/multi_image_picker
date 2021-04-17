//
//  PHAsset+Extension.swift
//  multi_image_picker
//
//  Created by johnson_zhong on 2020/5/17.
//

import Foundation
import Photos

extension PHAsset {
    
    
    var fileSize: Double {
        get {
            if #available(iOS 9, *) {
                let resource = PHAssetResource.assetResources(for: self)
                let imageSizeByte = resource.first?.value(forKey: "fileSize") as? Double ?? 0
                return imageSizeByte
            } else {
                // Fallback on earlier versions
                return 5.0
            }
        }
    }
    
    var originalFilename: String? {
        var fname:String?
        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if let resource = resources.first {
                fname = resource.originalFilename
            }
        }
        if fname == nil {
            fname = self.value(forKey: "filename") as? String
        }
        
        return fname
    }
    
    func compressAsset(_ thumb : Bool, saveDir : String, process: ((NSDictionary) -> Void)?, failed: ((NSError) -> Void)?, finish: ((NSDictionary) -> Void)?) {
        let manager = PHImageManager.default()
        let thumbOptions = PHImageRequestOptions()
        thumbOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        thumbOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
        thumbOptions.isSynchronous = false
        thumbOptions.isNetworkAccessAllowed = true
        thumbOptions.version = .current
        
        var uuid = "\(self.localIdentifier)-\(self.modificationDate?.timeIntervalSince1970 ?? 0)"
        uuid = uuid.replacingOccurrences(of: "/", with: "")
        let tmpSuffix = UUID().uuidString;
        
        if self.mediaType == .video {
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            manager.requestAVAsset(forVideo: self, options: options) { (avAsset, audioMix, info) in
                if avAsset != nil {
                    let dictionary : NSMutableDictionary = NSMutableDictionary()
                    let thumbName = "\(uuid).jpg"
                    let videoName = "\(uuid).mp4"
                    let thumbPath = saveDir + thumbName
                    let thumbTmpPath = saveDir + thumbName + "." + tmpSuffix
                    let videoPath = saveDir + videoName
                    let videoTmpPath = saveDir + videoName + "." + tmpSuffix
                    let duration = CMTimeGetSeconds(avAsset?.duration ?? CMTime(seconds: 0, preferredTimescale: 0))
                    if FileManager.default.fileExists(atPath: thumbPath), let thumbImg = UIImage(contentsOfFile: thumbPath) {
                        dictionary.setValue(thumbPath, forKey: "thumbPath")
                        dictionary.setValue(thumbName, forKey: "thumbName")
                        dictionary.setValue(thumbImg.size.height * thumbImg.scale, forKey: "thumbHeight")
                        dictionary.setValue(thumbImg.size.width * thumbImg.scale, forKey: "thumbWidth")
                    }else {
                        let gen = AVAssetImageGenerator(asset: avAsset!)
                        gen.appliesPreferredTrackTransform = true
                        let time = CMTimeMake(value: 0, timescale: 60);
                        var actualTime  = CMTimeMake(value: 0, timescale: 60)
                        if let image = try? gen.copyCGImage(at: time, actualTime: &actualTime) {
                            let thumbImg = UIImage(cgImage: image)
                            do {
                                try thumbImg.jpegData(compressionQuality: 0.6)?.write(to: URL(fileURLWithPath: thumbTmpPath))
                            } catch let error as NSError {
                                failed?(NSError(domain: error.domain, code: error.code, userInfo: [
                                    "identifier": self.localIdentifier,
                                    "errorCode": "1",
                                ]))
                                return
                            }
                            do {
                                try FileManager.default.moveItem(atPath: thumbTmpPath, toPath: thumbPath)
                            } catch let err as NSError {
                                print(err)
                            }
                            dictionary.setValue(thumbPath, forKey: "thumbPath")
                            dictionary.setValue(thumbName, forKey: "thumbName")
                            dictionary.setValue(thumbImg.size.height * thumbImg.scale, forKey: "thumbHeight")
                            dictionary.setValue(thumbImg.size.width * thumbImg.scale, forKey: "thumbWidth")
                        }else {
                            failed?(NSError(domain: "缩略图图片拷贝失败", code: 1, userInfo: [
                                "identifier": self.localIdentifier,
                                "errorCode": "1",
                            ]))
                            return
                        }
                    }

                    var thumbVideoSize = CGSize.zero
                    if FileManager.default.fileExists(atPath: videoPath) {
                        let thumbVideo = AVURLAsset(url: URL(fileURLWithPath: videoPath))
                        for track in thumbVideo.tracks {
                            if track.mediaType == AVMediaType.video {
                                thumbVideoSize = track.naturalSize
                            }
                        }
                    }
                    if thumbVideoSize != CGSize.zero {
                        dictionary.setValue(self.localIdentifier, forKey: "identifier")
                        dictionary.setValue(videoPath, forKey: "filePath")
                        dictionary.setValue(thumbVideoSize.width, forKey: "width")
                        dictionary.setValue(thumbVideoSize.height, forKey: "height")
                        dictionary.setValue(videoName, forKey: "name")
                        dictionary.setValue(duration, forKey: "duration")
                        dictionary.setValue("video", forKey: "fileType")
                        finish?(dictionary)
                    }else {
                        _ = LightCompressor().compressVideo(
                            source: avAsset!,
                            destination: URL(fileURLWithPath: videoTmpPath),
                            quality: .low,
                            keepOriginalResolution: false,
                            completion: {[weak self] result in
                                guard let `self` = self else { return }
                                switch (result) {
                                case .onCancelled:
                                    failed?(NSError(domain: "视频压缩已被取消", code: 2, userInfo: [
                                        "identifier": self.localIdentifier,
                                        "errorCode": "2"
                                    ]))
                                    print("compress canceled")
                                case .onFailure(let error):
                                    failed?(NSError(domain: error.localizedDescription, code: 2, userInfo: [
                                        "identifier": self.localIdentifier,
                                        "errorCode": "2"
                                    ]))
                                    print("compress failure \(error)")
                                case .onStart:
                                    print("start compress")
                                case .onSuccess(let path, let size):
                                    if FileManager.default.fileExists(atPath: path.path) {
                                        do {
                                            try FileManager.default.moveItem(atPath: path.path, toPath: videoPath)
                                        } catch let error as NSError{
                                            print(error)
                                        }
                                        dictionary.setValue(self.localIdentifier, forKey: "identifier")
                                        dictionary.setValue(videoPath, forKey: "filePath")
                                        dictionary.setValue(size.width, forKey: "width")
                                        dictionary.setValue(size.height, forKey: "height")
                                        dictionary.setValue(videoName, forKey: "name")
                                        dictionary.setValue(duration, forKey: "duration")
                                        dictionary.setValue("video", forKey: "fileType")
                                        finish?(dictionary)
                                        print("compress success")
                                    }else {
                                        failed?(NSError(domain: "视频请求失败", code: 2, userInfo: [
                                            "identifier": self.localIdentifier,
                                            "errorCode": "2"
                                        ]))
                                        print("compress finish but not found file")
                                    }
                                }
                           }
                        )
                    }
                }else {
                    failed?(NSError(domain: "视频请求失败", code: 2, userInfo: [
                        "identifier": self.localIdentifier,
                        "errorCode": "2"
                    ]))
                }
            }
        }else {
            var targetHeight : CGFloat = CGFloat(self.pixelHeight)
            var targetWidth : CGFloat = CGFloat(self.pixelWidth)
            if let uti = self.value(forKey: "filename"), uti is String, (uti as! String).uppercased().hasSuffix("GIF") {
                let fileName = "\(uuid).gif"
                let filePath = saveDir + fileName
                let checkFileName = "\(uuid)-check.gif"
                let checkPath = saveDir + checkFileName
                let fileTmpPath = saveDir + fileName + "." + tmpSuffix
                if FileManager.default.fileExists(atPath: filePath), FileManager.default.fileExists(atPath: checkPath) {
                    finish?([
                        "identifier": self.localIdentifier,
                        "filePath":filePath,
                        "checkPath":checkPath,
                        "width": targetWidth,
                        "height": targetHeight,
                        "name": fileName,
                        "fileType":"image/gif"
                    ])
                }else{
                    if FileManager.default.fileExists(atPath: filePath) {
                        do {
                            try FileManager.default.removeItem(atPath: filePath)
                        } catch let err as NSError {
                            print(err)
                        }
                    }
                    if FileManager.default.fileExists(atPath: checkPath) {
                        do {
                            try FileManager.default.removeItem(atPath: checkPath)
                        } catch let err as NSError {
                            print(err)
                        }
                    }
                    manager.requestImageData(for: self, options: thumbOptions) { (data, uti, ori, info) in
                        do {
                            if let file = data {
                                var resultData = try ImageCompress.compressImageData(file as Data, sampleCount: 1)
                                resultData = (resultData.count > file.count + 500 * 1024) ? file : resultData
                                try resultData.write(to: URL(fileURLWithPath: fileTmpPath))
                                let checkData = try ImageCompress.compressImageData(file as Data, sampleCount: 24)
                                try checkData.write(to: URL(fileURLWithPath: checkPath))
                                do {
                                    try FileManager.default.moveItem(atPath: fileTmpPath, toPath: filePath)
                                }catch let err as NSError {
                                    print(err)
                                }
                                if FileManager.default.fileExists(atPath: filePath) {
                                    finish?([
                                        "identifier": self.localIdentifier,
                                        "filePath":filePath,
                                        "checkPath":checkPath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "name": fileName,
                                        "fileType":"image/gif"
                                    ])
                                }else {
                                    failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                        "identifier": self.localIdentifier,
                                        "errorCode": "3"
                                    ]))
                                }
                            }else {
                                failed?(NSError(domain: "图片请求失败", code: 2, userInfo: [
                                    "identifier": self.localIdentifier,
                                    "errorCode": "2"
                                ]))
                            }
                        }catch let err as NSError {
                            print(err)
                            failed?(NSError(domain: "图片请求失败", code: 2, userInfo: [
                                "identifier": self.localIdentifier,
                                "errorCode": "2"
                            ]))
                        }
                    }
                }
            }else {
                let fileName = "\(uuid)-\(thumb ? "thumb" : "origin").jpg"
                let filePath = saveDir + fileName
                let checkPath = saveDir + fileName + ".check"
                let fileTmpPath = saveDir + fileName + "." + tmpSuffix
                if FileManager.default.fileExists(atPath: filePath) {
                    finish?([
                        "identifier": self.localIdentifier,
                        "filePath":filePath,
                        "checkPath": FileManager.default.fileExists(atPath: checkPath) ? checkPath : filePath,
                        "width": targetWidth,
                        "height": targetHeight,
                        "name": fileName,
                        "fileType":"image/jpeg"
                    ])
                }else {
                    let pixel = targetWidth * targetHeight
                    if pixel > 10000000 {
                        targetWidth = 10000000 / pixel * targetWidth
                        targetHeight = 10000000 / pixel * targetHeight
                    }
                    manager.requestImage(for: self, targetSize: CGSize(width: targetWidth, height: targetHeight), contentMode: PHImageContentMode.aspectFit, options: thumbOptions, resultHandler: { (image: UIImage?, info) in
                        if let imageData = (thumb ? UIImage.lubanCompressImage(image) : UIImage.lubanOriginImage(image)) as NSData? {
                            if thumb {
                                imageData.write(toFile: fileTmpPath, atomically: true)
                                if targetWidth * targetHeight > 312 * 312, let checkImage = UIImage.compressImage(UIImage(data: imageData as Data), toTargetWidth: 312, toTargetWidth: 312), let checkImageData = checkImage.jpegData(compressionQuality: 1.0) as NSData? {
                                    checkImageData.write(toFile: checkPath, atomically: true)
                                }
                                
                                do {
                                    try FileManager.default.moveItem(atPath: fileTmpPath, toPath: filePath)
                                } catch let err as NSError {
                                    print(err)
                                }
                                if FileManager.default.fileExists(atPath: filePath) {
                                    finish?([
                                        "identifier": self.localIdentifier,
                                        "filePath":filePath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "checkPath": FileManager.default.fileExists(atPath: checkPath) ? checkPath : filePath,
                                        "name": fileName,
                                        "fileType":"image/jpeg"
                                    ])
                                }else {
                                    failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                        "identifier": self.localIdentifier,
                                        "errorCode": "3"
                                    ]))
                                }
                            } else {
                                imageData.write(toFile: filePath, atomically: true)
                                if targetWidth * targetHeight > 312 * 312, let checkImage = UIImage.compressImage(UIImage(data: imageData as Data), toTargetWidth: 312, toTargetWidth: 312), let checkImageData = checkImage.jpegData(compressionQuality: 1.0) as NSData? {
                                    checkImageData.write(toFile: checkPath, atomically: true)
                                }
                                
                                if FileManager.default.fileExists(atPath: filePath) {
                                    finish?([
                                        "identifier": self.localIdentifier,
                                        "filePath":filePath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "checkPath": FileManager.default.fileExists(atPath: checkPath) ? checkPath : filePath,
                                        "name": fileName,
                                        "fileType":"image/jpeg"
                                    ])
                                }else {
                                    failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                        "identifier": self.localIdentifier,
                                        "errorCode": "3"
                                    ]))
                                }
                            }
                        }else {
                            failed?(NSError(domain: "图片请求失败", code: 2, userInfo: [
                                "identifier": self.localIdentifier,
                                "errorCode": "2"
                            ]))
                        }
                    })
                }
            }
        }
    }
}
