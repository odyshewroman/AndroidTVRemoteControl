//
//  KeyPress.swift
//  
//
//  Created by Roman Odyshew on 07.11.2023.
//

import Foundation

public struct KeyPress {
    let key: Key
    let direction: Direction
    
    init(_ key: Key, _ direction: Direction = .SHORT) {
        self.key = key
        self.direction = direction
    }
}

extension KeyPress: RequestDataProtocol {
    public var data: Data {
        let encodedKey = Encoder.encodeVarint(key.rawValue)
        var data = Data()
        data.append(contentsOf: [0x52, UInt8(3 + encodedKey.count), 0x08])
        data.append(contentsOf: encodedKey)
        data.append(contentsOf: [0x10, direction.rawValue])
        
        return data
    }
}
