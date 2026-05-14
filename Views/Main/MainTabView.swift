import SwiftUI

struct MainTabView: View {
    @Environment(CheckInViewModel.self) var viewModel

    var body: some View {
        TabView {
            MapContainerView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            PlacesView()
                .tabItem {
                    Label("Places", systemImage: "list.bullet")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
