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
import AVKit

final class PreviewViewController : UIViewController {
    var imageView: UIImageView?
    var mediaPlayer : AVPlayer?
    var fullscreen = false
    var cancelBarButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back", comment: ""), style: .plain, target: nil, action: nil)
    var asset: PHAsset? {
        didSet {
            if asset != nil {
                weak var weakSelf = self
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                PHCachingImageManager.default().requestImage(for: asset!, targetSize:imageView?.frame.size ?? UIScreen.main.bounds.size, contentMode: .aspectFit, options: options) { (result, _) in
                    weakSelf?.imageView?.image = result
                }
            }
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
//        view.backgroundColor = UIColor.black
        
        imageView = UIImageView(frame: view.bounds)
        imageView?.contentMode = .scaleAspectFit
        imageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView!)
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.addTarget(self, action: #selector(PreviewViewController.toggleFullscreen))
        view.addGestureRecognizer(tapRecognizer)
        
        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: .normal)
        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.gray], for: .highlighted)
        cancelBarButton.target = self
        cancelBarButton.action = #selector(PreviewViewController.cancelButtonPressed(_:))
        navigationItem.leftBarButtonItem = cancelBarButton
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func loadView() {
        super.loadView()
    }
    
    @objc func toggleFullscreen() {
        if asset?.mediaType == .video {
            weak var weakSelf = self
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = false
            PHCachingImageManager.default().requestAVAsset(forVideo: asset!, options: options) { (avasset, audiomix, dictionary) in
                DispatchQueue.main.async {
                    let token = dictionary?["PHImageFileSandboxExtensionTokenKey"] as? String
                    let filePath = String(token?.split(separator: ";").last ?? "")
                    weakSelf?.mediaPlayer = AVPlayer(url: URL(fileURLWithPath: filePath))
                    let layer = AVPlayerLayer(player: weakSelf?.mediaPlayer)
                    layer.frame = weakSelf?.view?.bounds ?? UIScreen.main.bounds
                    weakSelf?.view?.layer.addSublayer(layer)
                    weakSelf?.mediaPlayer?.play()
                }
            }
        }else {
            weak var weakSelf = self
            fullscreen = !fullscreen
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                weakSelf?.toggleNavigationBar()
                weakSelf?.toggleStatusBar()
            })
        }
    }
    
    @objc func toggleNavigationBar() {
        navigationController?.setNavigationBarHidden(fullscreen, animated: true)
    }
    
    @objc func toggleStatusBar() {
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden : Bool {
        return fullscreen
    }
    
    // MARK: Button actions
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
}
