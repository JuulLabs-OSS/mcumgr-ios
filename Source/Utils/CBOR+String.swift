/*
* Copyright (c) 2017-2018 Runtime Inc.
*
* SPDX-License-Identifier: Apache-2.0
*/

import SwiftCBOR

extension CBOR: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .unsignedInt(let value): return "\(value)"
        case .negativeInt(let value): return "\(value)"
        case .byteString(let bytes):
            return "0x\(bytes.map { String(format: "%02X", $0) }.joined())"
        case .utf8String(let value): return "\"\(value)\""
        case .array(let array):
            return "[" + array
                .map { $0.debugDescription }
                .joined(separator: ", ") + "]"
        case .map(let map):
            return "{" + map
                .map { key, value in
                    // This will print the "rc" in human readable format.
                    if case .utf8String(let k) = key, k == "rc",
                       case .unsignedInt(let v) = value,
                       let status = McuMgrReturnCode(rawValue: v) {
                        return "\(key) : \(status)"
                    }
                    return "\(key.debugDescription) : \(value.debugDescription)"
                }
                .joined(separator: ", ") + "}"
        case .tagged(let tag, let cbor):
            return "\(tag.rawValue): \(cbor)"
        case .simple(let value): return "\(value)"
        case .boolean(let value): return "\(value)"
        case .null: return "null"
        case .undefined: return "undefined"
        case .half(let value): return "\(value)"
        case .float(let value): return "\(value)"
        case .double(let value): return "\(value)"
        case .`break`: return "break"
        #if canImport(Foundation)
        case .date(let value): return "\(value)"
        #endif
        }
    }
    
}

extension Dictionary where Key == CBOR, Value == CBOR {
    
    // This overridden description takes care of printing the "rc" (Return Code)
    // in human readable format. All other values are printed as normal.
    public var description: String {
        return "{" +
            map { key, value in
                if case .utf8String(let k) = key, k == "rc",
                   case .unsignedInt(let v) = value,
                   let status = McuMgrReturnCode(rawValue: v) {
                    return "\(key) : \(status)"
                }
                return "\(key.description) : \(value.description)"
            }
            .joined(separator: ", ")
            + "}"
    }
    
}
