import Flutter
import UIKit
import Photos

public class SwiftMultiImagePickerPlugin: NSObject, FlutterPlugin {
    var controller: UIViewController!
    var imagesResult: FlutterResult?
    var messenger: FlutterBinaryMessenger;

    init(cont: UIViewController, messenger: FlutterBinaryMessenger) {
        self.controller = cont;
        self.messenger = messenger;
        super.init();
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "multi_image_picker", binaryMessenger: registrar.messenger())

        let app =  UIApplication.shared
        let rootController = app.delegate!.window!!.rootViewController
        var flutterController: FlutterViewController? = nil
        if rootController is FlutterViewController {
            flutterController = rootController as? FlutterViewController
        } else if app.delegate is FlutterAppDelegate {
            if (app.delegate?.responds(to: Selector(("flutterEngine"))))! {
                let engine: FlutterEngine? = app.delegate?.perform(Selector(("flutterEngine")))?.takeRetainedValue() as? FlutterEngine
                flutterController = engine?.viewController
            }
        }
        let controller : UIViewController = flutterController ?? rootController!;
        let instance = SwiftMultiImagePickerPlugin.init(cont: controller, messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
        case "pickImages":
            let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            if (status == PHAuthorizationStatus.denied) {
                return result(FlutterError(code: "PERMISSION_PERMANENTLY_DENIED", message: "The user has denied the gallery access.", details: nil))
            }
            
            let vc = BSImagePickerViewController()
            
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let maxImages = arguments["maxImages"] as! Int
            let options = arguments["iosOptions"] as! Dictionary<String, String>
            let selectedAssets = arguments["selectedAssets"] as! Array<String>
            let quality = (arguments["qualityOfImage"] as? Int) ?? 100
            let maxHeight = (arguments["maxHeight"] as? Int) ?? 100
            let maxWidth = (arguments["maxWidth"] as? Int) ?? 100
            let compressionQuality = Float(quality) / Float(100)
            
            vc.maxNumberOfSelections = maxImages
        
            
            if selectedAssets.count > 0{
                let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: selectedAssets, options: nil)
                vc.defaultSelections = assets
            }

            if let selectionFillColor = options["selectionFillColor"] , !selectionFillColor.isEmpty{
                vc.selectionFillColor = hexStringToUIColor(hex: selectionFillColor)
            }

            if let selectionShadowColor = options["selectionShadowColor"], !selectionShadowColor.isEmpty {
                vc.selectionShadowColor = hexStringToUIColor(hex: selectionShadowColor)
            }

            if let selectionStrokeColor = options["selectionStrokeColor"] ,!selectionStrokeColor.isEmpty {
                vc.selectionStrokeColor = hexStringToUIColor(hex: selectionStrokeColor)
            }

            if let selectionTextColor = options["selectionTextColor"] , !selectionTextColor.isEmpty{
                vc.selectionTextAttributes[NSAttributedString.Key.foregroundColor] = hexStringToUIColor(hex: selectionTextColor)
            }

            if let selectionCharacter = options["selectionCharacter"] , !selectionCharacter.isEmpty {
                vc.selectionCharacter = Character(selectionCharacter)
            }

            let thumbDir = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? NSTemporaryDirectory()) + "/multi_image_pick/thumb/"
            let manager = PHImageManager.default()
            let thumbOptions = PHImageRequestOptions()
            thumbOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            thumbOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
            thumbOptions.isSynchronous = false
            thumbOptions.isNetworkAccessAllowed = true
            thumbOptions.version = .current
            if !FileManager.default.fileExists(atPath: thumbDir) {
                do {
                    try FileManager.default.createDirectory(atPath: thumbDir, withIntermediateDirectories: true, attributes: nil)
                }catch{
                    print(error)
                }
            }
            
            controller!.bs_presentImagePickerController(vc, animated: true,
                select: { (asset: PHAsset) -> Void in
                    
                }, deselect: { (asset: PHAsset) -> Void in

                }, cancel: { (assets: [PHAsset]) -> Void in
                    result(FlutterError(code: "CANCELLED", message: "The user has cancelled the selection", details: nil))
                }, finish: { (assets: [PHAsset], thumb : Bool) -> Void in
                    var results = [NSDictionary]();
                    var count = 0;
                    for asset in assets {
                        if asset.mediaType == .video {
                            let options = PHVideoRequestOptions()
                            options.deliveryMode = .highQualityFormat
                            options.isNetworkAccessAllowed = false
                            manager.requestAVAsset(forVideo: asset, options: options) { (avAsset, audioMix, info) in
                                count += 1;
                                if avAsset != nil {
                                    let dictionary : NSMutableDictionary = NSMutableDictionary()
                                    let uuid = UUID().uuidString
                                    let thumbName = "\(uuid).jpg"
                                    let videoName = "\(uuid).mp4"
                                    let thumbPath = thumbDir + thumbName
                                    let videoPath = thumbDir + videoName
                                    if FileManager.default.fileExists(atPath: videoPath) {
                                        try? FileManager.default.removeItem(atPath: videoPath)
                                    }
                                    if FileManager.default.fileExists(atPath: thumbPath) {
                                        try? FileManager.default.removeItem(atPath: thumbPath)
                                    }
                                    
                                    let gen = AVAssetImageGenerator(asset: avAsset!)
                                    gen.appliesPreferredTrackTransform = true
                                    let time = CMTimeMakeWithSeconds(2.0, preferredTimescale: 600);
                                    var actualTime  = CMTimeMake(value: 0, timescale: 0)
                                    if let image = try? gen.copyCGImage(at: time, actualTime: &actualTime) {
                                        let thumbImg = UIImage(cgImage: image)
                                        do {
                                            try thumbImg.jpegData(compressionQuality: 0.6)?.write(to: URL(fileURLWithPath: thumbPath))
                                        } catch let error as NSError {
                                            print(error)
                                            if (count >= assets.count) {
                                                result(results);
                                            }
                                        }
                                        dictionary.setValue(thumbPath, forKey: "thumbPath")
                                        dictionary.setValue(thumbName, forKey: "thumbName")
                                        dictionary.setValue(thumbImg.size.height * thumbImg.scale, forKey: "thumbHeight")
                                        dictionary.setValue(thumbImg.size.width * thumbImg.scale, forKey: "thumbWidth")
                                    }else {
                                        if (count >= assets.count) {
                                            result(results);
                                        }
                                    }
                                    
                                    let exportSession = AVAssetExportSession(asset: avAsset!, presetName: AVAssetExportPresetMediumQuality)
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
                                            
                                            dictionary.setValue(asset.localIdentifier, forKey: "identifier")
                                            dictionary.setValue(videoPath, forKey: "filePath")
                                            dictionary.setValue(thumbVideoSize.width, forKey: "width")
                                            dictionary.setValue(thumbVideoSize.height, forKey: "height")
                                            dictionary.setValue(videoName, forKey: "name")
                                            dictionary.setValue("video", forKey: "fileType")
                                            results.append(dictionary);
                                        }
                                        if (count >= assets.count) {
                                            result(results);
                                        }
                                    })
                                }else {
                                    if (count >= assets.count) {
                                        result(results);
                                    }
                                }
                            }
                        }else {
                            var targetHeight : CGFloat = CGFloat(asset.pixelHeight)
                            var targetWidth : CGFloat = CGFloat(asset.pixelWidth)
                            if (thumb && (asset.pixelWidth > maxWidth || asset.pixelHeight > maxHeight)) {
                                let heightCompressRatio = CGFloat(maxHeight)/CGFloat(asset.pixelHeight)
                                let widthCompressRatio = CGFloat(maxWidth)/CGFloat(asset.pixelWidth)
                                if (heightCompressRatio <= widthCompressRatio) {
                                    targetHeight = CGFloat(maxHeight)
                                    targetWidth = heightCompressRatio * CGFloat(asset.pixelWidth)
                                }else {
                                    targetWidth = CGFloat(maxWidth)
                                    targetHeight = widthCompressRatio * CGFloat(asset.pixelHeight)
                                }
                            }
                            let ID: PHImageRequestID = manager.requestImage(for: asset, targetSize: CGSize(width: targetWidth, height: targetHeight), contentMode: PHImageContentMode.aspectFit, options: thumbOptions, resultHandler: { (image: UIImage?, info) in
                                count += 1;
                                let uuid = UUID().uuidString
                                let fileName = "\(uuid).jpg"
                                let filePath = thumbDir + fileName
                                if FileManager.default.fileExists(atPath: filePath) {
                                    try? FileManager.default.removeItem(atPath: filePath)
                                }
                                let imageData = image?.jpegData(compressionQuality: thumb ? CGFloat(compressionQuality) : 1.0) as NSData?
                                imageData?.write(toFile: filePath, atomically: true)
                                if FileManager.default.fileExists(atPath: filePath) {
                                    results.append([
                                        "identifier": asset.localIdentifier,
                                        "filePath":filePath,
                                        "width": targetWidth,
                                        "height": targetHeight,
                                        "name": fileName,
                                        "fileType":"image"
                                    ]);
                                }
                                if (count >= assets.count) {
                                    result(results);
                                }
                            })
                            if(PHInvalidImageRequestID != ID) {
                                if (count >= assets.count) {
                                    result(results);
                                }else {
                                    continue
                                }
                            }
                        }
                    }
                }, completion: nil)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    deinit {
        print("deinit")
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
