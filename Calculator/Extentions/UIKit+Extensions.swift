//
//  UIKit+Extensions.swift
//  Calculator
//
//  Created by Chijioke on 3/25/20.
//  Copyright © 2020 Chijioke. All rights reserved.
//

import UIKit

extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext();
        color.setFill()
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(image, for: state);
    }
}

extension UIView {
    func makeRound(radius: CGFloat? = nil) {
        clipsToBounds = true
        layer.cornerRadius = radius ?? bounds.height/2
    }

    func findAll<T: UIView>(type: T.Type) -> [T] {

        return self.subviews.flatMap({ item -> [T] in
            if let item = item as? T {
                return [item]
            }

            return item.findAll(type: type)
        })
    }
}
