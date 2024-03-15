//
//  VoiceConfig.swift
//
//
//  Created by Roman Odyshew on 16.03.2024.
//

import Foundation

public struct RemoteVoiceConfig {
    let audioFormat: UInt
    let channelConfig: UInt
    let sampleRate: UInt
    
    public init(_ audioFormat: UInt, _ channelConfig: UInt, _ sampleRate: UInt) {
        self.audioFormat = audioFormat
        self.channelConfig = channelConfig
        self.sampleRate = sampleRate
    }
}

extension RemoteVoiceConfig: RequestDataProtocol {
    public var data: Data {

        var data: Data = Data([8])
        data += Encoder.encodeVarint(sampleRate)
        data += [16]
        data += Encoder.encodeVarint(channelConfig)
        data += [24]
        data += Encoder.encodeVarint(audioFormat)
        
        return data
    }
}
