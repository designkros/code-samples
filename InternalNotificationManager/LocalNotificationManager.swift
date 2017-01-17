//
//  LocalNotificationManager.swift
//  Sample
//
//  Created by Michael Rose on 12/21/16.
//  Copyright © Michael Rose. All rights reserved.
//

import Foundation
import UserNotifications
import DeviceBLE

/* Centralizes the scheduling and unscheduling of the local notifications. Also parses the local notification internal delegate call into a internal notification to be displayed at the top of the screen.  */

class LocalNotificationManager: NSObject {

    public static let shared = LocalNotificationManager()
    
    // Using these custom notifications as they factor in the AWS calls that could fail
    public static let DevicePairingDidSucceed = NSNotification.Name(rawValue: "DevicePairingDidSucceed")
    public static let DeviceUnpairingDidSucceed = NSNotification.Name(rawValue: "DeviceUnpairingDidSucceed")
    
    // Required to get around the 10.2 bug where the notification is fired immediatley after .add
    fileprivate var scheduledTimes = [String : Double]()
    
    fileprivate let chargeReminderIdentifier = "chargeReminderIdentifier"
    fileprivate let chargeReminderDayInterval = 3
    
    fileprivate let syncReminderIndentifier = "syncReminderIndentifier"
    fileprivate let syncReminderDayInterval = 7
    
    fileprivate override init() {
        super.init()
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
    }
    
    deinit {
        stopNotifier()
    }
    
    // MARK: Public
    
    public func startNotifier() {
        stopNotifier()
        
        // Register for device notifications
        NotificationCenter.default.addObserver(self, selector: #selector(deivcePairingDidSucceed), name: LocalNotificationManager.DevicePairingDidSucceed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deivceUnpairingDidSucceed), name: LocalNotificationManager.DeviceUnpairingDidSucceed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deivceSyncingDidSucceed), name: Notification.Name(rawValue: DeviceSyncingDidSucceedNotification), object: nil)
    }
    
    public func stopNotifier() {
        // Un-register for device notifications
        NotificationCenter.default.removeObserver(self, name: LocalNotificationManager.DevicePairingDidSucceed, object: nil)
        NotificationCenter.default.removeObserver(self, name: LocalNotificationManager.DeviceUnpairingDidSucceed, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DeviceSyncingDidSucceedNotification), object: nil)
    }
    
    // Used for if the user didn't allow access for the notifications initially, but then later changed their settings.
    public func checkForScheduledNotifications() {
        if AccountHelper.userPairedDeivce {
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                    if requests.count == 0 {
                        self.scheduleNotifcations()
                    }
                })
            } else {
                // UILocalNotification
            }
        }
    }
    
    // MARK: Private
    
    fileprivate func scheduleNotifcations() {
        self.removeScheduledNotifications()
        
        if #available(iOS 10.0, *) {
            // UserNotification
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
                if (granted) {
                    self.scheduleChargeReminderNotification()
                    self.scheduleSyncReminderNotification()
                }
            })
        } else {
            // UILocalNotification
        }
    }
    
    fileprivate func removeScheduledNotifications() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        } else {
            // UILocalNotification
        }
    }
    
    fileprivate func scheduleChargeReminderNotification() {
        if #available(iOS 10.0, *) {
            let identifier = chargeReminderIdentifier
            let content = UNMutableNotificationContent()
            content.body = "Device battery level low"
            
            // QA (MINUTES INSTEAD OF DAYS)
            // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeIntervalForMinutes(minutes: chargeReminderDayInterval), repeats: true)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeIntervalForDays(days: chargeReminderDayInterval), repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            scheduledTimes[identifier] = CACurrentMediaTime()
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else {
            // UILocalNotification
        }

    }
    
    fileprivate func scheduleSyncReminderNotification() {
        if #available(iOS 10.0, *) {
            let identifier = syncReminderIndentifier
            let content = UNMutableNotificationContent()
            content.body = "New data available! Sync device now"
            
            // QA (MINUTES INSTEAD OF DAYS)
            // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeIntervalForMinutes(minutes: syncReminderDayInterval), repeats: true)
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeIntervalForDays(days: syncReminderDayInterval), repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            scheduledTimes[identifier] = CACurrentMediaTime()
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        } else {
            // UILocalNotification
        }
    }
    
    fileprivate func rescheduleSyncReminderNotification() {
        if #available(iOS 10.0, *) {
            // UserNotification
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [syncReminderIndentifier])
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
                if (granted) {
                    self.scheduleSyncReminderNotification()
                }
            })
        } else {
            // UILocalNotification
        }
    }
    
    // MARK: - Device Notifications
    
    @objc fileprivate func devicePairingDidSucceed() {
        scheduleNotifcations()
    }
    
    @objc fileprivate func deviceUnpairingDidSucceed() {
        removeScheduledNotifications()
    }
    
    @objc fileprivate func deviceSyncingDidSucceed() {
        rescheduleSyncReminderNotification()
    }
    
    // MARK: - Utility
    
    fileprivate func timeIntervalForDays(days: Int) -> TimeInterval {
        // seconds * minutes * hours * days
        return TimeInterval(60 * 60 * 24 * days)
    }
    
    // QA
    fileprivate func timeIntervalForMinutes(minutes: Int) -> TimeInterval {
        // seconds * minutes
        return TimeInterval(60 * minutes)
    }
    
}

@available(iOS 10.0, *)
extension LocalNotificationManager: UNUserNotificationCenterDelegate {
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            let identifier = notification.request.identifier
            
            // Required for 10.2
            // Adding a notification request to the notification center immediately fires this delegate when the trigger is set to repeat
            if let scheduledTime = scheduledTimes[identifier] {
                if CACurrentMediaTime() - scheduledTime < 1.0 {
                    completionHandler([])
                    return
                }
            }
            
            // Parse the notification into an internal notification and show it
            let message = notification.request.content.body
            let image = identifier == chargeReminderIdentifier ? UIImage(named: "batteryIconTiny") : UIImage(named: "newDataSyncIcon")
            let internalNotification = InternalMessageNotificationView(message: message, image: image)
            InternalNotificationManager.shared.queue(notification: internalNotification)
            
            completionHandler([])
        }
}
