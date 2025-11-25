//
//  MessageInputView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Message Input View

/// Input view for composing and sending messages.
///
/// Features:
/// - Text input with expanding height
/// - Attachment button
/// - Send/voice button toggle
/// - Reply/edit preview
/// - Voice recording UI
struct MessageInputView: View {
    // MARK: - Properties

    @Bindable var viewModel: ConversationViewModel

    // MARK: - Focus State

    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Reply/Edit preview
            if viewModel.replyingTo != nil || viewModel.editingMessage != nil {
                replyPreview
            }

            // Voice recording UI
            if viewModel.isRecordingVoice {
                voiceRecordingView
            } else {
                // Main input area
                mainInputArea
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Main Input Area

    private var mainInputArea: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            // Attachment button
            attachmentButton

            // Text input
            textInputField

            // Send/Voice button
            sendButton
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Attachment Button

    private var attachmentButton: some View {
        Button {
            viewModel.showAttachmentPicker = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSendMessages)
    }

    // MARK: - Text Input Field

    private var textInputField: some View {
        HStack(alignment: .bottom, spacing: Spacing.xxs) {
            // Emoji button
            Button {
                // TODO: Show emoji picker
            } label: {
                Image(systemName: "face.smiling")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            // Text field
            TextField(
                viewModel.inputPlaceholder,
                text: $viewModel.inputText,
                axis: .vertical
            )
            .font(Typography.bodyMedium)
            .lineLimit(1...6)
            .focused($isTextFieldFocused)
            .disabled(!viewModel.canSendMessages)
            .onChange(of: viewModel.inputText) { _, newValue in
                if !newValue.isEmpty {
                    viewModel.updateTypingIndicator()
                }
            }
            .onSubmit {
                if !viewModel.inputText.isEmpty {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            switch viewModel.sendButtonState {
            case .send:
                Task {
                    await viewModel.sendMessage()
                }
            case .microphone:
                viewModel.startVoiceRecording()
            case .stop:
                Task {
                    await viewModel.stopVoiceRecording(send: true)
                }
            }
        } label: {
            Image(systemName: sendButtonIcon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(sendButtonColor)
                )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSendMessages)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.sendButtonState)
    }

    private var sendButtonIcon: String {
        switch viewModel.sendButtonState {
        case .send:
            return "arrow.up"
        case .microphone:
            return "mic.fill"
        case .stop:
            return "stop.fill"
        }
    }

    private var sendButtonColor: Color {
        switch viewModel.sendButtonState {
        case .send:
            return Color.accentColor
        case .microphone:
            return Color.accentColor
        case .stop:
            return Color.red
        }
    }

    // MARK: - Reply Preview

    private var replyPreview: some View {
        HStack(spacing: Spacing.sm) {
            // Accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentColor)
                .frame(width: 3)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                // Header
                Text(replyPreviewHeader)
                    .font(Typography.captionBold)
                    .foregroundStyle(Color.accentColor)

                // Preview text
                Text(replyPreviewText)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Close button
            Button {
                if viewModel.editingMessage != nil {
                    viewModel.cancelEditing()
                } else {
                    viewModel.cancelReply()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color(.systemGray6).opacity(0.5))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var replyPreviewHeader: String {
        if viewModel.editingMessage != nil {
            return String(localized: "Edit message")
        } else if let reply = viewModel.replyingTo {
            return reply.isOutgoing ? String(localized: "Reply to yourself") : String(localized: "Reply")
        }
        return ""
    }

    private var replyPreviewText: String {
        if let editing = viewModel.editingMessage {
            return editing.content.previewText
        } else if let reply = viewModel.replyingTo {
            return reply.content.previewText
        }
        return ""
    }

    // MARK: - Voice Recording View

    private var voiceRecordingView: some View {
        HStack(spacing: Spacing.md) {
            // Cancel button
            Button {
                Task {
                    await viewModel.stopVoiceRecording(send: false)
                }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.red)
            }
            .buttonStyle(.plain)

            // Recording indicator
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(recordingPulseOpacity)

                Text(formattedRecordingDuration)
                    .font(Typography.bodyMedium)
                    .monospacedDigit()
            }

            Spacer()

            // Waveform visualization
            RecordingWaveformView()
                .frame(height: 30)

            Spacer()

            // Send button
            Button {
                Task {
                    await viewModel.stopVoiceRecording(send: true)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .transition(.opacity)
    }

    @State private var recordingPulseOpacity: Double = 1.0

    private var formattedRecordingDuration: String {
        let minutes = Int(viewModel.voiceRecordingDuration) / 60
        let seconds = Int(viewModel.voiceRecordingDuration) % 60
        let millis = Int((viewModel.voiceRecordingDuration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d,%d", minutes, seconds, millis)
    }
}

// MARK: - Recording Waveform View

/// Animated waveform visualization for voice recording.
struct RecordingWaveformView: View {
    @State private var levels: [CGFloat] = Array(repeating: 0.3, count: 30)
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<levels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: levels[index] * 30)
            }
        }
        .onAppear {
            startAnimating()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startAnimating() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.1)) {
                    levels = levels.map { _ in CGFloat.random(in: 0.2...1.0) }
                }
            }
        }
    }
}

// MARK: - Attachment Picker

/// Sheet for selecting attachments.
struct AttachmentPickerView: View {
    @Binding var isPresented: Bool
    let onSelect: (Attachment.AttachmentType) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    attachmentRow(
                        icon: "photo.fill",
                        color: .blue,
                        title: String(localized: "Photo or Video"),
                        subtitle: String(localized: "Send from your library")
                    ) {
                        onSelect(.photo)
                    }

                    attachmentRow(
                        icon: "camera.fill",
                        color: .orange,
                        title: String(localized: "Camera"),
                        subtitle: String(localized: "Take a photo or video")
                    ) {
                        onSelect(.photo)
                    }

                    attachmentRow(
                        icon: "doc.fill",
                        color: .purple,
                        title: String(localized: "Document"),
                        subtitle: String(localized: "Send a file")
                    ) {
                        onSelect(.document)
                    }

                    attachmentRow(
                        icon: "location.fill",
                        color: .green,
                        title: String(localized: "Location"),
                        subtitle: String(localized: "Share your location")
                    ) {
                        // Location handling
                    }

                    attachmentRow(
                        icon: "person.crop.circle.fill",
                        color: .cyan,
                        title: String(localized: "Contact"),
                        subtitle: String(localized: "Share a contact")
                    ) {
                        // Contact handling
                    }

                    attachmentRow(
                        icon: "chart.bar.fill",
                        color: .pink,
                        title: String(localized: "Poll"),
                        subtitle: String(localized: "Create a poll")
                    ) {
                        // Poll handling
                    }
                }
            }
            .navigationTitle(String(localized: "Attach"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func attachmentRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            isPresented = false
            action()
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(title)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Message Input") {
    VStack {
        Spacer()
        MessageInputView(viewModel: ConversationViewModel(chat: .mock()))
    }
}

#Preview("Message Input - Replying") {
    VStack {
        Spacer()
        MessageInputView(viewModel: {
            let vm = ConversationViewModel(chat: .mock())
            vm.replyingTo = .mock(text: "Hello, how are you?")
            return vm
        }())
    }
}
