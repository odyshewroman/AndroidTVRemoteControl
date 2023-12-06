//
//  Errors.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

public enum AndroidTVRemoteControlError {
    // TLS Error
    case unexpectedCertData
    case extractCFTypeRefError
    case secIdentityCreateError
    
    // Connecting Errors
    case toLongNames(description: String)
    case connectionCanceled
    case pairingNotSuccess(Data)
    case optionNotSuccess(Data)
    case configurationNotSuccess(Data)
    case secretNotSuccess(Data)
    case connectionWaitingError(Error)
    case connectionFailed(Error)
    case receiveDataError(Error)
    case sendDataError(Error)
    
    // Crypto Errors
    case invalidCode(description: String)
    case wrongCode
    case noSecAttributes
    case notRSAKey
    case notPublicKey
    case noKeySizeAttribute
    case noValueData
    case invalidCertData
    
    // Certificate Errors
    case createCertFromDataError
    case noClientPublicCertificate
    case noServerPublicCertificate
    case secTrustCopyKeyError
    case loadCertFromURLError(Error)
    case secPKCS12ImportNotSuccess
    case createTrustObjectError
    case secTrustCreateWithCertificatesNotSuccess(OSStatus)
}

extension AndroidTVRemoteControlError: Error {
    public var localizedDescription: String {
        switch self {
        case .unexpectedCertData:
            return "TLS Error: Unexpected Cert Data"
        case .extractCFTypeRefError:
            return "TLS Error: Extract CFTypeRef Error"
        case .secIdentityCreateError:
            return "TLS Error: SecIdentity Create Error"
        case .toLongNames(let description):
            return "Connection Error: To Long Names - " + description
        case .connectionCanceled:
            return "Connection Error: connection was canceled"
        case .pairingNotSuccess(let data):
            return "Connection Error: Pairing Not Success, data: \(Array(data))"
        case .optionNotSuccess(let data):
            return "Connection Error: option respponse is not success, data: \(Array(data))"
        case .configurationNotSuccess(let data):
            return "Connection Error: configuration not success, data: \(Array(data))"
        case .secretNotSuccess(let data):
            return "Connection Error: secret not success, data: \(Array(data))"
        case .connectionWaitingError(let error):
            return "Connection Error: connection waiting error: " + error.localizedDescription
        case .connectionFailed(let error):
            return "Connection Error: connection failed - " + error.localizedDescription
        case .receiveDataError(let error):
            return "Connection Error: receive data error - " + error.localizedDescription
        case .sendDataError(let error):
            return "Connection Error: send data error - " + error.localizedDescription
        case .invalidCode(let description):
            return "Crypto Error: invaid code - " + description
        case .wrongCode:
            return "Crypto Error: wrong code"
        case .noSecAttributes:
            return "Crypto Error: no SecAttributes"
        case .notRSAKey:
            return "Crypto Error: no RSAKey"
        case .notPublicKey:
            return "Crypto Error: no PublicKey"
        case .noKeySizeAttribute:
            return "Crypto Error: no KeySizeAttribute"
        case .noValueData:
            return "Crypto Error: no ValueData"
        case .invalidCertData:
            return "Crypto Error: invalid cert data"
        case .createCertFromDataError:
            return "Certificate Error: create cert from data error"
        case .noClientPublicCertificate:
            return "Certificate Error: no client public certificate"
        case .noServerPublicCertificate:
            return "Certificate Error: no server public certificate"
        case .secTrustCopyKeyError:
            return "Certificate Error: secTrustCopyKey Error"
        case .loadCertFromURLError(let error):
            return "Certificate Error: load cert from URL error - " + error.localizedDescription
        case .secPKCS12ImportNotSuccess:
            return "Certificate Error: secPKCS12Import is not success"
        case .createTrustObjectError:
            return "Certificate Error: create secTrust error"
        case .secTrustCreateWithCertificatesNotSuccess(let status):
            return "Certificate Error: secTrust create with certificate is not success, status: \(status)"
        }
    }
}
