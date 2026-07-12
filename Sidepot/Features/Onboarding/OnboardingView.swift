import SwiftUI
import SwiftData
import SidepotCore

/// First-launch sequence (§18): three explanatory pages, then a required profile step. Skip is
/// available everywhere except the final step.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var page = 0
    @State private var firstName = ""
    @State private var lastName = ""

    private let explanatoryPages: [(title: String, message: String, systemImage: String)] = [
        ("Track the game, not the GPS", "Keep using 18Birdies for scoring and stats. Sidepot handles the side bets.", "figure.golf"),
        ("Settle every bet automatically", "Skins, Nassau, presses, and custom bets are tracked and settled for you.", "checklist"),
        ("Friendly games only", "Sidepot never processes payments or moves money — it just keeps score of who owes who.", "person.2.fill")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(explanatoryPages.enumerated()), id: \.offset) { index, page in
                    explanatoryPage(page)
                        .tag(index)
                }
                profilePage
                    .tag(explanatoryPages.count)
            }
            .tabViewStyle(.page)

            if page < explanatoryPages.count {
                SecondaryButton("Skip") {
                    appState.completeOnboarding()
                }
                .padding(.horizontal, SidepotTheme.Spacing.l)
                .padding(.bottom, SidepotTheme.Spacing.l)
            }
        }
        .background(SidepotTheme.Colors.background)
    }

    private func explanatoryPage(_ page: (title: String, message: String, systemImage: String)) -> some View {
        VStack(spacing: SidepotTheme.Spacing.l) {
            Spacer()
            Image(systemName: page.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(SidepotTheme.Colors.accent)
            Text(page.title)
                .font(SidepotTheme.Typography.title)
                .multilineTextAlignment(.center)
            Text(page.message)
                .font(SidepotTheme.Typography.body)
                .foregroundStyle(SidepotTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SidepotTheme.Spacing.l)
            Spacer()
            PrimaryButton("Continue") {
                withAnimation { self.page += 1 }
            }
            .padding(.horizontal, SidepotTheme.Spacing.l)
        }
    }

    private var profilePage: some View {
        VStack(spacing: SidepotTheme.Spacing.l) {
            Spacer()
            Text("Create your profile")
                .font(SidepotTheme.Typography.title)
            VStack(spacing: SidepotTheme.Spacing.s) {
                TextField("First name", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                TextField("Last name (optional)", text: $lastName)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, SidepotTheme.Spacing.l)
            Spacer()
            PrimaryButton("Get Started", isEnabled: !firstName.trimmingCharacters(in: .whitespaces).isEmpty) {
                let player = Player(firstName: firstName, lastName: lastName)
                modelContext.insert(player)
                appState.completeOnboarding()
            }
            .padding(.horizontal, SidepotTheme.Spacing.l)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState(hasCompletedOnboarding: false))
        .modelContainer(PersistenceController.makePreviewContainer())
}
