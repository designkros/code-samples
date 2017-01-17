//
//  ConnectDeviceFooter.swift
//  Sample
//
//  Created by Michael Rose on 4/14/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit
import Intrepid

let ConnectDeviceFooterAnimationDuration: NSTimeInterval = 3.5
let ConnectDeviceFooterAnimationOffset: NSTimeInterval = 0.8

public class ConnectDeviceFooter: UIView {
    
    @IBOutlet weak var connectLabel: UILabel!
    @IBOutlet weak var bouncingArrow: UIImageView!
    
    public enum ConnectDeviceFooterDisplayMode {
        case DragToConnect
        case Release
        case Connecting
    }
    
    public var currentDisplayMode: ConnectDeviceFooterDisplayMode! {
        didSet {
            switch  self.currentDisplayMode! {
            case .DragToConnect:
                self.connectLabel.text = "Drag To Connect"
                self.bouncingArrow.fadeIn()
                break
            case .Release:
                self.connectLabel.text = "Release"
                self.bouncingArrow.fadeOut()
                break
            case .Connecting:
                self.connectLabel.text = "Connecting…"
                self.bouncingArrow.fadeOut()
                break
            }
            self.connectLabel.letterSpacing(0.5)
        }
    }
    
    private var timer: NSTimer? = nil {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    // MARK: - Init
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        self.currentDisplayMode = .DragToConnect
        self.startCaretAnimations()
    }
    
    // MARK: - Bouncing Arrow
    
    func startCaretAnimations() {
        let initialBobDelay =  ConnectDeviceFooterAnimationDuration - (ConnectDeviceFooterAnimationOffset * 3)
        After(initialBobDelay) { [weak self] in
            guard let welf = self else { return }
            welf.timerFired()
            welf.timer = NSTimer.scheduledTimerWithTimeInterval(
                ConnectDeviceFooterAnimationDuration,
                target: welf,
                selector: #selector(welf.timerFired),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    dynamic private func timerFired() {
        self.bouncingArrow.bobDownAndUp(0.3, totalTimes: 2)
    }

}
