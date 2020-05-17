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
    var imageView: UIImageView = UIImageView(frame: UIScreen.main.bounds)
    var playImageView : UIImageView = UIImageView(frame: CGRect.zero)
    
    var mediaPlayer : AVPlayer?
    var playerLayer : AVPlayerLayer?
    var videoAsset : AVAsset?
    
    var fullscreen = false
    var cancelBarButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back", comment: ""), style: .plain, target: nil, action: nil)
    var asset: PHAsset? {
        didSet {
            if asset != nil {
                self.playImageView.isHidden = self.asset?.mediaType != .video
                weak var weakSelf = self
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                PHCachingImageManager.default().requestImage(for: asset!, targetSize:imageView.frame.size, contentMode: .aspectFit, options: options) { (result, _) in
                    weakSelf?.imageView.image = result
                }
            }
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        view.backgroundColor = UIColor.black
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        playImageView.image = UIImage(named: "play_btn_unselect", in: BSImagePickerViewController.bundle, compatibleWith: nil)
        playImageView.highlightedImage = UIImage(named: "play_btn_select", in: BSImagePickerViewController.bundle, compatibleWith: nil)
        playImageView.contentMode = .scaleAspectFit
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playImageView)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: imageView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: playImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 50),
            NSLayoutConstraint(item: playImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 50),
            NSLayoutConstraint(item: playImageView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: playImageView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        ])

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
    
    deinit {
        self.mediaPlayer?.currentItem?.cancelPendingSeeks()
        self.mediaPlayer?.currentItem?.asset.cancelLoading()
        self.playerLayer?.removeFromSuperlayer()
        self.mediaPlayer = nil
        self.playerLayer = nil
    }
    
    @objc func toggleFullscreen() {
        if asset?.mediaType == .video {
            if self.mediaPlayer == nil {//未开始播
                weak var weakSelf = self
                let options = PHVideoRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = false
                PHCachingImageManager.default().requestAVAsset(forVideo: asset!, options: options) { (avasset, audiomix, dictionary) in
                    if avasset != nil {
                        weakSelf?.videoAsset = avasset
                        DispatchQueue.main.async {
                            if let player = weakSelf?.mediaPlayer, let _ = weakSelf?.playerLayer {
                                player.replaceCurrentItem(with: AVPlayerItem(asset: avasset!))
                            }else{
                                weakSelf?.mediaPlayer = AVPlayer(playerItem: AVPlayerItem(asset: avasset!))
                                weakSelf?.playerLayer = AVPlayerLayer(player: weakSelf?.mediaPlayer)
                            }
                            weakSelf?.playerLayer?.frame = weakSelf?.view?.bounds ?? UIScreen.main.bounds
                            weakSelf?.view?.layer.addSublayer((weakSelf?.playerLayer)!)
                            weakSelf?.mediaPlayer?.play()
                            weakSelf?.mediaPlayer?.addPeriodicTimeObserver(forInterval:weakSelf?.videoAsset?.duration ?? CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main, using: { (time) in
                                if time == weakSelf?.videoAsset?.duration {
                                    let timeToStart = CMTimeMake(value: 0, timescale: weakSelf?.mediaPlayer?.currentTime().timescale ?? 600)
                                    weakSelf?.mediaPlayer?.seek(to: timeToStart)
                                    if weakSelf != nil {
                                        weakSelf?.view.bringSubviewToFront(weakSelf!.playImageView)
                                    }
                                }
                            })
                        }
                    }
                }
            }else if self.mediaPlayer?.currentItem?.currentTime() == self.mediaPlayer?.currentItem?.duration {//stop
                let timeToStart = CMTimeMake(value: 0, timescale: self.mediaPlayer?.currentTime().timescale ?? 600)
                self.mediaPlayer?.seek(to: timeToStart)
                self.mediaPlayer?.play()
            }else if self.mediaPlayer?.rate != 0.0 {//正在播放
                self.view.bringSubviewToFront(self.playImageView)
                self.mediaPlayer?.rate = 0.0
            }else if self.mediaPlayer?.rate == 0.0 {//暂停
                self.mediaPlayer?.rate = 1.0
                self.view.sendSubviewToBack(self.playImageView)
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
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        self.mediaPlayer?.pause()
        self.mediaPlayer?.currentItem?.cancelPendingSeeks()
        self.mediaPlayer?.currentItem?.asset.cancelLoading()
        self.playerLayer?.removeFromSuperlayer()
        self.mediaPlayer = nil
        self.playerLayer = nil
        self.view.bringSubviewToFront(self.playImageView)
        self.navigationController?.popViewController(animated: true)
    }
}
