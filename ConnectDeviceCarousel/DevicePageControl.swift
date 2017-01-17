//
//  DevicePageControl.swift
//  Sample
//
//  Created by Michael Rose on 4/17/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

class DevicePageControl: UIPageControl {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        // Allow images applied in updateDots() to show through
        self.pageIndicatorTintColor = UIColor.clearColor()
        self.currentPageIndicatorTintColor = UIColor.clearColor()
    }
    
    override func updateCurrentPageDisplay() {
        super.updateCurrentPageDisplay()
        self.updateDots()
    }
    
    func updateDots() {
        subviews.enumerate().forEach { (index, view) in
            let selected = index == currentPage
            let dot = view.findOrCreateButton()
            if index == numberOfPages - 1 {
                dot.setImage(UIImage(named: "dotPlus"), forState: .Normal)
            } else {
                dot.setImage(UIImage(named: "dotFilled"), forState: .Normal)
            }
            let alpha: CGFloat = selected ? 1.0 : 0.2
            dot.alpha = alpha
            dot.tintColor = UIColor.blackColor()
        }
    }
    
}

private extension UIView {
    
    // Will find a button in the hierarchy or will create one at the first level of subviews.
    func findOrCreateButton() -> UIButton {
        if let button = findButton() {
            return button
        } else {
            let button = UIButton(type: .System)
            button.frame = bounds
            addSubview(button)
            return button
        }
    }
    
    func findButton() -> UIButton? {
        if let me = self as? UIButton {
            return me
        } else {
            return subviews
                .lazy
                .flatMap { $0.findButton() }
                .first
        }
    }
    
}
