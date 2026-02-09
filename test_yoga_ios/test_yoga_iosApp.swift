//
//  test_yoga_iosApp.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct test_yoga_iosApp: App {
    @State private var authViewModel: AuthViewModel

    init() {
        FirebaseApp.configure()
        _authViewModel = State(initialValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel)
        }
    }
}

struct RootView: View {
    var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                MainTabView(authViewModel: authViewModel)
            } else {
                AuthContainerView(authViewModel: authViewModel)
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
        .animation(.easeInOut, value: authViewModel.isSignedIn)
    }
}
