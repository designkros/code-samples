//
//  WheelValueCell.swift
//  Sample
//
//  Created by Michael Rose on 5/6/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

public class WheelValueCell: UICollectionViewCell {
 
    public var label:UILabel!
    
    private var cnX:NSLayoutConstraint!
    private var cnY:NSLayoutConstraint!
    private var cnWidth:NSLayoutConstraint!
    private var cnHeight:NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Rasterize the cells for performance
        self.contentView.layer.shouldRasterize = true
        self.contentView.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        // Label
        self.label = UILabel(frame: self.contentView.bounds)
        self.label.autoresizingMask = [ .FlexibleWidth, .FlexibleHeight]
        self.label.textColor = UIColor.blackColor()
        self.label.numberOfLines = 1
        self.label.textAlignment = .Center
        self.contentView.addSubview(self.label)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func prepareForReuse() {
        self.label.text = ""
    }
    
}
