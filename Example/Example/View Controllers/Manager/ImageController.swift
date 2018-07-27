/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import McuManager

class ImageController: UITableViewController, FirmwareUpgradeDelegate {
    @IBOutlet weak var connectionStatus: ConnectionStateLabel!
    
    private var defaultManager: DefaultManager!
    private var imageManager: ImageManager!
    private var dfuManager: FirmwareUpgradeManager!
    
    override func viewDidLoad() {
        let baseController = parent as! BaseViewController
        let transporter = baseController.transporter!
        defaultManager = DefaultManager(transporter: transporter)
        imageManager = ImageManager(transporter: transporter)
        dfuManager = FirmwareUpgradeManager(transporter: transporter, delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Set the connection status label as transport delegate.
        let bleTransporter = defaultManager.transporter as? McuMgrBleTransport
        bleTransporter?.delegate = connectionStatus
    }
    
    // MARK: - Firmware Upgrade Delegate
    func upgradeDidStart(controller: FirmwareUpgradeController) {
        
    }
    
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        
    }
    
    func upgradeDidComplete() {
        
    }
    
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        
    }
    
    func upgradeDidCancel(state: FirmwareUpgradeState) {
        
    }
    
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        
    }
}
