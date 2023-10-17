# AndroidTVRemoteControl

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager)
[![CocoaPods](https://img.shields.io/cocoapods/v/YourLibraryName.svg)](https://cocoapods.org/pods/AndroidTVRemoteControl)

This project it's implementation pairing and connection to Android TV OS devices, using protovol v2, and follows the approach described here [Google TV (aka Android TV) Remote Control (v2)](https://github.com/Aymkdn/assistant-freebox-cloud/wiki/Google-TV-(aka-Android-TV)-Remote-Control-(v2)).

## Compatibility

The AndroidTVRemoteControl is supported on iOS version 14 or later and Swift 4 and above.

## Installation


### [Swift Package Manager](https://github.com/apple/swift-package-manager)

In Xcode go to: ```File -> Swift Packages -> Add Package Dependency...```

Enter the CurvedTextView GitHub repository - ```https://github.com/odyshewroman/AndroidTVRemoteControl```

Select the version

Import AndroidTVRemoteControl module and start to use AndroidTVRemoteControl

## Usage

First of all, you need a certificate to establish a TLS connection with an Android TV OS device. Since the connection is made over a local network, a self-signed certificate is suitable for this purpose.

The entire process is divided into two parts - **Pairing** and **Sending** commands (and yes, there is also an internal pairing process there).

Next, you need to create an object - CryptoManager, passing your logic for obtaining the public key of the certificate within the closure.
Then, create a TLSManager and pass the logic for obtaining a CFArray - an array containing a dictionary for every item extracted from the certificate. You also need to set a closure where you will pass the SecTrust obtained from the Android TV OS device when connecting to it to the CryptoManager.

<img src="/assets/preparing.png">

### Pairing

Now you can create a **PairingManager**, passing **TLSManager** and **CryptoManager** as parameters. Set a closure to handle the pairing process states and call the connect method. When you receive the `waitingCode` state, on the Android TV OS device screen, three hex numbers (6 characters, you can validate - user input should only contain digits 0-9 and characters A-F) will be displayed. Upon receiving a string with these characters, you need to call the `sendSecret` method on the **PairingManager**. In a successful case, you will receive the `successPaired` state.

### Remote

**Congratulations, you've successfully connected to the Android TV OS device!** If you've paired with this device before, you can skip the pairing and code input step and proceed directly to the command-sending process.

For sending commands, you'll need the **RemoteManager** object. Additionally, set up a closure to handle the connection process states and call the `connect` method. When the *connected* state is reached, you can start sending your messages to the Android TV OS device using the `send` method. In practice, sometimes devices may not respond to the specified message sequences but are already ready to accept commands. In such cases, you can use a short timeout after the connection. If the state does not change to *error* within this timeout, you can consider the device ready to receive your commands.

<img src="/assets/pairing.png">
