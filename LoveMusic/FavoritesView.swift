//
//  FavoritesView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 08/06/25.
//

import SwiftUI

struct FavoritesView: View {
    @State private var favorites: [RadioStation] = []

    var body: some View {
        List(favorites, id: \.stationuuid) { station in
            VStack(alignment: .leading) {
                Text(station.name)
                    .font(.headline)
                Text(station.url)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("⭐ Favoritos")
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                loadFavorites()
            }
            #else
            loadFavorites()
            #endif
        }
    }

    private func loadFavorites() {
        let loaded = LocalDatabase.shared.loadFavorites()
        favorites = loaded.filter { !$0.url.isEmpty && URL(string: $0.url) != nil }
    }
}
