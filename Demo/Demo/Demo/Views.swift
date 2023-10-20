//
//  Views.swift
//  Demo
//
//  Created by Roman Odyshew on 21.10.2023.
//

import Foundation
import UIKit

extension ViewController {
    class Views {
        let connectButton = UIButton()
        let codeTextField = UITextField()
        let sendCodeButton = UIButton()
        let runNetflixButton = UIButton()
        
        let pairingStateLabel = UILabel()
        let remoteStateLabel = UILabel()
        
        func viewDidLoad(_ view: UIView) {
            // Do any additional setup after loading the view.
            view.backgroundColor = .white
            view.addSubview(pairingStateLabel)
            view.addSubview(remoteStateLabel)
            view.addSubview(connectButton)
            view.addSubview(codeTextField)
            view.addSubview(sendCodeButton)
            view.addSubview(runNetflixButton)
            
            pairingStateLabel.numberOfLines = 0
            remoteStateLabel.numberOfLines = 0
            
            pairingStateLabel.translatesAutoresizingMaskIntoConstraints = false
            remoteStateLabel.translatesAutoresizingMaskIntoConstraints = false
            connectButton.translatesAutoresizingMaskIntoConstraints = false
            codeTextField.translatesAutoresizingMaskIntoConstraints = false
            sendCodeButton.translatesAutoresizingMaskIntoConstraints = false
            runNetflixButton.translatesAutoresizingMaskIntoConstraints = false
            
            pairingStateLabel.textAlignment = .center
            remoteStateLabel.textAlignment = .center
            
            connectButton.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
            connectButton.layer.cornerRadius = 8
            sendCodeButton.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
            sendCodeButton.layer.cornerRadius = 8
            runNetflixButton.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
            runNetflixButton.layer.cornerRadius = 8
            
            codeTextField.layer.borderWidth = 2.0
            codeTextField.layer.borderColor = UIColor.darkGray.cgColor
            
            NSLayoutConstraint.activate([
                pairingStateLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
                pairingStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                pairingStateLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
                pairingStateLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
                
                remoteStateLabel.topAnchor.constraint(equalTo: pairingStateLabel.bottomAnchor, constant: 30),
                remoteStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                remoteStateLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
                remoteStateLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
                
                connectButton.topAnchor.constraint(equalTo: remoteStateLabel.bottomAnchor, constant: 30),
                connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                connectButton.heightAnchor.constraint(equalToConstant: 40),
                connectButton.widthAnchor.constraint(equalToConstant: 120),
                
                codeTextField.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 30),
                codeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                codeTextField.heightAnchor.constraint(equalToConstant: 35),
                codeTextField.widthAnchor.constraint(equalToConstant: 100),
                
                sendCodeButton.topAnchor.constraint(equalTo: codeTextField.bottomAnchor, constant: 30),
                sendCodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                sendCodeButton.heightAnchor.constraint(equalToConstant: 40),
                sendCodeButton.widthAnchor.constraint(equalToConstant: 120),
                
                runNetflixButton.topAnchor.constraint(equalTo: sendCodeButton.bottomAnchor, constant: 30),
                runNetflixButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                runNetflixButton.heightAnchor.constraint(equalToConstant: 40),
                runNetflixButton.widthAnchor.constraint(equalToConstant: 120),
            ])
            
            connectButton.setTitle("Connect", for: .normal)
            codeTextField.placeholder = "Enter Code"
            sendCodeButton.setTitle("Send Code", for: .normal)

            sendCodeButton.setTitleColor(.gray, for: .disabled)
            sendCodeButton.setTitleColor(.white, for: .normal)
            runNetflixButton.setTitle("Run Netflix", for: .normal)
            
            pairingStateLabel.text = "pairingStateLabel"
            remoteStateLabel.text = "remoteStateLabel"
        }
    }
}
