import SwiftUI

@main
struct TravelPinApp: App {
    @State private var viewModel = CheckInViewModel()
    @State private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(viewModel)
                .environment(locationService)
        }
    }
}
