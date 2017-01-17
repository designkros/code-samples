//
//  WheelMaskView.swift
//  Sample
//
//  Created by Michael Rose on 5/23/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

public class WheelMaskView: UIView {

    private var gradient: CAGradientLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Self
        self.userInteractionEnabled = false
        self.backgroundColor = UIColor.clearColor()
        
        // Gradient
        self.gradient = CAGradientLayer()
        let color1 = UIColor.RGBA(255.0, g: 0, b: 0, a: 0).CGColor
        let color2 = UIColor.RGBA(255.0, g: 0, b: 0, a: 1.0).CGColor
        gradient.colors = [color1, color2, color2, color1]
        gradient.locations = [0.0, 0.1, 0.9, 1.0]
        self.layer.addSublayer(self.gradient)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        self.gradient.frame = self.bounds
    }

}
