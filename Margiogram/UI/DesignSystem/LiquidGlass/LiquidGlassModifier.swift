//
//  LiquidGlassModifier.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Glass Intensity

/// Intensity levels for the glass effect.
enum GlassIntensity: CaseIterable {
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

// MARK: - Liquid Glass Modifier

/// A view modifier that applies the Liquid Glass design effect.
///
/// This creates a translucent, blurred background with subtle highlights
/// and shadows that adapt to both light and dark modes.
struct LiquidGlassModifier: ViewModifier {
    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Properties

    /// The intensity of the glass effect.
    let intensity: GlassIntensity

    /// Corner radius of the glass container.
    let cornerRadius: CGFloat

    /// Shadow radius for depth.
    let shadowRadius: CGFloat

    /// Whether to show the border.
    let showBorder: Bool

    /// Whether to show the highlight gradient.
    let showHighlight: Bool

    // MARK: - Initialization

    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = CornerRadius.xlarge,
        shadowRadius: CGFloat = 10,
        showBorder: Bool = true,
        showHighlight: Bool = true
    ) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.showBorder = showBorder
        self.showHighlight = showHighlight
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(borderView)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowRadius / 2
            )
    }

    // MARK: - Subviews

    private var backgroundView: some View {
        ZStack {
            // Material blur - use Rectangle with fill
            Rectangle()
                .fill(intensity.material)

            // Highlight gradient
            if showHighlight {
                LinearGradient(
                    colors: [
                        .white.opacity(colorScheme == .dark ? 0.05 : 0.2),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    @ViewBuilder
    private var borderView: some View {
        if showBorder {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(borderGradient, lineWidth: 0.5)
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(colorScheme == .dark ? 0.2 : 0.4),
                .white.opacity(colorScheme == .dark ? 0.05 : 0.15),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shadowColor: Color {
        .black.opacity(colorScheme == .dark ? 0.4 : 0.12)
    }
}

// MARK: - View Extension

extension View {
    /// Applies the Liquid Glass effect to the view.
    ///
    /// - Parameters:
    ///   - intensity: The intensity of the glass blur.
    ///   - cornerRadius: Corner radius of the glass container.
    ///   - shadowRadius: Shadow radius for depth.
    ///   - showBorder: Whether to show the subtle border.
    ///   - showHighlight: Whether to show the highlight gradient.
    /// - Returns: A view with the Liquid Glass effect applied.
    func liquidGlass(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = CornerRadius.xlarge,
        shadowRadius: CGFloat = 10,
        showBorder: Bool = true,
        showHighlight: Bool = true
    ) -> some View {
        modifier(LiquidGlassModifier(
            intensity: intensity,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            showBorder: showBorder,
            showHighlight: showHighlight
        ))
    }

    /// Applies a subtle glass effect suitable for cards.
    func glassCard() -> some View {
        liquidGlass(
            intensity: .thin,
            cornerRadius: CornerRadius.large,
            shadowRadius: 8
        )
    }

    /// Applies a glass effect suitable for navigation bars.
    func glassNavBar() -> some View {
        liquidGlass(
            intensity: .regular,
            cornerRadius: 0,
            shadowRadius: 4,
            showBorder: false,
            showHighlight: false
        )
    }

    /// Applies a glass effect suitable for input fields.
    func glassInput() -> some View {
        liquidGlass(
            intensity: .ultraThin,
            cornerRadius: CornerRadius.medium,
            shadowRadius: 2,
            showBorder: true,
            showHighlight: false
        )
    }

    /// Applies a glass effect suitable for buttons.
    func glassButton() -> some View {
        liquidGlass(
            intensity: .thin,
            cornerRadius: CornerRadius.circular,
            shadowRadius: 4,
            showBorder: true,
            showHighlight: true
        )
    }
}

// MARK: - Glass Container

/// A container view with Liquid Glass styling.
struct GlassContainer<Content: View>: View {
    let intensity: GlassIntensity
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = CornerRadius.xlarge,
        padding: CGFloat = Spacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .liquidGlass(intensity: intensity, cornerRadius: cornerRadius)
    }
}

// MARK: - Preview

#Preview("Liquid Glass") {
    ZStack {
        // Background image
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            // Ultra thin
            Text("Ultra Thin")
                .padding()
                .frame(maxWidth: .infinity)
                .liquidGlass(intensity: .ultraThin)

            // Thin
            Text("Thin")
                .padding()
                .frame(maxWidth: .infinity)
                .liquidGlass(intensity: .thin)

            // Regular
            Text("Regular")
                .padding()
                .frame(maxWidth: .infinity)
                .liquidGlass(intensity: .regular)

            // Thick
            Text("Thick")
                .padding()
                .frame(maxWidth: .infinity)
                .liquidGlass(intensity: .thick)

            // Card style
            GlassContainer {
                VStack(alignment: .leading) {
                    Text("Glass Card")
                        .font(Typography.headingMedium)
                    Text("This is a glass container with content")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}
