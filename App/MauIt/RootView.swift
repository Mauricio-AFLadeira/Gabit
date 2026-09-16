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
                MainTabView(authViewModel: authViewModel)
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                if phase == .login || phase == .register { phase = .onboarding }
            } else {
                phase = .login
            }
        }
    }
}

private struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel

    @State private var isLoggingFood = false
    @State private var isMenuOpen = false
    @State private var isShowingProfile = false

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 0) {
                ControlBar(onMenuTap: { withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen = true } })

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
                .sheet(isPresented: $isShowingProfile) {
                    ProfileView(user: authViewModel.session?.user, onDone: { isShowingProfile = false })
                }
            }

            if isMenuOpen {
                SideMenu(
                    userName: authViewModel.session?.user.name ?? "",
                    userEmail: authViewModel.session?.user.email ?? "",
                    onSelectProfile: {
                        withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen = false }
                        isShowingProfile = true
                    },
                    onLogout: {
                        withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen = false }
                        authViewModel.signOut()
                    },
                    onDismiss: { withAnimation(.easeInOut(duration: 0.25)) { isMenuOpen = false } }
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
    }
}

#Preview {
    RootView()
}
