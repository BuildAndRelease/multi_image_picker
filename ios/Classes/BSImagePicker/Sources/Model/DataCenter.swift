//
//  DataCenter.swift
//  multi_image_picker
//
//  Created by johnson_zhong on 2021/10/29.
//

import Photos
import Foundation

final class DataCenter {
    static let shared = DataCenter()
    private init() {}
    
    var assetStore = AssetStore()
    var settings = Settings()
    var defaultSelectMedia : String = ""
    var fetchOptions : PHFetchOptions? = nil
    var mediaShowTypes : [PHAssetMediaType] = [PHAssetMediaType.image, PHAssetMediaType.video] {
        didSet {
            if mediaShowTypes.contains(PHAssetMediaType.image), mediaShowTypes.contains(PHAssetMediaType.video) {
                fetchOptions = nil
            }else if mediaShowTypes.contains(PHAssetMediaType.image) {
                fetchOptions = PHFetchOptions()
                fetchOptions?.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            }else if mediaShowTypes.contains(PHAssetMediaType.video) {
                fetchOptions = PHFetchOptions()
                fetchOptions?.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            }
        }
    }
    var selectionClosure: ((_ asset: PHAsset) -> Void)?
    var deselectionClosure: ((_ asset: PHAsset) -> Void)?
    var cancelClosure: ((_ assets: [Dictionary<String, String>], _ thumb : Bool) -> Void)?
    var finishClosure: ((_ assets: NSDictionary, _ success : Bool, _ error : NSError) -> Void)?
    var selectLimitReachedClosure: ((_ selectionLimit: Int) -> Void)?
    
    @objc public lazy var fetchResults: [PHAssetCollection] = { () -> [PHAssetCollection] in
        return fetchPhotoAlbum()
    }()
    
    func resetAllData() {
        assetStore = AssetStore()
        settings = Settings()
        defaultSelectMedia = ""
        mediaShowTypes = [PHAssetMediaType.image, PHAssetMediaType.video]
        selectionClosure = nil
        deselectionClosure = nil
        cancelClosure = nil
        finishClosure = nil
        selectLimitReachedClosure = nil
    }
    
    func refreshFetchResults() {
        fetchResults = fetchPhotoAlbum()
    }
    
    func fetchPhotoAlbum() -> Array<PHAssetCollection> {
        var results =  Array<PHAssetCollection>()
        let cameraRollResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        
//        最多的那个文件夹排第一
        var maxCount = 0
        var maxCountCollection : PHAssetCollection?
        for i in 0 ..< cameraRollResult.count {
            let collection = cameraRollResult.object(at: i)
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            if assets.count > 0 {
                results.append(collection)
            }
            if maxCount < assets.count {
                maxCount = assets.count
                maxCountCollection = collection
            }
        }
        
        if maxCountCollection != nil, let index = results.firstIndex(of: maxCountCollection!) {
            let moveCollection = results.remove(at: index)
            results.insert(moveCollection, at: 0)
        }
        
//        增加其他类型的文件分类
        let albumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        for i in 0 ..< albumResult.count {
            let collection = albumResult.object(at: i)
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            if assets.count > 0 {
                results.append(collection)
            }
        }
        return results
    }
    
    func indexAndAssetsOfMainAlbum() -> (Int, PHFetchResult<PHAsset>)?  {
        if let album = fetchResults.first {
            let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
            var index = 0
            if defaultSelectMedia.isEmpty {
                if let asset = assetStore.assets.first {
                    index = assets.index(of: asset)
                }
            }else {
                for i in 0 ..< assets.count {
                    let asset = assets.object(at: i)
                    if asset.localIdentifier == defaultSelectMedia {
                        index = i
                        break
                    }
                }
            }
            return (index, assets)
        }
        return nil
    }
    
    func updateSelectMedias(selectMedias : [String]) {
        let assets : PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: selectMedias, options: nil)
        var sortedSelections : [PHAsset] = []
        for identify in selectMedias {
            for i in 0 ..< assets.count {
                if assets.object(at: i).localIdentifier == identify {
                    sortedSelections.append(assets.object(at: i))
                    break
                }
            }
        }
        assetStore.updateAssets(assets: sortedSelections)
    }
    
    func assetsWithAlbum(_ album: PHAssetCollection) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(in: album, options: fetchOptions)
    }
    
}
