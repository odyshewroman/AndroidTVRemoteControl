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
