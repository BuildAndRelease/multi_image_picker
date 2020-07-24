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

class PreviewCollectionViewCell: UICollectionViewCell, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    var photoImageView : UIImageView = UIImageView(frame: CGRect.zero)
    var playImageView : UIImageView = UIImageView(frame: CGRect.zero)
    var scrollView : UIScrollView = UIScrollView(frame: CGRect.zero)
    
    var mediaPlayer : AVPlayer?
    var playerLayer : AVPlayerLayer?
    var videoAsset : AVAsset?
    var scale : CGFloat = 1.0
    var image : UIImage? {
        didSet{
            if image != nil {
                photoImageView.image = image
                photoImageView.sizeToFit()

                let scaleW = scrollView.frame.width/image!.size.width
                let scaleH = scrollView.frame.height/image!.size.height
                scale = min(min(scaleW, scaleH), 1.0)
                scrollView.minimumZoomScale = scale
                scrollView.maximumZoomScale = scale * 8
                scrollView.zoomScale = scale
                scrollViewDidZoom(scrollView)
            }
        }
    }
    
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
                        weakSelf?.image = UIImage.gifImageWithData(result)
                    }else {
                        weakSelf?.image = UIImage(data: result)
                    }
                })
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height)
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(photoImageView)
        
        scrollView.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height)
        scrollView.isUserInteractionEnabled = true;
        scrollView.isScrollEnabled = true;
        scrollView.bounces = true;
        scrollView.maximumZoomScale = 8.0
        scrollView.minimumZoomScale = 0.2
        scrollView.delegate = self;
        scrollView.clipsToBounds = true;
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scrollView)
        
        playImageView.image = UIImage.wm_imageWithName_WMCameraResource(named: "play_btn_unselect")
        playImageView.highlightedImage = UIImage.wm_imageWithName_WMCameraResource(named: "play_btn_select")
        playImageView.contentMode = .scaleAspectFit
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(playImageView)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: scrollView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: playImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 50),
            NSLayoutConstraint(item: playImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 50),
            NSLayoutConstraint(item: playImageView, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: playImageView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
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
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageViewSize = photoImageView.frame.size
        let scrollViewSize = scrollView.frame.size
        
        let verticalPadding = (imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0)
        let horizontalPadding = (imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0)
                
        if verticalPadding >= 0 {
            scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        } else {
            scrollView.contentSize = imageViewSize
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
