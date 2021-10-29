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
    @objc lazy var photosViewController: PhotosViewController = {
        return PhotosViewController()
    }()
    
    @objc lazy var previewController: PreviewViewController = {
        let result = DataCenter.shared.indexAndAssetsOfMainAlbum()
        return PreviewViewController(currentAssetIndex: result?.0 ?? 0, assets: result?.1 ?? []);
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
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.white
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            if !DataCenter.shared.defaultSelectMedia.isEmpty {
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
