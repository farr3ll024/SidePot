import SwiftUI
import SidepotCore

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasCompletedOnboarding {
            tabs
        } else {
            OnboardingView()
        }
    }

    private var tabs: some View {
        @Bindable var appState = appState
        return TabView(selection: $appState.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(RootTab.home)

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(RootTab.history)

            NavigationStack {
                StandingsView()
            }
            .tabItem { Label("Standings", systemImage: "chart.bar.fill") }
            .tag(RootTab.standings)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(RootTab.settings)
        }
        .tint(SidepotTheme.Colors.accent)
    }
}

#Preview("Onboarded") {
    RootView()
        .environment(AppState(hasCompletedOnboarding: true))
        .environment(AppEnvironment())
        .modelContainer(PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate))
}

#Preview("First launch") {
    RootView()
        .environment(AppState(hasCompletedOnboarding: false))
        .environment(AppEnvironment())
        .modelContainer(PersistenceController.makePreviewContainer())
}
