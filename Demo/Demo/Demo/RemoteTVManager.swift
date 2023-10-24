//
//  RemoteTVManager.swift
//  Demo
//
//  Created by Roman Odyshew on 20.10.2023.
//

import Foundation

class RemoteTVManager {
    private let queue = DispatchQueue(label: "queue")
    
    private let pairingManager: PairingManager
    private let remoteManager: RemoteManager
    
    public var pairingStateChanged: ((String)->())?
    public var remoteStateChanged: ((String)->())?
    
    init() {
        let cryptoManager = CryptoManager()
        
        cryptoManager.clientPublicCertificate = {
            guard let url = Bundle.main.url(forResource: "cert", withExtension: "der") else {
                return .Error(.loadCertFromURLError(MyError.certNotFound))
            }
            
            return CertManager().getSecKey(url)
        }
        
        let tlsManager = TLSManager {
            guard let url = Bundle.main.url(forResource: "cert", withExtension: "p12") else {
                return .Error(.loadCertFromURLError(MyError.certNotFound))
            }
            
            return CertManager().cert(url, "")
        }
        
        tlsManager.secTrustClosure = { secTrust in
            cryptoManager.serverPublicCertificate = {
                guard let publicKey = SecTrustCopyKey(secTrust) else {
                    return .Error(.secTrustCopyKeyError)
                }
                
                return .Result(publicKey)
            }
        }
        
        pairingManager = PairingManager(tlsManager, cryptoManager)
        remoteManager = RemoteManager(tlsManager, CommandNetwork.DeviceInfo("client", "iPhone", "1.0.0", "example_app", "235"))
    }
    
    func connect(host: String) {
        queue.async {
            self.remoteManager.stateChanged = { [weak self] remoteState in
                self?.remoteStateChanged?(remoteState.toString())
                
                if case .error(.connectionWaitingError) = remoteState {
                    self?.pairingManager.stateChanged = { pairingState in
                        self?.pairingStateChanged?(pairingState.toString())

                        if case .successPaired = pairingState {
                            self?.remoteManager.connect(host)
                        }
                    }
                    
                    self?.pairingManager.connect(host, "client", "iPhone")
                }
            }
            
            self.remoteManager.connect(host)
        }
    }
    
    func sendCode(code: String) {
        queue.async {
            self.pairingManager.sendSecret(code)
        }
    }
    
    func runNetflix() {
        queue.async {
            self.remoteManager.send(NetflixApp())
        }
    }
}

public enum MyError: Error {
    case certNotFound
}

struct NetflixApp: RequestDataProtocol {
    let url = "https://www.netflix.com/title"
    
    var length: UInt8 {
        return UInt8(data.count)
    }
    
    var data: Data {
        var data = Data([0xd2, 0x05, UInt8(2 + url.count), 0xa, UInt8(url.count)])
        data.append(contentsOf: url.utf8)
        
        return data
    }
}

extension RemoteManager.RemoteState {
    func toString() -> String {
        switch self {
        case .idle:
            return "idle"
        case .connectionSetUp:
            return "connection Set Up"
        case .connectionPrepairing:
            return "connection Prepairing"
        case .connected:
            return "connected"
        case .fisrtConfigMessageReceived(let info):
            return "fisrt Config Message Received: vendor: \(info.vendor) model: \(info.model)"
        case .firstConfigSent:
            return "first Config Sent"
        case .secondCofigSent:
            return "second Cofig Sent"
        case .paired(let runningApp):
            return "Paired! Current runned app " + (runningApp ?? "")
        case .error(let error):
            return "Error: " + error.toString()
        }
    }
}

extension PairingManager.PairingState {
    func toString() -> String {
        switch self {
        case .idle:
            return "idle"
        case .extractTLSparams:
            return "Extract TLS params"
        case .connectionSetUp:
            return "Connection Set Up"
        case .connectionPrepairing:
            return "Connection Prepairing"
        case .connected:
            return "Connected"
        case .pairingRequestSent:
            return "Pairing Request Sent"
        case .pairingResponseSuccess:
            return "Pairing Response Success"
        case .optionRequestSent:
            return "Option Request Sent"
        case .optionResponseSuccess:
            return "Option Response Success"
        case .confirmationRequestSent:
            return "Confirmation Request Sent"
        case .confirmationResponseSuccess:
            return "Confirmation Response Success"
        case .waitingCode:
            return "Waiting Code"
        case .secretSent:
            return "Secret Sent"
        case .successPaired:
            return "Success Paired"
        case .error(let error):
            return "Error: " + error.toString()
            
        }
    }
}

extension AndroidTVRemoteControlError {
    func toString() -> String {
        switch self {
        case .unexpectedCertData:
            return "unexpected Cert Data"
        case .extractCFTypeRefError:
            return "extract CFTypeRef Error"
        case .secIdentityCreateError:
            return "sec Identity Create Error"
        case .toLongNames(let description):
            return "to Long Names" + description
        case .connectionCanceled:
            return "connection Canceled"
        case .pairingNotSuccess:
            return "pairing Not Success"
        case .optionNotSuccess:
            return "option Not Success"
        case .configurationNotSuccess:
            return "configuration Not Success"
        case .secretNotSuccess:
            return "secret Not Success"
        case .connectionWaitingError(let error):
            return "connection Waiting Error: " + error.localizedDescription
        case .connectionFailed:
            return "connection Failed"
        case .receiveDataError:
            return "receive Data Error"
        case .sendDataError:
            return "send Data Error"
        case .invalidCode(let description):
            return "invalid Code " + description
        case .wrongCode:
            return "wrong Code"
        case .noSecAttributes:
            return "no SecAttributes"
        case .notRSAKey:
            return "not RSA Key"
        case .notPublicKey:
            return "not Public Key"
        case .noKeySizeAttribute:
            return "no Key Size Attribute"
        case .noValueData:
            return "no Value Data"
        case .invalidCertData:
            return "invalid Cert Data"
        case .createCertFromDataError:
            return "create Cert From Data Error"
        case .noClientPublicCertificate:
            return "no Client Public Certificate"
        case .noServerPublicCertificate:
            return "no Server Public Certificate"
        case .secTrustCopyKeyError:
            return "sec Trust Copy Key Error"
        case .loadCertFromURLError:
            return "load Cert From URL Error"
        case .secPKCS12ImportNotSuccess:
            return "secPKCS12Import Not Success"
        case .createTrustObjectError:
            return "create Trust Object Error"
        case .secTrustCreateWithCertificatesNotSuccess:
            return "secTrust Create With Certificates Not Success"
        }
    }
}
