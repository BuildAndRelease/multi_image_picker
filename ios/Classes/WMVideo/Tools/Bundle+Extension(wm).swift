//
//  Bundle+Extension.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit

extension Bundle{
    
    /// get bundle
    ///
    /// - Returns: Bundle
    class func wm_videoBundle() -> Bundle{
        return Bundle.init(for: WMCameraViewController.self)
    }
    
    
}
