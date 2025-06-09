//
//  HistoryView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI

struct HistoryView: View {
    @State private var history: [RadioStation] = []

    var body: some View {
        List(history, id: \.stationuuid) { station in
            Text(station.name)
        }
        .onAppear {
            history = LocalDatabase.shared.loadHistory()
        }
    }
}
