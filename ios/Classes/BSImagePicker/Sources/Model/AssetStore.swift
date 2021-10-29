// The MIT License (MIT)
//
// Copyright (c) 2019 Joakim Gyllström
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

import Foundation
import Photos


class AssetStore {
    private init() {
        self.assets = []
    }
    
    private(set) var assets: [PHAsset]

    init(assets: [PHAsset] = []) {
        self.assets = assets
    }

    var count: Int {
        return assets.count
    }
    
    func updateAssets(assets: [PHAsset] = []) {
        self.assets = assets
    }

    func contains(_ asset: PHAsset) -> Bool {
        return assets.contains(asset)
    }

    func append(_ asset: PHAsset) {
        guard contains(asset) == false else { return }
        assets.append(asset)
    }
    
    func isContainVideo() -> Bool {
        for asset in assets {
            if asset.mediaType == .video {
                return true
            }
        }
        return false
    }
    
    func isContainPic() -> Bool {
        for asset in assets {
            if asset.mediaType == .image {
                return true
            }
        }
        return false
    }

    func remove(_ asset: PHAsset) {
        guard let index = assets.firstIndex(of: asset) else { return }
        assets.remove(at: index)
    }
    
    func canAppend(_ selectType : String, maxNum : Int) -> Bool {
        if "selectSingleType" == selectType , isContainVideo(){
            return false;
        }else{
            return assets.count <  maxNum
        }
    }
}
