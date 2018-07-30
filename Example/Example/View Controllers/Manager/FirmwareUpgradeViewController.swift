/*
 * Copyright (c) 2018 Nordic Semiconductor ASA.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import UIKit
import McuManager

class FirmwareUpgradeViewController: UIViewController {
    
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
        let importMenu = UIDocumentMenuViewController(documentTypes: ["public.data", "public.content"], in: .import)
        importMenu.delegate = self
        importMenu.popoverPresentationController?.sourceView = firmwareUpgradeActionSelect
        present(importMenu, animated: true, completion: nil)
    }
    @IBAction func start(_ sender: UIButton) {
        selectMode(for: imageData!)
    }
    @IBAction func pause(_ sender: UIButton) {
        dfuManager.pause()
        firmwareUpgradeActionPause.isHidden = true
        firmwareUpgradeActionResume.isHidden = false
    }
    @IBAction func resume(_ sender: UIButton) {
        dfuManager.resume()
        firmwareUpgradeActionPause.isHidden = false
        firmwareUpgradeActionResume.isHidden = true
    }
    @IBAction func cancel(_ sender: UIButton) {
        dfuManager.cancel()
    }
    
    private var dfuManager: FirmwareUpgradeManager!
    var transporter: McuMgrTransport! {
        didSet {
            dfuManager = FirmwareUpgradeManager(transporter: transporter, delegate: self)
        }
    }
    
    var imageData: Data?
    
    private func selectMode(for imageData: Data) {
        let alertController = UIAlertController(title: "Select mode", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Test and confirm", style: .default) {
            action in
            self.dfuManager!.mode = .testAndConfirm
            self.startFirmwareUpgrade(imageData: imageData)
        })
        alertController.addAction(UIAlertAction(title: "Test only", style: .default) {
            action in
            self.dfuManager!.mode = .testOnly
            self.startFirmwareUpgrade(imageData: imageData)
        })
        alertController.addAction(UIAlertAction(title: "Confirm only", style: .default) {
            action in
            self.dfuManager!.mode = .confirmOnly
            self.startFirmwareUpgrade(imageData: imageData)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    
        // If the device is an ipad set the popover presentation controller
        if let presenter = alertController.popoverPresentationController {
        presenter.sourceView = self.view
        presenter.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        presenter.permittedArrowDirections = []
        }
        present(alertController, animated: true)
    }
    
    private func startFirmwareUpgrade(imageData: Data) {
        do {
            try dfuManager.start(data: imageData)
        } catch {
            print("Error reading hash: \(error)")
            firmwareUpgradeStatus.text = "ERROR"
            firmwareUpgradeActionStart.isEnabled = false
        }
    }
}

// MARK: - Firmware Upgrade Delegate
extension FirmwareUpgradeViewController: FirmwareUpgradeDelegate {
    
    func upgradeDidStart(controller: FirmwareUpgradeController) {
        firmwareUpgradeActionStart.isHidden = true
        firmwareUpgradeActionPause.isHidden = false
        firmwareUpgradeActionCancel.isHidden = false
        firmwareUpgradeActionSelect.isEnabled = false
    }
    
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState) {
        switch newState {
        case .validate:
            firmwareUpgradeStatus.text = "VALIDATING..."
        case .upload:
            firmwareUpgradeStatus.text = "UPLOADING..."
        case .test:
            firmwareUpgradeStatus.text = "TESTING..."
        case .confirm:
            firmwareUpgradeStatus.text = "CONFIRMING..."
        case .reset:
            firmwareUpgradeStatus.text = "RESETTING..."
        case .success:
            firmwareUpgradeStatus.text = "UPLOAD COMPLETE"
        default:
            firmwareUpgradeStatus.text = ""
        }
    }
    
    func upgradeDidComplete() {
        firmwareUpgradeProgress.setProgress(0, animated: false)
        firmwareUpgradeActionPause.isHidden = true
        firmwareUpgradeActionResume.isHidden = true
        firmwareUpgradeActionCancel.isHidden = true
        firmwareUpgradeActionStart.isHidden = false
        firmwareUpgradeActionStart.isEnabled = false
        firmwareUpgradeActionSelect.isEnabled = true
        imageData = nil
    }
    
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error) {
        firmwareUpgradeProgress.setProgress(0, animated: true)
        firmwareUpgradeActionPause.isHidden = true
        firmwareUpgradeActionResume.isHidden = true
        firmwareUpgradeActionCancel.isHidden = true
        firmwareUpgradeActionStart.isHidden = false
        firmwareUpgradeActionSelect.isEnabled = true
        firmwareUpgradeStatus.text = "\(error)"
    }
    
    func upgradeDidCancel(state: FirmwareUpgradeState) {
        firmwareUpgradeProgress.setProgress(0, animated: true)
        firmwareUpgradeActionPause.isHidden = true
        firmwareUpgradeActionResume.isHidden = true
        firmwareUpgradeActionCancel.isHidden = true
        firmwareUpgradeActionStart.isHidden = false
        firmwareUpgradeActionSelect.isEnabled = true
        firmwareUpgradeStatus.text = "CANCELLED"
    }
    
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        firmwareUpgradeProgress.setProgress(Float(bytesSent) / Float(imageSize), animated: true)
    }
}

// MARK: - Document Picker
extension FirmwareUpgradeViewController: UIDocumentMenuDelegate, UIDocumentPickerDelegate {
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if let data = dataFrom(url: url) {
            firmwareUpgradeFileName.text = url.lastPathComponent
            firmwareUpgradeFileSize.text = "\(data.count) bytes"
            
            do {
                let hash = try McuMgrImage(data: data).hash
                
                imageData = data
                firmwareUpgradeFileHash.text = hash.hexEncodedString(options: .upperCase)
                firmwareUpgradeStatus.text = "READY"
                firmwareUpgradeActionStart.isEnabled = true
            } catch {
                print("Error reading hash: \(error)")
                firmwareUpgradeFileHash.text = ""
                firmwareUpgradeStatus.text = "INVALID FILE"
                firmwareUpgradeActionStart.isEnabled = false
            }
        }
    }
    
    /// Get the image data from the document URL
    private func dataFrom(url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
}
