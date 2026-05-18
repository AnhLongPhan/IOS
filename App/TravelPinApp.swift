import SwiftUI

@main
struct TravelPinApp: App {
    @State private var viewModel = CheckInViewModel()
    @State private var locationService = LocationService()
    @State private var userProfileStore = UserProfileStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if userProfileStore.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
                .environment(viewModel)
                .environment(locationService)
                .environment(userProfileStore)
                .preferredColorScheme(userProfileStore.displayMode.colorScheme)
        }
    }
}
