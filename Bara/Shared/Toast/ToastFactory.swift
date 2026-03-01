import Foundation
import SwiftUI
import Toasts

enum ToastKind {
    case success
    case error
    case info
}

enum ToastFactory {
    static func make(kind: ToastKind, message: String) -> ToastValue {
        switch kind {
        case .success:
            return ToastValue(
                icon: Image(systemName: "checkmark.circle.fill"),
                message: message
            )
        case .error:
            return ToastValue(
                icon: Image(systemName: "exclamationmark.triangle.fill"),
                message: message
            )
        case .info:
            return ToastValue(
                icon: Image(systemName: "bell.badge.fill"),
                message: message
            )
        }
    }

    static func userMessage(from error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .networkConnectionLost:
                return "Connection lost. Please try again."
            case .notConnectedToInternet:
                return "No internet connection."
            default:
                return urlError.localizedDescription
            }
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case URLError.networkConnectionLost.rawValue:
                return "Connection lost. Please try again."
            case URLError.notConnectedToInternet.rawValue:
                return "No internet connection."
            default:
                break
            }
        }

        return error.localizedDescription
    }
}
