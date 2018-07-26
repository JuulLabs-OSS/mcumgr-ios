/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import CoreBluetooth

class DeviceTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "deviceItem"
    
    @IBOutlet weak var peripheralName: UILabel!
    @IBOutlet weak var peripheralRSSIIcon: UIImageView!

    private var lastUpdateTimestamp = Date()
    private var peripheral: DiscoveredPeripheral!

    public func setupViewWithPeripheral(_ aPeripheral: DiscoveredPeripheral) {
        peripheral = aPeripheral
        peripheralName.text = aPeripheral.advertisedName

        if peripheral!.RSSI.decimalValue < -60 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_2")
        } else if peripheral!.RSSI.decimalValue < -50 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_3")
        } else if peripheral!.RSSI.decimalValue < -30 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_4")
        } else {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_1")
        }
    }
    
    public func peripheralUpdatedAdvertisementData(_ aPeripheral: DiscoveredPeripheral) {
        if Date().timeIntervalSince(lastUpdateTimestamp) > 1.0 {
            lastUpdateTimestamp = Date()
            setupViewWithPeripheral(aPeripheral)
        }
    }
}
