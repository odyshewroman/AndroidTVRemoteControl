//
//  Configuration.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

extension PairingNetwork {
    struct ConfigurationResponse {
        var length: Data?
        var data: Data?
        
        var isSuccess: Bool {
            guard length != nil, let data = data else {
                return false
            }
            
            var successArray: [UInt8] = [UInt8](ProtocolVersion2().data)
            successArray.append(contentsOf: Status.ok.data)
            successArray.append(contentsOf: [0xfa, 0x01])
            
            return data.starts(with: successArray)
        }
    }
}

extension PairingNetwork {
    struct ConfigurationRequest: RequestDataProtocol {
        let config = ParingConfiguration(clientRole: .input, encoding: ParingEncoding(symbolLength: 6, type: .hexadecimal))
        let status: Status = .ok
        let protocolVersion = ProtocolVersion2()
        
        var data: Data {
            var data = Data()
            
            data.append(protocolVersion.data)
            data.append(status.data)
            
            data.append(contentsOf: [0xf2, 0x01, config.length])
            data.append(config.data)
            
            return data
        }
    }
    
    struct ParingConfiguration {
        let clientRole: RoleType
        let encoding: ParingEncoding
        
        var data: Data {
            var data: Data = Data([0xa, encoding.length])
            data.append(encoding.data)
            data.append(contentsOf: [0x10, 0x1])
            
            return data
        }
        
        var length: UInt8 {
            return UInt8(data.count)
        }
    }
    
    enum RoleType: UInt8 {
        case unknown = 0
        case input = 1
        case output = 2
    }
}
