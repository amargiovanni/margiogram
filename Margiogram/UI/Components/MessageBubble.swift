//
//  MessageBubble.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Message Bubble

/// A view that displays a single message in a conversation.
struct MessageBubble: View {
    // MARK: - Properties

    let message: Message
    let isFromMe: Bool
    let showTail: Bool
    let showSenderName: Bool
    let senderName: String?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Initialization

    init(
        message: Message,
        isFromMe: Bool,
        showTail: Bool = true,
        showSenderName: Bool = false,
        senderName: String? = nil
    ) {
        self.message = message
        self.isFromMe = isFromMe
        self.showTail = showTail
        self.showSenderName = showSenderName
        self.senderName = senderName
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            if isFromMe { Spacer(minLength: 60) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: Spacing.xxxs) {
                // Sender name (for groups)
                if showSenderName, let name = senderName {
                    Text(name)
                        .font(Typography.captionBold)
                        .foregroundStyle(Color.avatarColors(for: name)[0])
                        .padding(.horizontal, Spacing.sm)
                }

                // Message content
                messageContent
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(bubbleBackground)
                    .clipShape(BubbleShape(isFromMe: isFromMe, showTail: showTail))

                // Metadata row
                metadataRow
            }

            if !isFromMe { Spacer(minLength: 60) }
        }
        .padding(.horizontal, Spacing.md)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.2), value: isPressed)
    }

    // MARK: - Message Content

    @ViewBuilder
    private var messageContent: some View {
        switch message.content {
        case .text(let formattedText):
            Text(formattedText.text)
                .font(Typography.message)
                .foregroundStyle(textColor)
                .textSelection(.enabled)

        case .photo(let photo):
            photoContent(photo)

        case .video(let video):
            videoContent(video)

        case .sticker(let sticker):
            stickerContent(sticker)

        case .voiceNote(let voice):
            voiceNoteContent(voice)

        case .document(let document):
            documentContent(document)

        case .location(let location):
            locationContent(location)

        default:
            Text(message.content.previewText)
                .font(Typography.message)
                .foregroundStyle(textColor)
                .italic()
        }
    }

    // MARK: - Photo Content

    private func photoContent(_ photo: Photo) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let url = photo.thumbnailURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                }
                .frame(maxWidth: 250, maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                .overlay {
                    if photo.hasSpoiler {
                        spoilerOverlay
                    }
                }
            }

            if let caption = photo.caption, !caption.text.isEmpty {
                Text(caption.text)
                    .font(Typography.message)
                    .foregroundStyle(textColor)
            }
        }
    }

    // MARK: - Video Content

    private func videoContent(_ video: Video) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ZStack {
                if let thumbnail = video.thumbnail, let url = thumbnail.file.localPath.flatMap({ URL(fileURLWithPath: $0) }) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }

                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)

                // Duration
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(formatDuration(video.duration))
                            .font(Typography.captionBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
            }
            .frame(maxWidth: 250, maxHeight: 200)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

            if let caption = video.caption, !caption.text.isEmpty {
                Text(caption.text)
                    .font(Typography.message)
                    .foregroundStyle(textColor)
            }
        }
    }

    // MARK: - Sticker Content

    private func stickerContent(_ sticker: Sticker) -> some View {
        Group {
            if let url = sticker.thumbnail?.file.localPath.flatMap({ URL(fileURLWithPath: $0) }) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Text(sticker.emoji)
                        .font(.system(size: 100))
                }
            } else {
                Text(sticker.emoji)
                    .font(.system(size: 100))
            }
        }
        .frame(width: 150, height: 150)
    }

    // MARK: - Voice Note Content

    private func voiceNoteContent(_ voice: VoiceNote) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(isFromMe ? .white : .accentColor)

            // Waveform
            WaveformView(data: voice.waveform, isPlaying: false)
                .frame(height: 30)
                .frame(maxWidth: 150)

            Text(formatDuration(voice.duration))
                .font(Typography.caption)
                .foregroundStyle(textColor.opacity(0.8))
        }
    }

    // MARK: - Document Content

    private func documentContent(_ document: Document) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: documentIcon(for: document.mimeType))
                .font(.system(size: 32))
                .foregroundStyle(isFromMe ? .white : .accentColor)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(document.fileName)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(textColor)
                    .lineLimit(1)

                Text(formatFileSize(document.file.size))
                    .font(Typography.caption)
                    .foregroundStyle(textColor.opacity(0.7))
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Location Content

    private func locationContent(_ location: Location) -> some View {
        VStack(spacing: Spacing.xs) {
            // Map placeholder
            Rectangle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 200, height: 120)
                .overlay {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                }
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

            Text("Location")
                .font(Typography.caption)
                .foregroundStyle(textColor.opacity(0.7))
        }
    }

    // MARK: - Spoiler Overlay

    private var spoilerOverlay: some View {
        ZStack {
            VisualEffectBlur()

            Text("Tap to reveal")
                .font(Typography.captionBold)
                .foregroundStyle(.white)
        }
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack(spacing: Spacing.xxs) {
            // Edit indicator
            if message.editDate != nil {
                Text("edited")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }

            // Time
            Text(message.formattedTime)
                .font(Typography.messageTime)
                .foregroundStyle(.secondary)

            // Read status
            if isFromMe {
                Image(systemName: message.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(message.isRead ? Color.accentColor : Color.secondary)
            }
        }
        .padding(.horizontal, Spacing.xs)
    }

    // MARK: - Bubble Background

    @ViewBuilder
    private var bubbleBackground: some View {
        if isFromMe {
            LinearGradient(
                colors: [.bubbleOutgoing, .bubbleOutgoing.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Rectangle()
                .fill(.regularMaterial)
        }
    }

    // MARK: - Helpers

    private var textColor: Color {
        isFromMe ? .white : .primary
    }

    private func formatDuration(_ seconds: Int32) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func documentIcon(for mimeType: String) -> String {
        if mimeType.contains("pdf") { return "doc.fill" }
        if mimeType.contains("zip") || mimeType.contains("rar") { return "doc.zipper" }
        if mimeType.contains("image") { return "photo.fill" }
        if mimeType.contains("audio") { return "music.note" }
        if mimeType.contains("video") { return "video.fill" }
        return "doc.fill"
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let isFromMe: Bool
    let showTail: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailWidth: CGFloat = 8
        let tailHeight: CGFloat = 6

        var path = Path()

        if isFromMe {
            // Top-left corner
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))

            // Top edge
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))

            // Top-right corner
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )

            // Right edge
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))

            if showTail {
                // Tail
                path.addQuadCurve(
                    to: CGPoint(x: rect.maxX + tailWidth, y: rect.maxY),
                    control: CGPoint(x: rect.maxX, y: rect.maxY)
                )
                path.addQuadCurve(
                    to: CGPoint(x: rect.maxX - tailWidth, y: rect.maxY - tailHeight),
                    control: CGPoint(x: rect.maxX, y: rect.maxY - tailHeight / 2)
                )
                path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY - tailHeight))
                path.addQuadCurve(
                    to: CGPoint(x: rect.minX, y: rect.maxY - tailHeight - radius),
                    control: CGPoint(x: rect.minX, y: rect.maxY - tailHeight)
                )
            } else {
                path.addQuadCurve(
                    to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                    control: CGPoint(x: rect.maxX, y: rect.maxY)
                )
                path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
                path.addQuadCurve(
                    to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                    control: CGPoint(x: rect.minX, y: rect.maxY)
                )
            }

            // Left edge
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))

            // Top-left corner
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Mirror for incoming messages
            path.move(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.minY))

            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.minY + radius),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )

            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))

            if showTail {
                path.addQuadCurve(
                    to: CGPoint(x: rect.minX - tailWidth, y: rect.maxY),
                    control: CGPoint(x: rect.minX, y: rect.maxY)
                )
                path.addQuadCurve(
                    to: CGPoint(x: rect.minX + tailWidth, y: rect.maxY - tailHeight),
                    control: CGPoint(x: rect.minX, y: rect.maxY - tailHeight / 2)
                )
                path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY - tailHeight))
                path.addQuadCurve(
                    to: CGPoint(x: rect.maxX, y: rect.maxY - tailHeight - radius),
                    control: CGPoint(x: rect.maxX, y: rect.maxY - tailHeight)
                )
            } else {
                path.addQuadCurve(
                    to: CGPoint(x: rect.minX + radius, y: rect.maxY),
                    control: CGPoint(x: rect.minX, y: rect.maxY)
                )
                path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
                path.addQuadCurve(
                    to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
                    control: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            }

            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + radius))

            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.minY),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
        }

        return path
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let data: Data
    let isPlaying: Bool

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<waveformBars(for: geometry.size.width), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 2, height: barHeight(at: index, totalHeight: geometry.size.height))
                }
            }
        }
    }

    private func waveformBars(for width: CGFloat) -> Int {
        Int(width / 4)
    }

    private func barHeight(at index: Int, totalHeight: CGFloat) -> CGFloat {
        // Generate pseudo-random heights based on waveform data
        let dataIndex = index % max(1, data.count)
        let value = data.isEmpty ? 0.5 : Double(data[dataIndex]) / 255.0
        return max(4, totalHeight * CGFloat(value))
    }
}

// MARK: - Visual Effect Blur

struct VisualEffectBlur: View {
    var body: some View {
        #if os(iOS)
        VisualEffectView(effect: UIBlurEffect(style: .regular))
        #else
        Rectangle()
            .fill(.ultraThinMaterial)
        #endif
    }
}

#if os(iOS)
struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#endif

// MARK: - Preview

#Preview("Message Bubbles") {
    ScrollView {
        VStack(spacing: Spacing.sm) {
            MessageBubble(
                message: .mock(text: "Hello! How are you?", isOutgoing: false),
                isFromMe: false
            )

            MessageBubble(
                message: .mock(text: "I'm doing great, thanks for asking! 😊", isOutgoing: true),
                isFromMe: true
            )

            MessageBubble(
                message: .mock(text: "This is a longer message that spans multiple lines to show how the bubble wraps text content properly.", isOutgoing: false),
                isFromMe: false,
                showTail: false
            )

            MessageBubble(
                message: .mock(text: "Perfect! Let's meet tomorrow.", isOutgoing: true),
                isFromMe: true
            )
        }
        .padding()
    }
    .background(Color(.systemBackground))
}
