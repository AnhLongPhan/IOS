//
//  MiniMapView.swift
//  TravelPin
//
//  Created by longanh on 14/5/26.
//

import SwiftUI
import MapKit

struct MiniMapView: View {
    let latitude: Double
    let longitude: Double

    @State private var position: MapCameraPosition = .automatic

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }

    var body: some View {
        Map(position: $position) {
            Marker("", coordinate: coordinate)
                .tint(.red)
        }
        .mapStyle(.standard)
        .mapControls { }
        .disabled(true) // không cho scroll/zoom
        .onAppear {
            position = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.02,
                        longitudeDelta: 0.02
                    )
                )
            )
        }
    }
}

#Preview {
    MiniMapView(latitude: 21.0285, longitude: 105.8542)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
