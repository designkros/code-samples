//
//  WheelProgressView.swift
//  Sample
//
//  Created by Michael Rose on 5/18/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

public class WheelProgressView: UIView {

    public enum WheelProgressStyle {
        case WheelProgressStyleTone
        case WheelProgressStyleVolume
    }
    
    public var progress: CGFloat = 0 {
        didSet {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    public var style: WheelProgressStyle!
    
    private var topBG:UIView!
    private var topProgress:UIView!
    
    private var bottomBG:UIView!
    private var bottomProgress:UIView!
    
    convenience init(style: WheelProgressStyle) {
        self.init(frame: CGRectZero)
        self.style = style
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialize() {
    
        // Top Background
        self.topBG = UIView()
        self.topBG.backgroundColor = UIColor.RGB(69.0, g: 69.0, b: 69.0)
        self.addSubview(self.topBG)
        
        // Top Progress
        self.topProgress = UIView()
        self.topProgress.backgroundColor = UIColor.whiteColor()
        self.addSubview(self.topProgress)
        
        // Bottom Background
        self.bottomBG = UIView()
        self.bottomBG.backgroundColor = UIColor.RGB(69.0, g: 69.0, b: 69.0)
        self.addSubview(self.bottomBG)
        
        // Top Progress
        self.bottomProgress = UIView()
        self.bottomProgress.backgroundColor = UIColor.whiteColor()
        self.addSubview(self.bottomProgress)
    }
    
    public override func layoutSubviews() {
        
        let margin:CGFloat = 2.0
        let width = self.bounds.size.width
        
        switch self.style! {
        case .WheelProgressStyleTone:
            // Centered
            let height = (self.bounds.size.height - margin) * 0.5
            
            self.topBG.frame = CGRect(x: 0, y: 0, width: width, height: height)
            self.bottomBG.frame = CGRect(x: 0, y: height + margin, width: width, height: height)
            
            if (progress == 0) {
                self.topProgress.frame = CGRectZero
                self.bottomProgress.frame = CGRectZero
            } else if (progress > 0) {
                // Bottom
                let frame = CGRect(x: 0, y: height + margin, width: width, height: height * self.progress)
                self.bottomProgress.frame = frame
                
                self.topProgress.frame = CGRectZero
            } else if (progress < 0) {
                // Top
                let frame = CGRect(x: 0, y: height, width: width, height: height * self.progress)
                self.topProgress.frame = frame
                
                self.bottomProgress.frame = CGRectZero
            }
            
            break
        case .WheelProgressStyleVolume:
            // Offset
            let topHeight = round((self.bounds.size.height - margin) * 0.666) // 0.333 for reverse
            let bottomHeight = round((self.bounds.size.height - margin) * 0.333) // 0.666 for reverse
            
            self.topBG.frame = CGRect(x: 0, y: 0, width: width, height: topHeight)
            self.bottomBG.frame = CGRect(x: 0, y: topHeight + margin, width: width, height: bottomHeight)
            
            if (progress == 0) {
                self.topProgress.frame = CGRectZero
                self.bottomProgress.frame = CGRectZero
            } else if (progress > 0) {
                // Bottom
                let frame = CGRect(x: 0, y: topHeight + margin, width: width, height: bottomHeight * self.progress)
                self.bottomProgress.frame = frame
                
                self.topProgress.frame = CGRectZero
            } else if (progress < 0) {
                // Top
                let frame = CGRect(x: 0, y: topHeight, width: width, height: topHeight * self.progress)
                self.topProgress.frame = frame
                
                self.bottomProgress.frame = CGRectZero
            }
            
            break
        }
        
    }

}
