//
//  TLSManager.swift
//  
//
//  Created by Roman Odyshew on 15.10.2023.
//

import Foundation
import Network

public class TLSManager {
    public var certificateProvider: () -> Result<CFArray?>
    public var secTrustClosure: ((SecTrust)->())?
    
    public init(_ certificateProviderClosure: @escaping () -> Result<CFArray?>) {
        self.certificateProvider = certificateProviderClosure
    }
    
    func getNWParams(_ queue: DispatchQueue) -> Result<NWParameters> {
        var rawItems: CFArray?

        switch certificateProvider() {
        case .Result(let items):
            rawItems = items
        case .Error(let error):
            return .Error(error)
        }
        
        guard let items = rawItems as? Array<Dictionary<String, Any>> else {
            return .Error(.unexpectedCertData)
        }
        
        // Extract the CFTypeRef representing the SecIdentity and check that cfIdentity type is SecIdentityGetTypeID, cause we should use force unwrap
        guard let cfIdentity = items.first?[kSecImportItemIdentity as String] as? CFTypeRef,
            CFGetTypeID(cfIdentity) == SecIdentityGetTypeID() else {
            return .Error(.extractCFTypeRefError)
        }

        let clientIdentity = cfIdentity as! SecIdentity
        
        guard let secIdentity: sec_identity_t = sec_identity_create(clientIdentity) else {
            return .Error(.secIdentityCreateError)
        }
        
        let options = NWProtocolTLS.Options()
        
        sec_protocol_options_set_verify_block(options.securityProtocolOptions, { [weak self] (_, sec_trust, completionHandler) in
            let serverTrust = sec_trust_copy_ref(sec_trust).takeRetainedValue()

            self?.secTrustClosure?(serverTrust)
            
            // not check and accepr all certificates
            completionHandler(true)
        }, queue)
        

        sec_protocol_options_set_challenge_block(options.securityProtocolOptions, { (_, completionHandler) in
            completionHandler(secIdentity)
        }, queue)
        
        return .Result(NWParameters(tls: options))
    }
}
