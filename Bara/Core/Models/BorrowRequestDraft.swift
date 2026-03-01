import Foundation

struct BorrowRequestDraft: Equatable {
    static let allowedMinutes: [Int] = [5, 10, 15, 20, 30]
    static let maxNoteLength = 120

    var minutes: Int
    var note: String

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedNote: String? {
        let trimmed = String(trimmedNote.prefix(Self.maxNoteLength))
        return trimmed.isEmpty ? nil : trimmed
    }

    func validate() throws {
        guard Self.allowedMinutes.contains(minutes) else {
            throw BorrowDraftValidationError.invalidMinutes
        }

        if trimmedNote.count > Self.maxNoteLength {
            throw BorrowDraftValidationError.noteTooLong
        }
    }
}

enum BorrowDraftValidationError: LocalizedError {
    case invalidMinutes
    case noteTooLong

    var errorDescription: String? {
        switch self {
        case .invalidMinutes:
            return "Please choose one of the preset minute options."
        case .noteTooLong:
            return "Message must be 120 characters or less."
        }
    }
}
