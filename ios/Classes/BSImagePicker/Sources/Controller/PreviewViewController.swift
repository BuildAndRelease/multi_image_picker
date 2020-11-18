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

final class PreviewViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, SelectionViewDelegate {
    private let cellIdentifier = "PreviewCollectionCell"
    
    var cancelClosure: ((_ assets: [Dictionary<String, String>], _ thumb : Bool) -> Void)?
    var finishClosure: ((_ assets: NSDictionary, _ success : Bool, _ error : NSError) -> Void)?
    var selectLimitReachedClosure: ((_ selectionLimit: Int) -> Void)?
    var selectionClosure: ((_ asset: PHAsset) -> Void)?
    var deselectionClosure: ((_ asset: PHAsset) -> Void)?
    
    var loadingView = true
    
    var currentAssetIndex : Int = 0
    var fetchResult: Array<PHAsset>? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    var collectionView : UICollectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: UICollectionViewFlowLayout())
    var cancelBarButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back", comment: ""), style: .plain, target: nil, action: nil)
    var selectBarButton: UIBarButtonItem = UIBarButtonItem()
    var selectionView: SelectionView = SelectionView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    var settings: BSImagePickerSettings? {
        didSet{
            if settings != nil {
                selectionView.settings = settings!
            }
        }
    }
    var assetStore: AssetStore?
    
    private var doneBarButtonTitle: String = NSLocalizedString("Done", comment: "")
    private let originBarButtonTitle: String = NSLocalizedString("Origin", comment: "")
    var originBarButton: SSRadioButton = SSRadioButton(type: .custom)
    var doneBarButton: UIButton = UIButton(type: .custom)
    var bottomContentView : UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    var bottomHeightConstraint : NSLayoutConstraint?
    
    required init(settings: BSImagePickerSettings) {
        super.init(nibName: nil, bundle: nil)
        
        self.settings = settings
        self.selectionView.settings = settings
        if !settings.doneButtonText.isEmpty {
            doneBarButtonTitle = settings.doneButtonText
        }
        view.backgroundColor = UIColor.black
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = UIScreen.main.bounds.size
        flowLayout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: flowLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PreviewCollectionViewCell.self, forCellWithReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(collectionView)
        
        let normalColor = settings.selectionStrokeColor
        doneBarButton.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        doneBarButton.backgroundColor = normalColor
        doneBarButton.setTitleColor(UIColor.white, for: .normal)
        doneBarButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        doneBarButton.setTitle(doneBarButtonTitle, for: .normal)
        doneBarButton.setBackgroundColor(color: normalColor, for: .normal)
        doneBarButton.setBackgroundColor(color: normalColor.withAlphaComponent(0.5), for: .disabled)
        doneBarButton.layer.masksToBounds = true
        doneBarButton.layer.cornerRadius = 5.0
        doneBarButton.center = CGPoint(x: bottomContentView.bounds.size.width - 40 - 5, y: bottomContentView.bounds.size.height/2.0)
        doneBarButton.addTarget(self, action: #selector(PreviewViewController.doneButtonPressed(_:)), for: .touchUpInside)
        doneBarButton.translatesAutoresizingMaskIntoConstraints = false
        
        originBarButton.frame = CGRect(x: 60, y: 0, width: 100, height: 50)
        originBarButton.setTitle(originBarButtonTitle, for: .normal)
        originBarButton.isSelected = !settings.thumb
        originBarButton.circleRadius = 8.0
        originBarButton.circleColor = settings.selectionStrokeColor
        originBarButton.center = CGPoint(x: bottomContentView.bounds.size.width/2.0, y: bottomContentView.bounds.size.height/2.0)
        originBarButton.addTarget(self, action: #selector(PreviewViewController.originButtonPressed(_:)), for: .touchUpInside)
        originBarButton.translatesAutoresizingMaskIntoConstraints = false
        
        bottomContentView.contentView.addSubview(doneBarButton)
        bottomContentView.contentView.addSubview(originBarButton)
        bottomContentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bottomContentView)
        
        let safeGuide = self.view
        bottomHeightConstraint = NSLayoutConstraint(item: bottomContentView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 49)
        NSLayoutConstraint.activate([
            bottomHeightConstraint!,
            NSLayoutConstraint(item: bottomContentView, attribute: .bottom, relatedBy: .equal, toItem: safeGuide, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bottomContentView, attribute: .leading, relatedBy: .equal, toItem: safeGuide, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bottomContentView, attribute: .trailing, relatedBy: .equal, toItem: safeGuide, attribute: .trailing, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: doneBarButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30),
            NSLayoutConstraint(item: doneBarButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 80),
            NSLayoutConstraint(item: doneBarButton, attribute: .top, relatedBy: .equal, toItem: bottomContentView, attribute: .top, multiplier: 1, constant: 9.5),
            NSLayoutConstraint(item: doneBarButton, attribute: .trailing, relatedBy: .equal, toItem: bottomContentView, attribute: .trailing, multiplier: 1, constant: -16),
            
            NSLayoutConstraint(item: originBarButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 49),
            NSLayoutConstraint(item: originBarButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 100),
            NSLayoutConstraint(item: originBarButton, attribute: .top, relatedBy: .equal, toItem: bottomContentView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: originBarButton, attribute: .centerX, relatedBy: .equal, toItem: bottomContentView, attribute: .centerX, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: safeGuide, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: safeGuide, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: safeGuide, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: safeGuide, attribute: .trailing, multiplier: 1, constant: 0),
        ])

        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: .normal)
        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.gray], for: .highlighted)
        cancelBarButton.target = self
        cancelBarButton.action = #selector(PreviewViewController.cancelButtonPressed(_:))
        
        selectBarButton = UIBarButtonItem(customView: selectionView);
        selectionView.offset = 12.5
        selectionView.delegate = self
        navigationItem.leftBarButtonItem = cancelBarButton
        navigationItem.rightBarButtonItem = selectBarButton
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.contentOffset = CGPoint(x: collectionView.bounds.width * CGFloat(self.currentAssetIndex), y: collectionView.contentOffset.y)
        updateButtonState()
        refreshSelectIndex()
        loadingView = false
    }
    
    override func viewDidLayoutSubviews() {
        var height : CGFloat?
        if #available(iOS 11.0, *) {
            height = self.view.safeAreaInsets.bottom
        } else {
            height = 0.0
        }
        bottomHeightConstraint?.constant = height! + 49
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loadingView = true
    }
    
    // MARK: Private helper methods
    func updateButtonState() {
        if assetStore?.assets.count ?? 0 > 0 {
            doneBarButton.setTitle("\(doneBarButtonTitle)(\(assetStore!.count))", for: .normal)
            var width : CGFloat = 90.0
            switch settings?.maxNumberOfSelections ?? 9 {
            case 0..<10:
                width = 90.0
            case 10..<100:
                width = 110.0
            case 100..<1000:
                width = 140.0
            default:
                width = 90.0
            }
            if width != doneBarButton.frame.size.width {
                doneBarButton.frame = CGRect(x: 0, y: 0, width: width, height: 30)
                doneBarButton.center = CGPoint(x: (self.navigationController?.toolbar.bounds.size.width ?? UIScreen.main.bounds.size.width) - width/2 - 10, y: (self.navigationController?.toolbar.bounds.size.height ?? 24.5)/2.0)
            }
        } else {
            doneBarButton.setTitle(doneBarButtonTitle, for: .normal)
            if 60 != doneBarButton.frame.size.width {
                doneBarButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
                doneBarButton.center = CGPoint(x: (self.navigationController?.toolbar.bounds.size.width ?? UIScreen.main.bounds.size.width) - 40, y: (self.navigationController?.toolbar.bounds.size.height ?? 24.5)/2.0)
            }
        }

        originBarButton.isSelected = !(settings?.thumb ?? false)
    }
    
    func refreshSelectIndex() {
        if currentAssetIndex < (self.fetchResult?.count ?? 0) , let asset = self.fetchResult?[currentAssetIndex] {
            let selectIndex = isSelectImageItem(asset)
            if selectIndex > 0 {
                selectionView.selectionString = "\(selectIndex)"
                selectionView.selected = true
            }else {
                selectionView.selectionString = ""
                selectionView.selected = false
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let cell = collectionView.cellForItem(at: indexPath) as! PreviewCollectionViewCell
        cell.cellDidReceiveTapAction()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PreviewCollectionViewCell
        cell.asset = self.fetchResult?[indexPath.row]
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        for cell in collectionView.visibleCells {
            (cell as! PreviewCollectionViewCell).stopPlayVideo()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !loadingView {
            let index = Int(round(scrollView.contentOffset.x/scrollView.bounds.width))
            if currentAssetIndex != index {
                currentAssetIndex = index
                refreshSelectIndex()
            }
        }
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        for cell in collectionView.visibleCells {
            (cell as! PreviewCollectionViewCell).stopPlayVideo()
        }
        if self.navigationController?.viewControllers[0] == self {
            let dictionary = needSelectedIdentify()
            cancelClosure?(dictionary, (settings?.thumb ?? false))
            self.dismiss(animated: true, completion: nil)
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func selectMediaItem(_ asset : PHAsset) -> Int {
        if let selectType = settings?.selectType, !selectType.isEmpty {
            if selectType == "selectVideo"{
                if asset.mediaType != .video  {
                    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud.mode = MBProgressHUDMode.text
                    hud.bezelView.backgroundColor = UIColor.darkGray
                    hud.label.text = NSLocalizedString("仅支持视频选择", comment: "")
                    hud.offset = CGPoint(x: 0, y: 0)
                    hud.hide(animated: true, afterDelay: 2.0)
                    return -1;
                }
            }
            
            if selectType == "selectImage" {
                if asset.mediaType != .image  {
                    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud.mode = MBProgressHUDMode.text
                    hud.bezelView.backgroundColor = UIColor.darkGray
                    hud.label.text = NSLocalizedString("仅支持图片选择", comment: "")
                    hud.offset = CGPoint(x: 0, y: 0)
                    hud.hide(animated: true, afterDelay: 2.0)
                    return -1;
                }
            }
            
            if selectType == "selectSingleType" {
                if self.assetStore?.isContainPic() ?? false, asset.mediaType != .image {
                    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud.mode = MBProgressHUDMode.text
                    hud.bezelView.backgroundColor = UIColor.darkGray
                    hud.label.text = NSLocalizedString("不能同时选择图片和视频", comment: "")
                    hud.offset = CGPoint(x: 0, y: 0)
                    hud.hide(animated: true, afterDelay: 2.0)
                    return -1;
                }
                if self.assetStore?.isContainVideo() ?? false, !(self.assetStore?.contains(asset) ?? true) {
                    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud.mode = MBProgressHUDMode.text
                    hud.bezelView.backgroundColor = UIColor.darkGray
                    hud.label.text = NSLocalizedString(asset.mediaType != .video ? "不能同时选择图片和视频" : "只能选择一个视频", comment: "")
                    hud.offset = CGPoint(x: 0, y: 0)
                    hud.hide(animated: true, afterDelay: 2.0)
                    return -1;
                }
            }
        }
        if self.assetStore?.contains(asset) ?? false {
            self.assetStore?.remove(asset)
            deselectionClosure?(asset)
            updateButtonState()
            return -1
        } else if self.assetStore?.count ?? 0 < (settings?.maxNumberOfSelections ?? 9) {
            self.assetStore?.append(asset)
            selectionClosure?(asset)
            updateButtonState()
            return self.assetStore?.count ?? 0
        }
        return -1
    }
    
    func selectViewDidSelectDidAction(_ view: SelectionView) {
        if let cell = collectionView.visibleCells.first, let asset = (cell as! PreviewCollectionViewCell).asset {
            if let error = canSelectImageItem(asset) {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = MBProgressHUDMode.text
                hud.bezelView.backgroundColor = UIColor.darkGray
                hud.label.text = NSLocalizedString(error.domain, comment: "")
                hud.offset = CGPoint(x: 0, y: 0)
                hud.hide(animated: true, afterDelay: 2.0)
            }else {
                let selectIndex = selectMediaItem(asset)
                if selectIndex > 0 {
                    selectionView.selectionString = "\(selectIndex)"
                    selectionView.selected = true
                }else if selectIndex == -1 {
                    selectionView.selectionString = ""
                    selectionView.selected = false
                }
            }
        }
    }
    
    func needSelectedIdentify() -> [Dictionary<String, String>]{
        var mediaList = [Dictionary<String, String>]()
        for asset in assetStore?.assets ?? [] {
            var dictionary = Dictionary<String, String>()
            dictionary["identify"] = asset.localIdentifier
            if asset.mediaType == .video {
                dictionary["fileType"] = "video"
            }else if asset.mediaType == .image {
              if let uti = asset.value(forKey: "uniformTypeIdentifier"), uti is String, (uti as! String).contains("gif") {
                dictionary["fileType"] = "image/gif"
              }else {
                dictionary["fileType"] = "image/jpeg"
              }
            }
            mediaList.append(dictionary)
        }
        return mediaList
    }
    
    func isSelectImageItem(_ asset : PHAsset) -> Int {
        return (assetStore?.assets.firstIndex(of: asset) ?? -1) + 1
    }
    
    func canSelectImageItem(_ asset : PHAsset) -> NSError? {
        if assetStore?.contains(asset) ?? false {
            return nil
        }else if assetStore?.count ?? 0 >= (settings?.maxNumberOfSelections ?? 9) {
            selectLimitReachedClosure?(assetStore?.count ?? 0)
            return NSError(domain: "最多只能选择\((settings?.maxNumberOfSelections ?? 9)!)个文件", code: 5, userInfo: nil)
        }
//        else if asset.fileSize > 1024 * 1024 * 100.0 {
//            return NSError(domain: "不能分享超过100M的文件", code: 6, userInfo: nil)
//        }
        return nil
    }
    
    @objc func originButtonPressed(_ sender: UIButton) {
        originBarButton.isSelected = !originBarButton.isSelected
        settings?.thumb = !originBarButton.isSelected
    }
    
    @objc func doneButtonPressed(_ sender: UIButton) {
        if (self.assetStore?.assets ?? []).count < 1 {
            if let cell = collectionView.visibleCells.first, let asset = (cell as! PreviewCollectionViewCell).asset {
                if let error = canSelectImageItem(asset) {
                    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud.mode = MBProgressHUDMode.text
                    hud.bezelView.backgroundColor = UIColor.darkGray
                    hud.label.text = NSLocalizedString(error.domain, comment: "")
                    hud.offset = CGPoint(x: 0, y: 0)
                    hud.hide(animated: true, afterDelay: 2.0)
                    return
                }else {
                    let selectIndex = selectMediaItem(asset)
                    if selectIndex > 0 {
                        selectionView.selectionString = "\(selectIndex)"
                        selectionView.selected = true
                    }else if selectIndex == -1 {
                        selectionView.selectionString = ""
                        selectionView.selected = false
                    }
                }
            }
        }
        weak var weakSelf = self
        let thumb = !originBarButton.isSelected
        let assets = self.assetStore?.assets ?? []
        if assets.count < 1 {
            return
        }
        doneBarButton.isEnabled = false
        
        DispatchQueue.global().async {
            let results = NSMutableDictionary();
            var identifiers = [String]();
            for asset in assets {
                identifiers.append(asset.localIdentifier)
            }
            results.setValue(identifiers, forKey: "identifiers")
            results.setValue(thumb, forKey: "thumb")
            
            DispatchQueue.main.async {
                weakSelf?.doneBarButton.isEnabled = true
                weakSelf?.finishClosure?(results, assets.count == identifiers.count, NSError())
                weakSelf?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
