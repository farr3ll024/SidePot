import SwiftUI
import SidepotCore

struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink("Players") { PlayersView() }
            NavigationLink("Default Rules") { DefaultRulesView() }
            NavigationLink("About") { AboutView() }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate))
}
