//
//  VolumeLevel.swift
//  AndroidTVRemoteControl
//
//  Created by Roman Odyshew on 20.11.2023.
//

import Foundation

// incoming data format: [data_length, 146, 3, sub_length, 8, <unknown>, <unknown>(optional), 16, <sub_length|unknown>, 26, model_name_length, model_name_string, 32, <unknown|0/1/2>, 40, unknown, 48, max_volume_level, 56, current_volume_level, 64, unknown]
// Fields after '32, <unknown|0/1/2>' is otional
// example [27, 146, 3, 24, 8, 2, 16, 2, 26, 8, 65, 105, 80, 108, 117, 115, 50, 75, 32, 2, 40, 0, 48, 100, 56, 74, 64, 0]
// example [23, 146, 3, 20, 8, 50, 16, 9, 26, 12, 78, 101, 120, 117, 115, 32, 80, 108, 97, 121, 101, 114, 32, 0]
struct VolumeLevel {
    var unknown1: UInt8
    var unknown2: UInt8
    var modelName: String
    var unknown3: UInt8
    var unknown4: UInt8?
    var volumeMax: UInt8?
    var volumeLevel: UInt8?
    var unknown5: UInt8?
    
    init?(_ data: Data) {
        self.init(Array(data))
    }
    
    init?(_ data: [UInt8]) {
        guard var index = data.firstIndex(of: 146), index > 0 else {
            return nil
        }
        
        let length = Int(data[index - 1])
        
        guard length >= 12,
              data.count >= index + length
        else {
            return nil
        }
        
        index += 1
        guard data.indices.contains(index), data[index] == 3,
              data.indices.contains(index + 2), data[index + 2] == 8 else {
            return nil
        }
        
        guard data.indices.contains(index + 3) else {
            return nil
        }
        unknown1 = data[index + 3]
        
        index += 4
        if !data.indices.contains(index) || data[index] != 16 {
            index += 1
        }
        
        guard data.indices.contains(index), data[index] == 16 else {
            return nil
        }
        
        guard data.indices.contains(index + 1) else {
            return nil
        }
        unknown2 = data[index + 1]
        
        let modelNameSizeIndex = index + 3
        
        guard data.indices.contains(modelNameSizeIndex) else {
            return nil
        }
        
        let modelNameSize = Int(data[modelNameSizeIndex])
        
        guard modelNameSizeIndex + modelNameSize < data.count else {
            return nil
        }
        
        guard let modelName = String(bytes: data[modelNameSizeIndex + 1...modelNameSizeIndex + modelNameSize], encoding: .utf8) else {
            return nil
        }
        
        self.modelName = modelName
        
        index = modelNameSizeIndex + modelNameSize + 1

        guard data.indices.contains(index) && data[index] == 32 else {
            return nil
        }
        
        index += 1
        
        guard data.indices.contains(index) else {
            return nil
        }
        
        unknown3 = data[index]
        
        index += 1
        guard data.indices.contains(index), data[index] == 40 else {
            return
        }
        
        index += 1
        guard data.indices.contains(index) else {
            return
        }
        
        unknown4 = data[index]
        
        index += 1
        guard data.indices.contains(index), data[index] == 48 else {
            return
        }
        
        index += 1
        guard data.indices.contains(index) else {
            return
        }
        
        volumeMax = data[index]
        
        index += 1
        guard data.indices.contains(index), data[index] == 56 else {
            return
        }
        
        index += 1
        guard data.indices.contains(index) else {
            return
        }
        
        volumeLevel = data[index]
    }
}
