//
//  UIImage+Extension.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit

extension UIImage{
    
    /// Get image from WMCameraResource.bundle
    ///
    /// - Parameter imgName: image name
    /// - Returns:  UIImage
    class func wm_imageWithName_WMCameraResource(named imgName:String) -> UIImage?{
        let imgBundle:Bundle = Bundle.wm_videoBundle()
        let name:String = imgName.appending("@2x")
        guard let imgPath = imgBundle.path(forResource: name, ofType: "png") else { return nil }
        let image:UIImage? = UIImage.init(contentsOfFile: imgPath)
        return image
    }
    
    /// 更改图片颜色
    public func maskImageWithColor(color : UIColor) -> UIImage{
        UIGraphicsBeginImageContext(self.size)
        color.setFill()
        let bounds = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIRectFill(bounds)
        self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
    
}
