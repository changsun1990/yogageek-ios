//
//  test_yoga_iosApp.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import SwiftUI
import FirebaseCore

@main
struct test_yoga_iosApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
