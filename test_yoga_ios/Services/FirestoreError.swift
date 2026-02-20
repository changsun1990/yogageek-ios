//
//  FirestoreError.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 2/9/26.
//

import Foundation

enum FirestoreError: LocalizedError {
    case notAuthenticated
    case documentNotFound
    case permissionDenied
    case networkUnavailable
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue."
        case .documentNotFound:
            return "The requested data was not found."
        case .permissionDenied:
            return "You don't have permission to perform this action."
        case .networkUnavailable:
            return "Network unavailable. Changes will sync when you're back online."
        case .unknown(let message):
            return message
        }
    }
}
