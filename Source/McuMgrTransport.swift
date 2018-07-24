/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetooth

/// McuManager transport scheme.
public enum McuMgrScheme {
    case ble, coapBle, coapUdp
    
    func isCoap() -> Bool {
        return self != .ble
    }
    
    func isBle() -> Bool {
        return self != .coapUdp
    }
}

/// The connectin state observer protocol.
public protocol ConnectionStateObserver: class {
    /// Called whenever the peripheral state changes.
    ///
    /// - parameter transport: the Mcu Mgr transport object.
    /// - parameter state: The new state of the peripehral.
    func peripheral(_ transport: McuMgrTransport, didChangeStateTo state: CBPeripheralState)
}

public enum McuMgrTransportError: Error {
    /// Connection to the remote device has timed out.
    case connectionTimeout
    /// Connection to the remote device has failed.
    case connectionFailed
    /// Sending the request to the device has timed out.
    case sendTimeout
    /// Sending the request to the device has failed.
    case sendFailed
    /// The transport MTU is insufficient to send the request. The transport's
    /// MTU must be sent back as this case's argument.
    case insufficientMtu(mtu: Int)
    /// The response received was bad.
    case badResponse
}

extension McuMgrTransportError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .connectionTimeout:
            return "Connection to the remote device has timed out."
        case .connectionFailed:
            return "Connection to the remote device has failed."
        case .sendTimeout:
            return "Sending the request to the device has timed out."
        case .sendFailed:
            return "Sending the request to the device has failed."
        case .insufficientMtu(mtu: let mtu):
            return "Insufficient MTU: \(mtu)."
        case .badResponse:
            return "Bad response received."
        }
    }
}

/// Mcu Mgr transport object. The transport object
/// should automatically handle connection on first request.
public protocol McuMgrTransport: class {
    /// Returns the transport scheme.
    ///
    /// - returns: The transport scheme.
    func getScheme() -> McuMgrScheme
    
    /// Sends given data using the transport object.
    ///
    /// - parameter data: The data to be sent.
    /// - parameter callback: The request callback.
    func send<T: McuMgrResponse>(data: Data, callback: @escaping McuMgrCallback<T>)
    
    /// Releases the transport object. This should disconnect the peripheral.
    func close()
    
    /// Adds the connection state observer.
    ///
    /// - parameter observer: The observer to be added.
    func addObserver(_ observer: ConnectionStateObserver);
    
    /// Removes the connection state observer.
    ///
    /// - parameter observer: The observer to be removed.
    func removeObserver(_ observer: ConnectionStateObserver);
}
