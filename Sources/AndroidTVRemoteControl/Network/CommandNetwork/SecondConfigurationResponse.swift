//
//  SecondConfigurationResponse.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

struct SecondConfigurationResponse {
    private(set) var powerPart = false
    private(set) var currentAppPart = false
    private(set) var volumeLevelPart = false
    
    private(set) var runAppName: String?
    
    var modelName: String = ""
    var readyFullResponse: Bool {
        return powerPart && currentAppPart && volumeLevelPart
    }

    mutating func parse(_ data: Data) -> Bool {
        let dataArray = Array(data)
        return parse(dataArray)
    }
    
    // The data arrives in portions in arbitrary order, and we attempt to parse parts related to the current state of power,
    // the currently running application, and the volume level
    mutating func parse(_ data: [UInt8]) -> Bool {
        var result: Bool = false
        
        if !powerPart {
            powerPart = parsePowerPart(data)
            result = powerPart
        }
        
        if !currentAppPart {
            runAppName = parseCurrentApp(data)
            currentAppPart = runAppName != nil
            result = result || currentAppPart
        }
        
        if !volumeLevelPart {
            volumeLevelPart = VolumeLevel(data) != nil
            result = result || volumeLevelPart
        }
        
        return result
    }
    
    // incoming data format: [5, 194, 2, 2, 8, <unknown|0/1>]
    private func parsePowerPart(_ data: [UInt8]) -> Bool {
        let pattern: [UInt8] = [194, 2, 2, 8]
        
        guard data.count >= pattern.count else {
            return false
        }
        
        if let index = data.firstIndex(of: 194), Array(data[index..<(index + pattern.count)]) == pattern {
            return true
        }
        
        return false
    }
    
    // incoming data format: [data_length, 162, 1, sub_length, 10, sub_length, 98, runing_app_name_length, runing_app_name_string]
    // For example: [16, 162, 1, 13, 10, 11, 98, 9, 99, 111, 109, 46, 118, 107, 46, 116, 118]
    private func parseCurrentApp(_ data: [UInt8]) -> String? {
        guard let index = data.firstIndex(of: 162), index > 0 else {
            return nil
        }
        
        let length = Int(data[index - 1])
        if length < 7 {
            return nil
        }
        
        if data.count < index + length {
            return nil
        }
        
        guard data.indices.contains(index + 1), data[index + 1] == 1,
              data.indices.contains(index + 3), data[index + 3] == 10 else {
            return nil
        }
        
        guard var index = data.firstIndex(of: 98), data.indices.contains(index + 1) else {
            return nil
        }
        
        index += 1
        let appNameLength = Int(data[index])
        if data.count <= index + appNameLength {
            return nil
        }
        
        index += 1
        let appNameArray = data[index..<index + appNameLength]
        return String(data: Data(appNameArray), encoding: .utf8)
    }
}
