//
//  CertManager.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation

class CertManager {
    func cert(_ url: URL, _ password: String) -> Result<CFArray?> {
        let p12Data: Data
        do {
            p12Data = try Data(contentsOf: url)
        } catch let error {
            return .Error(.loadCertFromURLError(error))
        }
        
        let importOptions = [kSecImportExportPassphrase as String: password]
        var rawItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, importOptions as CFDictionary, &rawItems)
        
        guard status == errSecSuccess else {
            return .Error(.secPKCS12ImportNotSuccess)
        }
        
        return .Result(rawItems)
    }
    
    func getSecKey(_ url: URL) -> Result<SecKey> {
        guard let certificateData = NSData(contentsOf:url),
              let certificate = SecCertificateCreateWithData(nil, certificateData) else {
            return .Error(.createCertFromDataError)
        }
        
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        guard status == errSecSuccess else {
            return .Error(.secTrustCreateWithCertificatesNotSuccess(status))
        }
 
        guard let secTrust = trust else {
            return (.Error(.createTrustObjectError))
        }
        
        guard let key = SecTrustCopyKey(secTrust) else {
            return .Error(.secTrustCopyKeyError)
        }
        
        return .Result(key)
    }
}
