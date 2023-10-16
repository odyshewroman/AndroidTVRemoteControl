//
//  Option.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

extension PairingNetwork {
    struct OptionRequest: RequestDataProtocol {
        let option: ParingOption
        let status: Status
        let protocolVersion = ProtocolVersion2()
        
        var data: Data {
            var data = Data()
            data.append(protocolVersion.data)
            data.append(status.data)
            
            data.append(contentsOf: [0xa2, 0x01, option.length])
            data.append(option.data)
            
            return data
        }
        
        var length: UInt8 {
            return UInt8(data.count)
        }
        
        init() {
            status = .ok
            option = ParingOption(inputEncodings: [ParingEncoding(symbolLength: 6, type: .hexadecimal)],
                                  outputEncodings: [],
                                  preferredRole: .input)
        }
    }
    
    struct OptionResponse {
        var length: Data?
        var data: Data?
        
        var isSuccess: Bool {
            guard length != nil, let data = data else {
                return false
            }

            var successArray: [UInt8] = [UInt8](ProtocolVersion2().data)
            successArray.append(contentsOf: Status.ok.data)
            successArray.append(contentsOf: [0xa2, 0x01])
            
            return data.starts(with: successArray)
        }
    }
}

extension PairingNetwork.OptionRequest {
    struct ParingOption {
        var inputEncodings: [PairingNetwork.ParingEncoding] = []
        var outputEncodings: [PairingNetwork.ParingEncoding] = []
        var preferredRole: RoleType = .input
        
        var data: Data {
            var data: Data = Data()
            
            if inputEncodings.count > 0 {
                for inputEncoding in inputEncodings {
                    data.append(contentsOf: [0xa, inputEncoding.length])
                    data.append(inputEncoding.data)
                }
            }
            
            if outputEncodings.count > 0 {
                for outputEncoding in outputEncodings {
                    data.append(contentsOf: [0x12, outputEncoding.length])
                    data.append(outputEncoding.data)
                }
            }
            
            if preferredRole.rawValue != 0 {
                data.append(contentsOf: [0x18, preferredRole.rawValue])
            }
            
            return data
        }
        
        var length: UInt8 {
            var length: UInt8 = 0
            
            if inputEncodings.count > 0 {
                for inputEncoding in inputEncodings {
                    length += 2
                    length += inputEncoding.length
                }
            }
            
            if outputEncodings.count > 0 {
                for outputEncoding in outputEncodings {
                    length += 2
                    length += outputEncoding.length
                }
            }
            
            if preferredRole.rawValue != 0 {
                length += 2
            }
            
            return length
        }
    }
    
    enum RoleType: UInt8 {
        case unknown = 0
        case input = 1
        case output = 2
    }
}
