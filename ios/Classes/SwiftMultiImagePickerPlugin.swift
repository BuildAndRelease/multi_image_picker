import Flutter
import UIKit
import Photos

public class SwiftMultiImagePickerPlugin: NSObject, FlutterPlugin, UIAlertViewDelegate {
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
        case "requestMediaData":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let selectedAssets = (arguments["selectedAssets"] as? Array<String>) ?? []
            let thumb = (arguments["thumb"] as? Bool) ?? true
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: selectedAssets, options: nil)
            DispatchQueue.global().async {
                let thumbDir = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? NSTemporaryDirectory()) + "/multi_image_pick/thumb/"
                if !FileManager.default.fileExists(atPath: thumbDir) {
                    do {
                        try FileManager.default.createDirectory(atPath: thumbDir, withIntermediateDirectories: true, attributes: nil)
                        var url = URL(fileURLWithPath: thumbDir, isDirectory: true)
                        var resourceValues = URLResourceValues()
                        resourceValues.isExcludedFromBackup = true
                        try url.setResourceValues(resourceValues)
                    }catch{
                        print(error)
                    }
                }
                var results = [NSDictionary]();
                for index in 0 ..< assets.count {
                    let asset = assets.object(at: index)
                    var compressing = true
                    asset.compressAsset(thumb, saveDir: thumbDir, process: { (process) in
                        
                    }, failed: { (err) in
                        results.append(err.userInfo as NSDictionary)
                        compressing = false
                    }) { (info) in
                        results.append(info)
                        compressing = false
                    }
                    while compressing {
                        usleep(50000)
                    }
                }
                result(results)
            }
        case "requestFileSize":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let localIdentifier = (arguments["identifier"] as? String) ?? ""
            DispatchQueue.global().async {
                if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject {
                    result("\(asset.fileSize)")
                }else {
                    result(FlutterError(code: "PARAM ERROR", message: "cannot find asset", details: nil))
                }
            }
        case "requestFileDimen":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let localIdentifier = (arguments["identifier"] as? String) ?? ""
            DispatchQueue.global().async {
                if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject {
                    result(["width": asset.pixelWidth, "height": asset.pixelHeight])
                }else {
                    result(FlutterError(code: "PARAM ERROR", message: "cannot find asset", details: nil))
                }
            }
        case "fetchMediaInfo":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            var limit = (arguments["limit"] as? Int) ?? 5
            var offset = (arguments["offset"] as? Int) ?? 0
            let selectedAssets = (arguments["selectedAssets"] as? Array<String>) ?? []
            weak var weakSelf = self
            DispatchQueue.global().async {
                let medias = NSMutableArray()
                
                let fetchResult = selectedAssets.count > 0 ? PHAsset.fetchAssets(withLocalIdentifiers: selectedAssets, options: nil) : PHAsset.fetchAssets(with: nil)
                var assets : Array<PHAsset> = []
                fetchResult.enumerateObjects(options: [.reverse]) { (asset, index, pt) in
                    assets.append(asset)
                }
                if limit == -1, offset == -1 {
                    limit = assets.count
                    offset = 0
                }else if limit < -1 {
                    result(FlutterError(code: "PARAM ERROR", message: "limit must cannot be \(limit)", details: nil))
                    return
                }else if offset < -1 {
                    result(FlutterError(code: "PARAM ERROR", message: "offset must cannot be \(offset)", details: nil))
                    return
                }
                for i in offset ..< min((limit + offset), assets.count) {
                    let asset = assets[i]
                    let size = weakSelf?.getThumbnailSize(originSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)) ?? CGSize(width: asset.pixelWidth/2, height: asset.pixelHeight/2)
                    let dictionary = NSMutableDictionary()
                    dictionary.setValue(asset.localIdentifier, forKey: "identifier")
                    dictionary.setValue("", forKey: "filePath")
                    dictionary.setValue(CGFloat(size.width), forKey: "width")
                    dictionary.setValue(CGFloat(size.height), forKey: "height")
                    dictionary.setValue(asset.originalFilename, forKey: "name")
                    dictionary.setValue(asset.duration, forKey: "duration")
                    if asset.mediaType == .video {
                        dictionary.setValue("video", forKey: "fileType")
                    }else if asset.mediaType == .image {
                      if let uti = asset.value(forKey: "uniformTypeIdentifier"), uti is String, (uti as! String).contains("gif") {
                          dictionary.setValue("image/gif", forKey: "fileType")
                      }else {
                          dictionary.setValue("image/jpeg", forKey: "fileType")
                      }
                    }
                    medias.add(dictionary)
                }
                result(medias)
            }
        case "fetchMediaThumbData":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let localIdentifier = (arguments["identifier"] as? String) ?? ""
            weak var weakSelf = self
            DispatchQueue.global().async {
                let imageRequestOptions = PHImageRequestOptions()
                imageRequestOptions.isNetworkAccessAllowed = true
                imageRequestOptions.deliveryMode = .highQualityFormat
                imageRequestOptions.resizeMode = .fast
                imageRequestOptions.isSynchronous = false
                let imageContentMode: PHImageContentMode = .aspectFill
                
                if let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject {
                    PHCachingImageManager.default().requestImage(for: asset, targetSize: weakSelf?.getThumbnailSize(originSize: CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))) ?? CGSize(width: asset.pixelWidth/2, height: asset.pixelHeight/2), contentMode: imageContentMode, options: imageRequestOptions) { (image, info) in
                        result(image?.jpegData(compressionQuality: 0.8) ?? FlutterError(code: "REQUEST FAILED", message: "image request failed \(localIdentifier)", details: nil))
                    }
                }else {
                    result(FlutterError(code: "REQUEST FAILED", message: "image request failed \(localIdentifier)", details: nil))
                }
            }
        case "requestThumbDirectory":
            result((NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? NSTemporaryDirectory()) + "/multi_image_pick/thumb/")
        case "requestTakePicture":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let themeColor = (arguments["themeColor"] as? String) ?? "#ff6179f2"
            let vc = WMCameraViewController()
            vc.videoMaxLength = 15
            vc.themeColor = hexStringToUIColor(hex: themeColor)
            vc.completeBlock = { url, type, duration, width, height, thumbPath, thumbWidth, thumbHeight in
                let dictionary = NSMutableDictionary()
                dictionary.setValue(url, forKey: "identifier")
                dictionary.setValue(url, forKey: "filePath")
                dictionary.setValue(width, forKey: "width")
                dictionary.setValue(height, forKey: "height")
                dictionary.setValue(url, forKey: "name")
                dictionary.setValue(duration, forKey: "duration")
                if type == .video {
                    dictionary.setValue("video", forKey: "fileType")
                }else if type == .image {
                    dictionary.setValue("image/jpeg", forKey: "fileType")
                }
                dictionary.setValue(thumbPath, forKey: "thumbPath")
                dictionary.setValue(thumbPath, forKey: "thumbName")
                dictionary.setValue(thumbHeight, forKey: "thumbHeight")
                dictionary.setValue(thumbWidth, forKey: "thumbWidth")
                result(dictionary)
            }
            vc.modalPresentationStyle = .fullScreen
            controller.present(vc, animated: true, completion: nil)
        case "pickImages":
            let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            if (status == PHAuthorizationStatus.denied) {
                return result(FlutterError(code: "PERMISSION_PERMANENTLY_DENIED", message: "The user has denied the gallery access.", details: nil))
            }
            
            let vc = BSImagePickerViewController()
            
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let maxImages = (arguments["maxImages"] as? Int) ?? 9
            let options = (arguments["iosOptions"] as? Dictionary<String, String>) ?? Dictionary<String, String>()
            let defaultAsset = (arguments["defaultAsset"] as? String) ?? ""
            let selectedAssets = (arguments["selectedAssets"] as? Array<String>) ?? [];
            let thumb = (arguments["thumb"] as? Bool) ?? true
            
            vc.maxNumberOfSelections = maxImages
            vc.selectMedias = selectedAssets
            vc.defaultSelectMedia = defaultAsset
            vc.thumb = thumb

            if let selectionFillColor = options["selectionFillColor"] , !selectionFillColor.isEmpty{
                vc.selectionFillColor = hexStringToUIColor(hex: selectionFillColor)
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

            controller!.bs_presentImagePickerController(vc, animated: true,
                select: { (asset: PHAsset) -> Void in
                    
                }, deselect: { (asset: PHAsset) -> Void in

                }, cancel: { (assets: [Dictionary<String, String>], thumb : Bool) -> Void in
                    let t = ["assets" : assets, "thumb" : thumb] as [String : Any]
                    result(FlutterError(code: "CANCELLED", message: "The user has cancelled the selection", details: t))
                }, finish: { (assets: NSDictionary, success : Bool, error : NSError) -> Void in
                    success ? result(assets) : result(FlutterError(code: "\(error.code)", message: error.domain, details: nil))
            }, completion: nil)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getThumbnailSize(originSize: CGSize) -> CGSize {
        let thumbnailWidth: CGFloat = (UIScreen.main.bounds.size.width) / 3 * UIScreen.main.scale
        let pixelScale = CGFloat(originSize.width)/CGFloat(originSize.height)
        let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailWidth/pixelScale)
        
        return thumbnailSize
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count == 6) {
            var rgbValue:UInt32 = 0
            Scanner(string: cString).scanHexInt32(&rgbValue)

            return UIColor(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: CGFloat(1.0))
        }else if (cString.count == 8) {
            var rgbValue:UInt32 = 0
            Scanner(string: cString).scanHexInt32(&rgbValue)

            return UIColor(
                red: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x000000FF) / 255.0,
                alpha: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0)
        }else {
            return UIColor.gray
        }
    
    }
    
    public func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
    }
}
