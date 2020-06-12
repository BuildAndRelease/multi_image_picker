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

final class PhotosViewController : UICollectionViewController , CustomTitleViewDelegate, PhotoCollectionViewDataSourceDelegate , PreviewViewControllerDelegate {
    var selectionClosure: ((_ asset: PHAsset) -> Void)?
    var deselectionClosure: ((_ asset: PHAsset) -> Void)?
    var cancelClosure: ((_ assets: [PHAsset]) -> Void)?
    var finishClosure: ((_ assets: [NSDictionary], _ success : Bool, _ error : NSError) -> Void)?
    var selectLimitReachedClosure: ((_ selectionLimit: Int) -> Void)?
    
    var cancelBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    let titleContentView = CustomTitleView(frame: CGRect(x: 0, y: 0, width: 120, height: 34.0))
    
    var originBarButton: SSRadioButton = SSRadioButton(type: .custom)
    var doneBarButton: UIButton = UIButton(type: .custom)
    var bottomContentView : UIView = UIView()
    
    let settings: BSImagePickerSettings
    private var assetStore: AssetStore
    private var needScrollToBottom : Bool = true
    
    private var photosDataSource: PhotoCollectionViewDataSource?
    private var albumsDataSource: AlbumTableViewDataSource
    
    private let doneBarButtonTitle: String = NSLocalizedString("Done", comment: "")
    private let originBarButtonTitle: String = NSLocalizedString("Origin", comment: "")
    
    lazy var albumsViewController: AlbumsViewController = {
        let vc = AlbumsViewController()
        vc.tableView.dataSource = self.albumsDataSource
        vc.tableView.delegate = self
        vc.preferredContentSize = CGSize(width: 320, height: min(self.albumsDataSource.countItems() * 100, 300))
        return vc
    }()
    
    private let previewViewContoller = PreviewViewController(nibName: nil, bundle: nil)
    
    required init(fetchResults: [PHFetchResult<PHAssetCollection>], assetStore: AssetStore, settings aSettings: BSImagePickerSettings) {
        self.albumsDataSource = AlbumTableViewDataSource(fetchResults: fetchResults)
        self.settings = aSettings
        self.assetStore = assetStore
        super.init(collectionViewLayout: GridCollectionViewLayout())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("b0rk: initWithCoder not implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        collectionView?.backgroundColor = UIColor.darkGray
        collectionView?.allowsMultipleSelection = true
        
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
        
        bottomContentView.frame = self.navigationController?.toolbar.bounds ?? CGRect(x: 0, y: 0, width:  UIScreen.main.bounds.size.width, height: 49.0)
        bottomContentView.backgroundColor = UIColor.clear
        
        doneBarButton.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        doneBarButton.backgroundColor = UIColor(red: 0, green: 186.0/255.0, blue: 90.0/255.0, alpha: 1.0)
        doneBarButton.setTitleColor(UIColor.white, for: .normal)
        doneBarButton.setTitleColor(UIColor.gray, for: .disabled)
        doneBarButton.setTitle(doneBarButtonTitle, for: .normal)
        doneBarButton.setBackgroundColor(color: UIColor(red: 0, green: 186.0/255.0, blue: 90.0/255.0, alpha: 1.0), for: .normal)
        doneBarButton.setBackgroundColor(color: UIColor.darkGray, for: .disabled)
        doneBarButton.layer.masksToBounds = true
        doneBarButton.layer.cornerRadius = 5.0
        doneBarButton.center = CGPoint(x: bottomContentView.bounds.size.width - 40 - 5, y: bottomContentView.bounds.size.height/2.0)
        doneBarButton.addTarget(self, action: #selector(PhotosViewController.doneButtonPressed(_:)), for: .touchUpInside)
        
        originBarButton.frame = CGRect(x: 60, y: 0, width: 100, height: 50)
        originBarButton.setTitle(originBarButtonTitle, for: .normal)
        originBarButton.isSelected = false
        originBarButton.circleRadius = 8.0
        originBarButton.circleColor = UIColor(red: 0, green: 186.0/255.0, blue: 90.0/255.0, alpha: 1.0)
        originBarButton.center = CGPoint(x: bottomContentView.bounds.size.width/2.0, y: bottomContentView.bounds.size.height/2.0)
        originBarButton.addTarget(self, action: #selector(PhotosViewController.originButtonPressed(_:)), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = cancelBarButton
        navigationItem.titleView = titleContentView
        
        bottomContentView.addSubview(doneBarButton)
        bottomContentView.addSubview(originBarButton)
        
        if let album = albumsDataSource.fetchResults.first?.firstObject {
            initializePhotosDataSource(album)
            updateAlbumTitle(album)
            collectionView?.reloadData()
        }
        
        photosDataSource?.registerCellIdentifiersForCollectionView(collectionView)
        photosDataSource?.delegate = self
        
        if assetStore.count > 0 {
            previewViewContoller.delegate = self
            let index = photosDataSource?.fetchResult.index(of: assetStore.assets.first!) ?? 0
            previewViewContoller.currentAssetIndex = index
            previewViewContoller.fetchResult = photosDataSource?.fetchResult
            navigationController?.pushViewController(previewViewContoller, animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        if needScrollToBottom {
            let indexPath = IndexPath(row: (photosDataSource?.fetchResult.count ?? 0) - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: false)
            needScrollToBottom = false
        }
        super.viewDidLayoutSubviews()
    }
    
    // MARK: Appear/Disappear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDoneButton()
        collectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if bottomContentView.superview == nil {
            self.navigationController?.setToolbarHidden(false, animated: true)
            self.navigationController?.toolbar.layoutIfNeeded()
            bottomContentView.frame = self.navigationController?.toolbar.bounds ?? CGRect(x: 0, y: 0, width:  UIScreen.main.bounds.size.width, height: 49.0)
            doneBarButton.center = CGPoint(x: bottomContentView.bounds.size.width - 40 - 5, y: bottomContentView.bounds.size.height/2.0)
            originBarButton.center = CGPoint(x: bottomContentView.bounds.size.width/2.0, y: bottomContentView.bounds.size.height/2.0)
            self.navigationController?.toolbar.addSubview(bottomContentView)
            let indexPath = IndexPath(row: (photosDataSource?.fetchResult.count ?? 0) - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: true)
            needScrollToBottom = false
        }
    }
    
    // MARK: Button actions
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
        cancelClosure?(assetStore.assets)
    }
    
    @objc func doneButtonPressed(_ sender: UIButton) {
        weak var weakSelf = self
        let maxWidth = settings.maxWidthOfImage
        let maxHeight = settings.maxHeightOfImage
        let quality = settings.qualityOfThumb
        let thumb = !originBarButton.isSelected
        let assets = self.assetStore.assets
        doneBarButton.isEnabled = false
        
        weak var hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.label.text = originBarButton.isSelected ? NSLocalizedString("拷贝中", comment: "") : NSLocalizedString("压缩中", comment: "")
        hud?.bezelView.backgroundColor = UIColor.darkGray
        DispatchQueue.global().async {
            let thumbDir = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? NSTemporaryDirectory()) + "/multi_image_pick/thumb/"
            if !FileManager.default.fileExists(atPath: thumbDir) {
                do {
                    try FileManager.default.createDirectory(atPath: thumbDir, withIntermediateDirectories: true, attributes: nil)
                }catch{
                    print(error)
                }
            }
            var results = [NSDictionary]();
            var error = NSError()
            for asset in assets {
                var compressing = true
                asset.compressAsset(maxWidth, maxHeight: maxHeight, quality: quality, thumb: thumb, saveDir: thumbDir, process: { (process) in
                    
                }, failed: { (err) in
                    error = err
                    compressing = false
                }) { (info) in
                    results.append(info)
                    compressing = false
                }
                while compressing {
                    usleep(50000)
                }
            }
            
            DispatchQueue.main.async {
                weakSelf?.doneBarButton.isEnabled = true
                hud?.hide(animated: true)
                weakSelf?.finishClosure?(results, assets.count == results.count, error)
                weakSelf?.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    @objc func originButtonPressed(_ sender: UIButton) {
        originBarButton.isSelected = !originBarButton.isSelected
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
    func updateDoneButton() {
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
    }

    func updateAlbumTitle(_ album: PHAssetCollection) {
        guard let title = album.localizedTitle else { return }
        titleContentView.titleView.text = title
    }
    
    func initializePhotosDataSource(_ album: PHAssetCollection) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
        needScrollToBottom = true
        photosDataSource = PhotoCollectionViewDataSource(fetchResult: fetchResult, assetStore: assetStore, settings: settings)
        photosDataSource?.delegate = self
        collectionView?.dataSource = photosDataSource
        collectionView?.delegate = self
        titleContentView.deSelectView()
        previewViewContoller.fetchResult = fetchResult
    }
    
    func photoCollectionViewDataSourceDidReceiveCellSelectAction(_ cell: PhotoCell) {
        guard let photosDataSource = photosDataSource, collectionView.isUserInteractionEnabled else { return }
        guard let asset = cell.asset else { return }

        if assetStore.contains(asset) {
            let canSelectBefore = assetStore.canAppend()
            assetStore.remove(asset)
            let canSelectAfter = assetStore.canAppend()
            updateDoneButton()
            let selectedIndexPaths = assetStore.assets.compactMap({ (asset) -> IndexPath? in
                let index = photosDataSource.fetchResult.index(of: asset)
                guard index != NSNotFound else { return nil }
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
            deselectionClosure?(asset)
        } else {
            if assetStore.count >= settings.maxNumberOfSelections {
                selectLimitReachedClosure?(assetStore.count)
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = MBProgressHUDMode.text
                hud.bezelView.backgroundColor = UIColor.darkGray
                hud.label.text = NSLocalizedString("选择的图片数量超过限制", comment: "")
                hud.offset = CGPoint(x: 0, y: 0)
                hud.hide(animated: true, afterDelay: 2.0)
            }else if asset.mediaType == .video, assetStore.isContainPic() {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = MBProgressHUDMode.text
                hud.bezelView.backgroundColor = UIColor.darkGray
                hud.label.text = NSLocalizedString("不能同时选择图片和视频", comment: "")
                hud.offset = CGPoint(x: 0, y: 0)
                hud.hide(animated: true, afterDelay: 2.0)
            }else if asset.mediaType == .video, assetStore.count > 0 {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = MBProgressHUDMode.text
                hud.bezelView.backgroundColor = UIColor.darkGray
                hud.label.text = NSLocalizedString("一次只能选择一个视频", comment: "")
                hud.offset = CGPoint(x: 0, y: 0)
                hud.hide(animated: true, afterDelay: 2.0)
            }else if asset.mediaType == .video , asset.duration > 61 {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = MBProgressHUDMode.text
                hud.bezelView.backgroundColor = UIColor.darkGray
                hud.label.text = NSLocalizedString("请选择60秒以下的视频", comment: "")
                hud.offset = CGPoint(x: 0, y: 0)
                hud.hide(animated: true, afterDelay: 2.0)
            }else if asset.mediaType == .image, assetStore.isContainVideo() {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = MBProgressHUDMode.text
                hud.bezelView.backgroundColor = UIColor.darkGray
                hud.label.text = NSLocalizedString("不能同时选择图片和视频", comment: "")
                hud.offset = CGPoint(x: 0, y: 0)
                hud.hide(animated: true, afterDelay: 2.0)
            }else{
                let canSelectBefore = assetStore.canAppend()
                assetStore.append(asset)
                let canSelectAfter = assetStore.canAppend()
                if let selectionCharacter = settings.selectionCharacter {
                    cell.selectionString = String(selectionCharacter)
                } else {
                    cell.selectionString = String(assetStore.count)
                }
                cell.photoSelected = true
                updateDoneButton()
                selectionClosure?(asset)
                if (canSelectBefore != canSelectAfter) {
                    collectionView.reloadData()
                }
            }
        }
    }
}

// MARK: UICollectionViewDelegate
extension PhotosViewController {
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell, let asset = cell.asset {
            previewViewContoller.delegate = self
            let index = photosDataSource?.fetchResult.index(of: asset) ?? 0
            previewViewContoller.currentAssetIndex = index
            previewViewContoller.fetchResult = photosDataSource?.fetchResult
            navigationController?.pushViewController(previewViewContoller, animated: true)
        }
        return true
    }
    
    func previewViewControllerIsSelectImageItem(_ asset: PHAsset) -> Int {
        return (assetStore.assets.firstIndex(of: asset) ?? -1) + 1
    }
    
    func previewViewControllerCanSelectImageItem(_ asset: PHAsset) -> NSError? {
        if assetStore.contains(asset) {
            return nil
        }else if asset.mediaType == .video, assetStore.isContainPic() {
            return NSError(domain: "不能同时选择图片和视频", code: 1, userInfo: nil)
        }else if asset.mediaType == .video, assetStore.count > 0 {
            return NSError(domain: "一次只能选择一个视频", code: 2, userInfo: nil)
        }else if asset.mediaType == .video , asset.duration > 61 {
            return NSError(domain: "请选择60秒以下的视频", code: 3, userInfo: nil)
        }else if asset.mediaType == .image, assetStore.isContainVideo() {
            return NSError(domain: "不能同时选择图片和视频", code: 4, userInfo: nil)
        }else if assetStore.count >= settings.maxNumberOfSelections {
            selectLimitReachedClosure?(assetStore.count)
            return NSError(domain: "图片选择数量超过最大限制", code: 5, userInfo: nil)
        }
        return nil
    }
    
    func previewViewControllerDidSelectImageItem(_ asset: PHAsset) -> Int {
        guard let photosDataSource = photosDataSource, collectionView.isUserInteractionEnabled else { return -1 }

        let cell = collectionView.cellForItem(at: IndexPath(row: photosDataSource.fetchResult.index(of: asset), section: 0)) as? PhotoCell
        if assetStore.contains(asset) {
            assetStore.remove(asset)
            updateDoneButton()
            cell?.photoSelected = false
            deselectionClosure?(asset)
            return -1
        } else if assetStore.count < settings.maxNumberOfSelections {
            assetStore.append(asset)
            if let selectionCharacter = settings.selectionCharacter {
                cell?.selectionString = String(selectionCharacter)
            } else {
                cell?.selectionString = String(assetStore.count)
            }
            cell?.photoSelected = true
            updateDoneButton()
            selectionClosure?(asset)
            return assetStore.count
        }
        return -1
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
        let album = albumsDataSource.fetchResults[indexPath.section][indexPath.row]
        initializePhotosDataSource(album)
        updateAlbumTitle(album)
        collectionView?.reloadData()
        albumsViewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: Traits
extension PhotosViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let collectionViewFlowLayout = collectionViewLayout as? GridCollectionViewLayout {
            let itemSpacing: CGFloat = 2.0
            let cellsPerRow = settings.cellsPerRow(traitCollection.verticalSizeClass, traitCollection.horizontalSizeClass)
            
            collectionViewFlowLayout.itemSpacing = itemSpacing
            collectionViewFlowLayout.itemsPerRow = cellsPerRow
                        
            updateDoneButton()
        }
    }
}
