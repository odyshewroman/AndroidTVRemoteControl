//
//  ViewController.swift
//  Demo
//
//  Created by Roman Odyshew on 20.10.2023.
//

import UIKit

class ViewController: UIViewController {
    private let views = Views()
    private let remoteManager = RemoteTVManager()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        remoteManager.pairingStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.views.pairingStateLabel.text = "Pairing state: " + state
                self?.views.sendCodeButton.isEnabled = state == "Waiting Code"
            }
        }
        
        remoteManager.remoteStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.views.remoteStateLabel.text = "Remote state: " + state
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        views.viewDidLoad(view)
        views.sendCodeButton.isEnabled = false
        views.connectButton.addTarget(self, action: #selector(connect), for: .touchUpInside)
        views.sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        views.runNetflixButton.addTarget(self, action: #selector(runNetflix), for: .touchUpInside)
        views.volUpButton.addTarget(self, action: #selector(volUp), for: .touchUpInside)
        views.volDownButton.addTarget(self, action: #selector(volDown), for: .touchUpInside)
    }
    
    @objc private func connect() {
        // set your Android TV device ip
        remoteManager.connect(host: "192.168.3.22")
    }
    
    @objc private func volUp() {
        remoteManager.volUp()
        print("volUp")
    }
    
    @objc private func volDown() {
        remoteManager.volDown()
        print("voldown")
    }
    
    @objc private func sendCode() {
        guard let code = views.codeTextField.text else {
            return
        }
        remoteManager.sendCode(code: code)
    }
    
    @objc private func runNetflix() {
        remoteManager.runNetflix()
    }
}
