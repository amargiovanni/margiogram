//
//  Colors.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // MARK: - Glass Colors

    /// Background color for glass effects.
    static let glassBackground = Color.white.opacity(0.1)

    /// Border color for glass effects.
    static let glassBorder = Color.white.opacity(0.2)

    /// Highlight color for glass effects.
    static let glassHighlight = Color.white.opacity(0.3)

    /// Shadow color for glass effects.
    static let glassShadow = Color.black.opacity(0.1)

    // MARK: - Accent Colors

    /// Primary accent color.
    static let accentPrimary = Color.accentColor

    /// Secondary accent color.
    static let accentSecondary = Color.accentColor.opacity(0.8)

    /// Tertiary accent color.
    static let accentTertiary = Color.accentColor.opacity(0.6)

    // MARK: - Text Colors

    /// Primary text color.
    static let textPrimary = Color.primary

    /// Secondary text color.
    static let textSecondary = Color.secondary

    /// Tertiary text color.
    static let textTertiary = Color.secondary.opacity(0.7)

    /// Inverted text color (for colored backgrounds).
    static let textInverted = Color.white

    // MARK: - Semantic Colors

    /// Success color.
    static let success = Color.green

    /// Warning color.
    static let warning = Color.orange

    /// Error/destructive color.
    static let error = Color.red

    /// Info color.
    static let info = Color.blue

    // MARK: - Chat Colors

    /// Outgoing message bubble color.
    static let bubbleOutgoing = Color.accentColor

    /// Incoming message bubble color.
    static let bubbleIncoming = Color(.systemGray5)

    /// Online status indicator color.
    static let statusOnline = Color.green

    /// Offline status indicator color.
    static let statusOffline = Color.gray

    // MARK: - Avatar Colors

    /// Generates avatar gradient colors based on a string hash.
    static func avatarColors(for name: String) -> [Color] {
        let colorPairs: [[Color]] = [
            [Color(hex: "FF6B6B"), Color(hex: "EE5A5A")],  // Red
            [Color(hex: "FFA94D"), Color(hex: "FF922B")],  // Orange
            [Color(hex: "FFD43B"), Color(hex: "FCC419")],  // Yellow
            [Color(hex: "69DB7C"), Color(hex: "51CF66")],  // Green
            [Color(hex: "38D9A9"), Color(hex: "20C997")],  // Teal
            [Color(hex: "4DABF7"), Color(hex: "339AF0")],  // Blue
            [Color(hex: "748FFC"), Color(hex: "5C7CFA")],  // Indigo
            [Color(hex: "B197FC"), Color(hex: "9775FA")],  // Violet
            [Color(hex: "F783AC"), Color(hex: "F06595")],  // Pink
        ]

        let hash = abs(name.hashValue)
        return colorPairs[hash % colorPairs.count]
    }
}

// MARK: - Hex Initializer

extension Color {
    /// Creates a color from a hex string.
    ///
    /// - Parameter hex: Hex color string (with or without #).
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Color Scheme Helpers

extension Color {
    /// Returns a color adapted for the current color scheme.
    func adaptedForColorScheme(_ colorScheme: ColorScheme) -> Color {
        // This can be used for custom color scheme handling
        self
    }
}

// MARK: - Gradient Presets

extension LinearGradient {
    /// Glass highlight gradient (top-left to bottom-right).
    static var glassHighlight: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.2), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Glass border gradient.
    static var glassBorder: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Accent gradient.
    static var accent: LinearGradient {
        LinearGradient(
            colors: [.accentColor, .accentColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Creates an avatar gradient for a name.
    static func avatar(for name: String) -> LinearGradient {
        let colors = Color.avatarColors(for: name)
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
