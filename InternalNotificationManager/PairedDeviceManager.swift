//
//  PairedDeviceManager.swift
//  Sample
//
//  Created by Michael Rose on 12/13/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import Foundation
import DeviceBLE

/* Listens for notifications coming from the device and converts them into NotififcationView objects that are then passed to the NotificationManager for display. */

class PairedDeviceManager {
    
    public static let shared = PairedDeviceManager()
    
    fileprivate var syncingNotification: InternalSyncNotificationView?
    
    fileprivate init() {
        //
    }
    
    deinit {
        stopNotifier()
    }
    
    // MARK: Public
    
    public func startNotifier() {
        stopNotifier()
        
        // Register for device notifications
        NotificationCenter.default.addObserver(self, selector: #selector(deviceSyncingDidStart), name: Notification.Name(rawValue: DeviceSyncingDidStartNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceSyncingDidUpdateProgress), name: Notification.Name(rawValue: DeviceSyncPercentComplete), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceSyncingDidSucceed), name: Notification.Name(rawValue: DeviceSyncingDidSucceedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceSyncingDidFail), name: Notification.Name(rawValue: DeviceSyncingDidFailNotification), object: nil)
    }
    
    public func stopNotifier() {
        // Un-register for device notifications
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DeviceSyncingDidStartNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DeviceSyncPercentComplete), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DeviceSyncingDidSucceedNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DeviceSyncingDidFailNotification), object: nil)
    }
    
    // MARK: - Private
    
    // It's up to the paired device manager to tell the notification manager when the sync progress is complete
    fileprivate func removeSyncingNotification() {
        if syncingNotification != nil {
            syncingNotification?.removeFromManager()
            syncingNotification = nil
        }
    }
    
    // MARK: - Device Notifications
    
    @objc func deviceSyncingDidStart(notification: Notification) {
        removeSyncingNotification()
        
        syncingNotification = InternalSyncNotificationView()
        InternalNotificationManager.shared.queue(notification: syncingNotification!)
    }
    
    @objc func deviceSyncingDidUpdateProgress(notification: Notification) {
        if let userInfo = notification.userInfo as? [String : AnyObject] {
            if let percentage = userInfo["percentage"] as? Float {
                print("percentage = \(percentage)")
                if syncingNotification != nil {
                    syncingNotification!.progressView.progress = percentage
                }
            }
        }
    }
    
    @objc func deviceSyncingDidSucceed(notification: Notification) {
        removeSyncingNotification()
        
        let notification = InternalMessageNotificationView(message: "Sync Complete")
        notification.priority = .high
        InternalNotificationManager.shared.queue(notification: notification)
    }
    
    @objc func deviceSyncingDidFail(notification: Notification) {
        removeSyncingNotification()
        
        let notification = InternalMessageNotificationView(message: "Sync Failed")
        notification.priority = .high
        notification.label.textColor = UIColor.RGB(r: 238, g: 72, b: 94)
        InternalNotificationManager.shared.queue(notification: notification)
    }
    
}
