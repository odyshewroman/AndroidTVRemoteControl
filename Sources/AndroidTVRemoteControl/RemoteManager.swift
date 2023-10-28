//
//  RemoteManager.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation
import Network

public class RemoteManager {
    private let stateQueue = DispatchQueue(label: "remote.state")
    private let remoteQueue = DispatchQueue(label: "remote.connect")
    private let receiveQueue = DispatchQueue(label: "remote.receive")
    
    private var connection: NWConnection?
    private let tlsManager: TLSManager
    
    private var data = Data()
    private var secondConfigurationResponse = SecondConfigurationResponse()
    
    public var stateChanged: ((RemoteState)->())?
    public var receiveData: ((Data?, Error?)->Void)?
    public var deviceInfo: CommandNetwork.DeviceInfo
    
    private var remoteState: RemoteState = .idle {
        didSet {
            stateQueue.async {
                self.stateChanged?(self.remoteState)
            }
        }
    }
    
    public init(_ tlsManager: TLSManager, _ deviceInfo: CommandNetwork.DeviceInfo) {
        self.tlsManager = tlsManager
        self.deviceInfo = deviceInfo
    }
    
    public func connect(_ host: String) {
        let tlsParams: NWParameters

        switch tlsManager.getNWParams(remoteQueue) {
        case .Result(let params):
            tlsParams = params
        case .Error(let error):
            remoteState = .error(error)
            return
        }
        
        connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: 6466),
            using: tlsParams)
        
        connection?.stateUpdateHandler = handleConnectionState
        connection?.start(queue: remoteQueue)
    }
    
    public func disconnect() {
        connection?.stateUpdateHandler = nil
        connection?.cancel()
        connection = nil
    }
    
    public func send(_ request: RequestDataProtocol) {
        send(Data([request.length]), request.data)
    }
    
    public func send(_ data: Data, _ nextData: Data? = nil) {
        connection?.send(content: data, completion: .contentProcessed({ [weak self] (error) in
            if let error = error {
                self?.remoteState = .error(.sendDataError(error))
                self?.disconnect()
                return
            }
            
            if let nextMessage = nextData {
                self?.send(nextMessage)
            }
        }))
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .setup:
            remoteState = .connectionSetUp
        case .waiting(let error):
            remoteState = .error(.connectionWaitingError(error))
            disconnect()
        case .preparing:
            remoteState = .connectionPrepairing
        case .ready:
            remoteState = .connected
            receive()
        case .failed(let error):
            remoteState = .error(.connectionFailed(error))
            disconnect()
        case .cancelled:
            remoteState = .error(.connectionCanceled)
            disconnect()
        default:
            break
        }
    }
    
    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 512) { [weak self] (data, context, isComplete, error) in
            guard let `self` = self else { return }
            
            self.receiveQueue.async {
                self.receiveData?(data, error)
            }
            
            if let error = error {
                remoteState = .error(.receiveDataError(error))
                return
            }
            
            guard let data = data, !data.isEmpty, isComplete == false else {
                self.receive()
                return
            }
            
            self.data.append(data)
            self.handleData()
        }
    }
    
    private func handleData() {
        if handlePing() {
            return
        }
        
        switch remoteState {
        case .connected:
            guard let configMessage = CommandNetwork.AndroidTVConfigurationMessage(data) else {
                receive()
                return
            }
            
            data.removeAll()
            remoteState = .fisrtConfigMessageReceived(configMessage.deviceInfo)
            
            secondConfigurationResponse.modelName = configMessage.deviceInfo.model
            
            send(CommandNetwork.FirstConfigurationRequest(deviceInfo: deviceInfo))
            remoteState = .firstConfigSent
            receive()
            
        case .firstConfigSent:
            guard CommandNetwork.FirstConfigurationResponse(data: data).isSuccess else {
                receive()
                return
            }
            
            data.removeAll()
            send(CommandNetwork.SecondConfigurationRequest())
            remoteState = .secondConfigSent
            receive()
            
        case .secondConfigSent:
            guard secondConfigurationResponse.parse(data) else {
                receive()
                return
            }
            
            data.removeAll()
            guard secondConfigurationResponse.readyFullResponse else {
                receive()
                return
            }
            
            remoteState = .paired(runningApp: secondConfigurationResponse.runAppName)
        default:
            return
        }
    }
    
    private func handlePing() -> Bool {
        guard let ping = CommandNetwork.Ping(data) else {
            return false
        }
        
        let pong = CommandNetwork.Pong(ping.val1)
        send(pong)
        data.removeAll()
        receive()
        return true
    }
}

extension RemoteManager {
    public enum RemoteState {
        case idle
        case connectionSetUp
        case connectionPrepairing
        case connected
        case fisrtConfigMessageReceived(CommandNetwork.DeviceInfo)
        case firstConfigSent
        case secondConfigSent
        case paired(runningApp: String?)
        case error(AndroidTVRemoteControlError)
    }
}
