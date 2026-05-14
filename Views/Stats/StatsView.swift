//
//  StatsView.swift
//  TravelPin
//
//  Created by longanh on 13/5/26.
//

import SwiftUI

struct StatsView: View {
    var body: some View {
        ZStack {
            Color("StatsView").ignoresSafeArea()
            VStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)
                Text("Stats")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

