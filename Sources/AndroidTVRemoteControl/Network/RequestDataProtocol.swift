//
//  RequestDataProtocol.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

protocol RequestDataProtocol {
    var data: Data { get }
    var length: UInt8 { get }
}
