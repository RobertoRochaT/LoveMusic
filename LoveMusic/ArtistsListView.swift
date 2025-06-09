//
//  ArtistsListView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI

struct ArtistsListView: View {
    @State private var searchQuery = ""
    @State private var artists: [Artist] = []

    private let lastFMService = LastFMService()

    var body: some View {
        VStack {
            TextField("Buscar artista", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchQuery) { newValue in
                    if newValue.isEmpty {
                        loadTopArtists()
                    } else {
                        searchArtists()
                    }
                }

            List(artists) { artist in
                NavigationLink(destination: ArtistDetailView(artistName: artist.name)) {
                    HStack {
                        if let imageURL = artist.imageURL, let url = URL(string: imageURL), !imageURL.isEmpty {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().frame(width: 50, height: 50).clipShape(Circle())
                                } else {
                                    Color.gray.frame(width: 50, height: 50).clipShape(Circle())
                                }
                            }
                        } else {
                            Color.gray.frame(width: 50, height: 50).clipShape(Circle())
                        }

                        Text(artist.name)
                            .font(.headline)
                    }
                }
            }
        }
        .navigationTitle("🎤 Artistas")
        .onAppear {
            loadTopArtists()
        }
    }

    private func searchArtists() {
        lastFMService.searchArtist(query: searchQuery) { results in
            DispatchQueue.main.async {
                self.artists = results
            }
        }
    }

    private func loadTopArtists() {
        lastFMService.getTopArtists { results in
            DispatchQueue.main.async {
                self.artists = results
            }
        }
    }
}
