//
//  AlbumDetailView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @State private var tracks: [String] = []

    private let lastFMService = LastFMService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let imageURL = album.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit().frame(height: 200).cornerRadius(20)
                        }
                    }
                }

                Text(album.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Artista: \(album.artist)")
                    .font(.headline)

                Divider()

                Text("🎵 Canciones")
                    .font(.headline)

                ForEach(tracks, id: \.self) { track in
                    Text(track)
                        .padding(.vertical, 4)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(album.name)
            .onAppear {
                loadAlbumTracks()
            }
        }
    }

    private func loadAlbumTracks() {
        lastFMService.getAlbumInfo(artist: album.artist, album: album.name) { trackList in
            DispatchQueue.main.async {
                self.tracks = trackList
            }
        }
    }
}
