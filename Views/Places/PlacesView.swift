import SwiftUI

struct PlacesView: View {
    @Environment(CheckInViewModel.self) var viewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredCheckIns) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                        Text(item.locationDisplay)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(item.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Places")
        }
    }
}
