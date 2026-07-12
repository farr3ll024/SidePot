import SwiftUI
import SidepotCore

/// §25 privacy copy, surfaced where a user would actually look for it.
struct AboutView: View {
    var body: some View {
        List {
            Section("About Sidepot") {
                Text("Sidepot is a companion app for golfers who already use an app like 18Birdies for GPS, scorekeeping, and stats — but want a better way to manage friendly on-course betting.")
            }
            Section("Privacy") {
                Text("Sidepot does not process payments.")
                Text("Sidepot does not connect to bank accounts.")
                Text("Sidepot does not sell user data.")
                Text("Sidepot stores round and player data on your device.")
                Text("Payment handles (Venmo, Cash App) are optional and are only shown to help you settle up outside the app.")
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    NavigationStack { AboutView() }
}
