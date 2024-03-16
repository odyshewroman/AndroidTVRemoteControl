//
//  VoiceBegin.swift
//
//
//  Created by Roman Odyshew on 16.03.2024.
//

import Foundation

public struct RemoteVoiceBegin {
    let sessionID: Int
    let remoteVoiceConfig: RemoteVoiceConfig
    
    public init(_ remoteVoiceConfig: RemoteVoiceConfig, _ sessionID: Int = -1) {
        self.remoteVoiceConfig = remoteVoiceConfig
        self.sessionID = sessionID
    }
}

extension RemoteVoiceBegin: RequestDataProtocol {
    public var data: Data {
        var data = Data([8] + Encoder.encodeSInt(sessionID) + [18] + Encoder.encodeSize(remoteVoiceConfig.data)) + remoteVoiceConfig.data
        data = Data(Encoder.encodeVarint(242) + Encoder.encodeSize(data)) + data
        
        return data
    }
}
