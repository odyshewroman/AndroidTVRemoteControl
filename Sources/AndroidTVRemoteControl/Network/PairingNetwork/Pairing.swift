//
//  Pairing.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

extension PairingNetwork {
    struct PairingRequest: RequestDataProtocol {
        let clientName: String
        let serviceName: String
        
        let protocolVersion = ProtocolVersion2()
        let statusCode: Status = .ok
        
        var data: Data {
            var data = Data()
            data.append(statusCode.data)
            data.append(protocolVersion.data)
            data.append(contentsOf: [0x52])
            
            if serviceName.isEmpty && clientName.isEmpty {
                data.append(contentsOf: [0])
                return data
            }
            
            var array: [UInt8] = []
            
            if !serviceName.isEmpty {
                array.append(0xa)
                array.append(UInt8(serviceName.utf8.count))
                array.append(contentsOf: serviceName.utf8)
            }
            
            if !clientName.isEmpty {
                array.append(0x12)
                array.append(UInt8(clientName.utf8.count))
                array.append(contentsOf: clientName.utf8)
            }
            
            data.append(contentsOf: [UInt8(array.count)])
            data.append(contentsOf: array)
            return data
        }
    }
}

extension PairingNetwork {
    struct PairingResponse {
        var length: Data?
        var data: Data?
        
        var isSuccess: Bool {
            guard length != nil, let data = data else {
                return false
            }
            
            var successdData = ProtocolVersion2().data
            successdData.append(Status.ok.data)
            successdData.append(contentsOf: [0x5a, 0x0])
            return data == successdData
        }
    }
}
