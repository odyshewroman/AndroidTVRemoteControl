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
}
