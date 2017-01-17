//
//  WheelsToolbar.swift
//  Sample
//
//  Created by Michael Rose on 5/17/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

public class WheelsToolbar: UIView {
    
    public var directionalityButton: DirectionalityButton!
    
    //TODO: Create Balance button View class
    public var balanceButton: BalanceButton!
    private var balanceImage: UIImageView!
    
    private var div: UIView!
    
    private var cnX:NSLayoutConstraint!
    private var cnY:NSLayoutConstraint!
    private var cnWidth:NSLayoutConstraint!
    private var cnHeight:NSLayoutConstraint!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        
        // Self
        self.backgroundColor = UIColor.whiteColor()
        
        // Div
        self.div = UIView(frame: CGRectZero)
        self.div.backgroundColor = UIColor.RGB(218.0, g: 218.0, b: 218.0)
        self.addSubview(self.div)
        
        self.div.translatesAutoresizingMaskIntoConstraints = false;
        self.cnX = NSLayoutConstraint(item: self.div, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0)
        self.cnY = NSLayoutConstraint(item: self.div, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0)
        self.cnWidth = NSLayoutConstraint(item: self.div, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: 0)
        self.cnHeight = NSLayoutConstraint(item: self.div, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0, constant: 0.5)
        self.addConstraints([cnX, cnY, cnWidth, cnHeight])
        
        // Directionality Button
        self.directionalityButton = DirectionalityButton()
        self.addSubview(self.directionalityButton)
        
        self.directionalityButton.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.directionalityButton, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0)
        self.cnY = NSLayoutConstraint(item: self.directionalityButton, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)
        self.cnWidth = NSLayoutConstraint(item: self.directionalityButton, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 0, constant: 80.0)
        self.cnHeight = NSLayoutConstraint(item: self.directionalityButton, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0, constant: 80.0)
        self.addConstraints([cnX, cnY, cnWidth, cnHeight])
        
        // Balance Button
        self.balanceButton = BalanceButton()
        self.addSubview(self.balanceButton)
        
        self.balanceButton.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.balanceButton, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 0.5, constant: -20.0)
        self.cnY = NSLayoutConstraint(item: self.balanceButton, attribute: .CenterY, relatedBy: .Equal, toItem: self.directionalityButton, attribute: .CenterY, multiplier: 1.0, constant: 0)
        self.cnWidth = NSLayoutConstraint(item: self.balanceButton, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 0, constant: 60.0)
        self.cnHeight = NSLayoutConstraint(item: self.balanceButton, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0, constant: 60.0)
        self.addConstraints([cnX, cnY, cnWidth, cnHeight])
        
    }

}
