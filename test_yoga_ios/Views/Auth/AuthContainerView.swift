//
//  AuthContainerView.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/7/26.
//

import SwiftUI

struct AuthContainerView: View {
    @State private var showSignUp = false

    var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            if showSignUp {
                SignUpView(authViewModel: authViewModel, showSignUp: $showSignUp)
            } else {
                LoginView(authViewModel: authViewModel, showSignUp: $showSignUp)
            }
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    var authViewModel: AuthViewModel
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showingForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @State private var showingResetSent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo and welcome
                VStack(spacing: 16) {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentColor)

                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Sign in to continue your yoga journey")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Login form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Forgot password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            forgotPasswordEmail = email
                            showingForgotPassword = true
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Sign in button
                Button {
                    Task {
                        await authViewModel.signIn(email: email, password: password)
                    }
                } label: {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                .padding(.horizontal)

                // Divider with "or"
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    Text("or")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                .padding(.horizontal)

                // Google Sign In button
                GoogleSignInButton(authViewModel: authViewModel)

                // Sign up link
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") {
                        authViewModel.clearError()
                        showSignUp = true
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)

                Spacer()
            }
        }
        .alert("Reset Password", isPresented: $showingForgotPassword) {
            TextField("Email", text: $forgotPasswordEmail)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            Button("Cancel", role: .cancel) {}
            Button("Send Reset Link") {
                Task {
                    let success = await authViewModel.sendPasswordReset(email: forgotPasswordEmail)
                    if success {
                        showingResetSent = true
                    }
                }
            }
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .alert("Email Sent", isPresented: $showingResetSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your email for a link to reset your password.")
        }
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    var authViewModel: AuthViewModel
    @Binding var showSignUp: Bool

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6 && passwordsMatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo and welcome
                VStack(spacing: 16) {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentColor)

                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Start your yoga journey today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Sign up form
                VStack(spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter your name", text: $displayName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("At least 6 characters", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !password.isEmpty && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    // Confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        SecureField("Re-enter your password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal)

                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Sign up button
                Button {
                    Task {
                        await authViewModel.signUp(email: email, password: password, displayName: displayName)
                    }
                } label: {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid || authViewModel.isLoading)
                .padding(.horizontal)

                // Divider with "or"
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    Text("or")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                .padding(.horizontal)

                // Google Sign In button
                GoogleSignInButton(authViewModel: authViewModel)

                // Sign in link
                HStack {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign In") {
                        authViewModel.clearError()
                        showSignUp = false
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)

                Spacer()
            }
        }
    }
}

// MARK: - Google Sign In Button

struct GoogleSignInButton: View {
    var authViewModel: AuthViewModel

    var body: some View {
        Button {
            Task {
                await authViewModel.signInWithGoogle()
            }
        } label: {
            HStack(spacing: 12) {
                // Google "G" logo using colors
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)

                    Text("G")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .yellow, .green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Continue with Google")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .disabled(authViewModel.isLoading)
        .padding(.horizontal)
    }
}

#Preview {
    AuthContainerView(authViewModel: AuthViewModel())
}
