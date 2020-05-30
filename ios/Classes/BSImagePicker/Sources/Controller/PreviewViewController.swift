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

protocol PreviewViewControllerDelegate : class {
    func previewViewControllerDidSelectImageItem(_ asset : PHAsset) -> Int
    func previewViewControllerIsSelectImageItem(_ asset : PHAsset) -> Int
}

final class PreviewViewController : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, SelectionViewDelegate {
    private let cellIdentifier = "PreviewCollectionCell"
    
    weak var delegate : PreviewViewControllerDelegate?
    var loadingView = true
    
    var currentAssetIndex : Int = 0
    var fetchResult: PHFetchResult<PHAsset>? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    var collectionView : UICollectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: UICollectionViewFlowLayout())
    var cancelBarButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back", comment: ""), style: .plain, target: nil, action: nil)
    var selectBarButton: UIBarButtonItem = UIBarButtonItem()
    var selectionView: SelectionView = SelectionView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
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
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: collectionView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 44.0),
            NSLayoutConstraint(item: collectionView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: collectionView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: collectionView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
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
        collectionView.scrollToItem(at: IndexPath(row: currentAssetIndex, section: 0), at: .centeredHorizontally, animated: false)
        refreshSelectIndex()
    }
    
    override func viewDidLayoutSubviews() {
        if loadingView {
            collectionView.scrollToItem(at: IndexPath(row: currentAssetIndex, section: 0), at: .centeredHorizontally, animated: false)
            refreshSelectIndex()
            loadingView = false
        }
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loadingView = true
    }
    
    func refreshSelectIndex() {
        if currentAssetIndex < (self.fetchResult?.count ?? 0) , let asset = self.fetchResult?[currentAssetIndex] , let selectIndex = self.delegate?.previewViewControllerIsSelectImageItem(asset) {
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
        self.navigationController?.popViewController(animated: true)
    }
    
    func selectViewDidSelectDidAction(_ view: SelectionView) {
        if let cell = collectionView.visibleCells.first, let asset = (cell as! PreviewCollectionViewCell).asset {
            if asset.mediaType == .video , asset.duration > 61 {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = MBProgressHUDMode.text
                hud.label.text = NSLocalizedString("请选择60秒以下的视频", comment: "")
                hud.bezelView.backgroundColor = UIColor.darkGray
                hud.offset = CGPoint(x: 0, y: 0)
                hud.hide(animated: true, afterDelay: 2.0)
            }else if let selectIndex = self.delegate?.previewViewControllerDidSelectImageItem(asset) {
                if selectIndex > 0 {
                    selectionView.selectionString = "\(selectIndex)"
                    selectionView.selected = true
                }else if selectIndex == -1 {
                    selectionView.selectionString = ""
                    selectionView.selected = false
                }else if selectIndex == -2 {
                    selectionView.selectionString = ""
                    selectionView.selected = false
                    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud.mode = MBProgressHUDMode.text
                    hud.bezelView.backgroundColor = UIColor.darkGray
                    hud.label.text = NSLocalizedString("选择的图片数量超过限制", comment: "")
                    hud.offset = CGPoint(x: 0, y: 0)
                    hud.hide(animated: true, afterDelay: 2.0)
                }
            }
        }
    }
}
