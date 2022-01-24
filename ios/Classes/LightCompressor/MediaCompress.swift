//
//  MediaCompress.swift
//  multi_image_picker
//
//  Created by johnson_zhong on 2021/3/22.
//

import Foundation
import AVFoundation
import Photos

class MediaCompress {
    func compressAsset(_ thumb : Bool, fileType : String, originPath : String, saveDir : String, process: ((NSDictionary) -> Void)?, failed: ((NSError) -> Void)?, finish: ((NSDictionary) -> Void)?) {
        if FileManager.default.fileExists(atPath: originPath) {
            var uuid = UUID().uuidString;
            uuid = uuid.replacingOccurrences(of: "/", with: "")
            let tmpSuffix = UUID().uuidString;
            if fileType.lowercased().contains("video") {
                let avAsset = AVURLAsset(url: URL(fileURLWithPath: originPath))
                let dictionary : NSMutableDictionary = NSMutableDictionary()
                let thumbName = "\(uuid).jpg"
                let videoName = "\(uuid).mp4"
                let thumbPath = saveDir + thumbName
                let thumbTmpPath = saveDir + thumbName + "." + tmpSuffix
                let videoPath = saveDir + videoName
                let videoTmpPath = saveDir + videoName + "." + tmpSuffix
                let duration = CMTimeGetSeconds(avAsset.duration)

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
                    dictionary.setValue("", forKey: "identifier")
                    dictionary.setValue(originPath, forKey: "originPath")
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
                        source: avAsset,
                        destination: URL(fileURLWithPath: videoTmpPath),
                        quality: .low,
                        keepOriginalResolution: false,
                        completion: {result in
                            switch (result) {
                            case .onCancelled:
                                failed?(NSError(domain: "视频压缩已被取消", code: 2, userInfo: [
                                    "fileType":fileType,
                                    "originPath":originPath,
                                    "errorCode": "11112"
                                ]))
                                print("compress canceled")
                            case .onFailure(let error):
                                failed?(NSError(domain: error.localizedDescription, code: 2, userInfo: [
                                    "fileType":fileType,
                                    "originPath":originPath,
                                    "errorCode": "111112"
                                ]))
                                print("compress failure \(error)")
                            case .onStart:
                                print("start compress")
                            case .onSuccess(let path, let size):
                                do {
                                    try PHAsset.moveFile(atPath: path.path, toPath: videoPath)
                                    if let thumbInfo = PHAsset.fetchThumbFromVideo(thumbPath: thumbPath, thumbTmpPath: thumbTmpPath, videoPath: videoPath)  {
                                        dictionary.setValue(thumbInfo.0, forKey: "thumbPath")
                                        dictionary.setValue(thumbName, forKey: "thumbName")
                                        dictionary.setValue(thumbInfo.1.height, forKey: "thumbHeight")
                                        dictionary.setValue(thumbInfo.1.width, forKey: "thumbWidth")
                                    }else {
                                        failed?(NSError(domain: "封面请求失败", code: 2, userInfo: [
                                            "identifier": "",
                                            "errorCode": "2"
                                        ]))
                                        print("compress finish but not found file")
                                    }
                                    dictionary.setValue("", forKey: "identifier")
                                    dictionary.setValue(originPath, forKey: "originPath")
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
                                        "fileType":fileType,
                                        "originPath":originPath,
                                        "errorCode": "1111112"
                                    ]))
                                    print("compress finish but not found file")
                                    print(error)
                                }
                            }
                       }
                    )
                }
            }else {
                let data = NSData(contentsOfFile: originPath) ?? NSData()
                let type = PHAsset.contentTypeForImageData(data: data)
                let image = UIImage(data: data as Data)
                let targetHeight : CGFloat = image?.size.height ?? 0
                let targetWidth : CGFloat = image?.size.width ?? 0
                if type.lowercased().contains("gif") {
                    let fileName = "\(uuid).gif"
                    let checkFileName = "\(uuid)-check.gif"
                    let filePath = saveDir + fileName
                    let checkPath = saveDir + checkFileName
                    let fileTmpPath = saveDir + fileName + "." + tmpSuffix
                    do {
                        let resultData = try ImageCompress.compressImageData(data as Data, sampleCount: 1)
                        try resultData.write(to: URL(fileURLWithPath: fileTmpPath))
                        let checkData = try ImageCompress.compressImageData(data as Data, sampleCount: 24)
                        try checkData.write(to: URL(fileURLWithPath: checkPath))
                        do {
                            try PHAsset.moveFile(atPath: fileTmpPath, toPath: filePath)
                        }catch let err as NSError {
                            print(err)
                        }
                        if FileManager.default.fileExists(atPath: filePath) {
                            finish?([
                                "identifier": "",
                                "fileType":fileType,
                                "originPath":originPath,
                                "filePath":filePath,
                                "checkPath":checkPath,
                                "width": targetWidth,
                                "height": targetHeight,
                                "name": fileName,
                                "fileType":"image/gif"
                            ])
                        }else {
                            failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                "identifier": "",
                                "fileType":fileType,
                                "originPath":originPath,
                                "errorCode": "3"
                            ]))
                        }
                    }catch let err as NSError {
                        print(err)
                        failed?(NSError(domain: "图片请求失败", code: 2, userInfo: [
                            "identifier": "",
                            "fileType":fileType,
                            "originPath":originPath,
                            "errorCode": "12"
                        ]))
                    }
                }else {
                    let fileName = "\(uuid)-\(thumb ? "thumb" : "origin").jpg"
                    let filePath = saveDir + fileName
                    let checkPath = saveDir + fileName + ".check"
                    let fileTmpPath = saveDir + fileName + "." + tmpSuffix
                    if FileManager.default.fileExists(atPath: filePath) {
                        finish?([
                            "identifier": "",
                            "filePath":filePath,
                            "checkPath": FileManager.default.fileExists(atPath: checkPath) ? checkPath : filePath,
                            "width": targetWidth,
                            "height": targetHeight,
                            "name": fileName,
                            "fileType":"image/jpeg"
                        ])
                    }else {
                        if let imageData = (thumb ? UIImage.lubanCompressImage(image) : UIImage.lubanOriginImage(image)) as NSData? {
                            if thumb {
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
                                        "identifier": "",
                                        "filePath":filePath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "checkPath": FileManager.default.fileExists(atPath: checkPath) ? checkPath : filePath,
                                        "name": fileName,
                                        "fileType":"image/jpeg"
                                    ])
                                }else {
                                    failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                        "identifier": "",
                                        "fileType":fileType,
                                        "originPath":originPath,
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
                                        "identifier": "",
                                        "filePath":filePath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "checkPath": FileManager.default.fileExists(atPath: checkPath) ? checkPath : filePath,
                                        "name": fileName,
                                        "fileType":"image/jpeg"
                                    ])
                                }else {
                                    failed?(NSError(domain: "图片保存失败", code: 3, userInfo: [
                                        "identifier": "",
                                        "fileType":fileType,
                                        "originPath":originPath,
                                        "errorCode": "3"
                                    ]))
                                }
                            }
                        }else {
                            failed?(NSError(domain: "图片请求失败", code: 2, userInfo: [
                                "identifier": "",
                                "fileType":fileType,
                                "originPath":originPath,
                                "errorCode": "112"
                            ]))
                        }
                    }
                }
            }
        }else {
            failed?(NSError(domain: "图片请求失败", code: 2, userInfo: [
                "identifier": "",
                "fileType":fileType,
                "originPath":originPath,
                "errorCode": "1112"
            ]))
        }
    }
}
