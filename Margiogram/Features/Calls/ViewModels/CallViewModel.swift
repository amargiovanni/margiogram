//
//  CallViewModel.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Call ViewModel

@Observable
@MainActor
final class CallViewModel {
    // MARK: - Properties

    var callState: CallState = .idle
    var callType: CallType = .audio
    var duration: TimeInterval = 0

    // Participants
    var localUser: User?
    var remoteUser: User?
    var participants: [CallParticipant] = []

    // Media State
    var isMuted: Bool = false
    var isSpeakerOn: Bool = false
    var isVideoEnabled: Bool = false
    var isFrontCamera: Bool = true

    // UI State
    var showControls: Bool = true
    var isMinimized: Bool = false
    var showParticipants: Bool = false
    var error: Error?

    // Signal Quality
    var signalQuality: SignalQuality = .excellent
    var networkType: String = "WiFi"

    // MARK: - Private Properties

    private var durationTimer: Timer?
    private var callId: Int64?

    // MARK: - Computed Properties

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var stateTitle: String {
        switch callState {
        case .idle:
            return ""
        case .ringing:
            return "Ringing..."
        case .connecting:
            return "Connecting..."
        case .connected:
            return formattedDuration
        case .reconnecting:
            return "Reconnecting..."
        case .ended:
            return "Call Ended"
        case .failed:
            return "Call Failed"
        }
    }

    var isCallActive: Bool {
        callState == .ringing || callState == .connecting || callState == .connected || callState == .reconnecting
    }

    // MARK: - Call Actions

    func startCall(to user: User, type: CallType) async {
        remoteUser = user
        callType = type
        callState = .ringing
        isVideoEnabled = type == .video

        // In real implementation: create call via TDLib
        #if DEBUG
        // Simulate call connection
        try? await Task.sleep(for: .seconds(2))
        await acceptCall()
        #endif
    }

    func acceptCall() async {
        callState = .connecting

        // In real implementation: accept incoming call via TDLib
        #if DEBUG
        try? await Task.sleep(for: .seconds(1))
        startConnectedState()
        #endif
    }

    func rejectCall() {
        callState = .ended
        cleanup()
    }

    func endCall() {
        callState = .ended
        // In real implementation: discard call via TDLib
        cleanup()
    }

    // MARK: - Media Controls

    func toggleMute() {
        isMuted.toggle()
        // In real implementation: mute/unmute audio
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        // In real implementation: switch audio output
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if isSpeakerOn {
                try audioSession.overrideOutputAudioPort(.speaker)
            } else {
                try audioSession.overrideOutputAudioPort(.none)
            }
        } catch {
            self.error = error
        }
        #endif
    }

    func toggleVideo() {
        guard callType == .video || !isVideoEnabled else { return }
        isVideoEnabled.toggle()
        // In real implementation: enable/disable video
    }

    func switchCamera() {
        guard isVideoEnabled else { return }
        isFrontCamera.toggle()
        // In real implementation: switch camera
    }

    // MARK: - UI Controls

    func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
    }

    func minimize() {
        withAnimation(.spring(duration: 0.3)) {
            isMinimized = true
        }
    }

    func maximize() {
        withAnimation(.spring(duration: 0.3)) {
            isMinimized = false
        }
    }

    // MARK: - Private Methods

    private func startConnectedState() {
        callState = .connected
        duration = 0
        startDurationTimer()
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.duration += 1
            }
        }
    }

    private func cleanup() {
        durationTimer?.invalidate()
        durationTimer = nil
        duration = 0
        isMuted = false
        isSpeakerOn = false
        isVideoEnabled = false
    }

    // MARK: - Incoming Call Handler

    func handleIncomingCall(callId: Int64, user: User, isVideo: Bool) {
        self.callId = callId
        self.remoteUser = user
        self.callType = isVideo ? .video : .audio
        self.callState = .ringing
    }
}

// MARK: - Call State

enum CallState: String, Sendable {
    case idle
    case ringing
    case connecting
    case connected
    case reconnecting
    case ended
    case failed

    var icon: String {
        switch self {
        case .idle:
            return ""
        case .ringing:
            return "phone.badge.waveform"
        case .connecting:
            return "phone.arrow.up.right"
        case .connected:
            return "phone.fill"
        case .reconnecting:
            return "phone.badge.waveform"
        case .ended:
            return "phone.down"
        case .failed:
            return "phone.down.fill"
        }
    }
}

// MARK: - Call Type

enum CallType: String, Sendable {
    case audio
    case video

    var icon: String {
        switch self {
        case .audio:
            return "phone.fill"
        case .video:
            return "video.fill"
        }
    }
}

// MARK: - Signal Quality

enum SignalQuality: Int, Sendable {
    case excellent = 4
    case good = 3
    case fair = 2
    case poor = 1
    case none = 0

    var icon: String {
        switch self {
        case .excellent:
            return "cellularbars"
        case .good:
            return "cellularbars"
        case .fair:
            return "cellularbars"
        case .poor:
            return "cellularbars"
        case .none:
            return "cellularbars"
        }
    }

    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .green
        case .fair:
            return .yellow
        case .poor:
            return .orange
        case .none:
            return .red
        }
    }
}

// MARK: - Call Participant

struct CallParticipant: Identifiable, Equatable, Sendable {
    let id: Int64
    let user: User
    var isMuted: Bool
    var isVideoEnabled: Bool
    var isSpeaking: Bool
    var signalQuality: SignalQuality

    init(
        id: Int64,
        user: User,
        isMuted: Bool = false,
        isVideoEnabled: Bool = false,
        isSpeaking: Bool = false,
        signalQuality: SignalQuality = .excellent
    ) {
        self.id = id
        self.user = user
        self.isMuted = isMuted
        self.isVideoEnabled = isVideoEnabled
        self.isSpeaking = isSpeaking
        self.signalQuality = signalQuality
    }
}

// MARK: - Call Record

struct CallRecord: Identifiable, Equatable, Sendable {
    let id: Int64
    let user: User
    let type: CallType
    let direction: CallDirection
    let duration: TimeInterval
    let date: Date
    let wasSuccessful: Bool

    var formattedDuration: String {
        guard duration > 0 else { return "Missed" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Call Direction

enum CallDirection: String, Sendable {
    case incoming
    case outgoing

    var icon: String {
        switch self {
        case .incoming:
            return "phone.arrow.down.left"
        case .outgoing:
            return "phone.arrow.up.right"
        }
    }
}

// MARK: - Call Error

enum CallError: LocalizedError {
    case notSupported
    case connectionFailed
    case permissionDenied
    case networkUnavailable
    case userBusy
    case userDeclined
    case timeout

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Calls are not supported"
        case .connectionFailed:
            return "Failed to connect"
        case .permissionDenied:
            return "Microphone access denied"
        case .networkUnavailable:
            return "Network unavailable"
        case .userBusy:
            return "User is busy"
        case .userDeclined:
            return "Call declined"
        case .timeout:
            return "Call timed out"
        }
    }
}

// MARK: - Mock Data

extension CallRecord {
    static var mockHistory: [CallRecord] {
        [
            CallRecord(
                id: 1,
                user: User.mock(firstName: "Alice", lastName: "Smith"),
                type: .video,
                direction: .outgoing,
                duration: 325,
                date: Date().addingTimeInterval(-3600),
                wasSuccessful: true
            ),
            CallRecord(
                id: 2,
                user: User.mock(firstName: "Bob", lastName: "Johnson"),
                type: .audio,
                direction: .incoming,
                duration: 0,
                date: Date().addingTimeInterval(-7200),
                wasSuccessful: false
            ),
            CallRecord(
                id: 3,
                user: User.mock(firstName: "Charlie", lastName: "Brown"),
                type: .audio,
                direction: .outgoing,
                duration: 180,
                date: Date().addingTimeInterval(-86400),
                wasSuccessful: true
            ),
        ]
    }
}
