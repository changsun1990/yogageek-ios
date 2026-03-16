//
//  test_yoga_iosApp.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import FirebaseAppCheck
import FirebaseCore
import FirebaseCrashlytics
import GoogleSignIn
import SwiftUI

@main
struct test_yoga_iosApp: App {
    @State private var authViewModel: AuthViewModel

    init() {
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
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
            if url.scheme == "yogageek-spotify" {
                MusicManager.shared.handleSpotifyURL(url)
            } else {
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .animation(.easeInOut, value: authViewModel.isSignedIn)
    }
}
