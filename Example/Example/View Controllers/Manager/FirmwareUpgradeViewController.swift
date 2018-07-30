/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import McuManager

class FirmwareUpgradeViewController: UIViewController, FirmwareUpgradeDelegate {
    
    @IBOutlet weak var firmwareUpgradeActionSelect: UIButton!
    @IBOutlet weak var firmwareUpgradeActionStart: UIButton!
    @IBOutlet weak var firmwareUpgradeActionPause: UIButton!
    @IBOutlet weak var firmwareUpgradeActionResume: UIButton!
    @IBOutlet weak var firmwareUpgradeActionCancel: UIButton!
    @IBOutlet weak var firmwareUpgradeStatus: UILabel!
    @IBOutlet weak var firmwareUpgradeFileHash: UILabel!
    @IBOutlet weak var firmwareUpgradeFileSize: UILabel!
    @IBOutlet weak var firmwareUpgradeFileName: UILabel!
    @IBOutlet weak var firmwareUpgradeProgress: UIProgressView!
    
    @IBAction func selectFirmware(_ sender: UIButton) {
    }
    @IBAction func start(_ sender: UIButton) {
    }
    @IBAction func pause(_ sender: UIButton) {
    }
    @IBAction func resume(_ sender: UIButton) {
    }
    @IBAction func cancel(_ sender: UIButton) {
    }
    
    private var dfuManager: FirmwareUpgradeManager!
    var transporter: McuMgrTransport! {
        didSet {
            dfuManager = FirmwareUpgradeManager(transporter: transporter, delegate: self)
        }
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
