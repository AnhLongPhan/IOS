import SwiftUI

@main
struct TravelPinApp: App {
    @State private var viewModel = CheckInViewModel()
    @State private var locationService = LocationService()
    @State private var userProfileStore = UserProfileStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if userProfileStore.shouldShowOnboarding {
                    OnboardingView()
                } else if userProfileStore.shouldShowUserSelection {
                    UserSelectionView()
                } else {
                    MainTabView()
                        .onAppear {
                            viewModel.setActiveUserID(userProfileStore.activeUserID)
                        }
                        .onChange(of: userProfileStore.activeUserID) { _, newValue in
                            viewModel.setActiveUserID(newValue)
                        }
                }
            }
                .environment(viewModel)
                .environment(locationService)
                .environment(userProfileStore)
                .preferredColorScheme(userProfileStore.displayMode.colorScheme)
        }
    }
}
