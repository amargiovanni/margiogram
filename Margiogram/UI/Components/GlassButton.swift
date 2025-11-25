//
//  GlassButton.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Glass Button Style

/// The style of a glass button.
enum GlassButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive

    var foregroundColor: Color {
        switch self {
        case .primary, .destructive:
            return .white
        case .secondary, .ghost:
            return .primary
        }
    }
}

// MARK: - Glass Button

/// A button with Liquid Glass styling.
struct GlassButton: View {
    // MARK: - Properties

    let title: String
    let icon: String?
    let style: GlassButtonStyle
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Initialization

    init(
        _ title: String,
        icon: String? = nil,
        style: GlassButtonStyle = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(style.foregroundColor)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }

                if !title.isEmpty {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(style.foregroundColor)
            .opacity(isDisabled ? 0.5 : 1)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(minWidth: size.minWidth)
            .background(background)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .scaleEffect(isPressed ? 0.96 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [.accentColor, .accentColor.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .secondary:
            Material.ultraThinMaterial

        case .ghost:
            Color.clear

        case .destructive:
            LinearGradient(
                colors: [.error, .error.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Button Size

/// Size presets for buttons.
enum ButtonSize {
    case small
    case medium
    case large

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Spacing.sm
        case .medium: return Spacing.lg
        case .large: return Spacing.xl
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return Spacing.xs
        case .medium: return Spacing.sm
        case .large: return Spacing.md
        }
    }

    var font: Font {
        switch self {
        case .small: return Typography.bodySmall
        case .medium: return Typography.bodyMedium
        case .large: return Typography.bodyLarge
        }
    }

    var minWidth: CGFloat {
        switch self {
        case .small: return 60
        case .medium: return 80
        case .large: return 100
        }
    }
}

// MARK: - Icon Button

/// A circular icon button with glass styling.
struct GlassIconButton: View {
    let icon: String
    let style: GlassButtonStyle
    let size: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        style: GlassButtonStyle = .secondary,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(style.foregroundColor)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1)
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
            Color.error
        }
    }
}

// MARK: - Floating Action Button

/// A floating action button with glass styling.
struct GlassFAB: View {
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    init(icon: String = "plus", action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview("Glass Buttons") {
    VStack(spacing: Spacing.lg) {
        // Styles
        HStack(spacing: Spacing.md) {
            GlassButton("Primary", style: .primary) {}
            GlassButton("Secondary", style: .secondary) {}
        }

        HStack(spacing: Spacing.md) {
            GlassButton("Ghost", style: .ghost) {}
            GlassButton("Delete", style: .destructive) {}
        }

        // Sizes
        HStack(spacing: Spacing.md) {
            GlassButton("Small", size: .small) {}
            GlassButton("Medium", size: .medium) {}
            GlassButton("Large", size: .large) {}
        }

        // With icons
        HStack(spacing: Spacing.md) {
            GlassButton("Send", icon: "paperplane.fill") {}
            GlassButton("Call", icon: "phone.fill", style: .secondary) {}
        }

        // States
        HStack(spacing: Spacing.md) {
            GlassButton("Loading", isLoading: true) {}
            GlassButton("Disabled", isDisabled: true) {}
        }

        // Icon buttons
        HStack(spacing: Spacing.md) {
            GlassIconButton(icon: "heart.fill", style: .primary) {}
            GlassIconButton(icon: "bookmark.fill", style: .secondary) {}
            GlassIconButton(icon: "trash.fill", style: .destructive) {}
        }

        // FAB
        GlassFAB {}
    }
    .padding()
}
