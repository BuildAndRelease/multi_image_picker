//
//  WMCameraViewController.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVFoundation
import Photos

enum WMCameraType {
    case video
    case image
    case imageAndVideo
}

class WMCameraViewController: UIViewController {
    
    var url: String?
    // output type
    var type: WMCameraType?
    // output duration
    var duration : CGFloat = 0.0
    // output height
    var height : CGFloat = 0.0
    // output width
    var width : CGFloat = 0.0
    // output thumbPath
    var thumbPath = ""
    // output thumbHeight
    var thumbHeight : CGFloat = 0.0
    // output thumbWidth
    var thumbWidth : CGFloat = 0.0
    // input tupe
    var inputType:WMCameraType = WMCameraType.imageAndVideo
    // record video max length
    var videoMaxLength: Double = 10
    
    var themeColor = UIColor.green
        
    var completeBlock: (String, WMCameraType, CGFloat, CGFloat, CGFloat, String, CGFloat, CGFloat) -> () = {_,_,_,_,_,_,_,_ in }
    
    let previewImageView = UIImageView()
    var videoPlayer: WMVideoPlayer!
    var controlView: WMCameraControl!
    var manager: WMCameraManger!
    
    let cameraContentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scale: CGFloat = 16.0 / 9.0
        let contentWidth = UIScreen.main.bounds.size.width
        let contentHeight = min(scale * contentWidth, UIScreen.main.bounds.size.height)
        
        cameraContentView.backgroundColor = UIColor.black
        cameraContentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        cameraContentView.center = self.view.center
        self.view.addSubview(cameraContentView)
        
        manager = WMCameraManger(superView: cameraContentView)
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.staruRunning()
        manager.focusAt(cameraContentView.center)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.black
        cameraContentView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(focus(_:))))
        cameraContentView.addGestureRecognizer(UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(_:))))
        
        videoPlayer = WMVideoPlayer(frame: cameraContentView.bounds)
        videoPlayer.isHidden = true
        cameraContentView.addSubview(videoPlayer)
        
        previewImageView.frame = cameraContentView.bounds
        previewImageView.backgroundColor = UIColor.black
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.isHidden = true
        cameraContentView.addSubview(previewImageView)
        
        controlView = WMCameraControl.init(frame: cameraContentView.bounds, themeColor: themeColor)
        controlView.delegate = self
        controlView.videoLength = self.videoMaxLength
        controlView.inputType = self.inputType
        cameraContentView.addSubview(controlView)
    }
    
    @objc func focus(_ ges: UITapGestureRecognizer) {
        let focusPoint = ges.location(in: cameraContentView)
        manager.focusAt(focusPoint)
    }
    
    @objc func pinch(_ ges: UIPinchGestureRecognizer) {
        guard ges.numberOfTouches == 2 else { return }
        if ges.state == .began {
            manager.repareForZoom()
        }
        manager.zoom(Double(ges.scale))
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
     
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
     
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
}

extension WMCameraViewController: WMCameraControlDelegate {
    
    func cameraControlDidComplete() {
        if self.type == .video {
            ALAssetsLibrary().writeVideoAtPath(toSavedPhotosAlbum: URL(fileURLWithPath: self.url!)) {[weak self] (url, error) in
                if let object = self {
                    object.dismiss(animated: true) {
                        object.completeBlock(object.url!, object.type!, object.duration, object.width, object.height, object.thumbPath, object.thumbWidth, object.thumbHeight)
                    }
                }
            }
        }else if self.type == .image {
            UIImageWriteToSavedPhotosAlbum(UIImage(contentsOfFile: self.url!) ?? UIImage(), nil, nil, nil)
            self.dismiss(animated: true) {
                self.completeBlock(self.url!, self.type!, self.duration, self.width, self.height, self.thumbPath, self.thumbWidth, self.thumbHeight)
            }
        }
    }
    
    func cameraControlDidTakePhoto() {
        manager.pickImage { [weak self] (imageUrl) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.type = .image
                self.url = imageUrl
                let image = UIImage.init(contentsOfFile: imageUrl)
                self.previewImageView.image = image
                self.previewImageView.isHidden = false
                self.controlView.showCompleteAnimation()
                
                let width = image?.size.width ?? 0.0
                let height = image?.size.height ?? 0.0
                self.duration = 0.0
                self.width = width
                self.height = height
            }
        }
    }
    
    func cameraControlBeginTakeVideo() {
        manager.repareForZoom()
        manager.startRecordingVideo()
    }
    
    func cameraControlEndTakeVideo() {
        manager.endRecordingVideo { [weak self] (videoUrl) in
            guard let `self` = self else { return }
            let url = URL.init(fileURLWithPath: videoUrl)
            self.type = .video
            self.url = videoUrl
            self.videoPlayer.isHidden = false
            self.videoPlayer.videoUrl = url
            self.videoPlayer.play()
            self.controlView.showCompleteAnimation()
            
            if let asset = self.videoPlayer.player.currentItem?.asset, let image = self.fetchVideoPreViewImage(asset) {
                let duration = CMTimeGetSeconds(asset.duration)
                let size = asset.tracks(withMediaType: .video).first?.naturalSize
                let width = size?.width ?? 0.0
                let height = size?.height ?? 0.0
                let imagePath = WMCameraFileTools.wm_createFileUrl("jpg")
                let imageJpegData = image.jpegData(compressionQuality: 1.0)
                do {
                    try imageJpegData?.write(to: URL(fileURLWithPath: imagePath as String))
                } catch let e as NSError {
                    print("Error: \(e.localizedDescription)")
                }
                self.thumbPath = imagePath
                self.thumbHeight = image.size.height
                self.thumbWidth = image.size.width
                self.duration = CGFloat(duration)
                self.width = width
                self.height = height
            }
        }
    }
    
    func fetchVideoPreViewImage(_ asset : AVAsset) -> UIImage? {
        let assetGen = AVAssetImageGenerator(asset: asset)
        assetGen.appliesPreferredTrackTransform = true
        var thumbnail: UIImage?
        do {
            thumbnail = try UIImage(cgImage: assetGen.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 1), actualTime: nil))
        } catch let e as NSError {
            print("Error: \(e.localizedDescription)")
        }
        return thumbnail
    }
    
    func cameraControlDidChangeFocus(focus: Double) {
        let sh = Double(UIScreen.main.bounds.size.width) * 0.15
        let zoom = (focus / sh) + 1
        self.manager.zoom(zoom)
    }
    
    func cameraControlDidChangeCamera() {
        manager.changeCamera()
    }
    
    func cameraControlDidClickBack() {
        self.previewImageView.isHidden = true
        self.videoPlayer.isHidden = true
        self.videoPlayer.pause()
    }
    
    func cameraControlDidExit() {
        dismiss(animated: true, completion: nil)
    }
    
}
