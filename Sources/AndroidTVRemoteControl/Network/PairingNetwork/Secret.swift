//
//  Secret.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

extension PairingNetwork {
    struct SecretRequest: RequestDataProtocol {
        let status: Status = .ok
        let protocolVersion = ProtocolVersion2()
        let encodedCert: [UInt8]
        
        private let unknownFields: [UInt8] = [0xc2, 0x02]
        
        var length: UInt8 {
            return UInt8(data.count)
        }
        
        var data: Data {
            var data = Data()
            
            data.append(protocolVersion.data)
            data.append(status.data)
            
            data.append(contentsOf: unknownFields)
            data.append(contentsOf: [UInt8(encodedCert.count + 2), 0xa, UInt8(encodedCert.count)])
            data.append(contentsOf: encodedCert)
            
            return data
        }
    }
}

extension PairingNetwork {
    struct SecretResponse {
        var data: Data?
        var code: String
        
        var isSuccess: Bool {
            guard let data = data, data.first == UInt8(data.count - 1) else {
                return false
            }
            
            guard code.count > 1, let firstNumber = UInt8(String(code.prefix(2)), radix: 16) else {
                return false
            }
            
            let subData: [UInt8] = [0xca, 0x02, 0x22, 0x0a]
            let subCount = data.count - 1 - ProtocolVersion2().size - Status.ok.size - subData.count - 1
            if subCount < 0 {
                return false
            }
            
            var successArray: [UInt8] = [UInt8(data.count - 1)]
            successArray.append(contentsOf: ProtocolVersion2().data)
            successArray.append(contentsOf: Status.ok.data)
            successArray.append(contentsOf: subData)
            successArray.append(contentsOf: [UInt8(subCount), firstNumber])
            
            return data.starts(with: successArray)
        }
    }
}
