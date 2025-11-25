//
//  GlassContainer.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//
//  NOTE: Main GlassContainer and GlassIntensity are defined in
//  UI/DesignSystem/LiquidGlass/LiquidGlassModifier.swift
//  This file contains additional glass-styled helper components.

import SwiftUI

// MARK: - Glass Card

/// A styled card with glass effect and padding.
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.md)
            .background(.regularMaterial)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xlarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xlarge, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
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

// MARK: - Glass Section Header

/// A glass-styled section header.
struct GlassSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Typography.captionBold)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(.ultraThinMaterial.opacity(0.5))
    }
}

// MARK: - Preview

#Preview("Glass Components") {
    ZStack {
        // Background gradient
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
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

            // Section header
            GlassSectionHeader(title: "Section Title")
        }
        .padding()
    }
}
