//
//  DeviceCommunication.swift
//  Sample
//
//  Created by Michael Rose on 3/1/16.
//  Copyright © 2016 Michael Rose. All rights reserved.
//

import UIKit
import CoreBluetooth

public let DEVICE_NOTIFICATION_STATE_CHANGE =          "DEVICE_NOTIFICATION_STATE_CHANGE"
public let DEVICE_NOTIFICATION_HEADER_COMPLETE =       "DEVICE_NOTIFICATION_HEADER_COMPLETE"
public let DEVICE_NOTIFICATION_GET_HISTORY_COMPLETE =  "DEVICE_NOTIFICATION_GET_HISTORY_COMPLETE"
public let DEVICE_NOTIFICATION_GET_DELTA_COMPLETE =    "DEVICE_NOTIFICATION_GET_DELTA_COMPLETE"
public let DEVICE_NOTIFICATION_ERASE_CYCLE_COMPLETE =  "DEVICE_NOTIFICATION_ERASE_CYCLE_COMPLETE"
public let DEVICE_NOTIFICATION_BYTES_RECEIVED =        "DEVICE_NOTIFICATION_BYTES_RECEIVED"

let DEVICE_SERVICE_UUID: String! =                     "00035B03-58E6-07DD-021A-08123A000300"
let DEVICE_CHARACTERISTIC_UUID: String! =              "00035B03-58E6-07DD-021A-08123A000301"

let DEVICE_RESTORE_ID: String! =                       "DEVICE_RESTORE_ID"

public enum ProtocolState {
    case Init                               // Wait for initial ACK, sends Ready command.
    case WaitForBLETransferHeader
    case Ready                              // Accepting commands, header received.
    case WaitForDownload                    // Download in progress.
    case WaitForDeltaDownload
    case WaitForErase
    case WaitForManufacturerDataWrite
    case Error
}

public class DeviceCommunicator: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    public static let sharedInstance = DeviceCommunicator()
    
    // App Delegate
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // Core Bluetooth
    public var centralManager: CBCentralManager!
    public var peripheral: CBPeripheral!
    public var characteristic: CBCharacteristic!
    
    // Public Data
    public var nasoData: NasoData?
    public var dataHeader: BLEDataHeader!
    public var currentState: ProtocolState {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { 
                NSNotificationCenter.defaultCenter().postNotificationName(DEVICE_NOTIFICATION_STATE_CHANGE, object: self, userInfo: nil)
            }
        }
    }
    public var commandCanBeSent: Bool {
        return ProtocolState.Ready == self.currentState && self.characteristic != nil
    }
    
    // Private Data
    private var fileURL: NSURL {
        let filePath = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as NSURL
        return filePath.URLByAppendingPathComponent("Data.nvmDataBin")
    }
    private var inputBuffer = [UInt8](count: DataUtils.NASO_MAX_TRANSFER_BYTES, repeatedValue: 0)
    private var lastIndexSaved = DataUtils.START_OF_PATIENT_DATA
    private var currentIndex = 0 {
        didSet {
            let bytesToDownload: Int
            if (self.currentState == .WaitForBLETransferHeader) {
                bytesToDownload = DataUtils.SIZEOF_BLE_DATA_HEADER
            } else {
                bytesToDownload = self.totalCharsToReceive
            }
            let percentage = Float(self.currentIndex)/Float(bytesToDownload)
            let dictionary = ["percentage" : percentage]
            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(DEVICE_NOTIFICATION_BYTES_RECEIVED, object: self, userInfo: dictionary)
            }
        }
    }
    private var totalCharsToReceive = 0     // Used for data transfer, size to wait for.
    private enum ReceiveBlockReturnType {
        case ReceiveNvmBlockDone
        case ReceiveNvmBlockInProgress
    }
    private var startTime: CFTimeInterval?
    private var elapsedTime: CFTimeInterval?
    private var getDataFlag = false
    
    // MARK: - Init
    
    private override init() {
        self.currentState = ProtocolState.Init
        super.init()
        
        if let data = NSData(contentsOfURL: self.fileURL) {
            // Add the existing file bytes to input buffer in memory
            let savedBuffer = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: data.length))
            self.lastIndexSaved = savedBuffer.count-1-2
            
            
            // TODO: Refactor into separate buffers so this merge isn't required
            // TODO: Save header, device, and patient data into separate buffers.
            // TODO: Don't save the CRC into buffer
            
            // Copy saved buffer into input buffer
            print("Merging saved buffer into memory, currently takes a while...")
            for i in 0 ..< savedBuffer.count-2 {
                self.inputBuffer.insert(savedBuffer[i], atIndex: i)
            }
            print("Buffer successfully merged with count: \(inputBuffer.count)")
            print("Last index saved = \(self.lastIndexSaved!)")
        
        } else {
            // Do nothing, the input buffer is already initialized
            print("We DO NOT have a file! Run full download ('Download Data') after receiving header.")
        }
        
        // let queue = dispatch_queue_create("com.pathfinder.tearbud", DISPATCH_QUEUE_CONCURRENT)
        self.centralManager = CBCentralManager.init(delegate: self, queue: nil, options:[CBCentralManagerOptionRestoreIdentifierKey:DEVICE_RESTORE_ID])
    }
    
    // MARK: - Public Methods
    
    public func disconnect() {
        print("Disconnect...")
        self.peripheral.setNotifyValue(false, forCharacteristic: self.characteristic)
        self.characteristic = nil
        
        self.centralManager.cancelPeripheralConnection(self.peripheral)
    }
    
    public func startScanning() {
        print("Start scanning for peripherals...")
        self.appDelegate.log.logString("Start scanning for peripherals...")
        
        self.centralManager.scanForPeripheralsWithServices([CBUUID.init(string: DEVICE_SERVICE_UUID)], options: nil)
        if (self.centralManager.isScanning) {
            print("Central manager is scanning...")
            self.appDelegate.log.logString("Central manager is scanning...")
        } else {
            print("Central manager is NOT scanning...")
            self.appDelegate.log.logString("Central manager is NOT scanning...")
        }
    }
    
    // This function kicks off the state machine that loads data from the Tear Bud device
    public func startNasoDownload() -> Bool {
        if self.commandCanBeSent {
            self.startTime = CACurrentMediaTime()
            self.elapsedTime = 0
            //
            let command = createCommandWithTime(BLECommands.BLE_COMMAND_SEND_DATA)
            let data = NSData(bytes: command, length: command.count)
        
            self.peripheral.writeValue(data, forCharacteristic: self.characteristic, type: CBCharacteristicWriteType.WithResponse)
        
            self.currentState = ProtocolState.WaitForDownload
        
            return true
        }
        
        return false
    }
    
    public func startPatientDownload() -> Bool {
        if self.commandCanBeSent && (self.inputBuffer.count - DataUtils.START_OF_PATIENT_DATA) > 0 {
            self.startTime = CACurrentMediaTime()
            self.elapsedTime = 0
            
            // Move current index point to accept new data coming in...
            self.currentIndex = self.lastIndexSaved + 1
            
            let index = UInt32(self.lastIndexSaved - DataUtils.START_OF_PATIENT_DATA)
            let command = createCommandWithTimeAndIndex(BLECommands.BLE_COMMAND_SEND_PATIENT_DATA, index: index)
            let data = NSData(bytes: command, length: command.count)
            
            self.peripheral.writeValue(data, forCharacteristic: self.characteristic, type: CBCharacteristicWriteType.WithResponse)
            
            self.currentState = ProtocolState.WaitForDeltaDownload
            
            return true
        }
        
        return false
    }
    
    // This function is provided for use by the UI to start a time set sequence.  true is returned upon success.
    public func deleteNasoNvm() -> Bool {
        if self.commandCanBeSent {
            self.startTime = CACurrentMediaTime()
            self.elapsedTime = 0
            //
            self.nasoData = nil
            let command = createCommandWithTime(BLECommands.BLE_COMMAND_ERASE)
            let data = NSData(bytes: command, length: command.count)
        
            self.peripheral.writeValue(data, forCharacteristic: self.characteristic, type: CBCharacteristicWriteType.WithResponse)
        
            self.currentState = ProtocolState.WaitForErase
        
            return true
        }
        
        return false
    }

    // MARK: - Private Methods

    private func processPacket(packet: [UInt8]) {
        
        NSLog("packet = \(packet)")
        
        switch self.currentState {
            
        case ProtocolState.Init:
            // Valid init response?
            if isAckInPacket(packet) {
                
                self.startTime = CACurrentMediaTime()
                self.elapsedTime = 0
                
                let command = BLECommands.BLE_CMD_READY
                let data = NSData(bytes: command, length: command.count)
                
                self.peripheral.writeValue(data, forCharacteristic: self.characteristic, type: CBCharacteristicWriteType.WithResponse)
                
                self.currentState = ProtocolState.WaitForBLETransferHeader
            } else {
                print("Error: Acknowledgment not received!")
            }
            break
            
        // Accumulate & validate the header.  When the header is found, validate the data,
        // and create the header class.  The header contains how many characters will be received,
        // and it validated with a 16 bit CRC.
        case ProtocolState.WaitForBLETransferHeader:
            self.totalCharsToReceive = DataUtils.NASO_MAX_TRANSFER_BYTES
            receiveNvmBlock(packet)
            
            if (DataUtils.SIZEOF_BLE_DATA_HEADER <= self.currentIndex) {
                // Here we have received the header-size. Process the header.
                self.dataHeader = BLEDataHeader.init(fromBuffer: inputBuffer)
                if (self.dataHeader.dataIsValid) {
                    // TODO: Do total length calculation here? Only place it's used?
                    self.totalCharsToReceive = dataHeader.totalLength!
                    self.currentState = ProtocolState.Ready
                    if self.getDataFlag {
                        startNasoDownload();
                    } else {
                        self.elapsedTime = CACurrentMediaTime() - self.startTime!
                        let dictionary = ["time":self.elapsedTime!]
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName(DEVICE_NOTIFICATION_HEADER_COMPLETE, object: self, userInfo: dictionary)
                        }
                    }
                } else {
                    self.dataHeader = nil
                    self.currentState = ProtocolState.Error
                    // TODO: Throw error that the header wasn't valid
                    // SendAppMessage.sendMessage(SendAppMessage.CRC_ERROR)
                }
            } else {
                 //
            }
            break
            
        // In this state, external commands from the Android UI can be accepted to initiate actions.
        // No data should be received in this state.
        case ProtocolState.Ready:
            //
            break
        
        // Accumulate & validate the NVM data download
        case ProtocolState.WaitForDownload:
            // Add all data found to the DataStore
            
            if ReceiveBlockReturnType.ReceiveNvmBlockDone == receiveNvmBlock(packet) {
                
                if self.payloadCRCIsValid(self.inputBuffer) {
                    
                    // TODO: Wrap in try/catch
                    // If fails -> // SendAppMessage.sendMessage(SendAppMessage.UNEXPECTED_ERROR)
                    
                    // Parse the naso data into structures usable by the UI
                    self.nasoData = NasoData(fromBuffer: self.inputBuffer, nasoNvmLength: self.dataHeader.payloadLength!)
                    
                    self.currentState = ProtocolState.Ready
                    
                    self.elapsedTime = CACurrentMediaTime() - self.startTime!
                    let dictionary = ["time":self.elapsedTime!]
                    if self.getDataFlag {
                        // After downloading the data due to erase OR mfg. data set, tell the UI.
                        self.getDataFlag = false;
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName(DEVICE_NOTIFICATION_ERASE_CYCLE_COMPLETE, object: self, userInfo: dictionary)
                        }
                    } else {
                        // History Data Download has completed successfully
                         dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotificationName(DEVICE_NOTIFICATION_GET_HISTORY_COMPLETE, object: self, userInfo: dictionary)
                        }
                    }
                
                    // Write the nvmDataBin file to disk (Documents folder)
                    let count = self.dataHeader.totalLength! + DataUtils.SIZEOF_BLE_DATA_HEADER + DataUtils.SIZEOF_CRC
                    let data = NSData(bytes: self.inputBuffer, length: count)
                    data.writeToURL(self.fileURL, atomically: true)
                    
                } else {
                    // SendAppMessage.sendMessage(SendAppMessage.CRC_ERROR)
                    self.currentState = ProtocolState.Error
                    // SendAppMessage.sendMessage(SendAppMessage.GET_HISTORY_FAILED)
                }
                
            } else {
                // SendAppMessage.sendDataBytesReceivedMessage(mCurrentIndex);
            }
            break
        
        case ProtocolState.WaitForDeltaDownload:
            // Add all data found to the DataStore
            
            if ReceiveBlockReturnType.ReceiveNvmBlockDone == receiveNvmBlock(packet) {
                
                if self.payloadCRCIsValid(self.inputBuffer) {
                    
                    // TODO: Wrap in try/catch
                    // If fails -> // SendAppMessage.sendMessage(SendAppMessage.UNEXPECTED_ERROR)
                    
                    // Parse the naso data into structures usable by the UI
                    self.nasoData = NasoData(fromBuffer: self.inputBuffer, nasoNvmLength: self.dataHeader.payloadLength!)
                    
                    self.currentState = ProtocolState.Ready
                    
                    self.elapsedTime = CACurrentMediaTime() - self.startTime!
                    let dictionary = ["time":self.elapsedTime!]
                    // Delta Data Download has completed successfully
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotificationName(DEVICE_NOTIFICATION_GET_DELTA_COMPLETE, object: self, userInfo: dictionary)
                    }
                    
                    // Overwrite the nvmDataBin file on disk (Documents folder)
                    let count = self.dataHeader.totalLength! + DataUtils.SIZEOF_BLE_DATA_HEADER + DataUtils.SIZEOF_CRC
                    let data = NSData(bytes: self.inputBuffer, length: count)
                    data.writeToURL(self.fileURL, atomically: true)
                    
                } else {
                    // SendAppMessage.sendMessage(SendAppMessage.CRC_ERROR)
                    self.currentState = ProtocolState.Error
                    // SendAppMessage.sendMessage(SendAppMessage.GET_HISTORY_FAILED)
                }
                
            } else {
                // SendAppMessage.sendDataBytesReceivedMessage(mCurrentIndex);
            }
            break
            
        // Wait for the ACK from the erase command.
        case ProtocolState.WaitForErase:
            if packet.count > 0 {
                for byte in packet {
                    if BLECommands.BLE_CMD_ACK == byte {
                        self.getDataFlag = true
                        self.currentIndex = 0 // Wipe out the existing data including header
                        self.nasoData = nil
                        self.dataHeader = nil
                        self.inputBuffer = []
                        self.receiveNvmBlock(packet)
                        self.currentState = ProtocolState.WaitForBLETransferHeader
                        break
                    } else if BLECommands.BLE_CMD_NACK == byte {
                        self.currentState = ProtocolState.Ready
                        // SendAppMessage.sendMessage(SendAppMessage.NVM_DATA_ERASE_FAILED)
                        break
                    }
                }
            }
            break
        
        // Wait for the ACK from the Manufacture command.
        case ProtocolState.WaitForManufacturerDataWrite:
            if packet.count > 0 {
                for byte in packet {
                    if BLECommands.BLE_CMD_ACK == byte {
                        self.getDataFlag = true
                        self.currentIndex = 0 // Wipe out the existing data including header
                        self.nasoData = nil
                        self.dataHeader = nil
                        self.inputBuffer = []
                        self.receiveNvmBlock(packet);
                        self.currentState = ProtocolState.WaitForBLETransferHeader
                        break
                    } else if BLECommands.BLE_CMD_NACK == byte {
                        self.currentState = ProtocolState.Ready
                        // SendAppMessage.sendMessage(SendAppMessage.NVM_DATA_MANUFACTURE_FAILED)
                        break
                    }
                }
            }
            break
        
        case ProtocolState.Error:
            print("ProtocolState.Error!")
            break
            
        }
        
    }
    
    // The NVM data goes into the accumulation buffer in the following order.
    // 1. transport header (not part of Naso NVM)
    // 2. fixed size device data (manufacturing block)
    // 3. variable sized patient/event data
    private func receiveNvmBlock(packet: [UInt8]) -> ReceiveBlockReturnType {
        var value = ReceiveBlockReturnType.ReceiveNvmBlockInProgress
        if (packet.count > 0) {
            for byte in packet {
                if (self.currentIndex < DataUtils.NASO_MAX_TRANSFER_BYTES) && (self.currentIndex < self.totalCharsToReceive) {
                    // Add byte to input buffer
                    self.inputBuffer.insert(byte, atIndex: self.currentIndex)
                    // Done?
                    self.currentIndex++
                    if self.currentIndex >= self.totalCharsToReceive {
                        value = ReceiveBlockReturnType.ReceiveNvmBlockDone
                        break
                    }
                }
            }
        }
        return value
    }
    
    // This function looks for the ACK character in the data stream.
    private func isAckInPacket(packet: [UInt8]) -> Bool {
        for int in packet {
            if BLECommands.BLE_CMD_ACK == int {
                return true
            }
        }
        return false
    }
    
    // This function will compute the crc of the payload, and return true if it matches the CRC
    // sent from the Naso.
    public func payloadCRCIsValid(buffer: [UInt8]) -> Bool {
        let crcIndex = self.totalCharsToReceive - 2
        let receivedCRC = DataUtils.combineMsbLsb(buffer[crcIndex], lsb: buffer[crcIndex + 1])
        let computedCRC = CRC16Modbus.CRC16(buffer, firstIndex: DataUtils.SIZEOF_BLE_DATA_HEADER, length: self.dataHeader.payloadLength!)
        return computedCRC == receivedCRC
    }
    
    // This function creates a message for the command, and a time at the end.
    private func createCommandWithTime(command: [UInt8]) -> [UInt8] {
        var commandWithTime = [UInt8]() + command
        
        // Build data structure to send seconds since 1970, utc.
        let seconds = Int(NSDate().timeIntervalSince1970)
        commandWithTime.append(UInt8(seconds >>  0 & 0xFF))
        commandWithTime.append(UInt8(seconds >>  8 & 0xFF))
        commandWithTime.append(UInt8(seconds >> 16 & 0xFF))
        commandWithTime.append(UInt8(seconds >> 24 & 0xFF))

        // CRC applies to the payload NOT the command and NOT the CRC itself.
        let computedCRC = CRC16Modbus.CRC16(commandWithTime, firstIndex:command.count, length: DataUtils.NASO_NUM_TIME_BYTES)
        commandWithTime.append(UInt8(computedCRC >> 8 & 0xFF))
        commandWithTime.append(UInt8(computedCRC & 0xFF))
        
        return commandWithTime
    }
    
    // This function creates a message for the command, and a time at the end.
    private func createCommandWithTimeAndIndex(command: [UInt8], index:UInt32) -> [UInt8] {
        var commandWithTimeAndIndex = [UInt8]() + command
        
        // Add start address
        commandWithTimeAndIndex.append(UInt8(index >> 24 & 0xFF))
        commandWithTimeAndIndex.append(UInt8(index >> 16 & 0xFF))
        commandWithTimeAndIndex.append(UInt8(index >> 8 & 0xFF))
        commandWithTimeAndIndex.append(UInt8(index >> 0 & 0xFF))
        
        // Build data structure to send seconds since 1970, utc.
        let seconds = Int(NSDate().timeIntervalSince1970)
        commandWithTimeAndIndex.append(UInt8(seconds >>  0 & 0xFF))
        commandWithTimeAndIndex.append(UInt8(seconds >>  8 & 0xFF))
        commandWithTimeAndIndex.append(UInt8(seconds >> 16 & 0xFF))
        commandWithTimeAndIndex.append(UInt8(seconds >> 24 & 0xFF))
        
        // CRC applies to the payload NOT the command and NOT the CRC itself.
        let computedCRC = CRC16Modbus.CRC16(commandWithTimeAndIndex, firstIndex:command.count, length: BLECommands.BLE_COMMAND_SEND_PATIENT_DATA_PAYLOAD_LEN)
        commandWithTimeAndIndex.append(UInt8(computedCRC >> 8 & 0xFF))
        commandWithTimeAndIndex.append(UInt8(computedCRC & 0xFF))
        
        return commandWithTimeAndIndex
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case CBCentralManagerState.Unauthorized:
            print("The app is not authorized to use Bluetooh low engergy.")
            break
        case CBCentralManagerState.PoweredOff:
            print("Bluetooth is currently powered off.")
            break
        case CBCentralManagerState.PoweredOn:
            print("Bluetooth is currently powered on and available to use.")
            if (self.peripheral == nil) {
                self.startScanning()
            }
            break
        case CBCentralManagerState.Resetting:
            print("Bluetooth state is currently resetting.")
            break
        default:
            //
            break
        }
        
    }
    
    public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // TODO: Reject if the signal strength is too low to be close enough (Close is around -22dB)
        /*
        if (RSSI.integerValue < CUTOFF_VAR) {
            return
        }
        */
        
        print("Central manager did discover peripheral: \(peripheral.name).")
        
        print("Retain and connect to peripheral: \(peripheral.name).")
        self.peripheral = peripheral
        self.centralManager.connectPeripheral(self.peripheral, options: nil)
    }
    
    public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Did connect to peripheral: \(peripheral.name).")
        
        // Set the delegate
        self.peripheral.delegate = self
        
        // Search only for services that match our UUID
        self.peripheral.discoverServices([CBUUID.init(string: DEVICE_SERVICE_UUID)])
    }
    
    public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Did disconnect from peripheral: \(peripheral.name)")
        
        self.peripheral.delegate = nil
        self.peripheral = nil
    
        // self.currentState = ProtocolState.Init
    }
    
    public func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        print("Central managager will restore state: \(dict)")
        self.appDelegate.log.logString("Central managager will restore state: \(dict)")
        
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
        if (peripherals?.count > 0) {
            self.peripheral = peripherals!.firstObject as! CBPeripheral
            self.peripheral.delegate = self
        }
    }
    
    // MARK - CBPeripheralDelegate
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Peripheral did discover services: \(peripheral.services)")
        for service in peripheral.services! {
            print("Look for the specific characteristic we're after...")
            peripheral.discoverCharacteristics([CBUUID.init(string: DEVICE_CHARACTERISTIC_UUID)], forService: service)
        }
    }
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("Did discover characteristics for service: \(service.UUID)")
        for characteristic in service.characteristics! {
            print("Characteristic: \(characteristic.UUID)")
            if characteristic.UUID.UUIDString == DEVICE_CHARACTERISTIC_UUID {
                print("Found the characteristic we're looking for, save reference to it and sign up for notifications.")
                self.characteristic = characteristic
                self.peripheral.setNotifyValue(true, forCharacteristic: self.characteristic)
            }
        }
    }
    
    public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        let data = characteristic.value
        let count = data!.length / sizeof(UInt8)
        var packet = [UInt8](count: count, repeatedValue: 0)
        data!.getBytes(&packet, length:count * sizeof(UInt8))
        
        self.processPacket(packet)
    }
    
    public func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("Peripheral did update notification state: \(characteristic.isNotifying) for characteristic: \(characteristic.UUID)")
    }
    
}