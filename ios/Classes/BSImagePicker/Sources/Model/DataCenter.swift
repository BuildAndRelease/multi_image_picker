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
    var mediaShowTypes : [PHAssetMediaType] = [PHAssetMediaType.image, PHAssetMediaType.video]
    var selectionClosure: ((_ asset: PHAsset) -> Void)?
    var deselectionClosure: ((_ asset: PHAsset) -> Void)?
    var cancelClosure: ((_ assets: [Dictionary<String, String>], _ thumb : Bool) -> Void)?
    var finishClosure: ((_ assets: NSDictionary, _ success : Bool, _ error : NSError) -> Void)?
    var selectLimitReachedClosure: ((_ selectionLimit: Int) -> Void)?
    
    @objc public lazy var fetchResults: [PHAssetCollection] = { () -> [PHAssetCollection] in
        var results =  Array<PHAssetCollection>()
        let cameraRollResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        
//        最多的那个文件夹排第一
        var maxCount = 0
        var maxCountCollection : PHAssetCollection?
        for i in 0 ..< cameraRollResult.count {
            let collection = cameraRollResult.object(at: i)
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            let assetsCount = assetsCountWithType(assets: assets)
            if assetsCount > 0 {
                results.append(collection)
            }
            if maxCount < assetsCount {
                maxCount = assetsCount
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
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            let assetsCount = assetsCountWithType(assets: assets)
            if assetsCount > 0 {
                results.append(collection)
            }
        }
        return results
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
    
    func indexAndAssetsOfMainAlbum() -> (Int, Array<PHAsset>)?  {
        if let album = fetchResults.first {
            let fetchResult = PHAsset.fetchAssets(in: album, options: nil)
            var assets : Array<PHAsset> = []
            fetchResult.enumerateObjects(options: [.reverse]) { (asset, index, pt) in
                if self.mediaShowTypes.contains(asset.mediaType) {
                    assets.append(asset)
                }
            }
            let index = defaultSelectMedia.isEmpty ? (assets.firstIndex(of: assetStore.assets.first!) ?? 0) : assets.firstIndex{asset in
                return asset.localIdentifier == defaultSelectMedia
            } ?? 0
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
    
    func assetsWithAlbum(_ album: PHAssetCollection) -> Array<PHAsset> {
        let fetchResult = PHAsset.fetchAssets(in: album, options: nil)
        var assets : Array<PHAsset> = []
        fetchResult.enumerateObjects { (asset, index, pt) in
            if self.mediaShowTypes.contains(asset.mediaType) {
                assets.append(asset)
            }
        }
        return assets
    }
    
    func assetsCountWithType(assets: PHFetchResult<PHAsset>) -> Int {
        var count = 0
        mediaShowTypes.forEach { type in
           count += assets.countOfAssets(with:  type)
        }
        return count
    }
    
    
}
