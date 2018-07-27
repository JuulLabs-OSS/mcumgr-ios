/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import CoreBluetooth
import McuManager

class ConnectionStateLabel: UILabel, ConnectionStateObserver {
    
    func peripheral(_ transport: McuMgrTransport, didChangeStateTo state: CBPeripheralState) {
        switch state {
        case .connected:
            text = "CONNECTED"
        case .connecting:
            text = "CONNECTING"
        case .disconnected:
            text = "DISCONNECTED"
        case .disconnecting:
            text = "DISCONNECTING"
        }
    }

}
