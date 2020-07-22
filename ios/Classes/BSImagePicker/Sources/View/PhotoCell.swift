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

protocol PhotoCellDelegate : class {
    func photoCellDidReceiveSelectAction(_ cell : PhotoCell)
}
/**
The photo cell.
*/
final class PhotoCell: UICollectionViewCell, SelectionViewDelegate {
    static let cellIdentifier = "photoCellIdentifier"
    
    weak var delegate : PhotoCellDelegate?
    let imageView: UIImageView = UIImageView(frame: .zero)
    private let disableOverlayView : UIView = UIView(frame: .zero)
    private let selectionOverlayView: UIView = UIView(frame: .zero)
    private let selectionView: SelectionView = SelectionView(frame: .zero)
    private let videoLabelContentView : UIView = UIView(frame: .zero)
    private let videoLabelImageView : UIImageView = UIImageView(frame: .zero)
    private let videoDurationLabel : UILabel = UILabel(frame: .zero)
    private let gifLabel : UILabel = UILabel(frame: .zero)
    
    weak var asset: PHAsset? {
        didSet {
            if (asset != nil && .video == asset?.mediaType) {
                videoLabelContentView.isHidden = false
                videoDurationLabel.isHidden = false
                videoLabelImageView.isHidden = false
                gifLabel.isHidden = true
                videoDurationLabel.text = "\(String(format: "%02d", (Int)(asset?.duration ?? 0)/60)):\(String(format: "%02d", (Int)(asset?.duration ?? 0)%60))"
            }else {
                let fileName = String(describing: asset?.value(forKey: "filename") ?? "")
                if fileName.hasSuffix("GIF") {
                    videoLabelContentView.isHidden = false
                    gifLabel.isHidden = false
                    videoDurationLabel.isHidden = true
                    videoLabelImageView.isHidden = true
                }else {
                    videoLabelContentView.isHidden = true
                }
            }
        }
    }

    var settings: BSImagePickerSettings {
        get {
            return selectionView.settings
        }
        set {
            selectionView.settings = newValue
        }
    }
    
    var selectionString: String {
        get {
            return selectionView.selectionString
        }
        
        set {
            selectionView.selectionString = newValue
        }
    }
    
    var photoSelected: Bool = false {
        didSet {
            self.updateAccessibilityLabel(photoSelected)
            let hasChanged = photoSelected != oldValue
            if UIView.areAnimationsEnabled && hasChanged {
                UIView.animate(withDuration: TimeInterval(0.1), animations: { () -> Void in
                    self.updateAlpha(self.photoSelected)
                    self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                    }, completion: { (finished: Bool) -> Void in
                        UIView.animate(withDuration: TimeInterval(0.1), animations: { () -> Void in
                            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                            }, completion: nil)
                })
            } else {
                updateAlpha(photoSelected)
            }
            selectionView.selected = photoSelected
        }
    }
    
    var photoDisable: Bool = false {
        didSet {
            self.disableOverlayView.alpha = photoDisable ? 0.5 : 0.0
        }
    }
    

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Setup views
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        disableOverlayView.backgroundColor = UIColor.white
        disableOverlayView.translatesAutoresizingMaskIntoConstraints = false;
        disableOverlayView.alpha = 0.0
        
        selectionOverlayView.backgroundColor = UIColor.darkGray
        selectionOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.delegate = self
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.8).cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor]
        gradientLayer.locations = [0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 320, height: 25)
        gradientLayer.masksToBounds = true
        videoLabelContentView.layer.addSublayer(gradientLayer)
        videoLabelContentView.layer.masksToBounds = true
        videoLabelContentView.translatesAutoresizingMaskIntoConstraints = false
        
        videoLabelImageView.clipsToBounds = true
        videoLabelImageView.contentMode = .scaleAspectFit
        videoLabelImageView.image = UIImage.wm_imageWithName_WMCameraResource(named: "video_btn")
        videoLabelImageView.translatesAutoresizingMaskIntoConstraints = false
    
        videoDurationLabel.text = "00:15"
        videoDurationLabel.textColor = UIColor.white
        videoDurationLabel.textAlignment = .center
        videoDurationLabel.font = UIFont.systemFont(ofSize: 12.0)
        videoDurationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        gifLabel.text = "GIF"
        gifLabel.textColor = UIColor.white
        gifLabel.textAlignment = .left
        gifLabel.font = UIFont.systemFont(ofSize: 12.0)
        gifLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        contentView.addSubview(selectionOverlayView)
        contentView.addSubview(selectionView)
        contentView.addSubview(videoLabelContentView)
        contentView.addSubview(disableOverlayView)
        videoLabelContentView.addSubview(gifLabel)
        videoLabelContentView.addSubview(videoLabelImageView)
        videoLabelContentView.addSubview(videoDurationLabel)

        // Add constraints
        NSLayoutConstraint.activate([
        NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: imageView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0),
        
        NSLayoutConstraint(item: disableOverlayView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: disableOverlayView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: disableOverlayView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: disableOverlayView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0),
        
        NSLayoutConstraint(item: selectionOverlayView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: selectionOverlayView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: selectionOverlayView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: selectionOverlayView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0),
        
        NSLayoutConstraint(item: selectionView, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.4, constant: 0),
        NSLayoutConstraint(item: selectionView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .width, multiplier: 0.4, constant: 0),
        NSLayoutConstraint(item: selectionView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: selectionView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0),
        
        NSLayoutConstraint(item: videoLabelContentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 25),
        NSLayoutConstraint(item: videoLabelContentView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: videoLabelContentView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: videoLabelContentView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0),
        
        NSLayoutConstraint(item: videoLabelImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20),
        NSLayoutConstraint(item: videoLabelImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 20),
        NSLayoutConstraint(item: videoLabelImageView, attribute: .leading, relatedBy: .equal, toItem: videoLabelContentView, attribute: .leading, multiplier: 1, constant: 2),
        NSLayoutConstraint(item: videoLabelImageView, attribute: .bottom, relatedBy: .equal, toItem: videoLabelContentView, attribute: .bottom, multiplier: 1, constant: 0),
        
        NSLayoutConstraint(item: gifLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20),
        NSLayoutConstraint(item: gifLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 100),
        NSLayoutConstraint(item: gifLabel, attribute: .leading, relatedBy: .equal, toItem: videoLabelContentView, attribute: .leading, multiplier: 1, constant: 2),
        NSLayoutConstraint(item: gifLabel, attribute: .bottom, relatedBy: .equal, toItem: videoLabelContentView, attribute: .bottom, multiplier: 1, constant: 0),
        
        NSLayoutConstraint(item: videoDurationLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20),
        NSLayoutConstraint(item: videoDurationLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 40),
        NSLayoutConstraint(item: videoDurationLabel, attribute: .trailing, relatedBy: .equal, toItem: videoLabelContentView, attribute: .trailing, multiplier: 1, constant: -2),
        NSLayoutConstraint(item: videoDurationLabel, attribute: .bottom, relatedBy: .equal, toItem: videoLabelContentView, attribute: .bottom, multiplier: 1, constant: 0)

        ])
        
//        NSLayoutConstraint.activate([
//            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            selectionOverlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            selectionOverlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            selectionOverlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            selectionOverlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            selectionView.heightAnchor.constraint(equalToConstant: 25),
//            selectionView.widthAnchor.constraint(equalToConstant: 25),
//            selectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
//            selectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4)
//        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    func updateAccessibilityLabel(_ selected: Bool) {
        self.accessibilityLabel = selected ? "deselect image" : "select image"
    }
    
    private func updateAlpha(_ selected: Bool) {
        if selected == true {
            self.selectionOverlayView.alpha = 0.5
        } else {
            self.selectionOverlayView.alpha = 0.0
        }
    }
    
    func selectViewDidSelectDidAction(_ view: SelectionView) {
        self.delegate?.photoCellDidReceiveSelectAction(self)
    }
    
}
