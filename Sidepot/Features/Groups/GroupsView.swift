import SwiftUI
import SwiftData
import SidepotCore

struct GroupsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GolfGroup.name) private var groups: [GolfGroup]
    @Query(sort: \Player.firstName) private var players: [Player]

    @State private var isPresentingNewGroup = false
    @State private var newGroupName = ""

    var body: some View {
        Group {
            if groups.isEmpty {
                EmptyStateView(
                    systemImage: "person.3.fill",
                    title: "No groups yet",
                    message: "Create a group for your regular foursome so round setup only takes a few taps.",
                    actionTitle: "New Group",
                    action: { isPresentingNewGroup = true }
                )
            } else {
                List {
                    ForEach(groups.filter { !$0.isArchived }) { group in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name).font(SidepotTheme.Typography.headline)
                            Text("\(group.players?.count ?? 0) players")
                                .font(SidepotTheme.Typography.caption)
                                .foregroundStyle(SidepotTheme.Colors.textSecondary)
                        }
                    }
                    .onDelete(perform: archiveGroups)
                }
            }
        }
        .navigationTitle("Groups")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Group") { isPresentingNewGroup = true }
            }
        }
        .sheet(isPresented: $isPresentingNewGroup) {
            NavigationStack {
                Form {
                    TextField("Group name", text: $newGroupName)
                }
                .navigationTitle("New Group")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isPresentingNewGroup = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let group = GolfGroup(name: newGroupName)
                            modelContext.insert(group)
                            newGroupName = ""
                            isPresentingNewGroup = false
                        }
                        .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func archiveGroups(at offsets: IndexSet) {
        let visible = groups.filter { !$0.isArchived }
        for index in offsets {
            visible[index].isArchived = true
        }
    }
}

#Preview("Populated") {
    NavigationStack { GroupsView() }
        .modelContainer(PersistenceController.makePreviewContainer(populate: PreviewFixtures.populate))
}

#Preview("Empty") {
    NavigationStack { GroupsView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
