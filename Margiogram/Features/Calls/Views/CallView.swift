//
//  CallView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Call View

struct CallView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CallViewModel

    // MARK: - Initialization

    init(viewModel: CallViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView

                // Video Preview (for video calls)
                if viewModel.callType == .video && viewModel.isVideoEnabled {
                    videoPreviewView(geometry: geometry)
                }

                // Content
                VStack {
                    // Top Bar
                    if viewModel.showControls {
                        topBar
                    }

                    Spacer()

                    // User Info
                    userInfoSection

                    Spacer()

                    // Control Buttons
                    if viewModel.showControls {
                        controlsSection
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 50)

                // Incoming Call Overlay
                if viewModel.callState == .ringing && viewModel.remoteUser != nil {
                    incomingCallOverlay
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onTapGesture {
            if viewModel.callState == .connected {
                viewModel.toggleControls()
            }
        }
        .onChange(of: viewModel.callState) { _, newState in
            if newState == .ended {
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    dismiss()
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            if viewModel.callType == .video && viewModel.isVideoEnabled {
                Color.black
            } else {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.8),
                        Color.accentColor.opacity(0.4),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    // MARK: - Video Preview

    private func videoPreviewView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Remote video (full screen)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay {
                    Image(systemName: "video.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }

            // Local video (picture-in-picture)
            VStack {
                HStack {
                    Spacer()
                    localVideoPreview
                        .frame(width: 120, height: 160)
                        .cornerRadius(12)
                        .padding()
                }
                Spacer()
            }
        }
    }

    private var localVideoPreview: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.8))

            if viewModel.isVideoEnabled {
                // In real implementation: show camera preview
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "video.slash.fill")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Minimize button
            Button {
                viewModel.minimize()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Circle())
            }

            Spacer()

            // Signal quality
            HStack(spacing: 4) {
                Image(systemName: viewModel.signalQuality.icon)
                    .foregroundColor(viewModel.signalQuality.color)
                Text(viewModel.networkType)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial.opacity(0.6))
            .clipShape(Capsule())

            Spacer()

            // Switch camera (video only)
            if viewModel.callType == .video && viewModel.isVideoEnabled {
                Button {
                    viewModel.switchCamera()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial.opacity(0.6))
                        .clipShape(Circle())
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .transition(.opacity)
    }

    // MARK: - User Info Section

    private var userInfoSection: some View {
        VStack(spacing: 16) {
            // Avatar
            if !viewModel.isVideoEnabled || viewModel.callType == .audio {
                userAvatar
            }

            // Name
            if let user = viewModel.remoteUser {
                Text(user.fullName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Call State
            Text(viewModel.stateTitle)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            // Encryption notice
            if viewModel.callState == .connected {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("End-to-end encrypted")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private var userAvatar: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 150, height: 150)
            .overlay {
                if let user = viewModel.remoteUser {
                    Text(user.fullName.prefix(1).uppercased())
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: 20)
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 24) {
            // Secondary controls
            HStack(spacing: 40) {
                // Speaker
                ControlButton(
                    icon: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                    label: "Speaker",
                    isActive: viewModel.isSpeakerOn
                ) {
                    viewModel.toggleSpeaker()
                }

                // Video toggle
                ControlButton(
                    icon: viewModel.isVideoEnabled ? "video.fill" : "video.slash.fill",
                    label: "Video",
                    isActive: viewModel.isVideoEnabled
                ) {
                    viewModel.toggleVideo()
                }

                // Mute
                ControlButton(
                    icon: viewModel.isMuted ? "mic.slash.fill" : "mic.fill",
                    label: "Mute",
                    isActive: viewModel.isMuted
                ) {
                    viewModel.toggleMute()
                }
            }

            // End call button
            Button {
                viewModel.endCall()
            } label: {
                Image(systemName: "phone.down.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .shadow(color: .red.opacity(0.4), radius: 10)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Incoming Call Overlay

    private var incomingCallOverlay: some View {
        VStack(spacing: 40) {
            Spacer()

            // Slide to answer (simplified with buttons)
            HStack(spacing: 60) {
                // Decline
                Button {
                    viewModel.rejectCall()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.red)
                            .clipShape(Circle())

                        Text("Decline")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }

                // Accept
                Button {
                    Task {
                        await viewModel.acceptCall()
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: viewModel.callType == .video ? "video.fill" : "phone.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.green)
                            .clipShape(Circle())

                        Text("Accept")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }

            Spacer()
                .frame(height: 100)
        }
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Control Button

private struct ControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .black : .white)
                    .frame(width: 56, height: 56)
                    .background(isActive ? Color.white : Color.white.opacity(0.2))
                    .clipShape(Circle())

                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Call History View

struct CallHistoryView: View {
    @State private var callHistory: [CallRecord] = CallRecord.mockHistory

    var body: some View {
        List {
            ForEach(callHistory) { record in
                CallHistoryRow(record: record)
            }
            .onDelete { indexSet in
                callHistory.remove(atOffsets: indexSet)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Calls")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }
}

// MARK: - Call History Row

private struct CallHistoryRow: View {
    let record: CallRecord

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(record.user.fullName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(record.user.fullName)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Image(systemName: record.direction.icon)
                        .font(.caption)
                        .foregroundColor(record.wasSuccessful ? .secondary : .red)

                    Text(record.formattedDuration)
                        .font(.subheadline)
                        .foregroundColor(record.wasSuccessful ? .secondary : .red)
                }
            }

            Spacer()

            // Call type & date
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: record.type.icon)
                    .foregroundColor(.accentColor)

                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("Active Call") {
    let viewModel = CallViewModel()
    viewModel.remoteUser = User.mock(firstName: "John", lastName: "Doe")
    viewModel.callState = .connected
    viewModel.callType = .audio

    return CallView(viewModel: viewModel)
}

#Preview("Call History") {
    NavigationStack {
        CallHistoryView()
    }
}
