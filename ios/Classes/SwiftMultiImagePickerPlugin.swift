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
        case "requestMediaData":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let selectedAssets = arguments["selectedAssets"] as! Array<String>
            let quality = (arguments["qualityOfImage"] as? Int) ?? 100
            let maxHeight = (arguments["maxHeight"] as? Int) ?? 1024
            let maxWidth = (arguments["maxWidth"] as? Int) ?? 768
            let compressionQuality = CGFloat(quality) / CGFloat(100)
            let thumb = (arguments["thumb"] as? Bool) ?? true
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: selectedAssets, options: fetchOptions)
            DispatchQueue.global().async {
                let thumbDir = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? NSTemporaryDirectory()) + "/multi_image_pick/thumb/"
                if !FileManager.default.fileExists(atPath: thumbDir) {
                    do {
                        try FileManager.default.createDirectory(atPath: thumbDir, withIntermediateDirectories: true, attributes: nil)
                    }catch{
                        print(error)
                    }
                }
                var results = [NSDictionary]();
                for index in 0 ..< assets.count {
                    let asset = assets.object(at: index)
                    var compressing = true
                    asset.compressAsset(maxWidth, maxHeight: maxHeight, quality: compressionQuality, thumb: thumb, saveDir: thumbDir, process: { (process) in
                        
                    }, failed: { (err) in
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
        case "fetchMediaInfo":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let limit = arguments["limit"] as! Int
            let offset = arguments["offset"] as! Int
            weak var weakSelf = self
            DispatchQueue.global().async {
                if limit < -1 {
                    result(FlutterError(code: "PARAM ERROR", message: "limit must cannot be \(limit)", details: nil))
                    return
                }
                if offset < -1 {
                    result(FlutterError(code: "PARAM ERROR", message: "offset must cannot be \(offset)", details: nil))
                    return
                }
                let medias = NSMutableArray()
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [
                    NSSortDescriptor(key: "creationDate", ascending: false)
                ]
                
                let assets = PHAsset.fetchAssets(with: fetchOptions)
                for i in offset ..< min((limit + offset), assets.count) {
                      let asset = assets.object(at: i)
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
                            dictionary.setValue("image/jpg", forKey: "fileType")
                        }
                      }
                      medias.add(dictionary)
                }
                result(medias)
            }
        case "fetchMediaThumbData":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let localIdentifier = arguments["identifier"] as! String
            weak var weakSelf = self
            DispatchQueue.global().async {
                let imageRequestOptions = PHImageRequestOptions()
                imageRequestOptions.isNetworkAccessAllowed = false
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
            let maxHeight = (arguments["maxHeight"] as? Int) ?? 1024
            let maxWidth = (arguments["maxWidth"] as? Int) ?? 768
            let compressionQuality = Float(quality) / Float(100)
            
            vc.maxNumberOfSelections = maxImages
            vc.maxWidthOfImage = maxWidth
            vc.maxHeightOfImage = maxHeight
            vc.qualityOfThumb = CGFloat(compressionQuality)
            
            if selectedAssets.count > 0{
                let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: selectedAssets, options: nil)
                vc.defaultSelections = assets
            }

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

                }, cancel: { (assets: [PHAsset]) -> Void in
                    result(FlutterError(code: "CANCELLED", message: "The user has cancelled the selection", details: nil))
            }, finish: { (assets: [NSDictionary], success : Bool, error : NSError) -> Void in
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
}
