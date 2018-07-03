/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

/// McuManager transport scheme.
public enum McuMgrScheme {
    case ble, coapBle, coapUdp
    func isCoap() -> Bool {
        return self != .ble
    }
}

public protocol McuMgrTransport {
    /// Returns the transport scheme.
    ///
    /// - returns: The transport scheme.
    func getScheme() -> McuMgrScheme
    
    /// Sends given data using the transport object.
    ///
    /// - parameter data: The data to be sent.
    /// - parameter callback: The request callback.
    func send<T: McuMgrResponse>(data: Data, callback: @escaping McuMgrCallback<T>)
}
