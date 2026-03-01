import SwiftUI

struct IncomingBuddyRequestCardView: View {
    let request: BorrowRequest?
    let isResolving: Bool
    let resolveError: String?
    let onDeny: () -> Void
    let onApprove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Incoming Request")
                    .font(AppTypography.subtitle)

                Spacer()

                if let request {
                    Text(relativeTimeText(from: request.createdAt))
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let request {
                Text("\(request.requesterDisplayName ?? "Your buddy") asked for \(request.minutesRequested) min")
                    .font(AppTypography.body)

                if let note = request.note, !note.isEmpty {
                    Text(note)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                HStack(spacing: 10) {
                    Button("Deny") {
                        onDeny()
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    .disabled(isResolving)

                    Button("Approve") {
                        onApprove()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accentGreen)
                    .disabled(isResolving)

                    if isResolving {
                        ProgressView()
                            .tint(AppColors.accentTeal)
                    }
                }
            } else {
                Text("No incoming requests")
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let resolveError, !resolveError.isEmpty {
                Text(resolveError)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func relativeTimeText(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
