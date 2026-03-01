import SwiftUI

struct DistractionSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DistractionSetupViewModel

    init(service: PetStateProviding) {
        _viewModel = StateObject(wrappedValue: DistractionSetupViewModel(service: service))
    }

    var body: some View {
        List {
            Section {
                Text("Select apps you consider distracting. This is a starter UI for your punishment flow.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Distracting Apps") {
                ForEach(viewModel.availableApps) { app in
                    Button {
                        viewModel.toggleSelection(for: app.id)
                    } label: {
                        HStack(spacing: Spacing.small) {
                            Image(systemName: app.symbolName)
                                .foregroundStyle(AppColors.accentTeal)
                                .frame(width: 22)

                            Text(app.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if viewModel.isSelected(app.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColors.accentGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Punishment Threshold") {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(AppColors.accentTeal)
                    Text("Start punishment after")
                    Spacer()
                    Text("\(viewModel.preferences.thresholdMinutes) min")
                        .foregroundStyle(.secondary)
                }

                Stepper(value: $viewModel.preferences.thresholdMinutes, in: 5...180, step: 5) {
                    Text("Adjust threshold")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [AppColors.sandBackground, AppColors.sandBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Distraction Setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    viewModel.save()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

