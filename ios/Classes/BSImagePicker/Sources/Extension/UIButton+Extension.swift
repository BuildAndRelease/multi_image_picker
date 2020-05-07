//
//  UIButton+Extension.swift
//  multi_image_picker
//
//  Created by johnson_zhong on 2020/5/7.
//

import Foundation
import SwiftUI

extension UIButton {
    private func imageWithColor(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(rect)

            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return image
        }else {
            return nil
        }
    }

    func setBackgroundColor(color: UIColor, for state: UIControl.State) {
        if let image = imageWithColor(color: color) {
            self.setBackgroundImage(image, for: state)
        }
    }
}
