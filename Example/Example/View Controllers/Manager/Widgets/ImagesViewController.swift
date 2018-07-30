/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import McuManager

class ImagesViewController: UIViewController , McuMgrViewController{
    
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var readAction: UIButton!
    @IBOutlet weak var testAction: UIButton!
    @IBOutlet weak var confirmAction: UIButton!
    @IBOutlet weak var eraseAction: UIButton!
    
    @IBAction func read(_ sender: UIButton) {
        imageManager.list { (response, error) in
            self.handle(response, error)
        }
    }
    @IBAction func test(_ sender: UIButton) {
        imageManager.test(hash: imageHash!) { (response, error) in
            self.handle(response, error)
        }
    }
    @IBAction func confirm(_ sender: UIButton) {
        imageManager.confirm(hash: imageHash!) { (response, error) in
            self.handle(response, error)
        }
    }
    @IBAction func erase(_ sender: UIButton) {
        imageManager.erase { (response, error) in
            if let _ = response {
                self.read(sender)
            } else {
                self.message.textColor = UIColor.red
                self.message.text = "\(error!)"
            }
        }
    }
    
    var imageHash: [UInt8]?
    
    private var imageManager: ImageManager!
    var transporter: McuMgrTransport! {
        didSet {
            imageManager = ImageManager(transporter: transporter)
        }
    }
    
    private func handle(_ response: McuMgrImageStateResponse?, _ error: Error?) {
        if let response = response {
            var info = "Split status: \(response.splitStatus ?? 0)"
            if let images = response.images {
                var i = 0
                for image in images {
                    info += "\nSlot \(i)\n" +
                        "• Version: \(image.version!)\n" +
                        "• Hash: \(Data(bytes: image.hash[0...16]).hexEncodedString(options: .upperCase))...\n" +
                    "• Flags: "
                    if image.bootable {
                        info += "Bootable, "
                    }
                    if image.pending {
                        info += "Pending, "
                    }
                    if image.confirmed {
                        info += "Confirmed, "
                    }
                    if image.active {
                        info += "Active, "
                    }
                    if image.permanent {
                        info += "Permanent, "
                    }
                    if !image.bootable && !image.pending && !image.confirmed && !image.active && !image.permanent {
                        info += "None"
                    } else {
                        info = String(info.dropLast(2))
                    }
                    i += 1
                    
                    if !image.confirmed {
                        imageHash = image.hash
                    }
                }
                self.testAction.isEnabled = images.count > 1 && !images[1].pending
                self.confirmAction.isEnabled = images.count > 1 && !images[1].permanent
                self.eraseAction.isEnabled = images.count > 1
            }
            self.message.text = info
            self.message.textColor = UIColor.darkGray
        } else {
            self.message.textColor = UIColor.red
            self.message.text = "\(error!)"
        }
    }
}
