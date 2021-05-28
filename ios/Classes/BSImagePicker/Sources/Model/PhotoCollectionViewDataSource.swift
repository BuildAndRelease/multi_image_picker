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

protocol PhotoCollectionViewDataSourceDelegate : AnyObject {
    func photoCollectionViewDataSourceDidReceiveCellSelectAction(_ cell : PhotoCell)
}

/**
 Gives UICollectionViewDataSource functionality with a given data source and cell factory
 */
final class PhotoCollectionViewDataSource : NSObject, UICollectionViewDataSource, PhotoCellDelegate {
    var fetchResult: Array<PHAsset>
    weak var delegate : PhotoCollectionViewDataSourceDelegate?
    private let photosManager = PHCachingImageManager.default()
    private let imageRequestOptions: PHImageRequestOptions
    private let imageContentMode: PHImageContentMode = .aspectFill
    private let assetStore: AssetStore
    private let cellWidth : CGFloat = (UIScreen.main.bounds.size.width / 4.0) * UIScreen.main.scale
    
    let settings: BSImagePickerSettings?
    
    init(fetchResult: Array<PHAsset>, assetStore: AssetStore, settings: BSImagePickerSettings?) {
        self.fetchResult = fetchResult
        self.settings = settings
        self.assetStore = assetStore
        imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.deliveryMode = .opportunistic
        imageRequestOptions.resizeMode = .fast
        imageRequestOptions.isSynchronous = false

        super.init()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        UIView.setAnimationsEnabled(false)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.cellIdentifier, for: indexPath) as! PhotoCell
        cell.accessibilityIdentifier = "photo_cell_\(indexPath.item)"
        cell.isAccessibilityElement = true
        cell.delegate = self
        if let settings = settings {
            cell.settings = settings
        }

        // Cancel any pending image requests
        if cell.tag != 0 {
            photosManager.cancelImageRequest(PHImageRequestID(Int32(cell.tag)))
            cell.tag = 0
        }
        
        let asset = fetchResult[indexPath.row]
        cell.asset = asset
        cell.imageView.contentMode = .scaleAspectFill
        cell.thumbCanLoad = false
        
        cell.tag = Int(photosManager.requestImage(for: asset, targetSize: CGSize(width: cellWidth, height: cellWidth), contentMode: imageContentMode, options: imageRequestOptions) { (result, info) in
            guard let result = result else {
                if let canceled = info?[PHImageCancelledKey] as? NSNumber, canceled == 1 {
                    return
                }
                cell.imageView.contentMode = .center
                cell.imageView.image = UIImage.wm_imageWithName_WMCameraResource(named: "ic_photo_error")?.maskImageWithColor(color: UIColor.gray)
                    return
            }
            cell.imageView.image = result
            cell.thumbCanLoad = true
            cell.tag = 0
        })
        
        // Set selection number
        if let index = assetStore.assets.firstIndex(of: asset) {
            if let character = settings?.selectionCharacter {
                cell.selectionString = String(character)
            } else {
                cell.selectionString = String(index+1)
            }
            cell.photoSelected = true
            cell.photoDisable = false
        } else {
            cell.photoSelected = false
            cell.photoDisable = !assetStore.canAppend(settings?.selectType ?? "", maxNum: settings?.maxNumberOfSelections ?? 9)
        }
        
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = UIAccessibilityTraits.button

        UIView.setAnimationsEnabled(true)
        
        return cell
    }
    
    func registerCellIdentifiersForCollectionView(_ collectionView: UICollectionView?) {
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.cellIdentifier)
    }
    
    func photoCellDidReceiveSelectAction(_ cell: PhotoCell) {
        self.delegate?.photoCollectionViewDataSourceDidReceiveCellSelectAction(cell)
    }
}
