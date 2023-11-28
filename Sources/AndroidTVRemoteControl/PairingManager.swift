//
//  PairingManager.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation
import Network
import CryptoKit

public class PairingManager {
    private let stateQueue = DispatchQueue(label: "pairing.state")
    private let connectQueue = DispatchQueue(label: "pairing.connect")
    
    private var pairingResponse = PairingNetwork.PairingResponse()
    private var optionResponse = PairingNetwork.OptionResponse()
    private var configResponse = PairingNetwork.ConfigurationResponse()
    
    private var connection: NWConnection?
    private var cryptoManager: CryptoManager
    private let tlsManager: TLSManager
    
    private var clientName = "client"
    private var serviceName = "service"
    private var code: String = ""
    
    public var stateChanged: ((PairingState)->())?
    
    private var pairingState: PairingState = .idle {
        didSet {
            stateQueue.async {
                self.stateChanged?(self.pairingState)
            }
        }
    }
    
    public init(_ tlsManager: TLSManager, _ cryptoManager: CryptoManager) {
        self.tlsManager = tlsManager
        self.cryptoManager = cryptoManager
    }
    
    public func connect(_ host: String, _ clientName: String, _ serviceName: String) {
        // The sum of the characters count from clientName and serviceName chould be less than 245
        guard serviceName.utf8.count + clientName.utf8.count < 244 else {
            pairingState = .error(.toLongNames(description: "The clientName and serviceName have too many characters, the combined maximum character count for these fields should be less than 244"))
            
            return
        }
        
        self.clientName = clientName
        self.serviceName = serviceName
        
        pairingState = .extractTLSparams
        
        let tlsParams: NWParameters

        switch tlsManager.getNWParams(connectQueue) {
        case .Result(let params):
            tlsParams = params
        case .Error(let error):
            pairingState = .error(error)
            return
        }
        
        connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: 6467),
            using: tlsParams)
        
        connection?.stateUpdateHandler = handleConnectionState
        connection?.start(queue: connectQueue)
    }
    
    public func disconnect() {
        connection?.stateUpdateHandler = nil
        connection?.cancel()
        connection = nil
    }
    
    public func sendSecret(_ code: String) {
        // Set the code for secret transmission
        self.code = code
        let secret: [UInt8]
        switch cryptoManager.getEncodedCert(code) {
        case .Result(let data):
            secret = data
        case .Error(let error):
            pairingState = .error(error)
            disconnect()
            return
        }
        
        send(PairingNetwork.SecretRequest(encodedCert: secret))
        pairingState = .secretSent
        
        receive()
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .setup:
            pairingState = .connectionSetUp
        case .waiting(let error):
            pairingState = .error(.connectionWaitingError(error))
            disconnect()
        case .preparing:
            pairingState = .connectionPrepairing
        case .ready:
            pairingState = .connected
            
            pairingResponse = PairingNetwork.PairingResponse()
            send(PairingNetwork.PairingRequest(clientName: clientName, serviceName: serviceName))
            pairingState = .pairingRequestSent
            
            receive()
        case .failed(let error):
            pairingState = .error(.connectionFailed(error))
            disconnect()
        case .cancelled:
            pairingState = .error(.connectionCanceled)
            disconnect()
        default:
            break
        }
    }
    
    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 256) { [weak self] (data, context, isComplete, error) in
            guard let `self` = self else { return }
            
            if let error = error {
                self.pairingState = .error(.receiveDataError(error))
                return
            }
            
            guard let data = data, !data.isEmpty, isComplete == false else {
                return
            }
            
            switch self.pairingState {
            case .pairingRequestSent:
                guard pairingResponse.length != nil else {
                    pairingResponse.length = data
                    self.receive()
                    return
                }
                
                pairingResponse.data = data
                guard pairingResponse.isSuccess else {
                    self.pairingState = .error(.pairingNotSuccess(data))
                    return
                }
                
                self.pairingState = .pairingResponseSuccess
                
                optionResponse = PairingNetwork.OptionResponse()
                send(PairingNetwork.OptionRequest())
                self.pairingState = .optionRequestSent
                self.receive()
                return
                
            case .optionRequestSent:
                guard optionResponse.length != nil else {
                    optionResponse.length = data
                    self.receive()
                    return
                }
                
                optionResponse.data = data
                guard optionResponse.isSuccess else {
                    self.pairingState = .error(.optionNotSuccess(data))
                    return
                }
                
                self.pairingState = .optionResponseSuccess
                configResponse = PairingNetwork.ConfigurationResponse()
                send(PairingNetwork.ConfigurationRequest())
                self.pairingState = .confirmationRequestSent
                self.receive()
                return
                
            case .confirmationRequestSent:
                guard configResponse.length != nil else {
                    configResponse.length = data
                    self.receive()
                    return
                }
                
                configResponse.data = data
                guard configResponse.isSuccess else {
                    self.pairingState = .error(.configurationNotSuccess(data))
                    return
                }
                
                self.pairingState = .confirmationResponseSuccess
                self.pairingState = .waitingCode
                stateChanged?(.waitingCode)
                return
            case .secretSent:
                let secretResponse = PairingNetwork.SecretResponse(data: data, code: code)
                if secretResponse.isSuccess {
                    self.pairingState = .successPaired
                }
                
                self.pairingState = secretResponse.isSuccess ? .successPaired : .error(.secretNotSuccess(data))
                self.disconnect()
            default:
                return
            }
        }
    }
    
    private func send(_ request: RequestDataProtocol) {
        send(Data(Encoder.encodeVarint(UInt(request.data.count))), request.data)
    }
    
    private func send(_ data: Data, _ nextData: Data? = nil) {
        connection?.send(content: data, completion: .contentProcessed({ [weak self] (error) in
            if let error = error {
                self?.pairingState = .error(.sendDataError(error))
                self?.disconnect()
                return
            }
            
            if let nextMessage = nextData {
                self?.send(nextMessage)
            }
        }))
    }
}

extension PairingManager {
   public enum PairingState {
        case idle
        case extractTLSparams
        case connectionSetUp
        case connectionPrepairing
        case connected
        case pairingRequestSent
        case pairingResponseSuccess
        case optionRequestSent
        case optionResponseSuccess
        case confirmationRequestSent
        case confirmationResponseSuccess
        case waitingCode
        case secretSent
        case successPaired
        case error(AndroidTVRemoteControlError)
    }
}
