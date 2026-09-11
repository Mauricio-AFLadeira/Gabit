import SwiftUI

/// Wires the app together: auth (login/register) gates onboarding, which
/// leads into a Today/Progress tab flow, and Today presents Log food as a
/// sheet. A restored session (token already in the Keychain) skips straight
/// to onboarding.
struct RootView: View {
    private enum Phase: Equatable {
        case login
        case register
        case onboarding
        case main
    }

    @StateObject private var authViewModel = AuthViewModel()
    // A token already in the Keychain means a previous launch signed in —
    // read that directly (no need to touch the MainActor-isolated
    // AuthViewModel just to pick the initial phase).
    @State private var phase: Phase = TokenStore.load() != nil ? .onboarding : .login

    var body: some View {
        Group {
            switch phase {
            case .login:
                LoginView(
                    viewModel: authViewModel,
                    onSwitchToRegister: {
                        authViewModel.clearError()
                        phase = .register
                    }
                )
            case .register:
                RegisterView(
                    viewModel: authViewModel,
                    onSwitchToLogin: {
                        authViewModel.clearError()
                        phase = .login
                    }
                )
            case .onboarding:
                OnboardingGoalView(onContinue: { phase = .main })
            case .main:
                MainTabView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated, phase == .login || phase == .register {
                phase = .onboarding
            }
        }
    }
}

private struct MainTabView: View {
    @State private var isLoggingFood = false

    var body: some View {
        TabView {
            TodayView(onLogFood: { isLoggingFood = true }, onLogBurn: {})
                .tabItem { Label("Today", systemImage: "flame") }

            ProgressScreenView(onAddCheckIn: {})
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(Palette.ink)
        .sheet(isPresented: $isLoggingFood) {
            LogFoodView(
                onCancel: { isLoggingFood = false },
                onSave: { isLoggingFood = false }
            )
        }
    }
}

#Preview {
    RootView()
}
