//
//  PulsingView.swift
//  Sample
//
//  Created by Michael Rose on 4/14/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

private let RingAnimationDuration: NSTimeInterval = 3.5
private let PerRingTimeOffset: NSTimeInterval = 0.8

public class PulsingView : UIView {
    
    private var rings: [CAShapeLayer] = []
    private var isGlowing: Bool = false
    
    private let maxScale: CGFloat = 9.0
    private let horizontalRotation: CGFloat = CGFloat(M_PI * 0.4)
    private let maxNumberOfRings: Int = 3
    private let ringInitialRatio: CGFloat = 0.16
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        self.backgroundColor = UIColor.clearColor()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = min(self.bounds.size.width, self.bounds.size.height) / 2.0
        rings.forEach { ring in
            ring.position = CGPoint(x: CGRectGetMidX(self.bounds), y: CGRectGetMidY(self.bounds))
        }
    }
    
    public func startGlow(horizontally horizontal: Bool = false) {
        if isGlowing { return }
        
        isGlowing = true
        for _ in 1...maxNumberOfRings {
            glowOneRing(horizontal)
        }
    }
    
    public func stopGlow() {
        isGlowing = false
        rings.forEach {
            $0.removeAllAnimations()
            $0.removeFromSuperlayer()
        }
        rings.removeAll()
    }
    
    private func glowOneRing(horizontal: Bool) {
        guard isGlowing && rings.count < maxNumberOfRings else { return }
        
        let halfWidth = self.bounds.size.width * 0.5
        let halfHeight = self.bounds.size.height * 0.5
        
        let ring = CAShapeLayer()
        ring.path = UIBezierPath(ovalInRect: self.bounds).CGPath
        ring.fillColor = UIColor.RGB(102.0, g: 102.0, b: 102.0).CGColor
        ring.zPosition = CGFloat(-100 - rings.count)
        ring.bounds = layer.bounds
        ring.position = CGPoint(x: halfWidth, y: halfHeight)
        
        if horizontal {
            let flatTransform = CATransform3DMakeTranslation(0, halfHeight, -halfWidth)
            ring.transform = CATransform3DRotate(flatTransform, horizontalRotation, self.bounds.size.width, 0, 0)
        }
        
        let scaleAnimation = CABasicAnimation()
        scaleAnimation.removedOnCompletion = false
        scaleAnimation.duration = RingAnimationDuration
        scaleAnimation.fromValue = ringInitialRatio
        scaleAnimation.toValue = maxScale
        scaleAnimation.repeatCount = HUGE
        scaleAnimation.timeOffset = PerRingTimeOffset * Double(rings.count)
        
        let fadeAnimation = CABasicAnimation()
        fadeAnimation.removedOnCompletion = false
        fadeAnimation.duration = RingAnimationDuration
        fadeAnimation.fromValue = 0.1
        fadeAnimation.toValue = 0.0
        fadeAnimation.repeatCount = HUGE
        fadeAnimation.timeOffset = PerRingTimeOffset * Double(rings.count)
        
        ring.addAnimation(scaleAnimation, forKey: "transform.scale")
        ring.addAnimation(fadeAnimation, forKey: "opacity")
        
        layer.insertSublayer(ring, below: layer)
        rings.append(ring)
    }
    
}
