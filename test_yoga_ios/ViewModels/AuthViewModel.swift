//
//  AuthViewModel.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/7/26.
//

import Foundation
import FirebaseAuth

@Observable
@MainActor
class AuthViewModel {
    var isSignedIn: Bool = false
    var currentUser: User?
    var isLoading: Bool = false
    var errorMessage: String?

    private nonisolated(unsafe) var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        authStateHandle = AuthService.shared.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isSignedIn = user != nil
            }
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.signUp(email: email, password: password)
            if !displayName.isEmpty {
                try await AuthService.shared.updateDisplayName(displayName)
            }
            currentUser = user
            isSignedIn = true
            isLoading = false
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.signIn(email: email, password: password)
            currentUser = user
            isSignedIn = true
            isLoading = false
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.signInWithGoogle()
            currentUser = user
            isSignedIn = true
            isLoading = false
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.signInWithApple()
            currentUser = user
            isSignedIn = true
            isLoading = false
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try AuthService.shared.signOut()
            currentUser = nil
            isSignedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await AuthService.shared.sendPasswordReset(email: email)
            isLoading = false
            return true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            isLoading = false
            return false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
