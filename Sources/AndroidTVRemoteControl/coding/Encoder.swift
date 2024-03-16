//
//  Encoder.swift
//  
//
//  Created by Roman Odyshew on 07.11.2023.
//

import Foundation

class Encoder {
    static func encodeVarint(_ value: UInt) -> [UInt8] {
        guard value > 127 else {
            return [UInt8(value)]
        }
        
        var encodedBytes: [UInt8] = []
        var val = value

        while val != 0 {
            var byte = UInt8(val & 0x7F)
            val >>= 7
            if val != 0 {
                byte |= 0x80
            }
            encodedBytes.append(byte)
        }

        return encodedBytes
    }
    
    static func encodeSize(_ collection: any Collection) -> [UInt8] {
        return self.encodeVarint(UInt(collection.count))
    }
    
    static func encodeSInt(_ value: Int) -> [UInt8] {
        var n = Int64(value) << 1
        if value < 0 {
            n = ~n
        }
        var bytes: [UInt8] = []
        var v = UInt64(bitPattern: n)
        while v >= 0x80 {
            let byte = UInt8(v & 0x7F | 0x80)
            bytes.append(byte)
            v >>= 7
        }
        bytes.append(UInt8(v))
        return bytes
    }
}
