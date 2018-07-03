/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetooth

public class BleCentralManager: NSObject {
    
    //*******************************************************************************************
    // MARK: Properties
    //*******************************************************************************************

    /// Central Manager.
    private var centralManager: CBCentralManager!
    
    /// Dictionary of scanned peripherals keyed by peripheral's address.
    private(set) var scannedPeripherals = [String : CBPeripheral]()
    
    /// Array of delegates for CoreBluetooth callbacks.
    private var delegates = [CBCentralManagerDelegate]()
    
    //*****************************************************************************************
    // MARK: Singleton
    //*****************************************************************************************

    /// Singleton instance of GatewayService.
    static var instance: BleCentralManager?
    
    /// Initialize the Central Manager.
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Initialize the Central Manager.
    private init(wrap manager: CBCentralManager) {
        super.init()
        centralManager = manager
    }
    
    /// Get the singleton instance of Central Manager. This method will create the singleton
    /// instance if not already created.
    ///
    /// - returns: the singleton instance of Central Manager.
    public static func getInstance() -> BleCentralManager {
        if instance == nil {
            instance = BleCentralManager()
        }
        return instance!
    }
    
    /// Create and return the singleton instance. If already created, this will return nil.
    /// Call this method before getInstance() to wrap the manager.
    ///
    /// - parameter manager: The Central Manager to be wrapped.
    /// - returns: The singleton instance of Central Manager, or nil if instance was created
    ///   before.
    public static func getInstance(wrap manager: CBCentralManager) -> BleCentralManager? {
        if instance == nil {
            instance = BleCentralManager(wrap: manager)
            return instance!
        }
        return nil
    }
    
    //*****************************************************************************************
    // MARK: Add Delegate
    //*****************************************************************************************
    
    /// Add delegate for getting CoreBluetooth callbacks such as didScanPeripheral.
    ///
    /// - parameter delegate: The delegate to add.
    public func addDelegate(_ delegate: CBCentralManagerDelegate) {
        delegates.append(delegate)
    }
    
    /// Remove delegate for getting CoreBluetooth callbacks such as didScanPeripheral.
    ///
    /// - parameter delegate: The delegate to remove.
    public func removeDelegate(_ delegate: CBCentralManagerDelegate) -> Bool {
        if let index = delegates.index(where: {$0.hash == delegate.hash}) {
            delegates.remove(at: index)
            return true
        }
        return false
    }
    
    //*****************************************************************************************
    // MARK: Scanning
    //*****************************************************************************************

    /// Start a BLE scan for peripherals with services matching the given UUIDs.
    ///
    /// - parameter uuids: The service UUIDs to scan for.
    public func startScan(forUUIDs uuids: [CBUUID]? = nil) {
        centralManager.scanForPeripherals(withServices: uuids, options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
    }
    
    /// Stop the BLE scan.
    public func stopScan() {
        centralManager.stopScan()
    }
    
    /// Get the dictionary of scanned peripherals. This dictionary is keyed by the string of
    /// the peripherals address (identifier).
    ///
    /// - returns: The dictionary of scanned peripherals.
    public func getScannedPeripherals() -> [String : CBPeripheral] {
        return scannedPeripherals
    }
    
    /// Get a scanned peripheral object using the address (identifier).
    ///
    /// - parameter address: The identifier of the peripheral to get.
    ///
    /// - returns: The peripheral scanned, or nil.
    public func getScannedPeripheral(withAddress address: String) -> CBPeripheral? {
        return scannedPeripherals[address]
    }
    
    /// Get a scanned peripheral object using the advertised name. This function
    /// will return the first peripheral whose name matches the provided
    /// parameter.
    ///
    /// - parameter name: the advertised name of the peripheral to get.
    ///
    /// - returns: The peripheral scanned with given name, or nil.
    public func getScannedPeripheral(withName name: String) -> CBPeripheral? {
        return scannedPeripherals.values.first(where: {$0.name == name})
    }
    
    /// Removes a scanned peripheral from the dictionary.
    ///
    /// - parameter address: The address of the peripheral to remove.
    ///
    /// - returns: The removed peripheral or nil if not found.
    public func removeScannedPeripheral(withAddress address: String) -> CBPeripheral? {
        if let peripheral = getScannedPeripheral(withAddress: address) {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        return scannedPeripherals.removeValue(forKey: address)
    }
    
    /// Connects to a peripheral with a given address.
    ///
    /// - parameter address: The address of the peripheral to connect to.
    /// - parameter options: Connection options.
    ///
    /// - returns: True if a peripheral with the given address was found, else otherwise.
    public func connect(toPeripheralWithAddress address: String, options: [String : Any]? = nil) -> Bool {
        if let prph = getScannedPeripheral(withAddress: address) {
            centralManager.connect(prph, options: nil)
            return true
        }
        NSLog("Could not find scanned peripheral with address: \(address)")
        return false
    }
    
    /// Connects to the given peripheral object.
    ///
    /// - parameter peripheral: The peripheral to connect to.
    /// - parameter options: Connection options.
    public func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        centralManager.connect(peripheral, options: options)
    }
    
    /// Forces the manager to disconnect from the peripheral.
    ///
    /// - parameter peripheral: The peripheral to disconnect.
    public func disconnect(_ peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /// Get the MTU for this central and the given peripheral.
    ///
    /// - parameter peripheral: The peripheral from which to determine the MTU.
    ///
    /// - returns: The MTU.
    public func getMTU(_ peripheral: CBPeripheral) -> Int {
        var centralMTU: Int = 0
        if #available(iOS 10.0, *) {
            // For iOS 10.0+
            centralMTU = 185
        } else {
            // For iOS 9.0
            centralMTU = 158
        }
        let peripheralMTU = peripheral.maximumWriteValueLength(for: CBCharacteristicWriteType.withResponse)
        return min(centralMTU, peripheralMTU)
    }
    
    /// Prints each peripheral in the scanned peripheral dictionary.
    public func printScannedPeripherals() {
        for (address, peripheral) in scannedPeripherals {
            print("\(peripheral.name ?? "Unknown")\t - \(address)")
        }
    }
    
    func GWSLog(_ text: String, peripheral: CBPeripheral? = nil, address: String? = nil) {
        guard let peripheral = peripheral else {
            guard let address = address else {
                NSLog(text)
                return
            }
            NSLog("\(address.prefix(4)) - \(text)")
            return
        }
        NSLog("\(peripheral.name ?? "Unknown") (\(peripheral.identifier.uuidString.prefix(4))) - \(text)")
    }
}

extension BleCentralManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        GWSLog("Central Manager: centralManagerDidUpdateState - \(central.state.rawValue)")
        for delegate in delegates {
            delegate.centralManagerDidUpdateState(central)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //GWSLog("Central Manager: didDiscoverPeripheral", peripheral: peripheral)
        scannedPeripherals.updateValue(peripheral, forKey: peripheral.identifier.uuidString)
        for delegate in delegates {
            delegate.centralManager?(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        GWSLog("Central Manager: didDisconnectPeripheral", peripheral: peripheral)
        for delegate in delegates {
            delegate.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        GWSLog("Did connect peripheral", peripheral: peripheral)
        for delegate in delegates {
            delegate.centralManager?(central, didConnect: peripheral)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        GWSLog("Did fail to connect", peripheral: peripheral)
        for delegate in delegates {
            delegate.centralManager?(central, didFailToConnect: peripheral, error: error)
        }
    }
}
