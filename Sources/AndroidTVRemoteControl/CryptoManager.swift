//
//  CryptoManager.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation
import CryptoKit

public class CryptoManager {
    public var clientPublicCertificate: (() -> Result<SecKey>)?
    public var serverPublicCertificate: (() -> Result<SecKey>)?
    
    public init() {}
    
    func getEncodedCert(_ code: String) -> Result<[UInt8]> {
        if code.count != 6 {
            return .Error(.invalidCode(description: "The code should contain 6 characters"))
        }
        
        guard let firstNumber = UInt8(String(code.prefix(2)), radix: 16),
              let secondNumber = UInt8(String(code.dropFirst(2).prefix(2)), radix: 16),
              let thirdNumber = UInt8(String(code.suffix(2)), radix: 16)
        else {
            return .Error(.invalidCode(description: "The code should contain only hex characters"))
        }
        
        let codeBytes: [UInt8] = [secondNumber, thirdNumber]
        
        let clientComponents: (mod: Data, exp: Data)
        let serverComponents: (mod: Data, exp: Data)
        
        guard let clientCert = clientPublicCertificate?() else {
            return .Error(.noClientPublicCertificate)
        }
        
        guard let serverCert = serverPublicCertificate?() else {
            return .Error(.noServerPublicCertificate)
        }
        
        switch clientCert {
            case .Result(let secKey):
                switch getCertComponents(secKey) {
                    case .Result(let data):
                        clientComponents = data
                    case .Error(let error):
                        return .Error(error)
                }
            case .Error(let error):
                return .Error(error)
        }
        
        switch serverCert {
            case .Result(let secKey):
                switch getCertComponents(secKey) {
                    case .Result(let data):
                        serverComponents = data
                    case .Error(let error):
                        return .Error(error)
                }
            case .Error(let error):
                return .Error(error)
        }
        
        var shaHash = CryptoKit.SHA256()
        shaHash.update(data: clientComponents.mod)
        shaHash.update(data: clientComponents.exp)
        shaHash.update(data: serverComponents.mod)
        shaHash.update(data: serverComponents.exp)
        shaHash.update(data: Data(codeBytes))
        
        let hashData: [UInt8] = shaHash.finalize().map { $0 }
        
        guard hashData.first == firstNumber else {
            return .Error(.wrongCode)
        }
        
        return .Result(hashData)
    }
    
    private func getCertComponents(_ secKey: SecKey) -> Result<(mod: Data, exp: Data)> {
        let keyAndData: (pubData: Data, keySize: Int)
         
        switch getPublicCertData(secKey) {
        case .Result(let result):
            keyAndData = result
        case .Error(let error):
            return .Error(error)
        }
        
        let modulus  = extractModulus(keyAndData.pubData, keyAndData.keySize)
        let exponent = extractExponent(keyAndData.pubData)
        
        return .Result((mod: modulus, exp: exponent))
    }
    
    private func getPublicCertData(_ publicKey: SecKey) -> Result<(pubData: Data, keySize: Int)> {
        guard let publicKeyAttributes = SecKeyCopyAttributes(publicKey) as? [String: Any] else {
            return .Error(.noSecAttributes)
        }
        
        // Check that this is really an RSA key
        guard let keyType = publicKeyAttributes[kSecAttrKeyType as String] as? String,
                keyType == kSecAttrKeyTypeRSA as String else {
            return .Error(.notRSAKey)
        }
        
        // Check that this is really a public key
        guard let keyClass = publicKeyAttributes[kSecAttrKeyClass as String] as? String,
                keyClass == kSecAttrKeyClassPublic as String
        else {
            return .Error(.notPublicKey)
        }
        
        guard let keySize = publicKeyAttributes[kSecAttrKeySizeInBits as String] as? Int else {
            return .Error(.noKeySizeAttribute)
        }
        
        guard let pubData = publicKeyAttributes[kSecValueData as String] as? Data else {
            return .Error(.noValueData)
        }
        
        if pubData.count < 13 {
            return .Error(.invalidCertData)
        }
        
        return .Result((pubData, keySize))
    }
    
    private func extractModulus(_ publicKeyData: Data, _ keySize: Int) -> Data {
        var modulus = publicKeyData.subdata(in: 8..<(publicKeyData.count - 5))
        
        if modulus.count > keySize / 8 { // --> 257 bytes
            modulus.removeFirst(1)
        }
        
        return modulus
    }
    
    private func extractExponent(_ publicKeyData: Data) -> Data {
        return publicKeyData.subdata(in: (publicKeyData.count - 3)..<publicKeyData.count)
    }
}
