import SwiftUI

/// Wires the five screens together: onboarding leads into a Today/Progress
/// tab flow, and Today presents Log food as a sheet.
struct RootView: View {
    private enum Phase {
        case onboarding
        case main
    }

    @State private var phase: Phase = .onboarding

    var body: some View {
        switch phase {
        case .onboarding:
            OnboardingGoalView(onContinue: { phase = .main })
        case .main:
            MainTabView()
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
