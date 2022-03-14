//
//  PHAsset+Extension.swift
//  multi_image_picker
//
//  Created by johnson_zhong on 2020/5/17.
//

import Foundation
import Photos

//最大像素
let MAXPixel = 20000000.0

extension PHAsset {
    var fileSize: Double {
        get {
            if #available(iOS 9, *) {
                let resource = PHAssetResource.assetResources(for: self)
                let imageSizeByte = resource.first?.value(forKey: "fileSize") as? Double ?? 0
                return imageSizeByte
            } else {
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
    
    class func removeFileIfNeed(path: String){
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch let err as NSError {
                print(err)
            }
        }
    }
    
    class func moveFile(atPath:String, toPath: String, deleteAtPath: Bool = true) throws{
        //先判断可以移动文件是否存在
        if !FileManager.default.fileExists(atPath: atPath){
            throw NSError(domain: "文件不存在", code: 3)
        }
        
        //如果两个路径一样，就不操作
        if (atPath == toPath) {
            return
        }
            
        //再判断目标文件是否存在
        if FileManager.default.fileExists(atPath: toPath){
            if deleteAtPath{
                try FileManager.default.removeItem(atPath: atPath)
            }
            return
        }
        //移动
        try FileManager.default.moveItem(atPath: atPath, toPath: toPath)
    }
    
    class func fetchThumbFromVideo(thumbPath : String, thumbTmpPath : String, videoPath : String) -> (String, CGSize)? {
        if FileManager.default.fileExists(atPath: thumbPath), let thumbImg = UIImage(contentsOfFile: thumbPath) {
            return (thumbPath, CGSize(width: thumbImg.size.width * thumbImg.scale, height: thumbImg.size.height * thumbImg.scale))
        }else {
            let gen = AVAssetImageGenerator(asset: AVURLAsset(url: URL(fileURLWithPath: videoPath)))
            gen.appliesPreferredTrackTransform = true
            let time = CMTimeMake(value: 0, timescale: 60);
            var actualTime  = CMTimeMake(value: 0, timescale: 60)
            if let image = try? gen.copyCGImage(at: time, actualTime: &actualTime) {
                let thumbImg = UIImage(cgImage: image)
                do {
                    try thumbImg.jpegData(compressionQuality: 0.6)?.write(to: URL(fileURLWithPath: thumbTmpPath))
                    try PHAsset.moveFile(atPath: thumbTmpPath, toPath: thumbPath)
                } catch let error as NSError {
                    print(error)
                    return nil
                }
                return (thumbPath, CGSize(width: thumbImg.size.width * thumbImg.scale, height: thumbImg.size.height * thumbImg.scale))
            }else {
                return nil
            }
        }
    }
    
    class func contentTypeForImageData(data : NSData) -> String {
        var value : UInt8 = 0
        if data.count > 1 {
            data.getBytes(&value, length: 1)
            switch (value) {
            case 0xFF:
                return "image/jpeg";
            case 0x89:
                return "image/png";
            case 0x47:
                return "image/gif";
            case 0x49:
                fallthrough
            case 0x4D:
                return "image/tiff";
            default:
                return ""
            }
        }else {
            return ""
        }
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

                    var thumbVideoSize = CGSize.zero
                    if FileManager.default.fileExists(atPath: videoPath) {
                        let thumbVideo = AVURLAsset(url: URL(fileURLWithPath: videoPath))
                        for track in thumbVideo.tracks {
                            if track.mediaType == AVMediaType.video {
                                thumbVideoSize = track.naturalSize
                            }
                        }
                    }
                    if thumbVideoSize != CGSize.zero, let thumbInfo = PHAsset.fetchThumbFromVideo(thumbPath: thumbPath, thumbTmpPath: thumbTmpPath, videoPath: videoPath) {
                        dictionary.setValue(self.localIdentifier, forKey: "identifier")
                        dictionary.setValue(videoPath, forKey: "filePath")
                        dictionary.setValue(thumbVideoSize.width, forKey: "width")
                        dictionary.setValue(thumbVideoSize.height, forKey: "height")
                        dictionary.setValue(videoName, forKey: "name")
                        dictionary.setValue(duration, forKey: "duration")
                        dictionary.setValue("video", forKey: "fileType")
                        dictionary.setValue(thumbInfo.0, forKey: "thumbPath")
                        dictionary.setValue(thumbName, forKey: "thumbName")
                        dictionary.setValue(thumbInfo.1.height, forKey: "thumbHeight")
                        dictionary.setValue(thumbInfo.1.width, forKey: "thumbWidth")
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
                                    do {
                                        //移动视频
                                        try PHAsset.moveFile(atPath: path.path, toPath: videoPath)
                                        //获取视频首帧封面
                                        if  let thumbInfo = PHAsset.fetchThumbFromVideo(thumbPath: thumbPath, thumbTmpPath: thumbTmpPath, videoPath: videoPath)  {
                                            dictionary.setValue(thumbInfo.0, forKey: "thumbPath")
                                            dictionary.setValue(thumbName, forKey: "thumbName")
                                            dictionary.setValue(thumbInfo.1.height, forKey: "thumbHeight")
                                            dictionary.setValue(thumbInfo.1.width, forKey: "thumbWidth")
                                        }else {
                                            failed?(NSError(domain: "封面请求失败", code: 2, userInfo: [
                                                "identifier": self.localIdentifier,
                                                "errorCode": "2"
                                            ]))
                                            print("compress finish but not found file")
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
                                    } catch let error as NSError{
                                        failed?(NSError(domain: "视频请求失败", code: 2, userInfo: [
                                            "identifier": self.localIdentifier,
                                            "errorCode": "2"
                                        ]))
                                        print(error)
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
            //gif压缩
            if let uti = self.value(forKey: "filename"), uti is String, (uti as! String).uppercased().hasSuffix("GIF") {
                let fileName = "\(uuid).gif"
                let filePath = saveDir + fileName
                let checkFileName = "\(uuid)-check.gif"
                let checkPath = saveDir + checkFileName
                let fileTmpPath = saveDir + fileName + "." + tmpSuffix
                if FileManager.default.fileExists(atPath: filePath), FileManager.default.fileExists(atPath: checkPath) {
                    let cacheImg = UIImage.init(contentsOfFile: filePath)
                    finish?([
                        "identifier": self.localIdentifier,
                        "filePath":filePath,
                        "checkPath":checkPath,
                        "width": cacheImg?.size.width ?? targetWidth,
                        "height": cacheImg?.size.height ?? targetHeight,
                        "name": fileName,
                        "fileType":"image/gif"
                    ])
                }else{
                    manager.requestImageData(for: self, options: thumbOptions) { (data, uti, ori, info) in
                        DispatchQueue.global().async {
                            do {
                                if let file = data {
                                    //压缩gif
                                    var resultData = try ImageCompress.compressImageData(file as Data, sampleCount: 1)
                                    resultData = (resultData.count > file.count) ? file : resultData
                                    try resultData.write(to: URL(fileURLWithPath: fileTmpPath))
                                    //压缩送审图片，更小
                                    let checkData = try ImageCompress.compressImageData(file as Data, sampleCount: 24)
                                    try checkData.write(to: URL(fileURLWithPath: checkPath))
                                    do {
                                        //移动文件到doc缓存目录
                                        try PHAsset.moveFile(atPath: fileTmpPath, toPath: filePath)
                                    }catch let err as NSError {
                                        print(err)
                                    }
                                    if FileManager.default.fileExists(atPath: filePath) {
                                        finish?([
                                            "identifier": self.localIdentifier,
                                            "filePath":filePath,
                                            "checkPath":checkPath,
                                            "width": resultData.imageSize.width,
                                            "height": resultData.imageSize.height,
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
                }
            }else {
                //图片压缩
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
                    if pixel > MAXPixel {
                        targetWidth = MAXPixel / pixel * targetWidth
                        targetHeight = MAXPixel / pixel * targetHeight
                    }
                    manager.requestImage(for: self, targetSize: CGSize(width: targetWidth, height: targetHeight), contentMode: PHImageContentMode.aspectFit, options: thumbOptions, resultHandler: { (image: UIImage?, info) in
                        DispatchQueue.global().async {
                            if let imageData = (thumb ? UIImage.lubanCompressImage(image) : UIImage.lubanOriginImage(image)) as NSData? {
                                if thumb {
                                    //使用缩率图
                                    imageData.write(toFile: fileTmpPath, atomically: true)
                                    if targetWidth * targetHeight > 312 * 312, let checkImage = UIImage.compressImage(UIImage(data: imageData as Data), toTargetWidth: 312, toTargetWidth: 312), let checkImageData = checkImage.jpegData(compressionQuality: 1.0) as NSData? {
                                        checkImageData.write(toFile: checkPath, atomically: true)
                                    }
                                    
                                    do {
                                        try PHAsset.moveFile(atPath: fileTmpPath, toPath: filePath)
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
                                    //使用原图
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
                        }
                    })
                }
            }
        }
    }
}
