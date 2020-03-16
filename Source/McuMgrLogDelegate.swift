//
//  McuMgrLogDelegate.swift
//  McuManager
//
//  Created by Dinesh Harjani on 16/03/2020.
//

import Foundation

public protocol McuMgrLogDelegate: class {
    
    /// Provides the delegate with content intended to be logged.
    ///
    /// - parameter msg: The text to log.
    func log(_ msg: String)
}
