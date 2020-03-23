/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

// MARK: - Log

class Log {
    
    static func log(_ level: McuMgrLogLevel, tag: String, msg: String) {
        print("\(timestamp()) \(level.rawValue)\(tag): \(msg)")
    }
    
    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
