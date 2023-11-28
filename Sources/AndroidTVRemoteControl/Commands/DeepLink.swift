//
//  DeepLink.swift
//  
//
//  Created by Roman Odyshew on 08.11.2023.
//

import Foundation

public struct DeepLink {
    let url: String
    
    public init(_ url: String) {
        self.url = url
    }
    
    public init(_ url: URL) {
        self.url = url.absoluteString
    }
}

extension DeepLink: RequestDataProtocol {
    public var data: Data {
        var data = Data([0xd2, 0x05, UInt8(2 + url.count), 0xa, UInt8(url.count)])
        data.append(contentsOf: url.utf8)
        return data
    }
}
