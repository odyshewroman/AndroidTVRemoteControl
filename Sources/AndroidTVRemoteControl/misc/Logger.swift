//
//  Logger.swift
//  
//
//  Created by Roman Odyshew on 05.12.2023.
//

import Foundation

public protocol Logger {
    func debugLog(_ str: String)
    
    func infoLog(_ str: String)
    
    func errorLog(_ str: String)
}

public class DefaultLogger: Logger {
    public init() {}
    
    public func debugLog(_ str: String) {
        log("Debug: " + str)
    }
    
    public func infoLog(_ str: String) {
        log("Info: " + str)
    }
    
    public func errorLog(_ str: String) {
        log("Error: " + str)
    }
    
    private func log(_ str: String) {
        NSLog(str)
    }
}
