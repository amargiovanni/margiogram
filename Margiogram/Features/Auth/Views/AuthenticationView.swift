//
//  AuthenticationView.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import SwiftUI

// MARK: - Authentication View

/// Main authentication view that handles the login flow.
struct AuthenticationView: View {
    // MARK: - Environment

    @EnvironmentObject private var authManager: AuthenticationManager

    // MARK: - State

    @State private var currentStep: AuthStep = .phoneNumber

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, geometry.safeAreaInsets.top + Spacing.xxl)

                    Spacer(minLength: Spacing.xl)

                    // Content based on state
                    contentView
                        .padding(.horizontal, Spacing.lg)

                    Spacer(minLength: Spacing.xl)

                    // Footer
                    footerView
                        .padding(.bottom, geometry.safeAreaInsets.bottom + Spacing.lg)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(backgroundView)
        .onChange(of: authManager.state) { _, newState in
            updateStep(for: newState)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: Spacing.md) {
            // Logo
            Image(systemName: "paperplane.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .accentColor.opacity(0.3), radius: 20, x: 0, y: 10)

            // Title
            Text("Margiogram")
                .font(Typography.displayMedium)
                .foregroundStyle(.primary)

            // Subtitle
            Text(subtitleText)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        switch authManager.state {
        case .waitingForPhoneNumber, .unauthorized, .loading:
            PhoneNumberInputView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .waitingForCode(let codeInfo):
            CodeVerificationView(codeInfo: codeInfo)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .waitingForPassword(let hint):
            PasswordInputView(hint: hint)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .waitingForRegistration:
            RegistrationView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .authorized:
            // Should not be shown, but handle gracefully
            ProgressView()
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: Spacing.sm) {
            Text("By signing in, you agree to the")
                .font(Typography.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.xs) {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(Typography.captionBold)

                Text("and")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)

                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(Typography.captionBold)
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -50)

                Circle()
                    .fill(Color.accentColor.opacity(0.03))
                    .frame(width: 400, height: 400)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
            }
        }
    }

    // MARK: - Helpers

    private var subtitleText: String {
        switch authManager.state {
        case .waitingForPhoneNumber, .unauthorized, .loading:
            return "Enter your phone number to get started"
        case .waitingForCode:
            return "Enter the code we sent you"
        case .waitingForPassword:
            return "Enter your two-factor authentication password"
        case .waitingForRegistration:
            return "Create your profile"
        case .authorized:
            return "Welcome back!"
        }
    }

    private func updateStep(for state: AuthorizationState) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch state {
            case .waitingForPhoneNumber, .unauthorized, .loading:
                currentStep = .phoneNumber
            case .waitingForCode:
                currentStep = .code
            case .waitingForPassword:
                currentStep = .password
            case .waitingForRegistration:
                currentStep = .registration
            case .authorized:
                break
            }
        }
    }

    enum AuthStep {
        case phoneNumber
        case code
        case password
        case registration
    }
}

// MARK: - Phone Number Input View

struct PhoneNumberInputView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var phoneNumber = ""
    @State private var selectedCountry = Country.italy
    @FocusState private var isPhoneFocused: Bool
    @State private var showCountryPicker = false
    @State private var shake = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Phone input
            GlassContainer(intensity: .thin, cornerRadius: CornerRadius.large) {
                HStack(spacing: Spacing.sm) {
                    // Country selector
                    Button {
                        showCountryPicker = true
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Text(selectedCountry.flag)
                                .font(.title2)

                            Text(selectedCountry.dialCode)
                                .font(Typography.bodyMedium)
                                .foregroundStyle(.primary)

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .frame(height: 30)

                    // Phone field
                    TextField("Phone number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($isPhoneFocused)
                        .font(Typography.bodyLarge)
                }
            }
            .modifier(ShakeEffect(animatableData: shake ? 1 : 0))

            // Error message
            if let error = authManager.error {
                Text(error.localizedDescription)
                    .font(Typography.caption)
                    .foregroundStyle(.error)
                    .transition(.opacity)
            }

            // Continue button
            GlassButton(
                "Continue",
                icon: "arrow.right",
                isLoading: authManager.isProcessing,
                isDisabled: !isValidPhoneNumber
            ) {
                submitPhoneNumber()
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            isPhoneFocused = true
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry)
        }
    }

    private var isValidPhoneNumber: Bool {
        phoneNumber.filter { $0.isNumber }.count >= 7
    }

    private func submitPhoneNumber() {
        let fullNumber = selectedCountry.dialCode + phoneNumber.filter { $0.isNumber }

        Task {
            do {
                try await authManager.sendPhoneNumber(fullNumber)
            } catch {
                withAnimation(.default) {
                    shake.toggle()
                }
            }
        }
    }
}

// MARK: - Code Verification View

struct CodeVerificationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    let codeInfo: AuthCodeInfo

    @State private var code = ""
    @State private var timeRemaining: Int
    @FocusState private var isCodeFocused: Bool
    @State private var shake = false

    init(codeInfo: AuthCodeInfo) {
        self.codeInfo = codeInfo
        _timeRemaining = State(initialValue: Int(codeInfo.timeout))
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Phone number display
            Text(codeInfo.phoneNumber)
                .font(Typography.headingMedium)
                .foregroundStyle(.primary)

            // Code type info
            Text(codeTypeText)
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Code input
            GlassContainer(intensity: .thin, cornerRadius: CornerRadius.large) {
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<6, id: \.self) { index in
                        CodeDigitView(
                            digit: digit(at: index),
                            isFocused: code.count == index
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
            .overlay {
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isCodeFocused)
                    .opacity(0.01)
                    .onChange(of: code) { _, newValue in
                        code = String(newValue.prefix(6).filter { $0.isNumber })
                        if code.count == 6 {
                            submitCode()
                        }
                    }
            }
            .onTapGesture {
                isCodeFocused = true
            }

            // Error message
            if let error = authManager.error {
                Text(error.localizedDescription)
                    .font(Typography.caption)
                    .foregroundStyle(.error)
                    .transition(.opacity)
            }

            // Resend / Timer
            HStack {
                if timeRemaining > 0 {
                    Text("Resend code in \(timeRemaining)s")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Resend code") {
                        resendCode()
                    }
                    .font(Typography.captionBold)
                }

                Spacer()

                Button("Change number") {
                    // Go back
                }
                .font(Typography.captionBold)
            }

            // Continue button
            GlassButton(
                "Continue",
                icon: "arrow.right",
                isLoading: authManager.isProcessing,
                isDisabled: code.count < 5
            ) {
                submitCode()
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            isCodeFocused = true
            startTimer()
        }
    }

    private var codeTypeText: String {
        switch codeInfo.type {
        case .sms:
            return "We've sent an SMS with a verification code"
        case .call:
            return "We're calling you with a verification code"
        case .flashCall:
            return "We're calling you. The code is the last digits of the phone number"
        case .missedCall(let pattern):
            return "We're calling you. Don't answer. The code is the last digits: \(pattern)"
        case .fragment:
            return "Get the code from the Fragment app"
        }
    }

    private func digit(at index: Int) -> String? {
        guard index < code.count else { return nil }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }

    private func submitCode() {
        Task {
            do {
                try await authManager.verifyCode(code)
            } catch {
                withAnimation(.default) {
                    shake.toggle()
                }
                code = ""
            }
        }
    }

    private func resendCode() {
        Task {
            try? await authManager.resendCode()
            timeRemaining = Int(codeInfo.timeout)
            startTimer()
        }
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Code Digit View

struct CodeDigitView: View {
    let digit: String?
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color(.systemGray6))
                .frame(width: 45, height: 55)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                )

            if let digit {
                Text(digit)
                    .font(.system(size: 24, weight: .semibold))
            } else if isFocused {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2, height: 24)
                    .opacity(isFocused ? 1 : 0)
            }
        }
    }
}

// MARK: - Password Input View

struct PasswordInputView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    let hint: String

    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Hint
            if !hint.isEmpty {
                Text("Hint: \(hint)")
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
            }

            // Password input
            GlassContainer(intensity: .thin, cornerRadius: CornerRadius.large) {
                HStack {
                    Group {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                    }
                    .textContentType(.password)
                    .focused($isPasswordFocused)
                    .font(Typography.bodyLarge)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Error message
            if let error = authManager.error {
                Text(error.localizedDescription)
                    .font(Typography.caption)
                    .foregroundStyle(.error)
                    .transition(.opacity)
            }

            // Continue button
            GlassButton(
                "Continue",
                icon: "arrow.right",
                isLoading: authManager.isProcessing,
                isDisabled: password.isEmpty
            ) {
                submitPassword()
            }
            .frame(maxWidth: .infinity)

            // Forgot password
            Button("Forgot password?") {
                // Handle forgot password
            }
            .font(Typography.captionBold)
        }
        .onAppear {
            isPasswordFocused = true
        }
    }

    private func submitPassword() {
        Task {
            try? await authManager.verifyPassword(password)
        }
    }
}

// MARK: - Registration View

struct RegistrationView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case firstName, lastName
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // First name
            GlassContainer(intensity: .thin, cornerRadius: CornerRadius.large) {
                TextField("First name", text: $firstName)
                    .textContentType(.givenName)
                    .focused($focusedField, equals: .firstName)
                    .font(Typography.bodyLarge)
            }

            // Last name
            GlassContainer(intensity: .thin, cornerRadius: CornerRadius.large) {
                TextField("Last name (optional)", text: $lastName)
                    .textContentType(.familyName)
                    .focused($focusedField, equals: .lastName)
                    .font(Typography.bodyLarge)
            }

            // Continue button
            GlassButton(
                "Create Account",
                icon: "person.badge.plus",
                isDisabled: firstName.isEmpty
            ) {
                // Submit registration
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            focusedField = .firstName
        }
    }
}

// MARK: - Country Picker View

struct CountryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountry: Country
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button {
                    selectedCountry = country
                    dismiss()
                } label: {
                    HStack {
                        Text(country.flag)
                            .font(.title2)

                        Text(country.name)
                            .font(Typography.bodyMedium)

                        Spacer()

                        Text(country.dialCode)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.secondary)

                        if country == selectedCountry {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return Country.all
        }
        return Country.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.dialCode.contains(searchText)
        }
    }
}

// MARK: - Country Model

struct Country: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let dialCode: String
    let code: String
    let flag: String

    static let italy = Country(name: "Italy", dialCode: "+39", code: "IT", flag: "🇮🇹")

    static let all: [Country] = [
        italy,
        Country(name: "United States", dialCode: "+1", code: "US", flag: "🇺🇸"),
        Country(name: "United Kingdom", dialCode: "+44", code: "GB", flag: "🇬🇧"),
        Country(name: "Germany", dialCode: "+49", code: "DE", flag: "🇩🇪"),
        Country(name: "France", dialCode: "+33", code: "FR", flag: "🇫🇷"),
        Country(name: "Spain", dialCode: "+34", code: "ES", flag: "🇪🇸"),
        Country(name: "Russia", dialCode: "+7", code: "RU", flag: "🇷🇺"),
        Country(name: "China", dialCode: "+86", code: "CN", flag: "🇨🇳"),
        Country(name: "Japan", dialCode: "+81", code: "JP", flag: "🇯🇵"),
        Country(name: "Brazil", dialCode: "+55", code: "BR", flag: "🇧🇷"),
    ]
}

// MARK: - Shake Effect

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

// MARK: - Preview

#Preview("Authentication") {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
