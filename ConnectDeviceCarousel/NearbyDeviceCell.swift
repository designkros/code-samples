//
//  NearbyDeviceCell.swift
//  Sample
//
//  Created by Michael Rose on 4/14/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

public protocol NearbyDeviceCellDelegate: NSObjectProtocol {
    func userDidStartPanningNearbyDeviceCell(cell:NearbyDeviceCell)
    func userIsPanningNearbyDeviceCell(cell:NearbyDeviceCell, percent:CGFloat)
    func userDidStopPanningNearbyDeviceCell(cell:NearbyDeviceCell, connect:Bool)
}

public class NearbyDeviceCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    weak public var delegate: NearbyDeviceCellDelegate?
    
    private let NearbyDeviceHeight:CGFloat = 308.0
    private let NearbyDeviceDefaultAlpha: CGFloat = 0.3
    private let NearbyDeviceDefaultOffset: CGFloat = -88.0-22.0 // -88.0 height of footer, -22.0 height of label
    private let NearbyDeviceFinalOffset:CGFloat = 0
    private let NearbyDeviceMaxZoom: CGFloat = 1.1
    private let NearbyDeviceMinZoom: CGFloat = 0.7
    
    let NearbyDeviceDistanceToPanRequired:CGFloat = 110.0
    
    private var pulsingView: PulsingView!
    public var imageView: UIImageView!
    private var imageViewCnY: NSLayoutConstraint!
    private var percent: CGFloat = 0.0
    
    public var panGesture: UIPanGestureRecognizer!
    
    public var label: UILabel!
    
    private var cnX:NSLayoutConstraint!
    private var cnY:NSLayoutConstraint!
    private var cnWidth:NSLayoutConstraint!
    private var cnHeight:NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Self
        self.contentView.backgroundColor = UIColor.clearColor()
        
        // Label
        self.label = UILabel()
        self.label.font = UIFont(name: "GothamSSm-Bold", size: 18.0)
        self.label.textAlignment = .Center
        self.label.textColor = UIColor.RGB(153.0, g: 153.0, b: 153.0)
        self.contentView.addSubview(self.label)
        
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.label, attribute: .Left, relatedBy: .Equal, toItem: self.contentView, attribute: .Left, multiplier: 1.0, constant: 0)
        self.cnY = NSLayoutConstraint(item: self.label, attribute: .Top, relatedBy: .Equal, toItem: self.contentView, attribute: .CenterY, multiplier: 1.0, constant: 88.0+22.0)
        self.cnWidth = NSLayoutConstraint(item: self.label, attribute: .Right, relatedBy: .Equal, toItem: self.contentView, attribute: .Right, multiplier: 1.0, constant: 0)
        self.cnHeight = NSLayoutConstraint(item: self.label, attribute: .Height, relatedBy: .Equal, toItem: self.contentView, attribute: .Height, multiplier: 0, constant: 22.0)
        self.contentView.addConstraints([self.cnX, self.cnY, self.cnWidth, self.cnHeight])
        
        // Image View
        self.imageView = UIImageView()
        self.imageView.userInteractionEnabled = true
        self.imageView.alpha = NearbyDeviceDefaultAlpha
        self.imageView.contentMode = .ScaleAspectFit
        self.contentView.addSubview(self.imageView)
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.imageView, attribute: .Left, relatedBy: .Equal, toItem: self.contentView, attribute: .Left, multiplier: 1.0, constant: 0)
        self.imageViewCnY = NSLayoutConstraint(item: self.imageView, attribute: .CenterY, relatedBy: .Equal, toItem: self.contentView, attribute: .CenterY, multiplier: 1.0, constant: NearbyDeviceDefaultOffset)
        self.cnWidth = NSLayoutConstraint(item: self.imageView, attribute: .Right, relatedBy: .Equal, toItem: self.contentView, attribute: .Right, multiplier: 1.0, constant: 0)
        self.cnHeight = NSLayoutConstraint(item: self.imageView, attribute: .Height, relatedBy: .Equal, toItem: self.contentView, attribute: .Height, multiplier: 0, constant: NearbyDeviceHeight)
        self.contentView.addConstraints([self.cnX, self.imageViewCnY, self.cnWidth, self.cnHeight])
        
        // Pan Gesture
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        self.panGesture.maximumNumberOfTouches = 1
        self.panGesture.delegate = self
        self.imageView.addGestureRecognizer(self.panGesture)
        
        // Pulsing View
        self.pulsingView = PulsingView(frame: CGRect(x: 0, y: 0, width: 115.0, height: 115.0))
        self.contentView.insertSubview(self.pulsingView, atIndex: 0)
        
        self.pulsingView.translatesAutoresizingMaskIntoConstraints = false
        self.cnX = NSLayoutConstraint(item: self.pulsingView, attribute: .CenterX, relatedBy: .Equal, toItem: self.imageView, attribute: .CenterX, multiplier: 1.0, constant: 0)
        self.cnY = NSLayoutConstraint(item: self.pulsingView, attribute: .Bottom, relatedBy: .Equal, toItem: self.imageView, attribute: .Bottom, multiplier: 1.0, constant: 0)
        self.cnWidth = NSLayoutConstraint(item: self.pulsingView, attribute: .Width, relatedBy: .Equal, toItem: self.contentView, attribute: .Width, multiplier: 0, constant: 115.0)
        self.cnHeight = NSLayoutConstraint(item: self.pulsingView, attribute: .Height, relatedBy: .Equal, toItem: self.contentView, attribute: .Height, multiplier: 0, constant: 115.0)
        self.contentView.addConstraints([self.cnX, self.cnY, self.cnWidth, self.cnHeight])
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        self.returnToIdle()
    }
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        
        switch recognizer.state {
        case .Began:
            self.delegate?.userDidStartPanningNearbyDeviceCell(self)
            
            break
        case .Changed:
            let translation = recognizer.translationInView(self.contentView)
    
            // TODO: NearbyDevice* Consts are not being used right now. More could probably be created.
    
            self.percent = translation.y / self.NearbyDeviceDistanceToPanRequired
            
            // Image View Y Position
            // Image View Zoom
            var yPos:CGFloat = NearbyDeviceDefaultOffset
            var zoom:CGFloat = 1.0
            if (percent > 0 && percent < 1.0) {
                // Drag To Connect
                zoom = 1.0 + (percent * 0.075)
                yPos = self.NearbyDeviceDefaultOffset + translation.y
            } else if (percent > 0) {
                // Release
                zoom = 1.0 + (percent * 0.075)
                yPos = self.NearbyDeviceDefaultOffset + self.NearbyDeviceDistanceToPanRequired
            }
            self.imageViewCnY.constant = yPos
            self.imageView.zoom(zoom)
            
            // Image View Alpha
            let alpha:CGFloat = percent * 2.0
            if (alpha > self.NearbyDeviceDefaultAlpha) {
                self.imageView.alpha = alpha
            } else {
                self.imageView.alpha = self.NearbyDeviceDefaultAlpha
            }
            // Label Alpha
            self.label.alpha = 1.0 - alpha
            
            self.delegate?.userIsPanningNearbyDeviceCell(self, percent: percent)
            
            break
        case .Ended:
            let connect = self.percent > 1.0
            if (connect) {
                // Connect...
                self.connect()
            } else {
                // Return to idle...
                self.returnToIdle()
            }
            self.delegate?.userDidStopPanningNearbyDeviceCell(self, connect: connect)
            
            break
        case .Cancelled, .Failed:
            // Do same action as ".Ended" but without the percentage completed (don't connect)
            self.returnToIdle()
            self.delegate?.userDidStopPanningNearbyDeviceCell(self, connect: false)
            break
        default:
            //
            break
        }
        
    }
    
    public func returnToIdle() {
        // Enable Pan Gesture
        self.panGesture.enabled = true
        
        // Image View Y Position, Zoom, Alpha
        // Label Alpha
        self.imageViewCnY.constant = self.NearbyDeviceDefaultOffset
        
        UIView.animateWithDuration(0.3) {
            self.imageView.alpha = self.NearbyDeviceDefaultAlpha
            self.imageView.zoom(1.0)
            self.label.alpha = 1.0
            self.contentView.layoutIfNeeded()
        }
        
        // Pulsing view
        self.pulsingView.stopGlow()
    }
    
    public func connect() {
        // Disable Pan Gesture
        self.panGesture.enabled = false
    
        // Image View Y Position, Zoom, Alpha
        // Label Alpha
        self.imageViewCnY.constant = self.NearbyDeviceDefaultOffset + self.NearbyDeviceDistanceToPanRequired
        
        UIView.animateWithDuration(0.3) {
            self.imageView.zoom(1.0)
            self.imageView.alpha = 1.0  // Just incase...
            self.label.alpha = 0
            self.layoutIfNeeded() // Animate imageViewCnY constant
        }
        
        // Pulsing view
        self.pulsingView.startGlow(horizontally: true)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    public override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow vertical panning
        let velocity = self.panGesture.velocityInView(self.contentView)
        print (velocity)
        return abs(velocity.y) > abs(velocity.x)
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return true
    }
    
}
