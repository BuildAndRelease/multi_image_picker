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

/**
Implements the UITableViewDataSource protocol with a data source and cell factory
*/
final class AlbumTableViewDataSource : NSObject, UITableViewDataSource {
    let fetchResults: [PHAssetCollection]
    private let imageRequestOptions: PHImageRequestOptions
    private let imageManager = PHCachingImageManager.default()
    
    override init() {
        self.fetchResults = DataCenter.shared.fetchResults
        imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.deliveryMode = .opportunistic
        imageRequestOptions.resizeMode = .fast
        imageRequestOptions.isSynchronous = false
        super.init()
    }
    
    func countItems() -> Int {
        return fetchResults.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AlbumCell.cellIdentifier, for: indexPath) as! AlbumCell
        
        let album = fetchResults[indexPath.row]
        if album.estimatedAssetCount > 1000 || album.estimatedAssetCount <= 0 {
            cell.albumTitleLabel.text = album.localizedTitle
        }else {
            cell.albumTitleLabel.text = "\(String(describing: (album.localizedTitle ?? "未知相册名称")!))"
        }

        let scale = UIScreen.main.scale
        let imageSize = CGSize(width: 79 * scale, height: 79 * scale)
        let imageContentMode: PHImageContentMode = .aspectFill
        let result = PHAsset.fetchAssets(in: album, options: nil)
        result.enumerateObjects({ [weak self] (asset, idx, stop) in
            switch idx {
            case 0:
                self?.imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: imageContentMode, options: self?.imageRequestOptions) { (result, _) in
                    guard let result = result else { return }
                    cell.firstImageView.image = result
                    cell.secondImageView.image = result
                    cell.thirdImageView.image = result
                }
            case 1:
                self?.imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: imageContentMode, options: self?.imageRequestOptions) { (result, _) in
                    guard let result = result else { return }
                    cell.secondImageView.image = result
                    cell.thirdImageView.image = result
                }
            case 2:
                self?.imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: imageContentMode, options: self?.imageRequestOptions) { (result, _) in
                    guard let result = result else { return }
                    cell.thirdImageView.image = result
                }
            default:
                stop.initialize(to: true)
            }
        })
        
        return cell
    }
}
