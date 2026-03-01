import SwiftUI

struct RequestMoreTimeCardView: View {
    let profile: BuddyProfile?
    let selectedMinutes: Int
    let note: String
    let inviteCode: String
    let pendingOutgoingRequest: BorrowRequest?
    let submitState: DashboardViewModel.AsyncActionState
    let pairState: DashboardViewModel.AsyncActionState
    let unpairState: DashboardViewModel.AsyncActionState
    let disabledReason: String?

    let onSelectMinutes: (Int) -> Void
    let onNoteChange: (String) -> Void
    let onInviteCodeChange: (String) -> Void
    let onPair: () -> Void
    let onUnpair: () -> Void
    let onSubmit: () -> Void
    @FocusState private var isNoteFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text("Request More Time")
                    .font(AppTypography.subtitle)

                Spacer()

                if let profile {
                    Text("Points: \(profile.points)")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let profile {
                inviteCodeRow(inviteCode: profile.inviteCode)

                if !profile.isPaired {
                    pairRow
                } else {
                    unpairRow
                }
            } else {
                Text("Loading your buddy profile...")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            if let pendingOutgoingRequest {
                Text("Pending: \(pendingOutgoingRequest.minutesRequested) min request sent")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accentTeal)
            }

            Text("Choose extra minutes")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)

            presetMinuteChips

            VStack(alignment: .leading, spacing: 6) {
                Text("Optional message")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)

                TextField(
                    "Ask for help (optional)",
                    text: Binding(get: { note }, set: { onNoteChange($0) }),
                    axis: .vertical
                )
                .lineLimit(1...3)
                .submitLabel(.done)
                .focused($isNoteFieldFocused)
                .onSubmit {
                    isNoteFieldFocused = false
                }
                .padding(10)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack {
                    Text("\(note.count)/\(BorrowRequestDraft.maxNoteLength)")
                        .font(AppTypography.caption)
                        .foregroundStyle(note.count > BorrowRequestDraft.maxNoteLength ? Color.red : Color.secondary)
                }
            }

            if let disabledReason {
                Text(disabledReason)
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            if let requestError = submitState.errorMessage {
                Text(requestError)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }

            if let unpairError = unpairState.errorMessage {
                Text(unpairError)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }

            Button {
                Haptics.impact(.medium)
                onSubmit()
            } label: {
                HStack {
                    Text("Request from Buddy")
                    if submitState.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                    }
                }
                .font(AppTypography.body)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accentGreen)
            .disabled(disabledReason != nil || submitState.isLoading)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isNoteFieldFocused = false
                }
            }
        }
    }

    private var presetMinuteChips: some View {
        HStack(spacing: 8) {
            ForEach(BorrowRequestDraft.allowedMinutes, id: \.self) { minutes in
                Button("\(minutes)") {
                    Haptics.selection()
                    onSelectMinutes(minutes)
                }
                .buttonStyle(.plain)
                .font(AppTypography.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(minutes == selectedMinutes ? AppColors.accentGreen : Color.white.opacity(0.7))
                .foregroundStyle(minutes == selectedMinutes ? Color.white : Color.primary)
                .clipShape(Capsule())
            }
        }
    }

    private var pairRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pair with your buddy using their invite code")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField(
                    "Invite code",
                    text: Binding(get: { inviteCode }, set: { onInviteCodeChange($0.uppercased()) })
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(10)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button("Pair") {
                    Haptics.impact(.light)
                    onPair()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentGreen)
                .disabled(pairState.isLoading)
            }

            if let message = pairState.errorMessage {
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var unpairRow: some View {
        HStack {
            Button(role: .destructive) {
                Haptics.impact(.light)
                onUnpair()
            } label: {
                HStack(spacing: 6) {
                    Text("Unpair Buddy")
                    if unpairState.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.red.opacity(0.85))
            .disabled(unpairState.isLoading)
        }
    }

    private func inviteCodeRow(inviteCode: String) -> some View {
        HStack(spacing: 6) {
            Text("Your code:")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)

            Text(inviteCode)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}
