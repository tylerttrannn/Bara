//
//  AuthorizationManager.swift
//  Bara
//
//  Created by Tyler Tran on 2/28/26.
//

import FamilyControls
import SwiftUI
import Combine



class AuthorizationManager: ObservableObject {
    @Published var authorizationStatus: FamilyControls.AuthorizationStatus = .notDetermined
    init() {
        Task {
            await checkAuthorization()
        }
    }
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual) // Use .individual for non-Family Sharing apps
            self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            // Handle errors appropriately (e.g., logging, showing an alert)
            print("Failed to request authorization: \(error)")
            self.authorizationStatus = .denied // Or handle specific errors
        }
    }
    func checkAuthorization() async {
         self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
}
