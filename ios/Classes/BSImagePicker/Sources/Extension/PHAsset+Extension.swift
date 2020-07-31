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
        if self.mediaType == .video {
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            manager.requestAVAsset(forVideo: self, options: options) { (avAsset, audioMix, info) in
                if avAsset != nil {
                    let dictionary : NSMutableDictionary = NSMutableDictionary()
                    let uuid = UUID().uuidString
                    let thumbName = "\(uuid).jpg"
                    let videoName = "\(uuid).mp4"
                    let thumbPath = saveDir + thumbName
                    let videoPath = saveDir + videoName
                    let duration = CMTimeGetSeconds(avAsset?.duration ?? CMTime(seconds: 0, preferredTimescale: 0))
                    if FileManager.default.fileExists(atPath: videoPath) {
                        try? FileManager.default.removeItem(atPath: videoPath)
                    }
                    if FileManager.default.fileExists(atPath: thumbPath) {
                        try? FileManager.default.removeItem(atPath: thumbPath)
                    }
                    
                    let gen = AVAssetImageGenerator(asset: avAsset!)
                    gen.appliesPreferredTrackTransform = true
                    let time = CMTimeMake(value: 0, timescale: 60);
                    var actualTime  = CMTimeMake(value: 0, timescale: 60)
                    if let image = try? gen.copyCGImage(at: time, actualTime: &actualTime) {
                        let thumbImg = UIImage(cgImage: image)
                        do {
                            try thumbImg.jpegData(compressionQuality: 0.6)?.write(to: URL(fileURLWithPath: thumbPath))
                        } catch let error as NSError {
                            print(error)
                            failed?(error)
                            return
                        }
                        dictionary.setValue(thumbPath, forKey: "thumbPath")
                        dictionary.setValue(thumbName, forKey: "thumbName")
                        dictionary.setValue(thumbImg.size.height * thumbImg.scale, forKey: "thumbHeight")
                        dictionary.setValue(thumbImg.size.width * thumbImg.scale, forKey: "thumbWidth")
                    }else {
                        failed?(NSError(domain: "缩略图图片拷贝失败", code: 1, userInfo: [
                            "identifier": self.localIdentifier
                        ]))
                        return
                    }
                    
                    let exportSession = AVAssetExportSession(asset: avAsset!, presetName: AVAssetExportPreset960x540)
                    exportSession?.outputURL = URL(fileURLWithPath: videoPath)
                    exportSession?.shouldOptimizeForNetworkUse = true
                    exportSession?.outputFileType = .mp4
                    exportSession?.exportAsynchronously(completionHandler: {
                        if FileManager.default.fileExists(atPath: videoPath) {
                            let thumbVideo = AVURLAsset(url: URL(fileURLWithPath: videoPath))
                            var thumbVideoSize = CGSize.zero
                            for track in thumbVideo.tracks {
                                if track.mediaType == AVMediaType.video {
                                    thumbVideoSize = track.naturalSize
                                }
                            }
                            dictionary.setValue(self.localIdentifier, forKey: "identifier")
                            dictionary.setValue(videoPath, forKey: "filePath")
                            dictionary.setValue(thumbVideoSize.width, forKey: "width")
                            dictionary.setValue(thumbVideoSize.height, forKey: "height")
                            dictionary.setValue(videoName, forKey: "name")
                            dictionary.setValue(duration, forKey: "duration")
                            dictionary.setValue("video", forKey: "fileType")
                            finish?(dictionary)
                        }else {
                            failed?(NSError(domain: "视频请求失败", code: 2, userInfo: [
                                "identifier": self.localIdentifier
                            ]))
                        }
                    })
                }else {
                    failed?(NSError(domain: "视频请求失败", code: 2, userInfo: [
                        "identifier": self.localIdentifier
                    ]))
                }
            }
        }else {
            let targetHeight : CGFloat = CGFloat(self.pixelHeight)
            let targetWidth : CGFloat = CGFloat(self.pixelWidth)
//            if (thumb && (self.pixelWidth > maxWidth || self.pixelHeight > maxHeight)) {
//                let heightCompressRatio = CGFloat(maxHeight)/CGFloat(self.pixelHeight)
//                let widthCompressRatio = CGFloat(maxWidth)/CGFloat(self.pixelWidth)
//                if (heightCompressRatio <= widthCompressRatio) {
//                    targetHeight = CGFloat(maxHeight)
//                    targetWidth = heightCompressRatio * CGFloat(self.pixelWidth)
//                }else {
//                    targetWidth = CGFloat(maxWidth)
//                    targetHeight = widthCompressRatio * CGFloat(self.pixelHeight)
//                }
//            }
            if let uti = self.value(forKey: "filename"), uti is String, (uti as! String).hasSuffix("GIF") {
                manager.requestImageData(for: self, options: thumbOptions) { (data, uti, ori, info) in
                    do {
                        if let file = data {
                            if file.count > 8 * 1024 * 1024 {
                                failed?(NSError(domain: "图片大小超过8M", code: 4, userInfo: [
                                    "identifier": self.localIdentifier
                                ]))
                            }else {
                                let uuid = UUID().uuidString
                                let fileName = "\(uuid).gif"
                                let filePath = saveDir + fileName
                                if FileManager.default.fileExists(atPath: filePath) {
                                    try? FileManager.default.removeItem(atPath: filePath)
                                }
                                try file.write(to: URL(fileURLWithPath: filePath))
                                if FileManager.default.fileExists(atPath: filePath) {
                                    finish?([
                                        "identifier": self.localIdentifier,
                                        "filePath":filePath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "name": fileName,
                                        "fileType":"image/gif"
                                    ])
                                }else {
                                    failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                        "identifier": self.localIdentifier
                                    ]))
                                }
                            }
                        }else {
                            failed?(NSError(domain: "图片请求失败", code: 2, userInfo: [
                                "identifier": self.localIdentifier
                            ]))
                        }
                    }catch let err as NSError {
                        print(err)
                    }
                }
            }else {
                manager.requestImage(for: self, targetSize: CGSize(width: targetWidth, height: targetHeight), contentMode: PHImageContentMode.aspectFit, options: thumbOptions, resultHandler: { (image: UIImage?, info) in
                    let uuid = UUID().uuidString
                    let fileName = "\(uuid).jpg"
                    let filePath = saveDir + fileName
                    if FileManager.default.fileExists(atPath: filePath) {
                        try? FileManager.default.removeItem(atPath: filePath)
                    }
                    
                    if let imageData = (thumb ? UIImage.lubanCompressImage(image) : UIImage.lubanOriginImage(image)) as NSData? {
                        print(imageData.length)
                        if thumb {
                            if imageData.length > 8 * 1024 * 1024 {
                                failed?(NSError(domain: "图片大小超过8M", code: 4, userInfo: [
                                    "identifier": self.localIdentifier
                                ]))
                            }else {
                                imageData.write(toFile: filePath, atomically: true)
                                if FileManager.default.fileExists(atPath: filePath) {
                                    finish?([
                                        "identifier": self.localIdentifier,
                                        "filePath":filePath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "name": fileName,
                                        "fileType":"image/jpg"
                                    ])
                                }else {
                                    failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                        "identifier": self.localIdentifier
                                    ]))
                                }
                            }
                        } else {
                            if imageData.length > 8 * 1024 * 1024 {
                                failed?(NSError(domain: "图片大小超过8M", code: 4, userInfo: [
                                    "identifier": self.localIdentifier
                                ]))
                            }else {
                                imageData.write(toFile: filePath, atomically: true)
                                if FileManager.default.fileExists(atPath: filePath) {
                                    finish?([
                                        "identifier": self.localIdentifier,
                                        "filePath":filePath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "name": fileName,
                                        "fileType":"image/jpg"
                                    ])
                                }else {
                                    failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                        "identifier": self.localIdentifier
                                    ]))
                                }
                            }
                        }
                    }else {
                        failed?(NSError(domain: "图片请求失败", code: 2, userInfo: [
                            "identifier": self.localIdentifier
                        ]))
                    }
                })
            }
        }
    }
}
