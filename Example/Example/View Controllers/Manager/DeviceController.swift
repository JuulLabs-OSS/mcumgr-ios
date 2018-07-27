/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import McuManager

class DeviceController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var connectionStatus: ConnectionStateLabel!
    @IBOutlet weak var message: UITextField!
    @IBOutlet weak var actionSend: UIButton!
    @IBOutlet weak var messageSent: UILabel!
    @IBOutlet weak var messageSentBackground: UIImageView!
    @IBOutlet weak var messageReceived: UILabel!
    @IBOutlet weak var messageReceivedBackground: UIImageView!
    
    @IBAction func sendTapped(_ sender: UIButton) {
        message.resignFirstResponder()
        
        let text = message.text!
        send(message: text)
    }
    
    private var defaultManager: DefaultManager!
    
    override func viewDidLoad() {
        message.delegate = self
        actionSend.tintColor = UIColor.accent
        
        let sentBackground = UIImage(named: "bubble_sent")!
            .resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 21, bottom: 17, right: 21), resizingMode: .stretch)
            .withRenderingMode(.alwaysTemplate)
        messageSentBackground.image = sentBackground
        
        let receivedBackground = UIImage(named: "bubble_received")!
            .resizableImage(withCapInsets: UIEdgeInsets(top: 17, left: 21, bottom: 17, right: 21), resizingMode: .stretch)
            .withRenderingMode(.alwaysTemplate)
        messageReceivedBackground.image = receivedBackground
        
        let baseController = parent as! BaseViewController
        let transporter = baseController.transporter!
        
        defaultManager = DefaultManager(transporter: transporter)
        
        // Add the Connection Status label as state observer
        transporter.addObserver(connectionStatus)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped(actionSend)
        return true
    }
    
    private func send(message: String) {
        messageSent.text = message
        messageSent.isHidden = false
        messageSentBackground.isHidden = false
        messageReceived.isHidden = true
        messageReceivedBackground.isHidden = true
        
        defaultManager.echo(message) { (response, error) in
            DispatchQueue.main.async {
                if let response = response {
                    self.messageReceived.text = response.response
                    self.messageReceivedBackground.tintColor = UIColor.zephyr
                }
                if let error = error {
                    self.messageReceived.text = "\(error)"
                    self.messageReceivedBackground.tintColor = UIColor.red
                }
                self.messageReceived.isHidden = false
                self.messageReceivedBackground.isHidden = false
            }
        }
    }
}
