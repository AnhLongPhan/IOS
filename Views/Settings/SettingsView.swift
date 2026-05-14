//
//  SettingsView.swift
//  TravelPin
//
//  Created by longanh on 13/5/26.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
                Text("Settings")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
