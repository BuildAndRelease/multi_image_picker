//
//  ImpUtils.swift
//  multi_image_picker
//
//  Created by amzwin on 2022/3/16.
//

import Foundation

class ImpUtils{
    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
            if let nav = base as? UINavigationController {
                return getTopViewController(base: nav.visibleViewController)

            } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                return getTopViewController(base: selected)

            } else if let presented = base?.presentedViewController {
                return getTopViewController(base: presented)
            }
            return base
     }
}
