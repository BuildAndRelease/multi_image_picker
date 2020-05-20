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

final class PhotosViewController : UICollectionViewController , CustomTitleViewDelegate, PhotoCollectionViewDataSourceDelegate {
    var selectionClosure: ((_ asset: PHAsset) -> Void)?
    var deselectionClosure: ((_ asset: PHAsset) -> Void)?
    var cancelClosure: ((_ assets: [PHAsset]) -> Void)?
    var finishClosure: ((_ assets: [PHAsset], _ thumb : Bool) -> Void)?
    var selectLimitReachedClosure: ((_ selectionLimit: Int) -> Void)?
    
    var cancelBarButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    let titleContentView = CustomTitleView(frame: CGRect(x: 0, y: 0, width: 120, height: 34.0))
    
    var originBarButton: SSRadioButton = SSRadioButton(type: .custom)
    var doneBarButton: UIButton = UIButton(type: .custom)
    var bottomContentView : UIView = UIView()
    
    let settings: BSImagePickerSettings
    private var assetStore: AssetStore
    
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
    
    private lazy var previewViewContoller: PreviewViewController? = {
        return PreviewViewController(nibName: nil, bundle: nil)
    }()
    
    required init(fetchResults: [PHFetchResult<PHAssetCollection>], assetStore: AssetStore, settings aSettings: BSImagePickerSettings) {
        self.albumsDataSource = AlbumTableViewDataSource(fetchResults: fetchResults)
        self.settings = aSettings
        self.assetStore = assetStore
        super.init(collectionViewLayout: GridCollectionViewLayout())
        
        PHPhotoLibrary.shared().register(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("b0rk: initWithCoder not implemented")
    }
    
    deinit {
        print("PhotosViewController deinit")
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func loadView() {
        super.loadView()
        
        collectionView?.backgroundColor = settings.backgroundColor
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
    }
    
    // MARK: Appear/Disappear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDoneButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.toolbar.layoutIfNeeded()
        bottomContentView.frame = self.navigationController?.toolbar.bounds ?? CGRect(x: 0, y: 0, width:  UIScreen.main.bounds.size.width, height: 49.0)
        doneBarButton.center = CGPoint(x: bottomContentView.bounds.size.width - 40 - 5, y: bottomContentView.bounds.size.height/2.0)
        originBarButton.center = CGPoint(x: bottomContentView.bounds.size.width/2.0, y: bottomContentView.bounds.size.height/2.0)
        self.navigationController?.toolbar.addSubview(bottomContentView)
    }
    
    // MARK: Button actions
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
        cancelClosure?(assetStore.assets)
    }
    
    @objc func doneButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        finishClosure?(assetStore.assets, !originBarButton.isSelected)
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
            doneBarButton.setTitle("\(doneBarButtonTitle)(\(assetStore.count)/\(settings.maxNumberOfSelections))", for: .normal)
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
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        photosDataSource = PhotoCollectionViewDataSource(fetchResult: PHAsset.fetchAssets(in: album, options: fetchOptions), assetStore: assetStore, settings: settings)
        photosDataSource?.delegate = self
        collectionView?.dataSource = photosDataSource
        collectionView?.delegate = self
        titleContentView.deSelectView()
    }
    
    func photoCollectionViewDataSourceDidReceiveCellSelectAction(_ cell: PhotoCell) {
        guard let photosDataSource = photosDataSource, collectionView.isUserInteractionEnabled else { return }
        guard let asset = cell.asset else { return }

        if assetStore.contains(asset) {
            assetStore.remove(asset)
            updateDoneButton()
            let selectedIndexPaths = assetStore.assets.compactMap({ (asset) -> IndexPath? in
                let index = photosDataSource.fetchResult.index(of: asset)
                guard index != NSNotFound else { return nil }
                return IndexPath(item: index, section: 0)
            })
            UIView.setAnimationsEnabled(false)
            collectionView.reloadItems(at: selectedIndexPaths)
            UIView.setAnimationsEnabled(true)
            cell.photoSelected = false
            deselectionClosure?(asset)
        } else if assetStore.count < settings.maxNumberOfSelections {
            assetStore.append(asset)
            if let selectionCharacter = settings.selectionCharacter {
                cell.selectionString = String(selectionCharacter)
            } else {
                cell.selectionString = String(assetStore.count)
            }

            cell.photoSelected = true
            updateDoneButton()
            selectionClosure?(asset)
        } else if assetStore.count >= settings.maxNumberOfSelections {
            selectLimitReachedClosure?(assetStore.count)
        }
    }
}

// MARK: UICollectionViewDelegate
extension PhotosViewController {
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let vc = previewViewContoller, let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell, let asset = cell.asset {
            vc.currentAsset = asset
            vc.fetchResult = photosDataSource?.fetchResult
            navigationController?.pushViewController(vc, animated: true)
            bottomContentView.removeFromSuperview()
            navigationController?.setToolbarHidden(true, animated: true)
        }
        
        return true
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

// MARK: PHPhotoLibraryChangeObserver
extension PhotosViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async(execute: { () -> Void in
            guard let photosDataSource = self.photosDataSource, let collectionView = self.collectionView else {
                return
            }
            if let photosChanges = changeInstance.changeDetails(for: photosDataSource.fetchResult as! PHFetchResult<PHObject>) {
                let removedCount = photosChanges.removedIndexes?.count ?? 0
                let insertedCount = photosChanges.insertedIndexes?.count ?? 0
                let changedCount = photosChanges.changedIndexes?.count ?? 0
                if photosChanges.hasIncrementalChanges && (removedCount > 0 || insertedCount > 0 || changedCount > 0) {
                    photosDataSource.fetchResult = photosChanges.fetchResultAfterChanges as! PHFetchResult<PHAsset>
                    collectionView.performBatchUpdates({
                        if let removed = photosChanges.removedIndexes {
                            collectionView.deleteItems(at: removed.bs_indexPathsForSection(0))
                        }
                        
                        if let inserted = photosChanges.insertedIndexes {
                            collectionView.insertItems(at: inserted.bs_indexPathsForSection(0))
                        }
                        
                        if let changed = photosChanges.changedIndexes {
                            collectionView.reloadItems(at: changed.bs_indexPathsForSection(0))
                        }
                    })
                } else if photosChanges.hasIncrementalChanges == false {
                    photosDataSource.fetchResult = photosChanges.fetchResultAfterChanges as! PHFetchResult<PHAsset>
                    collectionView.reloadData()
                }
            }
        })
    }
}
