//
//  Ping.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

extension CommandNetwork {
    struct Ping {
        let val1: [UInt8]
        let val2: [UInt8]
        
        init?(_ data: Data) {
            let arrayData = Array(data)
            self.init(arrayData)
        }
        
        init?(_ data: [UInt8]) {
            guard data.indices.contains(1), data[1] == 66,
                  data.indices.contains(3), data[3] == 8,
                  let index = data.suffix(from: 3).firstIndex(of: 16) else {
                return nil
            }
            
            val1 = Array(data[4..<index])
            
            guard data.count > index + 1 else {
                return nil
            }
            
            val2 = Array(data.suffix(from: index + 1))
        }
    }
}

extension CommandNetwork {
    struct Pong: RequestDataProtocol {
        var length: UInt8 {
            return UInt8(data.count)
        }
        
        let data: Data
        
        init(_ value: [UInt8]) {
            var data: [UInt8] = [74, 2, 8]
            data.append(contentsOf: value)
            data.insert(UInt8(data.count), at: 0)
            self.data = Data(data)
        }
    }
}
