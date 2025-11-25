---
model: claude-sonnet-4-5-20250929
description: Create and improve UI components with Liquid Glass design (iOS 26+)
updated: 2025-11
---

# UI Command

Crea e migliora componenti UI seguendo il design system Liquid Glass (iOS 26 style).

## Utilizzo

```
/ui [create|improve|animate] [component_name]
```

## Design System: Liquid Glass

### Principi Fondamentali

1. **Trasparenza**: Gli elementi mostrano il contenuto sottostante con effetto blur
2. **Profondità**: Layering visivo con ombre e bordi sottili
3. **Fluidità**: Transizioni e animazioni naturali
4. **Coerenza**: Stesso linguaggio su iOS e macOS
5. **Adattabilità**: Si adatta a tema chiaro/scuro automaticamente

### Palette Colori

```swift
import SwiftUI

extension Color {
    // MARK: - Glass Colors
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    static let glassHighlight = Color.white.opacity(0.3)
    static let glassShadow = Color.black.opacity(0.1)

    // MARK: - Accent
    static let accentPrimary = Color.blue
    static let accentSecondary = Color.blue.opacity(0.8)

    // MARK: - Semantic
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.secondary.opacity(0.7)

    // MARK: - Status
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue

    // MARK: - Chat Bubbles
    static let bubbleOutgoing = Color.accentColor
    static let bubbleIncoming = Color(.systemGray5)
}
```

### Tipografia

```swift
import SwiftUI

extension Font {
    // MARK: - Display
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 22, weight: .bold, design: .rounded)

    // MARK: - Headings
    static let headingLarge = Font.system(size: 20, weight: .semibold)
    static let headingMedium = Font.system(size: 17, weight: .semibold)
    static let headingSmall = Font.system(size: 15, weight: .semibold)

    // MARK: - Body
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Caption
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionBold = Font.system(size: 12, weight: .medium)

    // MARK: - Mono
    static let mono = Font.system(size: 14, weight: .regular, design: .monospaced)
}
```

### Spaziatura

```swift
enum Spacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}
```

### Corner Radius

```swift
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 20
    static let xxlarge: CGFloat = 28
    static let circular: CGFloat = 9999
}
```

## Componenti Base

### LiquidGlassModifier

```swift
import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    var intensity: GlassIntensity
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat
    var showBorder: Bool

    enum GlassIntensity {
        case ultraThin, thin, regular, thick, ultraThick

        var material: Material {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .ultraThick: return .ultraThickMaterial
            }
        }
    }

    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = CornerRadius.xlarge,
        shadowRadius: CGFloat = 10,
        showBorder: Bool = true
    ) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.showBorder = showBorder
    }

    func body(content: Content) -> some View {
        content
            .background(intensity.material)
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(colorScheme == .dark ? 0.05 : 0.2),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: showBorder ? [
                                .white.opacity(0.3),
                                .white.opacity(0.1),
                                .clear
                            ] : [.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
    }
}

extension View {
    func liquidGlass(
        intensity: LiquidGlassModifier.GlassIntensity = .regular,
        cornerRadius: CGFloat = CornerRadius.xlarge,
        shadowRadius: CGFloat = 10,
        showBorder: Bool = true
    ) -> some View {
        modifier(LiquidGlassModifier(
            intensity: intensity,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            showBorder: showBorder
        ))
    }
}
```

### GlassButton

```swift
import SwiftUI

struct GlassButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    @State private var isPressed = false

    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        case destructive
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.bodyMedium.weight(.semibold))
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(background)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            Color.accentColor
        case .secondary:
            Material.ultraThinMaterial
        case .ghost:
            Color.clear
        case .destructive:
            Color.red
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary, .ghost:
            return .primary
        }
    }
}
```

### GlassCard

```swift
import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.md)
            .liquidGlass()
    }
}
```

### AvatarView

```swift
import SwiftUI

struct AvatarView: View {
    let url: URL?
    let name: String
    let size: CGFloat
    let showOnlineIndicator: Bool
    let isOnline: Bool

    init(
        url: URL? = nil,
        name: String,
        size: CGFloat = 48,
        showOnlineIndicator: Bool = false,
        isOnline: Bool = false
    ) {
        self.url = url
        self.name = name
        self.size = size
        self.showOnlineIndicator = showOnlineIndicator
        self.isOnline = isOnline
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarImage
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            if showOnlineIndicator {
                onlineIndicator
            }
        }
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderAvatar
                case .empty:
                    placeholderAvatar
                        .overlay(ProgressView())
                @unknown default:
                    placeholderAvatar
                }
            }
        } else {
            placeholderAvatar
        }
    }

    private var placeholderAvatar: some View {
        ZStack {
            LinearGradient(
                colors: avatarColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var onlineIndicator: some View {
        Circle()
            .fill(isOnline ? Color.green : Color.gray)
            .frame(width: size * 0.25, height: size * 0.25)
            .overlay(
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: 2)
            )
    }

    private var initials: String {
        let components = name.split(separator: " ").prefix(2)
        return components.map { String($0.prefix(1)) }.joined().uppercased()
    }

    private var avatarColors: [Color] {
        let hash = abs(name.hashValue)
        let colorPairs: [[Color]] = [
            [.red, .orange],
            [.orange, .yellow],
            [.green, .mint],
            [.teal, .cyan],
            [.blue, .indigo],
            [.purple, .pink]
        ]
        return colorPairs[hash % colorPairs.count]
    }
}
```

### MessageBubble

```swift
import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isFromMe: Bool
    let showTail: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            if isFromMe { Spacer(minLength: 60) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: Spacing.xxs) {
                messageContent
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(bubbleBackground)
                    .clipShape(BubbleShape(isFromMe: isFromMe, showTail: showTail))

                // Timestamp
                HStack(spacing: Spacing.xxs) {
                    Text(message.formattedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isFromMe {
                        Image(systemName: readStatusIcon)
                            .font(.caption2)
                            .foregroundStyle(message.isRead ? .blue : .secondary)
                    }
                }
            }

            if !isFromMe { Spacer(minLength: 60) }
        }
        .padding(.horizontal, Spacing.md)
    }

    @ViewBuilder
    private var messageContent: some View {
        switch message.content {
        case .text(let text):
            Text(text)
                .font(.bodyMedium)
                .foregroundStyle(isFromMe ? .white : .primary)

        case .photo(let photo):
            AsyncImage(url: photo.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(maxWidth: 250, maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

        default:
            Text("[Unsupported content]")
                .font(.bodyMedium)
                .italic()
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isFromMe {
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Material.regularMaterial
        }
    }

    private var readStatusIcon: String {
        message.isRead ? "checkmark.circle.fill" : "checkmark.circle"
    }
}

struct BubbleShape: Shape {
    let isFromMe: Bool
    let showTail: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailWidth: CGFloat = 8
        let tailHeight: CGFloat = 6

        var path = Path()

        if isFromMe {
            // Angolo in alto a sinistra
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))

            // Lato superiore
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))

            // Angolo in alto a destra
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )

            // Lato destro
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))

            if showTail {
                // Coda
                path.addQuadCurve(
                    to: CGPoint(x: rect.maxX + tailWidth, y: rect.maxY),
                    control: CGPoint(x: rect.maxX, y: rect.maxY)
                )
                path.addQuadCurve(
                    to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                    control: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            } else {
                path.addQuadCurve(
                    to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                    control: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            }

            // Lato inferiore
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))

            // Angolo in basso a sinistra
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )

            // Lato sinistro
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))

            // Angolo in alto a sinistra
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Mirror per messaggi in arrivo
            // ... implementazione simmetrica
        }

        return path
    }
}
```

### InputBar

```swift
import SwiftUI

struct InputBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    let onSend: () -> Void
    let onAttachment: () -> Void
    let onVoice: () -> Void

    @State private var isRecording = false

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            // Attachment button
            Button(action: onAttachment) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            // Text input
            HStack(alignment: .bottom, spacing: Spacing.xs) {
                TextField("Message", text: $text, axis: .vertical)
                    .focused($isFocused)
                    .lineLimit(1...6)
                    .font(.bodyMedium)
                    .padding(.vertical, Spacing.xs)

                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            // Send / Voice button
            Button(action: text.isEmpty ? onVoice : onSend) {
                Image(systemName: text.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(text.isEmpty ? .secondary : .accentColor)
                    .contentTransition(.symbolEffect(.replace))
            }
            .scaleEffect(isRecording ? 1.2 : 1)
            .animation(.spring(response: 0.3), value: isRecording)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
    }
}
```

## Animazioni

### Press Effect

```swift
import SwiftUI

struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false

    var scale: CGFloat
    var opacity: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1)
            .opacity(isPressed ? opacity : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

extension View {
    func pressEffect(scale: CGFloat = 0.96, opacity: CGFloat = 0.9) -> some View {
        modifier(PressEffectModifier(scale: scale, opacity: opacity))
    }
}
```

### Shake Effect

```swift
import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0
        ))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    var trigger: Bool
    @State private var shakeAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.default) {
                        shakeAmount = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        shakeAmount = 0
                    }
                }
            }
    }
}
```

### Spring Appear

```swift
import SwiftUI

extension View {
    func springAppear(delay: Double = 0) -> some View {
        modifier(SpringAppearModifier(delay: delay))
    }
}

struct SpringAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    appeared = true
                }
            }
    }
}
```

## Layout Adattivo

```swift
import SwiftUI

struct AdaptiveLayout<Content: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    let compact: () -> Content
    let regular: () -> Content

    var body: some View {
        if sizeClass == .compact {
            compact()
        } else {
            regular()
        }
    }
}

// Usage
AdaptiveLayout {
    // iPhone layout
    NavigationStack {
        ChatListView()
    }
} regular: {
    // iPad/Mac layout
    NavigationSplitView {
        ChatListView()
    } detail: {
        ConversationView()
    }
}
```

## Preview Helpers

```swift
import SwiftUI

// Dark/Light mode preview
struct ColorSchemePreview<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            content
                .preferredColorScheme(.light)

            content
                .preferredColorScheme(.dark)
        }
    }
}

// Device preview
struct DevicePreview<Content: View>: View {
    let content: Content

    var body: some View {
        Group {
            content
                .previewDevice("iPhone 17 Pro")
                .previewDisplayName("iPhone")

            content
                .previewDevice("iPad Pro (12.9-inch)")
                .previewDisplayName("iPad")
        }
    }
}
```
