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

final class PhotosViewController : UIViewController, CustomTitleViewDelegate, PhotoCollectionViewDataSourceDelegate, UICollectionViewDelegate {
    var cancelBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    let titleContentView = CustomTitleView(frame: CGRect(x: 0, y: 0, width: 120, height: 34.0))
    
    var originBarButton: SSRadioButton = SSRadioButton(type: .custom)
    var doneBarButton: UIButton = UIButton(type: .custom)
    var bottomContentView : UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    var bottomHeightConstraint : NSLayoutConstraint?
    
    let settings = DataCenter.shared.settings
    let assetStore = DataCenter.shared.assetStore
    private var needScrollToBottom : Bool = true
    
    private var photosDataSource: PhotoCollectionViewDataSource?
    lazy var albumsDataSource: AlbumTableViewDataSource = {
       return AlbumTableViewDataSource()
    }()
    
    private var doneBarButtonTitle: String = NSLocalizedString("Done", comment: "")
    private let originBarButtonTitle: String = NSLocalizedString("Origin", comment: "")
    
    private var collectionView : UICollectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: GridCollectionViewLayout())
    
    lazy var albumsViewController : AlbumsViewController = {
        let vc = AlbumsViewController()
        vc.tableView.dataSource = self.albumsDataSource
        vc.tableView.delegate = self
        vc.preferredContentSize = CGSize(width: 320, height: min(self.albumsDataSource.countItems() * 100, 300))
        return vc
    }()
    
    required init() {
        if !settings.doneButtonText.isEmpty {
            doneBarButtonTitle = settings.doneButtonText
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("b0rk: initWithCoder not implemented")
    }
    
    override func loadView() {
        super.loadView()
        self.view.backgroundColor = UIColor.darkGray
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset  = UIEdgeInsets(top: 0, left: 0, bottom: 49, right: 0)
        
        collectionView.backgroundColor = UIColor.darkGray
        collectionView.allowsMultipleSelection = true
        
        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: .normal)
        cancelBarButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.gray], for: .highlighted)
        cancelBarButton.target = self
        cancelBarButton.action = #selector(PhotosViewController.cancelButtonPressed(_:))
        
        titleContentView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.15)
        titleContentView.translatesAutoresizingMaskIntoConstraints = false
        titleContentView.titleView.text = "最近项目"
        titleContentView.layer.masksToBounds = true
        titleContentView.layer.cornerRadius = 17.5
        titleContentView.delegate = self
        
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
        doneBarButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        doneBarButton.titleLabel?.adjustsFontSizeToFitWidth = true
        doneBarButton.center = CGPoint(x: bottomContentView.bounds.size.width - 40 - 5, y: bottomContentView.bounds.size.height/2.0)
        doneBarButton.addTarget(self, action: #selector(PhotosViewController.doneButtonPressed(_:)), for: .touchUpInside)
        doneBarButton.translatesAutoresizingMaskIntoConstraints = false
        
        originBarButton.frame = CGRect(x: 60, y: 0, width: 100, height: 50)
        originBarButton.setTitle(originBarButtonTitle, for: .normal)
        originBarButton.isSelected = !settings.thumb
        originBarButton.circleRadius = 8.0
        originBarButton.circleColor = settings.selectionStrokeColor
        originBarButton.isHidden = settings.hiddenThumb
        originBarButton.center = CGPoint(x: bottomContentView.bounds.size.width/2.0, y: bottomContentView.bounds.size.height/2.0)
        originBarButton.addTarget(self, action: #selector(PhotosViewController.originButtonPressed(_:)), for: .touchUpInside)
        originBarButton.translatesAutoresizingMaskIntoConstraints = false
        
        navigationItem.leftBarButtonItem = cancelBarButton
        navigationItem.titleView = titleContentView
        
        bottomContentView.contentView.addSubview(doneBarButton)
        bottomContentView.contentView.addSubview(originBarButton)
        bottomContentView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(collectionView)
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
        
        initCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        if needScrollToBottom, let photosDataSource = photosDataSource {
            let indexPath = IndexPath(row: photosDataSource.assets.count - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: false)
            needScrollToBottom = false
        }
        var height : CGFloat?
        if #available(iOS 11.0, *) {
            height = self.view.safeAreaInsets.bottom
        } else {
            height = 0.0
        }
        bottomHeightConstraint?.constant = height! + 49
        super.viewDidLayoutSubviews()
    }
    
    // MARK: Appear/Disappear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateButtonState()
        collectionView.reloadData()
    }
    
    func initCollectionView() {
        weak var hud = showHUDLoading(text: "加载中...");
        DispatchQueue.global().async { [weak self] in
            if self?.albumsDataSource.fetchResults.count ?? 0 > 0, let album = self?.albumsDataSource.fetchResults[0] {
                DispatchQueue.main.async {
                    self?.initializePhotosDataSource(album)
                    self?.updateAlbumTitle(album)
                    if self?.needScrollToBottom ?? false {
                        let indexPath = IndexPath(row: (self?.photosDataSource?.assets.count ?? 0) - 1, section: 0)
                        self?.collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: false)
                        self?.needScrollToBottom = false
                    }
                    self?.collectionView.reloadData()
                    self?.hideHUDLoading(hud: hud)
                }
            }else{
                DispatchQueue.main.async {
                    self?.hideHUDLoading(hud: hud)
                    self?.showHUDAlert(text: NSLocalizedString("本地相册暂无图片与视频，快去拍摄吧", comment: ""))
                }
            }
        }
    }
    
    // MARK: Button actions
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        var mediaList = [Dictionary<String, String>]()
        for asset in assetStore.assets {
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
        DataCenter.shared.cancelClosure?(mediaList, settings.thumb)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: UIButton) {
        weak var weakSelf = self
        let thumb = !originBarButton.isSelected
        let assets = self.assetStore.assets
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
                DataCenter.shared.finishClosure?(results, assets.count == identifiers.count, NSError())
                weakSelf?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc func originButtonPressed(_ sender: UIButton) {
        originBarButton.isSelected = !originBarButton.isSelected
        settings.thumb = !originBarButton.isSelected
    }
    
    func customTitleViewDidAction(_ view: CustomTitleView) {
        guard let popVC = albumsViewController.popoverPresentationController else { return }
        
        popVC.permittedArrowDirections = .up
        popVC.sourceView = view
        let senderRect = view.convert(view.frame, from: view.superview)
        let sourceRect = CGRect(x: senderRect.origin.x, y: senderRect.origin.y + (view.frame.size.height / 2), width: senderRect.size.width, height: senderRect.size.height)
        popVC.sourceRect = sourceRect
        popVC.delegate = self
        albumsViewController.tableView.reloadData()
        
        present(albumsViewController, animated: true, completion: nil)
    }
    
    // MARK: Private helper methods
    func updateButtonState() {
        if assetStore.assets.count > 0 {
            doneBarButton.setTitle("\(doneBarButtonTitle)(\(assetStore.count))", for: .normal)
            var width : CGFloat = 90.0
            switch settings.maxNumberOfSelections {
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

        doneBarButton.isEnabled = assetStore.assets.count > 0
        originBarButton.isSelected = !settings.thumb
    }

    func updateAlbumTitle(_ album: PHAssetCollection) {
        guard let title = album.localizedTitle else { return }
        titleContentView.titleView.text = title
    }
    
    func initializePhotosDataSource(_ album: PHAssetCollection) {
        needScrollToBottom = true
        photosDataSource = PhotoCollectionViewDataSource(album)
        photosDataSource?.delegate = self
        photosDataSource?.registerCellIdentifiersForCollectionView(collectionView)
        collectionView.dataSource = photosDataSource
        collectionView.delegate = self
        titleContentView.deSelectView()
    }
    
    func photoCollectionViewDataSourceDidReceiveCellSelectAction(_ cell: PhotoCell) {
        guard let photosDataSource = photosDataSource, collectionView.isUserInteractionEnabled else { return }
        guard let asset = cell.asset else { return }
        if !cell.thumbCanLoad {
            showHUDAlert(text: NSLocalizedString("媒体信息异常", comment: ""))
        }
        if !settings.selectType.isEmpty {
            if settings.selectType == "selectVideo"{
                if asset.mediaType != .video  {
                    showHUDAlert(text: NSLocalizedString("仅支持视频选择", comment: ""))
                    return;
                }
            }
            
            if settings.selectType == "selectImage" {
                if asset.mediaType != .image  {
                    showHUDAlert(text: NSLocalizedString("仅支持图片选择", comment: ""))
                    return;
                }
            }
            
            if settings.selectType == "selectSingleType" {
                if assetStore.isContainPic(), asset.mediaType != .image {
                    showHUDAlert(text: NSLocalizedString("不能同时选择图片和视频", comment: ""))
                    return;
                }
                if assetStore.isContainVideo(), !assetStore.contains(asset) {
                    showHUDAlert(text: NSLocalizedString(asset.mediaType != .video ? "不能同时选择图片和视频" : "只能选择一个视频", comment: ""))
                    return;
                }
            }
        }
        if assetStore.contains(asset) {
            let canSelectBefore = assetStore.canAppend(settings.selectType, maxNum: settings.maxNumberOfSelections)
            assetStore.remove(asset)
            let canSelectAfter = assetStore.canAppend(settings.selectType, maxNum: settings.maxNumberOfSelections)
            updateButtonState()
            let selectedIndexPaths = assetStore.assets.compactMap({ (asset) -> IndexPath? in
                let index = photosDataSource.assets.index(of: asset)
                return IndexPath(item: index, section: 0)
            })
            if (canSelectBefore != canSelectAfter) {
                collectionView.reloadData()
            }else {
                UIView.setAnimationsEnabled(false)
                collectionView.reloadItems(at: selectedIndexPaths)
                UIView.setAnimationsEnabled(true)
            }
            cell.photoSelected = false
            DataCenter.shared.deselectionClosure?(asset)
        } else {
            if assetStore.count >= settings.maxNumberOfSelections {
                DataCenter.shared.selectLimitReachedClosure?(assetStore.count)
                showHUDAlert(text: NSLocalizedString("最多只能选择\(settings.maxNumberOfSelections)个文件", comment: ""))
            } else {
                let canSelectBefore = assetStore.canAppend(settings.selectType, maxNum: settings.maxNumberOfSelections)
                assetStore.append(asset)
                let canSelectAfter = assetStore.canAppend(settings.selectType, maxNum: settings.maxNumberOfSelections)
                if let selectionCharacter = settings.selectionCharacter {
                    cell.selectionString = String(selectionCharacter)
                } else {
                    cell.selectionString = String(assetStore.count)
                }
                cell.photoSelected = true
                updateButtonState()
                DataCenter.shared.selectionClosure?(asset)
                if (canSelectBefore != canSelectAfter) {
                    collectionView.reloadData()
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell, let asset = cell.asset, !cell.photoDisable {
            let index = photosDataSource?.assets.index(of: asset) ?? 0
            navigationController?.pushViewController(PreviewViewController(currentAssetIndex: index, assets: photosDataSource?.assets ?? PHFetchResult<PHAsset>()), animated: true)
        }
        return true
    }
    
    func showHUDAlert(text: String) {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = MBProgressHUDMode.text
        hud.bezelView.backgroundColor = UIColor.darkGray
        hud.label.text = text
        hud.offset = CGPoint(x: 0, y: 0)
        hud.hide(animated: true, afterDelay: 2.0)
    }
    
    func showHUDLoading(text: String) -> MBProgressHUD {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = MBProgressHUDMode.indeterminate
        hud.bezelView.backgroundColor = UIColor.darkGray
        hud.label.text = text
        hud.offset = CGPoint(x: 0, y: 0)
        return hud
    }
    
    func hideHUDLoading(hud : MBProgressHUD?) {
        hud?.hide(animated: true)
    }
}

// MARK: UIPopoverPresentationControllerDelegate
extension PhotosViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        titleContentView.deSelectView()
        return true
    }
}

// MARK: UITableViewDelegate
extension PhotosViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Update photos data source
        let album = albumsDataSource.fetchResults[indexPath.row]
        initializePhotosDataSource(album)
        updateAlbumTitle(album)
        collectionView.reloadData()
        albumsViewController.dismiss(animated: true, completion: nil)
        
        let indexPath = IndexPath(row: (photosDataSource?.assets.count ?? 1) - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: false)
        needScrollToBottom = false
    }
}
