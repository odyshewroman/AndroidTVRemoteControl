//
//  Decoder.swift
//  
//
//  Created by Roman Odyshew on 16.12.2023.
//

import Foundation

class Decoder {
    static func decodeVarint(_ data: Data) -> (value: UInt, bytesCount: Int)? {
        return Self.decodeVarint(Array(data))
    }
    
    static func decodeVarint(_ data: [UInt8]) -> (value: UInt, bytesCount: Int)? {
        guard data.first != nil else {
            return nil
        }
        
        var shift: UInt = 0
        var value: UInt = 0
        
        for byte in data {
            value |= (UInt(byte) & 0x7f) << shift
            if byte & 0x80 == 0 {
                return (value, Int(shift) % 7 + 1)
            }
            
            shift += 7
            
            if shift > 31 {
                return nil
            }
        }
        
        return (value, Int(shift) % 7 + 1)
    }
}
