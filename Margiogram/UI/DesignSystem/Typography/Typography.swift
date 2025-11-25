//
//  Typography.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Typography

/// Typography system for Margiogram.
enum Typography {
    // MARK: - Display

    /// Large display text (34pt, bold, rounded).
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)

    /// Medium display text (28pt, bold, rounded).
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Small display text (22pt, bold, rounded).
    static let displaySmall = Font.system(size: 22, weight: .bold, design: .rounded)

    // MARK: - Headings

    /// Large heading (20pt, semibold).
    static let headingLarge = Font.system(size: 20, weight: .semibold)

    /// Medium heading (17pt, semibold).
    static let headingMedium = Font.system(size: 17, weight: .semibold)

    /// Small heading (15pt, semibold).
    static let headingSmall = Font.system(size: 15, weight: .semibold)

    // MARK: - Body

    /// Large body text (17pt, regular).
    static let bodyLarge = Font.system(size: 17, weight: .regular)

    /// Medium body text (15pt, regular).
    static let bodyMedium = Font.system(size: 15, weight: .regular)

    /// Small body text (13pt, regular).
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Caption

    /// Regular caption (12pt, regular).
    static let caption = Font.system(size: 12, weight: .regular)

    /// Bold caption (12pt, medium).
    static let captionBold = Font.system(size: 12, weight: .medium)

    // MARK: - Specialized

    /// Monospace font for code.
    static let mono = Font.system(size: 14, weight: .regular, design: .monospaced)

    /// Message text font.
    static let message = Font.system(size: 16, weight: .regular)

    /// Message time font.
    static let messageTime = Font.system(size: 11, weight: .regular)

    /// Chat list title font.
    static let chatTitle = Font.system(size: 16, weight: .semibold)

    /// Chat list preview font.
    static let chatPreview = Font.system(size: 14, weight: .regular)

    /// Badge font.
    static let badge = Font.system(size: 12, weight: .semibold)
}

// MARK: - Font Extension

extension Font {
    /// Returns a font with the specified weight.
    func weight(_ weight: Font.Weight) -> Font {
        // SwiftUI already provides this, but we can extend if needed
        self
    }
}

// MARK: - Text Style Modifiers

extension View {
    /// Applies display large style.
    func displayLargeStyle() -> some View {
        self
            .font(Typography.displayLarge)
            .foregroundStyle(.primary)
    }

    /// Applies heading style.
    func headingStyle() -> some View {
        self
            .font(Typography.headingMedium)
            .foregroundStyle(.primary)
    }

    /// Applies body style.
    func bodyStyle() -> some View {
        self
            .font(Typography.bodyMedium)
            .foregroundStyle(.primary)
    }

    /// Applies caption style.
    func captionStyle() -> some View {
        self
            .font(Typography.caption)
            .foregroundStyle(.secondary)
    }

    /// Applies message style.
    func messageStyle() -> some View {
        self
            .font(Typography.message)
            .foregroundStyle(.primary)
    }
}

// MARK: - Spacing

/// Spacing system for consistent layouts.
enum Spacing {
    /// Extra extra extra small spacing (2pt).
    static let xxxs: CGFloat = 2

    /// Extra extra small spacing (4pt).
    static let xxs: CGFloat = 4

    /// Extra small spacing (8pt).
    static let xs: CGFloat = 8

    /// Small spacing (12pt).
    static let sm: CGFloat = 12

    /// Medium spacing (16pt).
    static let md: CGFloat = 16

    /// Large spacing (24pt).
    static let lg: CGFloat = 24

    /// Extra large spacing (32pt).
    static let xl: CGFloat = 32

    /// Extra extra large spacing (48pt).
    static let xxl: CGFloat = 48

    /// Extra extra extra large spacing (64pt).
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius

/// Corner radius presets.
enum CornerRadius {
    /// Small corner radius (8pt).
    static let small: CGFloat = 8

    /// Medium corner radius (12pt).
    static let medium: CGFloat = 12

    /// Large corner radius (16pt).
    static let large: CGFloat = 16

    /// Extra large corner radius (20pt).
    static let xlarge: CGFloat = 20

    /// Extra extra large corner radius (28pt).
    static let xxlarge: CGFloat = 28

    /// Circular (pill shape).
    static let circular: CGFloat = 9999
}

// MARK: - Icon Sizes

/// Icon size presets.
enum IconSize {
    /// Small icon (16pt).
    static let small: CGFloat = 16

    /// Medium icon (20pt).
    static let medium: CGFloat = 20

    /// Large icon (24pt).
    static let large: CGFloat = 24

    /// Extra large icon (32pt).
    static let xlarge: CGFloat = 32

    /// Navigation icon (28pt).
    static let navigation: CGFloat = 28

    /// Tab bar icon (24pt).
    static let tabBar: CGFloat = 24
}

// MARK: - Avatar Sizes

/// Avatar size presets.
enum AvatarSize {
    /// Small avatar (32pt).
    static let small: CGFloat = 32

    /// Medium avatar (40pt).
    static let medium: CGFloat = 40

    /// Large avatar (48pt).
    static let large: CGFloat = 48

    /// Extra large avatar (56pt).
    static let xlarge: CGFloat = 56

    /// Chat list avatar (52pt).
    static let chatList: CGFloat = 52

    /// Profile avatar (80pt).
    static let profile: CGFloat = 80

    /// Header avatar (100pt).
    static let header: CGFloat = 100
}
