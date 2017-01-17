//
//  SearchCell.swift
//  Sample
//
//  Created by Michael Rose on 4/14/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

public protocol SearchCellDelegate: NSObjectProtocol {
    func userNeedsHelp()
}

public class SearchCell: UICollectionViewCell {
    
    weak public var delegate: SearchCellDelegate?
    public var pulsingView: PulsingView!
    
    private var imageView: UIImageView!
    private var button: UIButton!
    private var label: UILabel!
    
    private var cnX:NSLayoutConstraint!
    private var cnY:NSLayoutConstraint!
    private var cnWidth:NSLayoutConstraint!
    private var cnHeight:NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Self
        self.contentView.backgroundColor = UIColor.clearColor()
        
        // Pulsing View
        self.pulsingView = PulsingView(frame: CGRect(x: 0, y: 0, width: 128.0, height: 128.0))
        self.pulsingView.startGlow()
        self.contentView.addSubview(self.pulsingView)
        
        self.pulsingView.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.pulsingView, attribute: .CenterX, relatedBy: .Equal, toItem: self.contentView, attribute: .CenterX, multiplier: 1.0, constant: 0)
        self.cnY = NSLayoutConstraint(item: self.pulsingView, attribute: .CenterY, relatedBy: .Equal, toItem: self.contentView, attribute: .CenterY, multiplier: 1.0, constant: -88.0) // -88.0 height of footer
        self.cnWidth = NSLayoutConstraint(item: self.pulsingView, attribute: .Width, relatedBy: .Equal, toItem: self.contentView, attribute: .Width, multiplier: 0, constant: 128.0)
        self.cnHeight = NSLayoutConstraint(item: self.pulsingView, attribute: .Height, relatedBy: .Equal, toItem: self.contentView, attribute: .Height, multiplier: 0, constant: 128.0)
        self.contentView.addConstraints([self.cnX, self.cnY, self.cnWidth, self.cnHeight])
        
        // Image View
        self.imageView = UIImageView(image: UIImage(named: "logo"))
        self.contentView.addSubview(self.imageView)
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.imageView, attribute: .CenterX, relatedBy: .Equal, toItem: self.pulsingView, attribute: .CenterX, multiplier: 1.0, constant: 0)
        self.cnY = NSLayoutConstraint(item: self.imageView, attribute: .CenterY, relatedBy: .Equal, toItem: self.pulsingView, attribute: .CenterY, multiplier: 1.0, constant: 0)
        self.contentView.addConstraints([self.cnX, self.cnY])
        
        // Button
        self.button = UIButton(type: .Custom)
        self.button.setTitle("Need Help?", forState: .Normal)
        self.button.setTitleColor(UIColor.RGB(170.0, g: 170.0, b: 170.0), forState: .Normal)
        self.button.setTitleColor(UIColor.RGB(130.0, g: 130.0, b: 130.0), forState: .Highlighted)
        self.button.titleLabel!.font = UIFont(name: "GothamSSm-Bold", size: 13.0)
        self.button.titleLabel!.textAlignment = .Center
        self.button.contentEdgeInsets = UIEdgeInsetsMake(0, 22.0, 0, 22.0) // Increase left/right touch area
        self.button.addTarget(self, action: #selector(didButton), forControlEvents: .TouchUpInside)
        self.contentView.addSubview(self.button)
        
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.button, attribute: .CenterX, relatedBy: .Equal, toItem: self.contentView, attribute: .CenterX, multiplier: 1.0, constant: 0)
        self.cnY = NSLayoutConstraint(item: self.button, attribute: .Bottom, relatedBy: .Equal, toItem: self.contentView, attribute: .Bottom, multiplier: 1.0, constant: -33.0)
        self.cnHeight = NSLayoutConstraint(item: self.button, attribute: .Height, relatedBy: .Equal, toItem: self.contentView, attribute: .Height, multiplier: 0, constant: 44.0)
        self.contentView.addConstraints([self.cnX, self.cnY, self.cnHeight])
        
        // Label
        self.label = UILabel()
        self.label.textColor = UIColor.RGB(170.0, g: 170.0, b: 170.0)
        self.label.font = UIFont(name: "GothamSSm-Book", size: 12.0)
        self.label.numberOfLines = 2
        self.label.textAlignment = .Center
        self.label.text = "Make sure your product is on and\nwithin range of this device."
        self.contentView.addSubview(self.label)
        
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.label, attribute: .CenterX, relatedBy: .Equal, toItem: self.button, attribute: .CenterX, multiplier: 1.0, constant: 0)
        self.cnY = NSLayoutConstraint(item: self.label, attribute: .Bottom, relatedBy: .Equal, toItem: self.button, attribute: .Top, multiplier: 1.0, constant: -11.0)
        self.cnWidth = NSLayoutConstraint(item: self.label, attribute: .Width, relatedBy: .Equal, toItem: self.contentView, attribute: .Width, multiplier: 0, constant: 286.0)
        self.cnHeight = NSLayoutConstraint(item: self.label, attribute: .Height, relatedBy: .Equal, toItem: self.contentView, attribute: .Height, multiplier: 0, constant: 44.0)
        self.contentView.addConstraints([self.cnX, self.cnY, self.cnWidth, self.cnHeight])
    
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didButton() {
        self.delegate?.userNeedsHelp()
    }
    
}
