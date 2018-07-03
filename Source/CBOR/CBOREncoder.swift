/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

let isBigEndian = Int(bigEndian: 42) == 42

/**
 Takes a value breaks it into bytes. Assumes necessity to reverse for endianness
 if needed This function has only been tested with UInt_s, Floats and Doubles
 T must be a simple type. It cannot be a collection type.
 */
func rawBytes<T>(of x: T) -> [UInt8] {
    let size = MemoryLayout<T>.size
    let bigendian_res = UnsafePointer<T>([x]).withMemoryRebound(to: UInt8.self, capacity: size, { ptr in
        return (0..<size).map { (ptr + $0).pointee }
    })
    return isBigEndian ? bigendian_res : bigendian_res.reversed()
}

/// Defines basic CBOR.encode API.
/// Defines more fine-grained functions of form CBOR.encode*(_ x)
/// for all CBOR types except Float16.
extension CBOR {

    public static func encode<T: CBOREncodable>(_ value: T) -> [UInt8] {
        return value.encode()
    }

    /// Encodes an array as either a CBOR array type or a CBOR bytestring type,
    /// depending on `asByteString`. NOTE: when `asByteString` is true and
    /// T = UInt8, the array is interpreted in network byte order Arrays with
    /// values of all other types will have their bytes reversed if the system
    /// is little endian.
    public static func encode<T: CBOREncodable>(_ array: [T], asByteString: Bool = false) -> [UInt8] {
        if asByteString {
            let length = array.count
            var res = length.encode()
            res[0] = res[0] | 0b010_00000
            let itemSize = MemoryLayout<T>.size
            let bytelength = length * itemSize
            res.reserveCapacity(res.count + bytelength)

            let noReversalNeeded = isBigEndian || T.self == UInt8.self
            UnsafePointer<T>(array).withMemoryRebound(to: UInt8.self, capacity: bytelength, { ptr in
                var j = 0
                for i in 0..<bytelength {
                    j = noReversalNeeded ? i : bytelength - 1 - i
                    res.append((ptr + j).pointee)
                }
            })
            return res
        } else {
            return encodeArray(array)
        }
    }

    public static func encode<A: CBOREncodable, B: CBOREncodable>(_ dict: [A: B]) -> [UInt8] {
        return encodeMap(dict)
    }
    
    // major 0: unsigned integer
    public static func encodeUInt8(_ x: UInt8) -> [UInt8] {
        if (x < 24) { return [x] }
        else { return [0x18, x] }
    }
    
    public static func encodeUInt16(_ x: UInt16) -> [UInt8] {
        return [0x19] + rawBytes(of: x)
    }
    
    public static func encodeUInt32(_ x: UInt32) -> [UInt8] {
        return [0x1a] + rawBytes(of: x)
    }
    
    public static func encodeUInt64(_ x: UInt64) -> [UInt8] {
        return [0x1b] + rawBytes(of: x)
    }
    
    // major 1: negative integer
    public static func encodeNegativeInt(_ x: Int) -> [UInt8] {
        assert(x < 0)
        var res = Int(-x - 1).encode()
        let c = res.count
        switch c {
        case 1: res[0] = 0b001_00000 | res[0]
        case 2: res[0] = 0x38
        case 3: res[0] = 0x39
        case 5: res[0] = 0x3a
        case 9: res[0] = 0x3b
        default: assert(false)
        }
        return res
    }
    
    // major 2: bytestring
    public static func encodeByteString(_ bs: [UInt8]) -> [UInt8] {
        var res = bs.count.encode()
        res[0] = res[0] | 0b010_00000
        res.append(contentsOf: bs)
        return res
    }
    
    // major 3: UTF8 string
    public static func encodeString(_ str: String) -> [UInt8] {
        let utf8array = Array(str.utf8)
        var res = utf8array.count.encode()
        res[0] = res[0] | 0b011_00000
        res.append(contentsOf: utf8array)
        return res
    }
    
    // major 4: array of data items
    public static func encodeArray<T: CBOREncodable>(_ arr: [T]) -> [UInt8] {
        var res = arr.count.encode()
        res[0] = res[0] | 0b100_00000
        res.append(contentsOf: arr.flatMap{ return $0.encode() })
        return res
    }
    
    // major 5: a map of pairs of data items
    public static func encodeMap<A: CBOREncodable, B: CBOREncodable>(_ map: [A: B]) -> [UInt8] {
        var res: [UInt8] = []
        res.reserveCapacity(1 + map.count * (MemoryLayout<A>.size + MemoryLayout<B>.size + 2))
        res = map.count.encode()
        res[0] = res[0] | 0b101_00000
        for (k,v) in map {
            res.append(contentsOf: k.encode())
            res.append(contentsOf: v.encode())
        }
        return res
    }
    
    // major 6:
    // TODO: tagging typechecks etc.
    public static func encodeTagged<T: CBOREncodable>(tag: UInt8, value: T) -> [UInt8] {
        return [0b110_00000 | tag] + value.encode()
    }
    
    // major 7: floats, simple values, the 'break' stop code
    public static func encodeSimpleValue(_ x: UInt8) -> [UInt8] {
        if x < 24 {
            return [0b111_00000 | x]
        } else {
            return [0xf8, x]
        }
    }
    
    public static func encodeNull() -> [UInt8] {
        return [0xf6]
    }
    
    public static func encodeUndefined() -> [UInt8] {
        return [0xf7]
    }
    
    public static func encodeBreak() -> [UInt8] {
        return [0xff]
    }
    
    public static func encodeFloat(_ x: Float) -> [UInt8] {
        return [0xfa] + rawBytes(of: x)
    }
    
    public static func encodeDouble(_ x: Double) -> [UInt8] {
        return [0xfb] + rawBytes(of: x)
    }
    
    public static func encodeBool(_ x: Bool) -> [UInt8] {
        return x ? [0xf5] : [0xf4]
    }

    // -----------------------
    // Indefinite length items

    /// Returns a CBOR value indicating the opening of an indefinite-length data item.
    /// The user is responsible for creating and sending subsequent valid CBOR.
    /// In particular, the user must end the stream with the CBOR.break byte, which
    /// can be returned with `encodeStreamEnd()`.
    ///
    /// The stream API is limited right now, but will get better when Swift allows
    /// one to generically constrain the elements of generic Iterators, in which case
    /// streaming implementation is trivial
    public static func encodeArrayStreamStart() -> [UInt8] {
        return [0x9f]
    }

    public static func encodeMapStreamStart() -> [UInt8] {
        return [0xbf]
    }

    public static func encodeStringStreamStart() -> [UInt8] {
        return [0x7f]
    }

    public static func encodeByteStringStreamStart() -> [UInt8] {
        return [0x5f]
    }

    /// This is the same as a CBOR "break" value
    public static func encodeStreamEnd() -> [UInt8] {
        return [0xff]
    }

    //TODO: unify definite and indefinite code
    public static func encodeArrayChunk<T: CBOREncodable>(_ chunk: [T]) -> [UInt8] {
        var res: [UInt8] = []
        res.reserveCapacity(chunk.count * MemoryLayout<T>.size)
        res.append(contentsOf: chunk.flatMap{ return $0.encode() })
        return res
    }

    public static func encodeMapChunk<A: CBOREncodable, B: CBOREncodable>(_ map: [A: B]) -> [UInt8] {
        var res: [UInt8] = []
        let count = map.count
        res.reserveCapacity(count * MemoryLayout<A>.size + count * MemoryLayout<B>.size)
        for (k, v) in map {
            res.append(contentsOf: k.encode())
            res.append(contentsOf: v.encode())
        }
        return res
    }
}
