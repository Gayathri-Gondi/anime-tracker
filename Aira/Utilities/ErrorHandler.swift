//
//  ErrorHandler.swift
//  Aira
//
//  Created by Gayathri Gondi on 18/07/25.
//

// Utilities/ErrorHandler.swift
import SwiftUI
import Combine

class ErrorHandler: ObservableObject {
    @Published var currentAlert: AlertItem?
    
    struct AlertItem: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let dismissButton: Alert.Button
    }
    
    func handle(_ error: Error, title: String = "Error") {
        let message: String
        
        if let networkError = error as? NetworkService.NetworkError {
            message = networkError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        
        currentAlert = AlertItem(
            title: title,
            message: message,
            dismissButton: .default(Text("OK"))
        )
        
        print("❌ Error: \(error)")
    }
}

extension NetworkService.NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingFailed:
            return "Failed to encode request"
        case .decodingFailed:
            return "Failed to decode response"
        case .authenticationFailed:
            return "Authentication failed"
        case .serverError(let message):
            return message
        }
    }
}
