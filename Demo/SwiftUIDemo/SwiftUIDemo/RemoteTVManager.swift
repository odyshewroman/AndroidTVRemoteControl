//
//  RemoteTVManager.swift
//  Demo
//
//

import Foundation

enum RemoteKey {
    case volumeUp
    case volumeDown
    case dpadUp
    case dpadDown
    case dpadLeft
    case dpadRight
    case dpadCenter
    case home
    case back
    case menu
    
    var keycode: Key {
        switch self {
        case .volumeUp:
            return .KEYCODE_VOLUME_UP
        case .volumeDown:
            return .KEYCODE_VOLUME_DOWN
        case .dpadUp:
            return .KEYCODE_DPAD_UP
        case .dpadDown:
            return .KEYCODE_DPAD_DOWN
        case .dpadLeft:
            return .KEYCODE_DPAD_LEFT
        case .dpadRight:
            return .KEYCODE_DPAD_RIGHT
        case .dpadCenter:
            return .KEYCODE_DPAD_CENTER
        case .home:
            return .KEYCODE_HOME
        case .back:
            return .KEYCODE_BACK
        case .menu:
            return .KEYCODE_MENU
        }
    }
}

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
            
            return CertManager().cert(url, "azerty")
        }
        
        tlsManager.secTrustClosure = { secTrust in
            cryptoManager.serverPublicCertificate = {
                if #available(iOS 14.0, *) {
                    guard let key = SecTrustCopyKey(secTrust) else {
                        return .Error(.secTrustCopyKeyError)
                    }
                    return .Result(key)
                } else {
                    guard let key = SecTrustCopyPublicKey(secTrust) else {
                        return .Error(.secTrustCopyKeyError)
                    }
                    return .Result(key)
                }
            }
        }
        
        pairingManager = PairingManager(tlsManager, cryptoManager, DefaultLogger())
        remoteManager = RemoteManager(tlsManager, CommandNetwork.DeviceInfo("client", "iPhone", "1.0.0", "example_app", "235"), DefaultLogger())
    }
    
    func pairing(host: String) {
        queue.async {
            self.pairingManager.stateChanged = { [weak self] state in
                self?.pairingStateChanged?(state.toString())
            }
            
            self.pairingManager.connect(host, "TV Remote", "iPhone")
        }
    }
    
    func connect(host: String) {
        queue.async {
            self.remoteManager.disconnect()
            self.pairingManager.disconnect()
            
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
            self.remoteManager.send(DeepLink("https://www.netflix.com/title"))
        }
    }
    
    func sendKey(_ key: RemoteKey) {
        queue.async {
            self.remoteManager.send(KeyPress(key.keycode))
        }
    }
    
    func disconnect() {
        queue.async {
            self.pairingManager.disconnect()
            self.remoteManager.disconnect()
            self.pairingStateChanged?("idle")
            self.remoteStateChanged?("idle")
        }
    }
}

public enum MyError: Error {
    case certNotFound
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
        case .secondConfigSent:
            return "second Config Sent"
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
