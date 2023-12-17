//
//  PairingNetwork.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

struct PairingNetwork {
    struct ProtocolVersion2 {
        let data = Data([0x08, 0x02])
        let size = 2
    }
    
    enum Status: Int {
        case unknown = 0
        case ok = 200
        case error = 400
        case badConfiguration = 401
        case badSecret = 402
        
        var data: Data {
            switch self {
            case .unknown:
                return Data()
            case .ok:
                return Data([0x10, 0xc8, 0x01])
            case .error:
                return Data([0x10, 0x90, 0x02])
            case .badConfiguration:
                return Data([0x10, 0x91, 0x02])
            case .badSecret:
                return Data([0x10, 0x92, 0x02])
            }
        }
        
        var size: Int {
            switch self {
            case .unknown:
                return 0
            default:
                return 3
            }
        }
    }
    
    enum EncodingType: UInt8 {
        case unknown = 0
        case alphanumeric = 1
        case numeric = 2
        case hexadecimal = 3
        case qrcode = 4
    }
    
    struct ParingEncoding {
        var symbolLength: UInt8
        var type: EncodingType
        
        var data: Data {
            var array: [UInt8] = []
            
            if type.rawValue != 0 {
                array = [0x08, type.rawValue]
            }
            
            if symbolLength > 0 {
                array.append(16)
                if symbolLength < 128 {
                    array.append(UInt8(symbolLength))
                } else {
                    let part2 = symbolLength / 128
                    let part1 = symbolLength - (part2 - 1) * 128
                    
                    array.append(UInt8(part1))
                    array.append(UInt8(part2))
                }
            }
            
            return Data(array)
        }
        
        var length: UInt8 {
            return UInt8(data.count)
        }
    }
}
