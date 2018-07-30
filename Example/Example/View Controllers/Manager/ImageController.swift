/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import McuManager

class ImageController: UITableViewController {
    @IBOutlet weak var connectionStatus: ConnectionStateLabel!
    
    override func viewDidAppear(_ animated: Bool) {
        showModeSwitch()
        
        // Set the connection status label as transport delegate.
        let baseController = parent as! BaseViewController
        let bleTransporter = baseController.transporter as? McuMgrBleTransport
        bleTransporter?.delegate = connectionStatus
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tabBarController!.navigationItem.rightBarButtonItem = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let baseController = parent as! BaseViewController
        let transporter = baseController.transporter
        
        var destination = segue.destination as? McuMgrViewController
        destination?.transporter = transporter!
    }
    
    // MARK: - Handling Basic / Advanced mode
    private var advancedMode: Bool = false
    
    @objc func modeSwitched() {
        showModeSwitch(toggle: true)
        tableView.reloadData()
    }
    
    private func showModeSwitch(toggle: Bool = false) {
        if toggle {
            advancedMode = !advancedMode
        }
        let action = advancedMode ? "Basic" : "Advanced"
        tabBarController!.navigationItem.rightBarButtonItem = UIBarButtonItem(title: action, style: .plain, target: self, action: #selector(modeSwitched))
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (advancedMode && section == 1) || (!advancedMode && 2...4 ~= section) {
            return 0.1
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (advancedMode && section == 1) || (!advancedMode && 2...4 ~= section) {
            return 0.1
        }
        return super.tableView(tableView, heightForFooterInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (advancedMode && section == 1) || (!advancedMode && 2...4 ~= section) {
            return 0
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (advancedMode && section == 1) || (!advancedMode && 2...4 ~= section) {
            return nil
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }
}
