/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetooth

public class FileSystemManager: McuManager {
    private static let TAG = "FileSystemManager"
    
    //**************************************************************************
    // MARK: FS Constants
    //**************************************************************************
    
    // Mcu File System Manager ids
    let ID_FILE        =  UInt8(0)
    
    //**************************************************************************
    // MARK: Initializers
    //**************************************************************************
    
    public init(transporter: McuMgrTransport) {
        super.init(group: .fs, transporter: transporter)
    }
    
    //**************************************************************************
    // MARK: File System Commands
    //**************************************************************************

    /// Sends the next packet of data from given offset.
    /// To send a complete file, use upload(name:data:delegate) method instead.
    ///
    /// - parameter name: The file name.
    /// - parameter data: The file data.
    /// - parameter offset: The offset from this data will be sent.
    /// - parameter callback: The callback.
    public func upload(name: String, data: Data, offset: UInt, callback: @escaping McuMgrCallback<McuMgrFsUploadResponse>) {
        // Calculate the number of remaining bytes.
        let remainingBytes: UInt = UInt(data.count) - offset
        
        // Data length to end is the minimum of the max data lenght and the
        // number of remaining bytes.
        let packetOverhead = calculatePacketOverhead(name: name, data: data, offset: offset)
        
        // Get the length of file data to send.
        let maxDataLength: UInt = UInt(mtu) - UInt(packetOverhead)
        let dataLength: UInt = min(maxDataLength, remainingBytes)
        
        // Build the request payload.
        var payload: [String:CBOR] = ["name": CBOR.utf8String(name),
                                      "data": CBOR.byteString([UInt8](data[offset..<(offset+dataLength)])),
                                      "off": CBOR.unsignedInt(offset)]
        
        // If this is the initial packet, send the file data length.
        if offset == 0 {
            payload.updateValue(CBOR.unsignedInt(UInt(data.count)), forKey: "len")
        }
        // Build request and send.
        send(op: .write, commandId: ID_FILE, payload: payload, callback: callback)
    }
    
    /// Begins the file upload to a peripheral.
    ///
    /// An instance of FileSystemManager can only have one upload in progress at a
    /// time. Therefore, if this method is called multiple times on the same
    /// FileSystemManager instance, all calls after the first will return false.
    /// Upload progress is reported asynchronously to the delegate provided in
    /// this method.
    ///
    /// - parameter name: The file name.
    /// - parameter data: The file data to be sent to the peripheral.
    /// - parameter peripheral: The BLE periheral to send the data to. The
    ///   peripneral must be supplied so FileSystemManager can determine the MTU and
    ///   thus the number of bytes of file data that it can send per packet.
    /// - parameter delegate: The delegate to recieve progress callbacks.
    ///
    /// - returns: True if the upload has started successfully, false otherwise.
    public func upload(name: String, data: Data, delegate: FileUploadDelegate) -> Bool {
        // Make sure two uploads cant start at once.
        objc_sync_enter(self)
        // If upload is already in progress or paused, do not continue.
        if uploadState == .none {
            // Set upload flag to true.
            uploadState = .uploading
        } else {
            Log.d(FileSystemManager.TAG, msg: "A file upload is already in progress")
            return false
        }
        objc_sync_exit(self)
        
        // Set upload delegate.
        uploadDelegate = delegate
        
        // Set file data.
        fileName = name
        fileData = data
        
        upload(name: name, data: fileData!, offset: 0, callback: uploadCallback)
        return true
    }
    
    //**************************************************************************
    // MARK: Image Upload
    //**************************************************************************
    
    /// Image upload states
    public enum UploadState: UInt8 {
        case none = 0
        case uploading = 1
        case downloading = 2
        case paused = 3
    }
    
    /// State of the file upload.
    private var uploadState: UploadState = .none
    /// Current file byte offset to send from.
    private var offset: UInt = 0
    
    /// The file name.
    private var fileName: String?
    /// Contains the file data to send to the device.
    private var fileData: Data?
    /// Delegate to send file upload updates to.
    private var uploadDelegate: FileUploadDelegate?
    
    /// Cancels the current upload.
    ///
    /// If an error is supplied, the delegate's didFailUpload method will be
    /// called with the Upload Error provided.
    ///
    /// - parameter error: The optional upload error which caused the
    ///   cancellation. This error (if supplied) is used as the argument for the
    ///   delegate's didFailUpload method.
    public func cancelUpload(error: Error? = nil) {
        objc_sync_enter(self)
        let state = uploadState
        resetUploadVariables()
        if error != nil {
            Log.d(FileSystemManager.TAG, msg: "Upload cancelled due to error: \(error!)")
            uploadDelegate?.uploadDidFail(with: error!)
        } else {
            Log.d(FileSystemManager.TAG, msg: "Upload cancelled!")
            if state == .none {
                print("There is no file upload currently in progress.")
            } else if state == .paused {
                uploadDelegate?.uploadDidCancel()
            }
        }
        uploadDelegate = nil
        objc_sync_exit(self)
    }
    
    /// Pauses the current upload. If there is no upload in progress, nothing
    /// happens.
    public func pauseUpload() {
        objc_sync_enter(self)
        if uploadState == .none {
            Log.d(FileSystemManager.TAG, msg: "Upload is not in progress and therefore cannot be paused")
        } else {
            Log.d(FileSystemManager.TAG, msg: "Upload paused")
            uploadState = .paused
        }
        objc_sync_exit(self)
    }
    
    /// Continues a paused upload. If the upload is not paused or not uploading,
    /// nothing happens.
    public func continueUpload() {
        objc_sync_enter(self)
        guard let fileData = fileData else {
            if uploadState != .none {
                cancelUpload(error: ImageUploadError.invalidData)
            }
            return
        }
        if uploadState == .paused {
            Log.d(FileSystemManager.TAG, msg: "Continuing upload from \(offset)/\(fileData.count)")
            uploadState = .uploading
            upload(name: fileName!, data: fileData, offset: offset, callback: uploadCallback)
        } else {
            print("Upload has not been previously paused");
        }
        objc_sync_exit(self)
    }
    
    // MARK: - File Upload Private Methods
    
    private lazy var uploadCallback: McuMgrCallback<McuMgrFsUploadResponse> = {
        [unowned self] (response: McuMgrFsUploadResponse?, error: Error?) in
        // Check for an error.
        if let error = error {
            if case let McuMgrTransportError.insufficientMtu(newMtu) = error {
                if !self.setMtu(newMtu) {
                    self.cancelUpload(error: error)
                } else {
                    self.restartUpload()
                }
                return
            }
            self.cancelUpload(error: error)
            return
        }
        // Make sure the file data is set.
        guard let fileData = self.fileData else {
            self.cancelUpload(error: FileUploadError.invalidData)
            return
        }
        // Make sure the response is not nil.
        guard let response = response else {
            self.cancelUpload(error: FileUploadError.invalidPayload)
            return
        }
        // Check for an error return code.
        guard response.isSuccess() else {
            self.cancelUpload(error: FileUploadError.mcuMgrErrorCode(response.returnCode))
            return
        }
        // Get the offset from the response.
        if let offset = response.off {
            // Set the file upload offset.
            self.offset = offset
            self.uploadDelegate?.uploadProgressDidChange(bytesSent: Int(offset), fileSize: fileData.count, timestamp: Date())
            
            if self.uploadState == .none {
                self.resetUploadVariables()
                self.uploadDelegate?.uploadDidCancel()
                self.uploadDelegate = nil
                return
            }
            
            // Check if the upload has completed.
            if offset == fileData.count {
                self.resetUploadVariables()
                self.uploadDelegate?.uploadDidFinish()
                self.uploadDelegate = nil
                return
            }
            
            // Send the next packet of data.
            self.sendNext(from: offset)
        } else {
            self.cancelUpload(error: ImageUploadError.invalidPayload)
        }
    }
    
    private func sendNext(from offset: UInt) {
        if uploadState != .uploading {
            return
        }
        upload(name: fileName!, data: fileData!, offset: offset, callback: uploadCallback)
    }
    
    private func resetUploadVariables() {
        objc_sync_enter(self)
        // Reset upload state.
        uploadState = .none
        
        // Deallocate and nil file data pointers.
        fileData = nil
        fileName = nil
        
        // Reset upload vars.
        offset = 0
        objc_sync_exit(self)
    }
    
    private func restartUpload() {
        objc_sync_enter(self)
        guard let fileName = fileName, let fileData = fileData, let uploadDelegate = uploadDelegate else {
            Log.e(FileSystemManager.TAG, msg: "Could not restart upload: file data or callback is null")
            return
        }
        let tempName = fileName
        let tempData = fileData
        let tempDelegate = uploadDelegate
        resetUploadVariables()
        _ = upload(name: tempName, data: tempData, delegate: tempDelegate)
        objc_sync_exit(self)
    }
    
    private func calculatePacketOverhead(name: String, data: Data, offset: UInt) -> Int {
        // Get the Mcu Manager header.
        var payload: [String:CBOR] = ["name": CBOR.utf8String(name),
                                      "data": CBOR.byteString([UInt8]([0])),
                                      "off": CBOR.unsignedInt(offset)]
        // If this is the initial packet we have to include the length of the
        // entire file.
        if offset == 0 {
            payload.updateValue(CBOR.unsignedInt(UInt(data.count)), forKey: "len")
        }
        // Build the packet and return the size.
        let packet = buildPacket(op: .write, flags: 0, group: group, sequenceNumber: 0, commandId: ID_FILE, payload: payload)
        var packetOverhead = packet.count + 5
        if transporter.getScheme().isCoap() {
            // Add 25 bytes to packet overhead estimate for the CoAP header.
            packetOverhead = packetOverhead + 25
        }
        return packetOverhead
    }
}

public enum FileUploadError: Error {
    /// Response payload values do not exist.
    case invalidPayload
    /// File Data is nil.
    case invalidData
    /// McuMgrResponse contains a error return code.
    case mcuMgrErrorCode(McuMgrReturnCode)
}

extension FileUploadError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .invalidPayload:
            return "Response payload values do not exist."
        case .invalidData:
            return "File data is nil."
        case .mcuMgrErrorCode(let code):
            return "\(code)"
        }
    }
}

//******************************************************************************
// MARK: File Upload Delegate
//******************************************************************************

public protocol FileUploadDelegate {
    
    /// Called when a packet of file data has been sent successfully.
    ///
    /// - parameter bytesSent: The total number of file bytes sent so far.
    /// - parameter fileSize:  The overall size of the file being uploaded.
    /// - parameter timestamp: The time this response packet was received.
    func uploadProgressDidChange(bytesSent: Int, fileSize: Int, timestamp: Date)
    
    /// Called when an file upload has failed.
    ///
    /// - parameter error: The error that caused the upload to fail.
    func uploadDidFail(with error: Error)
    
    /// Called when the upload has been cancelled.
    func uploadDidCancel()
    
    /// Called when the upload has finished successfully.
    func uploadDidFinish()
}
