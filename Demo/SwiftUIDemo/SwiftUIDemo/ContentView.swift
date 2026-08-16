import SwiftUI

class RemoteTVManagerViewModel: ObservableObject {
    private let remoteManager = RemoteTVManager()
    
    @Published var pairingState: String = "pairingStateLabel"
    @Published var remoteState: String = "remoteStateLabel"
    @Published var isCodeEntryEnabled: Bool = false
    @Published var codeText: String = ""
    @Published var ipAddress: String = "192.168.0.159" // Default IP
    
    init() {
        remoteManager.pairingStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.pairingState = "Pairing state: " + state
                self?.isCodeEntryEnabled = state == "Waiting Code"
            }
        }
        
        remoteManager.remoteStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.remoteState = "Remote state: " + state
            }
        }
    }
    
    func connect() {
        remoteManager.connect(host: ipAddress)
    }
    
    func startPairing() {
        // Make sure to disconnect before starting pairing
        disconnect()
        // Then connect to start pairing
        remoteManager.pairing(host: ipAddress)
    }
    
    func sendCode() {
        guard !codeText.isEmpty else { return }
        remoteManager.sendCode(code: codeText)
    }
    
    func runNetflix() {
        remoteManager.runNetflix()
    }
    
    func sendKey(_ key: RemoteKey) {
        remoteManager.sendKey(key)
    }
    
    func disconnect() {
        remoteManager.disconnect()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = RemoteTVManagerViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Remote Control Section
                    if viewModel.remoteState.contains("runned") || viewModel.remoteState.contains("connected") {
                        Divider()
                        remoteControlSection
                    }
                    
                    // Connection Section
                    connectionSection
                }
                .padding()
            }
            .navigationTitle("Android TV Remote")
            .background(Color.gray.opacity(0.1))
        }
    }
    
    private var connectionSection: some View {
        VStack(spacing: 16) {
            // Status Information
            statusInfoView
            
            // IP Address Field
            ipAddressEntryView
            
            // Connection Buttons
            HStack {
                // Connect Button
                Button(action: {
                    viewModel.connect()
                }) {
                    Text("Connect")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Pairing Button
                Button(action: {
                    viewModel.startPairing()
                }) {
                    Text("Pairing")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            // Code Entry Section
            if viewModel.isCodeEntryEnabled {
                codeEntryView
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var ipAddressEntryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TV IP Address")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("192.168.0.xxx", text: $viewModel.ipAddress)
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var statusInfoView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                Text(viewModel.pairingState)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Image(systemName: "tv")
                    .foregroundColor(.blue)
                Text(viewModel.remoteState)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var codeEntryView: some View {
        VStack(spacing: 16) {
            Text("Enter the code displayed on your Android TV")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Code", text: $viewModel.codeText)
                    .keyboardType(.default)
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(width: 120)
                
                Button(action: {
                    viewModel.sendCode()
                }) {
                    Text("Send")
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var remoteControlSection: some View {
        VStack(spacing: 24) {
            // Disconnect Button
            Button(action: viewModel.disconnect) {
                HStack {
                    Image(systemName: "link.badge.minus")
                    Text("Disconnect")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // D-Pad Controls
            dpadControlsView
            
            // Volume Controls
            volumeControlsView
            
            // Media Controls
            mediaControlsView
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var dpadControlsView: some View {
        VStack(spacing: 0) {
            Text("Navigation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            
            // Up Button
            HStack {
                Spacer()
                dpadButton(icon: "arrow.up", action: { viewModel.sendKey(.dpadUp) })
                Spacer()
            }
            
            // Left, Center, Right Buttons Row
            HStack(spacing: 0) {
                dpadButton(icon: "arrow.left", action: { viewModel.sendKey(.dpadLeft) })
                dpadButton(icon: "circle.fill", action: { viewModel.sendKey(.dpadCenter) })
                dpadButton(icon: "arrow.right", action: { viewModel.sendKey(.dpadRight) })
            }
            
            // Down Button
            HStack {
                Spacer()
                dpadButton(icon: "arrow.down", action: { viewModel.sendKey(.dpadDown) })
                Spacer()
            }
            
            // Home Button
            HStack {
                Spacer()
                Button(action: { viewModel.sendKey(.home) }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.orange)
                        .cornerRadius(30)
                }
                .buttonStyle(PressEffectButtonStyle())
                .padding(.top, 16)
                Spacer()
            }
        }
    }
    
    private func dpadButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .cornerRadius(30)
        }
        .buttonStyle(PressEffectButtonStyle())
        .padding(8)
    }
    
    private var volumeControlsView: some View {
        VStack(spacing: 16) {
            Text("Volume")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Button(action: { viewModel.sendKey(.volumeDown) }) {
                    HStack {
                        Image(systemName: "speaker.wave.1.fill")
                        Text("Vol -")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: { viewModel.sendKey(.volumeUp) }) {
                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                        Text("Vol +")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var mediaControlsView: some View {
        VStack(spacing: 16) {
            Text("Applications")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: viewModel.runNetflix) {
                HStack {
                    Image(systemName: "play.tv.fill")
                    Text("Netflix")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}

// Button press effect
struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
