//
//  AndroidTVConfigurationMessage.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

extension CommandNetwork {
    struct AndroidTVConfigurationMessage {
        private let flags: UInt16
        let deviceInfo: DeviceInfo
        
        init?(_ data: Data) {
            guard data.count > 10 else {
                return nil
            }
            
            var flags: UInt16 = UInt16(data[5]) << 8
            flags += UInt16(data[4])

            self.flags = flags
            
            guard data[8] == 0xa,
                  let deviceInfo = DeviceInfo(Data(data.dropFirst(9))),
                  deviceInfo.length + 17 < 256 else {
                return nil
            }
            
            self.deviceInfo = deviceInfo
        }
    }
    
    struct FirstConfigurationRequest: RequestDataProtocol {
        let deviceInfo: DeviceInfo
        
        var data: Data {
            var data = Data()
            
            let length = UInt8(17 + deviceInfo.length)
            
            data.append(contentsOf: [0xa, length, 0x08, 0xEE, 0x04, 0x12, length - 5, 0xa])
            data.append(contentsOf: [UInt8(deviceInfo.model.count)])
            data.append(contentsOf: deviceInfo.model.utf8)
            data.append(contentsOf: [0x12, UInt8(deviceInfo.vendor.count)])
            data.append(contentsOf: deviceInfo.vendor.utf8)
            data.append(contentsOf: [0x18, 0x01, 0x22, UInt8(deviceInfo.appBuild.count)])
            data.append(contentsOf: deviceInfo.appBuild.utf8)
            data.append(contentsOf: [0x2a, UInt8(deviceInfo.appName.count)])
            data.append(contentsOf: deviceInfo.appName.utf8)
            data.append(contentsOf: [0x32])
            data.append(contentsOf: [UInt8(deviceInfo.version.count)])
            data.append(contentsOf: deviceInfo.version.utf8)
            
            return data
        }
        
        var length: UInt8 {
            return UInt8(data.count)
        }
    }

    public struct DeviceInfo {
        public let model: String
        public let vendor: String
        public let version: String
        public let appName: String
        public let appBuild: String
        
        var length: Int {
            return model.count + vendor.count + version.count + appBuild.count + appName.count
        }
        
        public init(_ model: String, _ vendor: String, _ version: String, _ appName: String, _ appBuild: String) {
            self.model = model
            self.vendor = vendor
            self.version = version
            self.appName = appName
            self.appBuild = appBuild
        }
        
        init?(_ data: Data) {
            let length = data.count
            var index = 0
            guard let model = Self.extractString(data, index) else {
                return nil
            }
            
            self.model = model
            
            index += 1 + model.count
            guard index < length, data[index] == 0x12 else {
                return nil
            }
            
            index += 1
            guard let vendor = Self.extractString(data, index) else {
                return nil
            }
            self.vendor = vendor
            index += 1 + vendor.count
            
            guard index + 2 < length, [data[index], data[index + 1], data[index + 2]] == [0x18, 0x1, 0x22] else {
                return nil
            }
            
            index += 3
            guard let version = Self.extractString(data, index) else {
                return nil
            }
            self.version = version
            
            index += 1 + version.count
            guard index < length, data[index] == 0x2a else {
                return nil
            }
            
            index += 1
            guard let appName = Self.extractString(data, index) else {
                return nil
            }
            self.appName = appName
            
            index += appName.count + 1
            guard index < length, data[index] == 0x32 else {
                return nil
            }
            
            index += 1
            let appBuild = Self.extractString(data, index) ?? "-1"
            self.appBuild = appBuild
        }
        
        private static func extractString(_ data: Data, _ index: Int) -> String? {
            guard data.count > index else { return nil }
            
            let size = Int(data[index])
            guard data.count > index + size else { return nil }
            
            let startIndex = index + 1
            let endIndex = startIndex + size
            let subData = data[startIndex..<endIndex]
            
            if let string = String(data: Data(subData), encoding: .utf8) {
                return string
            }
            
            return nil
        }
    }

    struct FirstConfigurationResponse {
        var data: Data
        
        var isSuccess: Bool {
            return data.starts(with: [0x02, 0x12, 0x0])
        }
    }
}
