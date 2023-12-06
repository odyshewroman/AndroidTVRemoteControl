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
    
    public var logger: Logger?
    private let logPrefix = "Pairing: "
    
    public var stateChanged: ((PairingState)->())?
    
    private var pairingState: PairingState = .idle {
        didSet {
            stateQueue.async {
                switch self.pairingState {
                case .idle:
                    self.logger?.infoLog(self.logPrefix + "idle")
                case .extractTLSparams:
                    self.logger?.infoLog(self.logPrefix + "extract TLS parameters")
                case .connectionSetUp:
                    self.logger?.infoLog(self.logPrefix + "connection set up")
                case .connectionPrepairing:
                    self.logger?.infoLog(self.logPrefix + "connection prepairing")
                case .connected:
                    self.logger?.infoLog(self.logPrefix + "connected")
                case .pairingRequestSent:
                    self.logger?.infoLog(self.logPrefix + "pairing request has been sent")
                case .pairingResponseSuccess:
                    self.logger?.infoLog(self.logPrefix + "pairing sesponse success")
                case .optionRequestSent:
                    self.logger?.infoLog(self.logPrefix + "option request sent")
                case .optionResponseSuccess:
                    self.logger?.infoLog(self.logPrefix + "option response success")
                case .confirmationRequestSent:
                    self.logger?.infoLog(self.logPrefix + "confirmation request has been sent")
                case .confirmationResponseSuccess:
                    self.logger?.infoLog(self.logPrefix + "confirmation response success")
                case .waitingCode:
                    self.logger?.infoLog(self.logPrefix + "waiting code")
                case .secretSent:
                    self.logger?.infoLog(self.logPrefix + "secret has been sent")
                case .successPaired:
                    self.logger?.infoLog(self.logPrefix + "success paired")
                case .error(let error):
                    self.logger?.errorLog(self.logPrefix + error.localizedDescription)
                }
                
                self.stateChanged?(self.pairingState)
            }
        }
    }
    
    public init(_ tlsManager: TLSManager, _ cryptoManager: CryptoManager, _ logger: Logger? = nil) {
        self.tlsManager = tlsManager
        self.cryptoManager = cryptoManager
        self.logger = logger
    }
    
    public func connect(_ host: String, _ clientName: String, _ serviceName: String) {
        if host.isEmpty {
            logger?.errorLog(logPrefix + "host shouldn't be empty!")
        }
        
        // The sum of the characters count from clientName and serviceName chould be less than 245
        guard serviceName.utf8.count + clientName.utf8.count < 244 else {
            pairingState = .error(.toLongNames(description:
                                                "The clientName and serviceName have too many characters, the combined maximum character count for these fields should be less than 244"))
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
        logger?.infoLog(logPrefix + "connecting " + host + ":6467")
        connection?.start(queue: connectQueue)
    }
    
    public func disconnect() {
        logger?.infoLog(logPrefix + "disconnect")
        connection?.stateUpdateHandler = nil
        connection?.cancel()
        connection = nil
    }
    
    public func sendSecret(_ code: String) {
        // Set the code for secret transmission
        logger?.debugLog("code: " + code)
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
            logger?.debugLog(logPrefix + "Sending pairing request")
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
                self.logger?.infoLog(self.logPrefix + "Empty or completion data received")
                return
            }
            
            self.logger?.debugLog(self.logPrefix + "recived: \(Array(data))")
            
            switch self.pairingState {
            case .pairingRequestSent:
                guard pairingResponse.length != nil else {
                    self.logger?.debugLog(self.logPrefix + "it's lentgh of pairing response")
                    pairingResponse.length = data
                    self.receive()
                    return
                }
                
                pairingResponse.data = data
                guard pairingResponse.isSuccess else {
                    self.pairingState = .error(.pairingNotSuccess(data))
                    return
                }
                
                self.logger?.debugLog(self.logPrefix + "it's pairing response data")
                self.pairingState = .pairingResponseSuccess
                
                optionResponse = PairingNetwork.OptionResponse()
                logger?.debugLog(self.logPrefix + "Sending option request")
                send(PairingNetwork.OptionRequest())
                self.pairingState = .optionRequestSent
                self.receive()
                return
                
            case .optionRequestSent:
                guard optionResponse.length != nil else {
                    self.logger?.debugLog(self.logPrefix + "it's lentgh of option response")
                    optionResponse.length = data
                    self.receive()
                    return
                }
                
                self.logger?.debugLog(self.logPrefix + "it's option response data")
                optionResponse.data = data
                guard optionResponse.isSuccess else {
                    self.pairingState = .error(.optionNotSuccess(data))
                    return
                }
                
                self.pairingState = .optionResponseSuccess
                configResponse = PairingNetwork.ConfigurationResponse()
                logger?.debugLog(self.logPrefix + "Sending configuration request")
                send(PairingNetwork.ConfigurationRequest())
                self.pairingState = .confirmationRequestSent
                self.receive()
                return
                
            case .confirmationRequestSent:
                guard configResponse.length != nil else {
                    self.logger?.debugLog(self.logPrefix + "it's lentgh of confirmation response")
                    configResponse.length = data
                    self.receive()
                    return
                }
                
                self.logger?.debugLog(self.logPrefix + "it's confirmation response data")
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
        logger?.debugLog(logPrefix + "Sending data: \(Array(data))")
        connection?.send(content: data, completion: .contentProcessed({ [weak self] (error) in
            guard let `self` = self else {
                return
            }
            
            if let error = error {
                self.pairingState = .error(.sendDataError(error))
                self.disconnect()
                return
            }
            
            self.logger?.debugLog(self.logPrefix + "Success sent")
            if let nextMessage = nextData {
                self.send(nextMessage)
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
