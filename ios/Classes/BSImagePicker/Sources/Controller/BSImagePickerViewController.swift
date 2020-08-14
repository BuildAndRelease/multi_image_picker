// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import Photos

/**
BSImagePickerViewController.
Use settings or buttons to customize it to your needs.
*/
open class BSImagePickerViewController : UINavigationController{
    var assetStore : AssetStore?
    var defaultSelectMedia : String = ""
    var selectionClosure: ((_ asset: PHAsset) -> Void)?
    var deselectionClosure: ((_ asset: PHAsset) -> Void)?
    var cancelClosure: ((_ assets: [Dictionary<String, String>], _ thumb : Bool) -> Void)?
    var finishClosure: ((_ assets: NSDictionary, _ success : Bool, _ error : NSError) -> Void)?
    var selectLimitReachedClosure: ((_ selectionLimit: Int) -> Void)?
    
    open var settings: BSImagePickerSettings = Settings()
    
    @objc open var selectMedias: [String] = [] {
        didSet {
            let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: selectMedias, options: nil)
            var sortedSelections : [PHAsset] = []
            for identify in selectMedias {
                for i in 0 ..< assets.count {
                    if assets.object(at: i).localIdentifier == identify {
                        sortedSelections.append(assets.object(at: i))
                        break
                    }
                }
            }
            self.assetStore = AssetStore(assets: sortedSelections)
        }
    }
    
    @objc open lazy var fetchResults: [PHFetchResult] = { () -> [PHFetchResult<PHAssetCollection>] in
        let fetchOptions = PHFetchOptions()
        // Camera roll fetch result
        let cameraRollResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)
        fetchOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        // Albums fetch result
        let albumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        return [cameraRollResult, albumResult]
    }()
    
    @objc lazy var photosViewController: PhotosViewController = {
        let vc = PhotosViewController(fetchResults: self.fetchResults, assetStore: assetStore ?? AssetStore(assets: []), settings: self.settings)
        vc.selectionClosure = selectionClosure
        vc.deselectionClosure = deselectionClosure
        vc.cancelClosure = cancelClosure
        vc.finishClosure = finishClosure
        vc.selectLimitReachedClosure = selectLimitReachedClosure
        return vc
    }()
    
    @objc lazy var previewController: PreviewViewController = {
        let vc = PreviewViewController(settings: settings);
        vc.cancelClosure = cancelClosure
        vc.finishClosure = finishClosure
        vc.selectionClosure = selectionClosure
        vc.deselectionClosure = deselectionClosure
        vc.selectLimitReachedClosure = selectLimitReachedClosure
        if let album = fetchResults.first?.firstObject {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending:false)
            ]
            let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
            var index = 0
            if (!self.defaultSelectMedia.isEmpty) {
                if let defaultAsset = PHAsset.fetchAssets(withLocalIdentifiers: [self.defaultSelectMedia], options: fetchOptions).firstObject {
                    index = fetchResult.index(of: defaultAsset)
                }
            }else{
                index = fetchResult.index(of: self.assetStore!.assets.first!)
            }
            vc.currentAssetIndex = index
            vc.fetchResult = fetchResult
        }
        return vc
    }()
    
    @objc class func authorize(_ status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(), fromViewController: UIViewController, completion: @escaping (_ authorized: Bool) -> Void) {
        switch status {
        case .authorized:
            // We are authorized. Run block
            completion(true)
        case .notDetermined:
            // Ask user for permission
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    self.authorize(status, fromViewController: fromViewController, completion: completion)
                })
            })
        default: ()
            DispatchQueue.main.async(execute: { () -> Void in
                completion(false)
            })
        }
    }
    
    /**
    Sets up an classic image picker with results from camera roll and albums
    */
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
    Load view. See apple documentation
    */
    open override func loadView() {
        super.loadView()
        // TODO: Settings
        view.backgroundColor = UIColor.white
        
        // Make sure we really are authorized
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            if !defaultSelectMedia.isEmpty {
                setViewControllers([previewController], animated: false)
            }else {
                setViewControllers([photosViewController], animated: false)
            }
        }
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
}

// MARK: ImagePickerSettings proxy
extension BSImagePickerViewController: BSImagePickerSettings {
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var thumb: Bool {
        get {
            return settings.thumb
        }
        set {
            settings.thumb = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var maxNumberOfSelections: Int {
        get {
            return settings.maxNumberOfSelections
        }
        set {
            settings.maxNumberOfSelections = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    public var selectionCharacter: Character? {
        get {
            return settings.selectionCharacter
        }
        set {
            settings.selectionCharacter = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var selectionFillColor: UIColor {
        get {
            return settings.selectionFillColor
        }
        set {
            settings.selectionFillColor = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var selectionStrokeColor: UIColor {
        get {
            return settings.selectionStrokeColor
        }
        set {
            settings.selectionStrokeColor = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var selectionTextAttributes: [NSAttributedString.Key: AnyObject] {
        get {
            return settings.selectionTextAttributes
        }
        set {
            settings.selectionTextAttributes = newValue
        }
    }
    
    /**
     See BSImagePicketSettings for documentation
     */
    @objc public var cellsPerRow: (_ verticalSize: UIUserInterfaceSizeClass, _ horizontalSize: UIUserInterfaceSizeClass) -> Int {
        get {
            return settings.cellsPerRow
        }
        set {
            settings.cellsPerRow = newValue
        }
    }
    
}
