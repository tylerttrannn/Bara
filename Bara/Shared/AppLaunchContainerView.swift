import SwiftUI
import UIKit
import Toasts

struct AppLaunchContainerView: View {
    let service: PetStateProviding
    let buddyService: BuddyProviding
    let allowanceStore: BorrowAllowanceProviding

    @State private var showSplash = true
    @State private var splashOpacity = 1.0

    var body: some View {
        ZStack {
            RootTabView(service: service, buddyService: buddyService, allowanceStore: allowanceStore)
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                LaunchSplashView()
                    .opacity(splashOpacity)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .installToast(position: .bottom)
        .task {
            guard showSplash else { return }

            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.45)) {
                splashOpacity = 0
            }
            try? await Task.sleep(for: .milliseconds(450))
            showSplash = false
            splashOpacity = 1
        }
    }
}

private struct LaunchSplashView: View {
    @State private var animateCapybara = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.sandBackground, AppColors.sandBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.medium) {
                Image("very_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .scaleEffect(animateCapybara ? 1.03 : 0.97)
                    .offset(y: animateCapybara ? -5 : 4)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateCapybara)

                Text("Bara")
                    .font(AppTypography.title)
                    .foregroundStyle(.primary)
                    .opacity(animateCapybara ? 1 : 0.88)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateCapybara)
            }
        }
        .onAppear {
            animateCapybara = true
            triggerSplashHaptic()
        }
    }

    private func triggerSplashHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
    }
}
