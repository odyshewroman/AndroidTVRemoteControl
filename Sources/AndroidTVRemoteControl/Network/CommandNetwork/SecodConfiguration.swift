//
//  SecodConfiguration.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

extension CommandNetwork {
    struct SecondConfigurationRequest: RequestDataProtocol {
        let data = Data([0x12, 0x3, 0x8, 0xEE, 0x4])
        
        var length: UInt8 = 5
    }
}
