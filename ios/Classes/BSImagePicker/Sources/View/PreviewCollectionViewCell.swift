//
//  WQPreviewCollectionViewCell.swift
//  WQPhotoAlbum
//
//  Created by 王前 on 16/12/5.
//  Copyright © 2016年 qian.com. All rights reserved.
//

import UIKit
import Photos
import AVKit

class PreviewCollectionViewCell: UICollectionViewCell {
    var photoImageView : UIImageView = UIImageView(frame: CGRect.zero)
    var playImageView : UIImageView = UIImageView(frame: CGRect.zero)
    
    var mediaPlayer : AVPlayer?
    var playerLayer : AVPlayerLayer?
    var videoAsset : AVAsset?
    
    var asset: PHAsset? {
        didSet {
            if asset != nil {
                self.playImageView.isHidden = self.asset?.mediaType != .video
                self.mediaPlayer?.currentItem?.cancelPendingSeeks()
                self.mediaPlayer?.currentItem?.asset.cancelLoading()
                self.playerLayer?.removeFromSuperlayer()
                self.mediaPlayer = nil
                self.playerLayer = nil
                weak var weakSelf = self
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = false
                if self.tag != 0 {
                    PHCachingImageManager.default().cancelImageRequest(PHImageRequestID(Int32(self.tag)))
                }

                self.tag = Int(PHCachingImageManager.default().requestImageData(for: asset!, options: options) { (data, uti, orientation, info) in
                    guard let tUti = uti, let result = data else { return }
                    if (tUti.contains("gif")) {
                        weakSelf?.photoImageView.image = UIImage.gifImageWithData(result)
                    }else {
                        weakSelf?.photoImageView.image = UIImage(data: result)
                    }
                })
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        photoImageView.contentMode = .scaleAspectFit
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(photoImageView)
        
        playImageView.image = UIImage(named: "play_btn_unselect")
        playImageView.highlightedImage = UIImage(named: "play_btn_select")
        playImageView.contentMode = .scaleAspectFit
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(playImageView)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: photoImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: photoImageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: photoImageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: photoImageView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: playImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 50),
            NSLayoutConstraint(item: playImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 50),
            NSLayoutConstraint(item: playImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: playImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func cellDidReceiveTapAction()  {
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
                            weakSelf?.playerLayer?.frame = weakSelf?.bounds ?? UIScreen.main.bounds
                            weakSelf?.layer.addSublayer((weakSelf?.playerLayer)!)
                            weakSelf?.mediaPlayer?.play()
                            weakSelf?.mediaPlayer?.addPeriodicTimeObserver(forInterval:weakSelf?.videoAsset?.duration ?? CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main, using: { (time) in
                                if time == weakSelf?.videoAsset?.duration {
                                    let timeToStart = CMTimeMake(value: 0, timescale: weakSelf?.mediaPlayer?.currentTime().timescale ?? 600)
                                    weakSelf?.mediaPlayer?.seek(to: timeToStart)
                                    if weakSelf != nil {
                                        weakSelf?.bringSubviewToFront(weakSelf!.playImageView)
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
                self.bringSubviewToFront(self.playImageView)
                self.mediaPlayer?.rate = 0.0
            }else if self.mediaPlayer?.rate == 0.0 {//暂停
                self.mediaPlayer?.rate = 1.0
                self.sendSubviewToBack(self.playImageView)
            }
        }
    }
    
    func stopPlayVideo() {
        if asset?.mediaType == .video {
            if self.mediaPlayer?.rate != 0.0 {//正在播放
                self.bringSubviewToFront(self.playImageView)
                self.mediaPlayer?.rate = 0.0
            }
        }
    }
    
    deinit {
        self.mediaPlayer?.currentItem?.cancelPendingSeeks()
        self.mediaPlayer?.currentItem?.asset.cancelLoading()
        self.playerLayer?.removeFromSuperlayer()
        self.mediaPlayer = nil
        self.playerLayer = nil
    }
    
}
