import SwiftUI
import SwiftData
import SidepotCore

@main
struct SidepotApp: App {
    @State private var appState = AppState()
    @State private var appEnvironment = AppEnvironment()
    private let modelContainer = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(appEnvironment)
        }
        .modelContainer(modelContainer)
    }
}
