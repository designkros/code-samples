//
//  WheelView.swift
//  Sample
//
//  Created by Michael Rose on 5/17/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit

public let WheelValueHeight:CGFloat = 110.0
public let WheelVisibleArea:CGFloat = WheelValueHeight * 3

private let CellIdentifier = "CellIdentifier"

public protocol WheelViewDelegate: NSObjectProtocol {
    func wheelViewIsReady(wheelView: WheelView)
    func wheelViewDidStartTouch(wheelView: WheelView)
    func wheelViewDidStartScroll(wheelView: WheelView)
    func wheelViewDidScroll(wheelView: WheelView)
    func wheelViewDidEndTouch(wheelView: WheelView)
    func wheelViewDidEndScrollAnimation(wheelView: WheelView, userInitiated: Bool)
}

public class WheelView: UIView, UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    weak public var delegate: WheelViewDelegate?
    
    public var wheelValues:[String]!
    public var currentIndex:Int!
    public var progress:CGFloat!
    
    // View
    
    private var wheelViewSmall:UICollectionView!
    private var wheelViewLarge:UICollectionView!
    
    private var wheelViewIsReady = false
    private var wheelViewSmallIsReady = false
    private var wheelViewLargeIsReady = false
    
    // Scrolling
    
    private var wheelViewPan:UIView!
    private var wheelPan:UIPanGestureRecognizer!
    private var previousTranslation = CGPointZero
    private var previousPercent:CGFloat = 0
    
    private var scrollDirection:Int = 0
    private var finalVelocity:CGFloat!
    
    private var userInitated:Bool!
    private var displayLink:CADisplayLink?
    private var lastTimerTick:CFTimeInterval!
    private var animationPointsPerSecond:CGFloat!
    
    private var startContentOffset:CGPoint!
    private var finalContentOffset:CGPoint!
    
    private var middleBar:UIView!
    
    private var cnX:NSLayoutConstraint!
    private var cnY:NSLayoutConstraint!
    private var cnWidth:NSLayoutConstraint!
    private var cnHeight:NSLayoutConstraint!
    
    convenience init(wheelValues: [String]) {
        self.init(frame: CGRectZero)
        self.wheelValues = wheelValues
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    private func initialize() {
        
        self.backgroundColor = UIColor.clearColor()
        
        // Wheel View Small
        self.wheelViewSmall = UICollectionView(frame: CGRectZero, collectionViewLayout: WheelLayout())
        self.wheelViewSmall.userInteractionEnabled = false
        self.wheelViewSmall.dataSource = self
        self.wheelViewSmall.delegate = self
        self.wheelViewSmall.decelerationRate = UIScrollViewDecelerationRateFast
        self.wheelViewSmall.registerClass(WheelValueCell.self, forCellWithReuseIdentifier: CellIdentifier)
        self.wheelViewSmall.backgroundColor = UIColor.clearColor()
        self.wheelViewSmall.showsHorizontalScrollIndicator = false
        self.wheelViewSmall.showsVerticalScrollIndicator = false
        self.addSubview(self.wheelViewSmall)
        
        self.wheelViewSmall.translatesAutoresizingMaskIntoConstraints = false
        cnX = NSLayoutConstraint(item: self.wheelViewSmall, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0)
        cnY = NSLayoutConstraint(item: self.wheelViewSmall, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0)
        cnWidth = NSLayoutConstraint(item: self.wheelViewSmall, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: 0)
        cnHeight = NSLayoutConstraint(item: self.wheelViewSmall, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0)
        self.addConstraints([ cnX, cnY, cnWidth, cnHeight ])
        
        // Middle Bar
        self.middleBar = UIView()
        self.middleBar.clipsToBounds = true
        self.middleBar.backgroundColor = UIColor.RGB(34.0, g: 34.0, b: 34.0)
        self.middleBar.userInteractionEnabled = false
        self.addSubview(self.middleBar)
        
        self.middleBar.translatesAutoresizingMaskIntoConstraints = false
        cnX = NSLayoutConstraint(item: self.middleBar, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0)
        cnY = NSLayoutConstraint(item: self.middleBar, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)
        cnWidth = NSLayoutConstraint(item: self.middleBar, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: 0)
        cnHeight = NSLayoutConstraint(item: self.middleBar, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0, constant: WheelValueHeight)
        self.addConstraints([ cnX, cnY, cnWidth, cnHeight ])
        
        // Wheel View Large
        self.wheelViewLarge = UICollectionView(frame: CGRectZero, collectionViewLayout: WheelLayout())
        self.wheelViewLarge.backgroundColor = UIColor.clearColor()
        self.wheelViewLarge.userInteractionEnabled = false
        self.wheelViewLarge.dataSource = self
        self.wheelViewLarge.delegate = self
        self.wheelViewLarge.decelerationRate = UIScrollViewDecelerationRateFast
        self.wheelViewLarge.registerClass(WheelValueCell.self, forCellWithReuseIdentifier: CellIdentifier)
        self.wheelViewLarge.showsHorizontalScrollIndicator = false
        self.wheelViewLarge.showsVerticalScrollIndicator = false
        self.middleBar.addSubview(self.wheelViewLarge)
        
        self.wheelViewLarge.translatesAutoresizingMaskIntoConstraints = false
        cnX = NSLayoutConstraint(item: self.wheelViewLarge, attribute: .Left, relatedBy: .Equal, toItem: self.wheelViewSmall, attribute: .Left, multiplier: 1.0, constant: 0)
        cnY = NSLayoutConstraint(item: self.wheelViewLarge, attribute: .Top, relatedBy: .Equal, toItem: self.wheelViewSmall, attribute: .Top, multiplier: 1.0, constant: 0)
        cnWidth = NSLayoutConstraint(item: self.wheelViewLarge, attribute: .Right, relatedBy: .Equal, toItem: self.wheelViewSmall, attribute: .Right, multiplier: 1.0, constant: 0)
        cnHeight = NSLayoutConstraint(item: self.wheelViewLarge, attribute: .Bottom, relatedBy: .Equal, toItem: self.wheelViewSmall, attribute: .Bottom, multiplier: 1.0, constant: 0)
        self.addConstraints([ cnX, cnY, cnWidth, cnHeight ])
        
        // Wheel View Pan
        self.wheelViewPan = UIView(frame: CGRectZero)
        self.wheelViewPan.backgroundColor = UIColor.clearColor()
        self.addSubview(self.wheelViewPan)
        
        self.wheelViewPan.translatesAutoresizingMaskIntoConstraints = false
        cnX = NSLayoutConstraint(item: self.wheelViewPan, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1.0, constant: 0)
        cnY = NSLayoutConstraint(item: self.wheelViewPan, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0)
        cnWidth = NSLayoutConstraint(item: self.wheelViewPan, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: 0)
        cnHeight = NSLayoutConstraint(item: self.wheelViewPan, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0)
        self.addConstraints([ cnX, cnY, cnWidth, cnHeight ])
        
        // Wheel Pan Gesture
        self.wheelPan = UIPanGestureRecognizer(target: self, action: #selector(wheelDidPan))
        self.wheelPan.maximumNumberOfTouches = 1
        self.wheelPan.cancelsTouchesInView = false
        self.wheelPan.delegate = self
        self.wheelViewPan.addGestureRecognizer(self.wheelPan)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update the layout section inset to min/max values can be scrolled to
        let inset = (self.bounds.size.height * 0.5) - (WheelValueHeight * 0.5)
        let sectionInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        
        let smallLayout = self.wheelViewSmall.collectionViewLayout as! WheelLayout
        smallLayout.sectionInset = sectionInset
        
        let largeLayout = self.wheelViewLarge.collectionViewLayout as! WheelLayout
        largeLayout.sectionInset = sectionInset
    }
    
    public func scrollToIndex(index: Int!, animated: Bool = false) {
        let contentOffset = CGPoint(x: 0, y: CGFloat(index) * WheelValueHeight)
        if (animated) {
            
            self.delegate?.wheelViewDidStartScroll(self)
            
            self.finalVelocity = 4000.0
            self.startContentOffset = self.wheelViewSmall.contentOffset
            self.finalContentOffset = contentOffset
            
            self.delegate?.wheelViewDidEndTouch(self)
            
            self.userInitated = false
            self.beginAnimation()
        } else {
            
            self.progress = self.progressForIndex(index)
            
            self.wheelViewSmall.contentOffset = contentOffset
            self.wheelViewLarge.contentOffset = contentOffset
            
            self.delegate?.wheelViewDidEndTouch(self)
            self.delegate?.wheelViewDidEndScrollAnimation(self, userInitiated: false)
        }
    }
    
    private func progressForIndex(index: Int!) -> CGFloat {
        let indexAsFloat = CGFloat(index)
        let mid = CGFloat(self.wheelValues.indexOf("0")!)
        var max:CGFloat
        if (indexAsFloat < mid) {
            max = mid
            return ((indexAsFloat-mid)/max) * -1 // -1 for reverse
        } else {
            max = CGFloat(self.wheelValues.count-1)
            return ((indexAsFloat-mid)/(max-mid)) * -1 // -1 for reverse
        }
    }
    
    // MARK: - Touch / Release / Pan (Scroll)
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        self.delegate?.wheelViewDidStartTouch(self)
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        self.delegate?.wheelViewDidEndTouch(self)
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        self.delegate?.wheelViewDidEndTouch(self)
    }
    
    func wheelDidPan(panGesture: UIPanGestureRecognizer) {
        
        switch panGesture.state {
        case .Began:
            
            self.delegate?.wheelViewDidStartScroll(self)
            
            self.endAnimation()
            break
            
        case .Changed:
            let translation = panGesture.translationInView(self.wheelViewPan)
            let velocity = panGesture.velocityInView(self.wheelViewPan)
            let diff = self.previousTranslation.y - translation.y
            let diffWithVelocity = diff + (velocity.y * 0.15)
            let currentOffset = self.wheelViewSmall.contentOffset
            let offset = currentOffset.y - diffWithVelocity
            
            let min:CGFloat = 0
            let max:CGFloat = self.wheelViewSmall.contentSize.height - self.wheelViewSmall.bounds.size.height
            if (offset >= min && offset <= max) {
                let contentOffset = CGPoint(x: 0, y: offset)
                self.wheelViewSmall.contentOffset = contentOffset
                self.wheelViewLarge.contentOffset = contentOffset
            } else if (offset < min) {
                let contentOffset = CGPoint(x: 0, y: min)
                self.wheelViewSmall.contentOffset = contentOffset
                self.wheelViewLarge.contentOffset = contentOffset
            } else if (offset > max) {
                let contentOffset = CGPoint(x: 0, y: max)
                self.wheelViewSmall.contentOffset = contentOffset
                self.wheelViewLarge.contentOffset = contentOffset
            }
            
            self.previousTranslation = translation
            break
            
        case .Ended, .Cancelled, .Failed:
            
            let translation = panGesture.translationInView(self.wheelViewPan)
            let velocity = panGesture.velocityInView(self.wheelViewPan)
            let diff = previousTranslation.y - translation.y
            
            // Store the final velocity for animation duration / easing
            self.finalVelocity = velocity.y
          
            let diffWithVelocity = diff + (self.finalVelocity * 0.15)
            let currentOffset = self.wheelViewSmall.contentOffset
            let offset = currentOffset.y - diffWithVelocity
            
            let min:CGFloat = 0
            let max:CGFloat = self.wheelViewSmall.contentSize.height - self.wheelViewSmall.bounds.size.height
            var contentOffset = CGPointZero
            if (offset >= min && offset <= max) {
                let roundedOffset:CGFloat = round(offset/WheelValueHeight) * WheelValueHeight
                contentOffset = CGPoint(x: 0, y: roundedOffset)
            } else if (offset < min) {
                contentOffset = CGPoint(x: 0, y: min)
            } else if (offset > max) {
                contentOffset = CGPoint(x: 0, y: max)
            }
            
            self.startContentOffset = currentOffset
            self.finalContentOffset = contentOffset
            
            // self.delegate?.wheelViewDidEndTouch(self)
            
            self.userInitated = true
            self.beginAnimation()
            
            break
            
        default:
            //
            break
        }
    }
    
    func beginAnimation() {
        if (self.finalContentOffset.y < self.startContentOffset.y) {
            // Scroll Up
            self.scrollDirection = 1
        } else {
            // Scroll Down
            self.scrollDirection = 2
        }
        
        self.lastTimerTick = 0
        
        self.animationPointsPerSecond = fabs(self.finalVelocity)
        if (self.animationPointsPerSecond < WheelVisibleArea) {
            self.animationPointsPerSecond = WheelVisibleArea
        }
        self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        self.displayLink!.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func endAnimation() {
        if let _ = self.displayLink {
            self.displayLink!.invalidate()
            self.displayLink = nil
            
            self.wheelViewSmall.contentOffset = self.finalContentOffset
            self.wheelViewLarge.contentOffset = self.finalContentOffset
            
            self.previousTranslation = CGPointZero
            self.finalContentOffset = CGPointZero
        }
    }
    
    func displayLinkTick() {
        if self.lastTimerTick == 0 {
            self.lastTimerTick = self.displayLink!.timestamp
            return
        }
        let currentTimestamp = self.displayLink!.timestamp
        var newContentOffset = self.wheelViewSmall.contentOffset
        var percent:CGFloat = 0
        
        let elapsedTime = CGFloat(currentTimestamp) - CGFloat(self.lastTimerTick);
        if (self.scrollDirection == 1) {
            let totalTravelDistance = self.startContentOffset.y - self.finalContentOffset.y
            // print("start distance = \(startDistance)")
            
            if (totalTravelDistance != 0) {
                let currentDistance = newContentOffset.y - self.finalContentOffset.y
                // print("current distance = \(currentDistnce)")
                
                percent = currentDistance/totalTravelDistance
                // print("percent = \(percent)")
                // Force animation to stop
                if (percent == self.previousPercent) {
                    percent = 0
                }
                
                let ease = self.calculateEase(percent, totalTravelDistance: totalTravelDistance)
                
                newContentOffset.y -= ease * elapsedTime
            }
            
        } else if (self.scrollDirection == 2) {
            let totalTravelDistance = self.finalContentOffset.y - self.startContentOffset.y
            
            if (totalTravelDistance != 0) {
                let currentDistance = self.finalContentOffset.y - newContentOffset.y
                
                percent = currentDistance/totalTravelDistance
                // Force animation to stop
                if (percent == self.previousPercent) {
                    percent = 0
                }
                
                let ease = self.calculateEase(percent, totalTravelDistance: totalTravelDistance)
                
                newContentOffset.y += ease * elapsedTime
            }
        }
        
        self.wheelViewSmall.contentOffset = newContentOffset
        self.wheelViewLarge.contentOffset = newContentOffset
        
        self.lastTimerTick = currentTimestamp
        
        self.previousPercent = percent
        
        if (percent <= 0) {
            self.endAnimation()
            self.delegate?.wheelViewDidEndScrollAnimation(self, userInitiated: self.userInitated)
        }
    }
    
    private func calculateEase(percentCompleted: CGFloat, totalTravelDistance: CGFloat) -> CGFloat {
        let base = max(4000.0, self.animationPointsPerSecond)
        let ease = base * (percentCompleted * (0.0025 * totalTravelDistance))
    
        return ease
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    override public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow vertical panning
        let velocity = self.wheelPan.velocityInView(self)
        return abs(velocity.y) > abs(velocity.x)
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return true
    }
    
    // MARK: UICollectionViewDataSource
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.wheelValues.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let value = self.wheelValues[indexPath.row]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! WheelValueCell
        
        // Set the label text value
        cell.label.text = value
        
        // Set the font size of the label
        if (collectionView == self.wheelViewSmall) {
            cell.label.font = UIFont.GothamBold(24.0)
            cell.label.textColor = UIColor.RGB(209.0, g: 209.0, b: 209.0)
        } else {
            cell.label.font = UIFont.GothamBold(48.0)
            cell.label.textColor = UIColor.whiteColor()
        }
        
        // TODO: Blur the label based on calculated value (velocity) in scrollViewDidScroll
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    // Used to check to see if the wheel view is loaded and ready to use (scroll to initial index/position)
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if (self.wheelViewIsReady == false) {
            if (collectionView == self.wheelViewSmall && self.wheelViewSmallIsReady == false) {
                self.wheelViewSmallIsReady = true
            } else if (collectionView == self.wheelViewLarge && self.wheelViewLargeIsReady == false) {
                self.wheelViewLargeIsReady = true
            }
            if (self.wheelViewSmallIsReady == true && self.wheelViewLargeIsReady == true) {
                self.wheelViewIsReady = true
                self.delegate?.wheelViewIsReady(self)
            }
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {        
        return CGSize(width: collectionView.bounds.width, height: WheelValueHeight)
    }
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        let indexAsFloat = round(scrollView.contentOffset.y/WheelValueHeight)
        let index = Int(indexAsFloat)
        self.progress = self.progressForIndex(index)
        self.currentIndex = index
        
        self.delegate?.wheelViewDidScroll(self)
    }

}
