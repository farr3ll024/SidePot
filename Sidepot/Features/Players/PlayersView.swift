import SwiftUI
import SwiftData
import SidepotCore

/// §18: create, edit, archive, search. Players are never hard-deleted — archiving is the only
/// removal path, since historical rounds may still reference them.
struct PlayersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.firstName) private var players: [Player]

    @State private var searchText = ""
    @State private var isPresentingNewPlayer = false
    @State private var newFirstName = ""
    @State private var newLastName = ""

    private var filteredPlayers: [Player] {
        let active = players.filter { !$0.isArchived }
        guard !searchText.isEmpty else { return active }
        return active.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if players.isEmpty {
                EmptyStateView(
                    systemImage: "person.fill.badge.plus",
                    title: "No players yet",
                    message: "Add the people you regularly play with to speed up round setup.",
                    actionTitle: "Add Player",
                    action: { isPresentingNewPlayer = true }
                )
            } else {
                List {
                    ForEach(filteredPlayers) { player in
                        HStack(spacing: SidepotTheme.Spacing.m) {
                            PlayerAvatar(initials: player.initials)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.displayName).font(SidepotTheme.Typography.headline)
                                if let handicap = player.defaultHandicapIndex {
                                    Text("Handicap \(handicap, specifier: "%.1f")")
                                        .font(SidepotTheme.Typography.caption)
                                        .foregroundStyle(SidepotTheme.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: archivePlayers)
                }
                .searchable(text: $searchText)
            }
        }
        .navigationTitle("Players")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add") { isPresentingNewPlayer = true }
            }
        }
        .sheet(isPresented: $isPresentingNewPlayer) {
            NavigationStack {
                Form {
                    TextField("First name", text: $newFirstName)
                    TextField("Last name", text: $newLastName)
                }
                .navigationTitle("New Player")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isPresentingNewPlayer = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let player = Player(firstName: newFirstName, lastName: newLastName)
                            modelContext.insert(player)
                            newFirstName = ""
                            newLastName = ""
                            isPresentingNewPlayer = false
                        }
                        .disabled(newFirstName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func archivePlayers(at offsets: IndexSet) {
        for index in offsets {
            filteredPlayers[index].isArchived = true
        }
    }
}

#Preview("Populated") {
    NavigationStack { PlayersView() }
        .modelContainer(PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate))
}

#Preview("Empty") {
    NavigationStack { PlayersView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
