//
//  ConnectDeviceViewController.swift
//  Sample
//
//  Created by Michael Rose on 4/12/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

//  - ConnectDeviceViewController
//      - DevicePageControl
//      - UICollectionView
//          - SearchCell
//              - PulsingView (1/2)
//          - NerbyDeviceCell
//      - ConnectDeviceFooter
//          - PulsingView (2/2)

import UIKit
import BMAP
import ExternalAccessory
import Intrepid

private let SearchCellIdentifier = "SearchCellIdentifier"
private let NearbyDeviceCellIdentifier = "NearbyDeviceCellIdentifier"

private let ConnectionFailureCountMax = 3

class ConnectDeviceViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SearchCellDelegate, WebViewControllerDelegate, NearbyDeviceCellDelegate, VideoViewControllerDelegate, VideoFinishedViewControllerDelegate, WarningViewControllerDelegate, WheelsViewControllerDelegate, DeviceUpdateListenerType {
    
    @IBOutlet weak var pageControl: DevicePageControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var footerView: ConnectDeviceFooter!
    @IBOutlet weak var footerYConstaint: NSLayoutConstraint!
    @IBOutlet weak var pulsingView: PulsingView!
    
    private var searchCell: SearchCell?
    private var backgroundGradient: BasicVerticalGradientLayer!
    
    private var sessionManager:SessionManager!
    private var device:Device?
    private var isConnecting = false // Trying to avoid multiple calls
    private var connectionFailureCount = 0
    
    private enum ConnectDeviceCellTypeDisplayMode {
        case NearbyDevice
        case Searching
    }
    private var currentCellType: ConnectDeviceCellTypeDisplayMode = .Searching
    
    private var currentIndex = 0 {
        didSet {
            self.redrawPageControl()
        }
    }
    
    private var availableStetsonDevices = Array<Device>() {
        didSet {
            if availableStetsonDevices.count > 0 {
                // Only works for adding devices to the list, no logic for handling devices being removed from the list.
                // This feature is currently not supported by the BMAP framework.
                // startListeningWithUpdateBlock does not update when a device is turned off/out of range.
            
                let devicesToInsert = Set(self.availableStetsonDevices).subtract(oldValue)
                
                // If there are new devices to insert, carry on...
                if (devicesToInsert.count > 0) {
                    // Build index path list
                    var indexPaths = Array<NSIndexPath>()
                    for device in devicesToInsert {
                        let index = self.availableStetsonDevices.indexOf(device)
                        indexPaths.append(NSIndexPath(forRow: index!, inSection: 0))
                    }
                    
                    // Set the current cell type (updates footer, page control, etc... normally on scrollViewDidScroll)
                    self.setCurrentCellType(.NearbyDevice, animated: true)
                    
                    // Redraw the page control
                    self.redrawPageControl()
                    
                    // Perform the insert on the collection view
                    self.collectionView.performBatchUpdates({
                        self.collectionView.insertItemsAtIndexPaths(indexPaths)
                    }, completion: { (completed) in
                        if completed {
                            // Auto-connect to device if already connected via Bluetooth > Settings
                            for device in self.availableStetsonDevices {
                                if device.isConnectedToLocalDevice {
                                    self.collectionView.performBatchUpdates({ 
                                        // Scroll to the device you want to connect to
                                        let index = self.availableStetsonDevices.indexOf(device)
                                        let indexPath = NSIndexPath(forRow: index!, inSection: 0)
                                        self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
                                    }, completion: { (completed) in
                                        // Connect to device
                                        self.connect(device)
                                    })
                                    break
                                }
                            }
                        }
                    })
                }
            } else {
                // Reload the colleciton view
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Background Gradient
        self.backgroundGradient = BasicVerticalGradientLayer(topColor: UIColor.whiteColor(), bottomColor:  UIColor.RGB(238.0, g: 238.0, b: 238.0))
        self.view.layer.insertSublayer(self.backgroundGradient, atIndex: 0)
        
        // Setup the page control
        self.pageControl.numberOfPages = self.availableStetsonDevices.count + 1
        self.pageControl.currentPage = self.currentIndex
        self.pageControl.updateCurrentPageDisplay() // Redraws O and + images
        
        // Start the pulsing view
        self.pulsingView.startGlow()
        
        // Register cell classes
        self.collectionView!.registerClass(SearchCell.self, forCellWithReuseIdentifier: SearchCellIdentifier)
        self.collectionView!.registerClass(NearbyDeviceCell.self, forCellWithReuseIdentifier: NearbyDeviceCellIdentifier)
        
        // Set the cell size to full screen (1/2)
        let layout = self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsetsZero
        // layout.itemSize is set via delegate (doens't work correctly here)
        
        // TODO:    Add noitifcation from AppDelegate to tell when the app is sent to background
        //          and back to foreground to stop/start pulsing views
        
        //
        // BMAP
        //
        
        // Look for nearby Stetson devices
        self.startScanning()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.backgroundGradient.frame = self.view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - States
    
    private func returnToIdle() { // AKA "disconnect
        // No longer in connecting state
        self.isConnecting = false
        
        // Enable scrolling on scroll view
        self.collectionView.scrollEnabled = true
        
        // Page Control
        UIView.animateWithDuration(0.3, delay: 0, options: .BeginFromCurrentState, animations: {
            self.navigationItem.titleView?.alpha = 1.0
            }, completion: nil)
        
        // Footer
        self.footerView.currentDisplayMode = .DragToConnect
        
        // Loop through all visible NearbyDeviceCells and returnToIdle (usually handled internally while panning)
        for cell in collectionView.visibleCells() {
            if (cell is NearbyDeviceCell) {
                let deviceCell = cell as! NearbyDeviceCell
                deviceCell.returnToIdle()
            }
        }
    }
    
    private func connect(device: Device) {
        if (self.isConnecting == false) {
            // Entering connecting state
            self.isConnecting = true
            
            // Disable scrolling on scroll view
            self.collectionView.scrollEnabled = false
            
            // Page Control
            UIView.animateWithDuration(0.3, delay: 0, options: .BeginFromCurrentState, animations: { 
                self.navigationItem.titleView?.alpha = 0
                }, completion: nil)
            
            // Footer
            self.footerView.currentDisplayMode = .Connecting
            
            // Update current cell to connect state
            let index = self.availableStetsonDevices.indexOf(device)
            let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index!, inSection: 0))
            // TODO: Find out why the connect() method is being called sometimes when the SearchCell is the current index
            if cell is NearbyDeviceCell {
                let deviceCell = cell as! NearbyDeviceCell
                deviceCell.connect()
            }
            
            // Connect to selected device
            self.openSessionAndConnect(device)
        }
    }
    
    private func setCurrentCellType(cellType: ConnectDeviceCellTypeDisplayMode, animated: Bool = false) {
        switch cellType {
            
        case .NearbyDevice:
            // Nearby Device
            if (animated) {
                UIView.animateWithDuration(0.3, animations: {
                    self.pulsingView.alpha = 1.0
                    self.footerView.alpha = 1.0
                    self.footerYConstaint.constant = 0
                    self.searchCell?.pulsingView.alpha = 0
                })
            } else {
                self.pulsingView.alpha = 1.0
                self.footerView.alpha = 1.0
                self.footerYConstaint.constant = 0
                self.searchCell?.pulsingView.alpha = 0
            }
            break
            
        case .Searching:
            // Searching
            if (animated) {
                UIView.animateWithDuration(0.3, animations: {
                    self.pulsingView.alpha = 0
                    self.footerView.alpha = 0
                    self.footerYConstaint.constant = self.footerView.bounds.size.height
                    self.searchCell?.pulsingView.alpha = 1.0
                })
            } else {
                self.pulsingView.alpha = 0
                self.footerView.alpha = 0
                self.footerYConstaint.constant = self.footerView.bounds.size.height
                self.searchCell?.pulsingView.alpha = 1.0
            }
            break
            
        }
    }
    
    private func redrawPageControl() {
        // Update page controller
        self.pageControl.numberOfPages = self.availableStetsonDevices.count + 1
        self.pageControl.currentPage = self.currentIndex
        self.pageControl.updateCurrentPageDisplay() // Redraws custom images
    }
    
    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.availableStetsonDevices.count + 1
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell
        
        if (indexPath.row == self.availableStetsonDevices.count) {
            // Search Cell
            let searchCell = collectionView.dequeueReusableCellWithReuseIdentifier(SearchCellIdentifier, forIndexPath: indexPath) as! SearchCell
            self.searchCell = searchCell // Store reference to animate it's pulse view on scroll
            self.searchCell!.delegate = self
            
            cell = searchCell
        } else {
            // Nearby Device Cell
            let device = self.availableStetsonDevices[indexPath.row]
            
            let deviceCell = collectionView.dequeueReusableCellWithReuseIdentifier(NearbyDeviceCellIdentifier, forIndexPath: indexPath) as! NearbyDeviceCell
            deviceCell.delegate = self
            deviceCell.label.text = device.settings.name?.uppercaseString
            deviceCell.label.letterSpacing(2.8)
            // TODO: Add deviceIsConnectedAndSessionIsOpen (or similar) method)
            // deviceCell.textColor = deviceIsConnectedAndSessionIsOpen ? .blackColor() : Palette.DarkGrey.color
            deviceCell.imageView.image = device.productInfo.image()
        
            cell = deviceCell
        }
    
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        
        // Set the cell size to full screen (2/2)
        let width = collectionView.bounds.width
            - collectionView.contentInset.left
            - collectionView.contentInset.right
            - layout.sectionInset.left
            - layout.sectionInset.right
        let height = collectionView.bounds.height
            - collectionView.contentInset.top
            - collectionView.contentInset.bottom
            - layout.sectionInset.top
            - layout.sectionInset.bottom
        
        return CGSize(width: width, height: height)
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // Update current index
        self.currentIndex =  Int(round(scrollView.contentOffset.x/scrollView.frame.size.width))
        
        // Show/hide ConnectDeviceFooter (y pos)
        // Show/hide pulsing view (alpha)
        // Show/hide SearchCell's pulsingView (if available, alpha)
        let currentOffset = scrollView.contentOffset.x
        let hidePosition = scrollView.frame.size.width * CGFloat(self.availableStetsonDevices.count-1)
        if (currentOffset > hidePosition) {
            let diff = currentOffset - hidePosition
            let percentage = diff/scrollView.frame.size.width
            if (percentage < 1.0) {
                self.pulsingView.alpha = 1.0 - (percentage * 2.0) // 2x faster fade
                self.footerView.alpha = 1.0 - (percentage * 2.0)
                self.footerYConstaint.constant = self.footerView.bounds.size.height * (percentage * 0.5)
                
                self.searchCell?.pulsingView.alpha = (percentage * 2.0)
        
            } else {
                self.setCurrentCellType(.Searching, animated: false)
            }
        } else {
            self.setCurrentCellType(.NearbyDevice, animated: false)
        }
    
    }
    
    // MARK: - SearchCellDelegate
    
    func userNeedsHelp() {
        let helpURL = NSURL(string: "https://google.com")
        let webViewController = WebViewController(url: helpURL!)
        webViewController.delegate = self
        let navController = UINavigationController(rootViewController: webViewController)
        
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    // MARK: - WebViewControllerDelegate
    
    func closeButtonTapped() {
        // Return to idle
        self.returnToIdle()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - NearbyDeviceCellDelegate
    
    func userDidStartPanningNearbyDeviceCell(cell: NearbyDeviceCell) {
        // Disable collection view scrolling while the user is panning
        self.collectionView.scrollEnabled = false
    }
    
    func userIsPanningNearbyDeviceCell(cell: NearbyDeviceCell, percent: CGFloat) {
        // Update UI while the user is panning, the cell is updated internally
        
        // Page Control
        self.navigationItem.titleView?.alpha = 1.0-percent*2
        
        // Footer
        if percent > 1.0 {
            self.footerView.currentDisplayMode = .Release
        } else {
            self.footerView.currentDisplayMode = .DragToConnect
        }
    }
    
    func userDidStopPanningNearbyDeviceCell(cell: NearbyDeviceCell, connect: Bool) {
        if (connect && (self.currentIndex < self.availableStetsonDevices.count)) {
            let indexPath = self.collectionView.indexPathForCell(cell)
            let device = self.availableStetsonDevices[indexPath!.row]
            self.connect(device)
        } else {
            // Return to idle
            self.returnToIdle()
        }
    }
    
    // MARK: - VideoViewControllerDelegate
    
    func userDidClose(viewController: VideoViewController) {
        // Return to idle
        self.returnToIdle()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func videoDidFinish(viewController: VideoViewController) {
        // TODO: Better way to find the Bluetooth Pairing view controller
        if (viewController.videoText.containsString("Bluetooth")) {
            let viewController = VideoFinishedViewController(feedbackIcon: UIImage(named: "check")!, feedbackTitle: "That's It", feedbackDescription: "Now head to settings and\ncomplete the steps.")
            viewController.delegate = self
            // Close Button
            viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .Plain, target: self, action: #selector(userDidClose))
            let navController = self.presentedViewController as! UINavigationController
            navController.pushViewController(viewController, animated: true)
        }
    }
    
    // MARK: - VideoFinishedViewControllerDelegate
    
    func userDidGoToSettings(viewController: VideoFinishedViewController) {
        UIApplication.sharedApplication().openBluetoothSettings()
    }
    
    func userDidWatchAgain(viewController: VideoFinishedViewController) {
        let navController = self.presentedViewController as! UINavigationController
        navController.popViewControllerAnimated(true)
    }
    
    // MARK: - WarningViewControllerDelegate
    
    func userDidAction(viewController: WarningViewController) {

        // Dismiss the warning
        self.dismissViewControllerAnimated(true, completion: nil)
        
        self.connectionFailureCount += 1
        if (self.connectionFailureCount > 2) {
            // Start Over...
            self.connectionFailureCount = 0
            // Reset available devices list...
            self.resetScanning()
        } else {
            // Try Again...
            self.connect(self.device!)
        }
    }
    
    func userDidCancel(viewController: WarningViewController) {
        // Reset connection failure count
        self.connectionFailureCount = 0
        
        // Return to idle
        self.returnToIdle()
        
        // Reset available devices list...
        self.resetScanning()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - WheelsViewControllerDelegate
    
    func userDidCloseSession() {
        // Clear device
        self.device = nil
        
        // Clear session manager
        self.sessionManager = nil
        
        // Return to idle
        self.returnToIdle()
        
        // Start scanning again...
        self.startScanning()
        
        // "Disconnect" command received from the WheelsViewController
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - BMAP Connect/Disconnect
    
    func startScanning(clearCache clearCache: Bool = false) {
        appDelegate.connectionManager.startListeningWithUpdateBlock(clearCache: clearCache) { [weak self] _, availableDevices in
            // Filter available devices to only Stetson devices
            
            let currentDevices = self?.availableStetsonDevices.filter({ $0.productInfo.productType == .Stetson })
            
            for device in currentDevices! {
                print("product type = \(device.productInfo.productType)")
            }
            
            // Create array of "seen" devices, freeze them in place regardless of RSSI
            let currentlyEstablishedOrder: [Device]
            let currentlyVisiblePage = self?.currentIndex
            if currentlyVisiblePage < currentDevices!.count {
                currentlyEstablishedOrder = currentDevices!.prefixThrough(currentlyVisiblePage!).ip_toArray()
            } else {
                currentlyEstablishedOrder = currentDevices!
            }
            
            // Create array of "unseen" devices and sort by RSSI (distance)
            let malleableOrder = availableDevices.filter({ $0.productInfo.productType == .Stetson }).filter(!currentlyEstablishedOrder.contains).sort { $0.rssi > $1.rssi }
            
            
            // Combine "seen" with "unseen" devices
            self?.availableStetsonDevices = currentlyEstablishedOrder + malleableOrder
        }
    }
    
    func stopScanning() {
        appDelegate.connectionManager.stopScanForDevices()
    }
    
    func resetScanning() {
        self.stopScanning()
        
        // Remove the device listener
        self.device!.removeDeviceUpdateSubscribers { $0 === self }
        
        // Remove device
        self.device = nil
        
        // Set the current cell type (updates footer, page control, etc... normally on scrollViewDidScroll)
        self.setCurrentCellType(.Searching, animated: false)
    
        // Reset available stetson devices
        self.availableStetsonDevices = Array<Device>()
        
        // Redraw the page control
        self.redrawPageControl()
        
        // Start scanning
        self.startScanning(clearCache: true)
    }
    
    func openSessionAndConnect(device:Device) {
        // Save Device
        self.device = device
        
        // Subscribe to device updates
        self.device?.subscribeToDeviceUpdates(self)
        
        // Create the session manager
        self.sessionManager = SessionManager(device: device)
        
        // Open session and connect
        self.sessionManager.openSessionAndConnect(attempts: 3) { [weak self] result in
            guard let welf = self else { return }
            switch result {
            case .Success:
                
                // Stop scanning for new devices...
                welf.stopScanning()
                
                // Get world volume, tone, and directionality from the device
                // before pushing the wheels view controller (see deviceDidUpdate)
                try! welf.device!.getDirectionality()
                try! welf.device!.getMappedSettingsOffsetControl()
                try! welf.device!.getMuting()
                try! welf.device!.getMappedSettingsMode()
                try! welf.device!.getLimits_MappedSettings()
                try! welf.device!.getGlobalMute()
                
            case .Failure(let someError):
                // Handle the error
                welf.handleConnectError(someError)
            }
        }
    }
    
    func openDeviceUpdateSession() {
        /*
         Intrepid:
         
         We failed here, but we need updates from ble bmap session because we're going to
         use it to receive messages about pairing and connection status.
         
         This way we can close videos and progress when possible.
         */
        
        sessionManager.session.openSession(attempts: 3) { [weak self] result in
            switch result {
            case .Success(_):
                // Request the pairing mode value right away...
                let pairingPacket = BasicOutgoingPacket(
                    block: .DeviceManagement,
                    method: DeviceManagementFunctionMethod.PairingMode,
                    functionOperator: .Get,
                    payload: nil
                )
                do {
                    try self?.sessionManager.write([pairingPacket])
                } catch {
                    print("Error sending initial pairing packet...")
                }
            case .Failure(let error):
                print("Error reopening session: \(error)")
                // Dismiss the device pairing video
                // TODO:    Do we need to know which view controller is currently being presented or is it
                //          safe to assume that only this view controller can be the one currently presented?
                
                // Return to idle
                self?.returnToIdle()
                
                self?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    func handleConnectError(error: BMAPSession.ConnectionError) {
        switch error {
        case .PairingModeRequired:
            /*
             Device not paired with iOS, start a BLE connection (session) to receive
             updates from the device when it's isInPairingMode value changes.
             
             deviceDidUpdate() will notify this view controller when that value changes.
             
             As soon as isInPairingMode is true, we can dismiss the device pairing video
             and showExternalAccessoryPairing() or showBluetoothSettingsPairingVideo()
             */
            self.openDeviceUpdateSession()
            self.showDevicePairingModeVideo()
            break
        case .BluetoothSettingsPairingRequired:
            if (self.sessionManager.device.supportsMfi) {
                // Return to Idle state
                self.returnToIdle()
                // Show Mfi picker
                // TODO: Need to sign up for the connection event to dismiss this view controller
                // Code is currently commented out in the device did update handler
                // Can't test without a MFi enabled Trapper device.
                self.showExternalAccessoryPairing(self.sessionManager.device)
            } else {
                // Show Bluetooth > Settings video
                self.showBluetoothSettingsPairingVideo()
            }
            break
        default:
            self.showGenericConnectionError()
            break
        }
    }
    
    func showDevicePairingModeVideo() {
        // Device Pairing Mode
        let url = NSBundle.mainBundle().URLForResource("pairing-mode-walkthrough-Isaac", withExtension: "mov")
        let text = "Drag up & hold to place headphones in pairing mode."
        let textPosition: VideoTextPosition = .VideoTextPositionBottom
        
        let videoViewController = VideoViewController(videoURL: url!, videoText: text, videoTextPosition: textPosition)
        videoViewController.delegate = self
        videoViewController.repeats = true
        
        // Close Button
        videoViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .Plain, target: self, action: #selector(userDidClose))
        
        let navigationController = UINavigationController(rootViewController: videoViewController)
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func showExternalAccessoryPairing(device:Device) {
        guard device.supportsMfi else {
            fatalError("Ensure device supports mfi before attempting to pair via external accessory")
        }
 
        var predicate: NSPredicate? = nil
        if let name = device.settings.name {
            predicate = NSPredicate(format: "%@ BEGINSWITH self", name)
        }
        
        let mFIPickerViewController = MFiPickerViewcontroller(predicate: predicate!)
        mFIPickerViewController.modalTransitionStyle = .CrossDissolve
        self.presentViewController(mFIPickerViewController, animated: true, completion: nil)
    }
    
    func showBluetoothSettingsPairingVideo() {
        // Pair via iOS (Bluetooth > Settings)
        // Two steps (next step in videoDidFinish)
        let url = NSBundle.mainBundle().URLForResource("bluetooth-pairing-walkthrough", withExtension: "m4v")
        let text = "Pair headphones\nin Bluetooth settings."
        let textPosition: VideoTextPosition = .VideoTextPositionTop
        
        let videoViewController = VideoViewController(videoURL: url!, videoText: text, videoTextPosition: textPosition)
        videoViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: videoViewController)
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func showGenericConnectionError() {
        var title:String!
        var description:String!
        let deviceName = self.device!.settings.name!
        var style:WarningStyle = .WarningStyleActionWithCancel
        var action = "Try Again"
        
        switch self.connectionFailureCount {
        case 0:
            title = "Aw Snap!"
            description = "Something happened and we couldn't connect to \(deviceName). Please make sure your product is on and within range of this device."
        case 1:
            title = "Hmm..."
            description = "We still couldn't connect to \(deviceName). Let's try this one more time. Remember your product must be turned on and within range. If you're far away, try moving closer to \(deviceName)."
        case 2:
            title = "No Dice..."
            description = "Sorry, but after three attempts we still couldn't connect \(deviceName). Let's start over to make sure that the product you are trying to connect is still available and powered on."
            style = .WarningStyleActionOnly
            action = "Start Over"
        default: break
            
        }
        let warningViewController = WarningViewController(warningTitle: title, warningDescription: description, warningStyle: style, actionTitle: action)
        warningViewController.delegate = self
        self.presentViewController(warningViewController, animated: true, completion: nil)
    }
    
    // MARK: - DeviceUpdateListenerType
    
    func deviceDidUpdate(device: Device) {
        // Wait until the device is connected and GET the wheel values, before pushing the wheels UI
        let correctDevice = device == self.device
        let wheelsNotPushed = self.navigationController?.visibleViewController == self
        
        // All the values we need to receive before showing the wheels view controller
        let wheelValueReceived = device.hearingAssistance.mappedSettingsOffsetControl.Loudness != nil
        let balanceValueReceived = device.hearingAssistance.mode != nil
        let muteValueReceived = device.hearingAssistance.mutingLeftChannel != nil
        let directionalityValueReceived = device.hearingAssistance.directionality != nil
        let loudnessLimitReceived = device.hearingAssistance.lowerLoudnessLimit != nil
        let globalMuteReceived = device.hearingAssistance.globalMute != nil
        
        if (correctDevice && wheelsNotPushed && wheelValueReceived && directionalityValueReceived && balanceValueReceived && muteValueReceived && loudnessLimitReceived && globalMuteReceived) {
            // Remove the device listener
            device.removeDeviceUpdateSubscribers { $0 === self }
            
            // Push "Stetson" UI
            let wheelsViewController = WheelsViewController(sessionManager: self.sessionManager)
            wheelsViewController.delegate = self
            self.navigationController?.pushViewController(wheelsViewController, animated: true)
        }
        
        /*
        if device.deviceManagement.isInPairingMode == true && device.isConnectedToLocalDevice == false {
            print("device.deviceManagement.isInPairingMode == true && device.isConnectedToLocalDevice == false")
            
            // TODO: Better way to grab the video controller
            if let viewController = self.presentedViewController?.childViewControllers[0] {
                if viewController is VideoViewController {
                    // Return to idle
                    self.returnToIdle()
                    
                    // Dismiss the device pairing video
                    self.dismissViewControllerAnimated(true, completion: {
                        // Try to pair the OS with the device
                        // TODO: Code repeated below, find a way to clean up
                        if device.supportsMfi {
                            self.showExternalAccessoryPairing(device)
                        } else {
                            self.showBluetoothSettingsPairingVideo()
                        }
                    })
                }
            } else {
                // Try to pair the OS with the device
                if device.supportsMfi {
                    self.showExternalAccessoryPairing(device)
                } else {
                    self.showBluetoothSettingsPairingVideo()
                }
            }
        } else if device.isConnectedToLocalDevice == true && device.isConnectedToLocalDevice == true {
            if let _ = self.presentedViewController {
                // TODO: Group all of these returnToIdle() dismissViewController() calls?
                
                // Return to idle
                self.returnToIdle()
            
                // Dismiss any view controllers
                self.dismissViewControllerAnimated(true, completion: {
                    // Auto-connect to the device
                    // TODO: Code repeated below, find a way to clean up
                    self.connect(device)
                })
            } else {
                
                // Auto-connect to the device
                self.connect(device)
            }
        }
        */
    }
}
