//
//  GlassContainer.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Glass Intensity

/// The intensity of the glass blur effect.
enum GlassIntensity {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick

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

// MARK: - Glass Container

/// A container view with Liquid Glass styling.
///
/// Use `GlassContainer` to wrap content in a glass-like card
/// with blur effects and subtle borders.
///
/// ```swift
/// GlassContainer {
///     Text("Hello, World!")
/// }
/// ```
struct GlassContainer<Content: View>: View {
    // MARK: - Properties

    let intensity: GlassIntensity
    let cornerRadius: CGFloat
    let showBorder: Bool
    let shadowRadius: CGFloat
    let content: Content

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = CornerRadius.large,
        showBorder: Bool = true,
        shadowRadius: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.shadowRadius = shadowRadius
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        content
            .padding(Spacing.md)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(borderOverlay)
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            intensity.material

            // Glass highlight gradient
            LinearGradient(
                colors: [
                    .white.opacity(colorScheme == .dark ? 0.05 : 0.15),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Border

    @ViewBuilder
    private var borderOverlay: some View {
        if showBorder {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }
}

// MARK: - Glass Card

/// A styled card with glass effect and padding.
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GlassContainer(intensity: .regular, cornerRadius: CornerRadius.xlarge) {
            content
        }
    }
}

// MARK: - Glass TextField Container

/// A glass-styled container optimized for text fields.
struct GlassTextFieldContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

// MARK: - Preview

#Preview("Glass Containers") {
    ZStack {
        // Background gradient
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            // Basic container
            GlassContainer {
                Text("Regular Glass Container")
                    .font(Typography.bodyMedium)
            }

            // Different intensities
            GlassContainer(intensity: .ultraThin) {
                Text("Ultra Thin")
                    .font(Typography.bodySmall)
            }

            GlassContainer(intensity: .thick) {
                Text("Thick")
                    .font(Typography.bodySmall)
            }

            // Card style
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Glass Card")
                        .font(Typography.headingMedium)
                    Text("A styled card with glass effect.")
                        .font(Typography.bodySmall)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Text field container
            GlassTextFieldContainer {
                TextField("Enter text...", text: .constant(""))
            }
        }
        .padding()
    }
}
