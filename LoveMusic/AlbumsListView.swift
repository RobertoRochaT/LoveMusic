//
//  AlbumsListView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//
import SwiftUI

struct AlbumsListView: View {
    @State private var genre: String = ""
    @State private var albums: [Album] = []
    private let lastFMService = LastFMService()

    private let defaultGenre = "rock"

    var body: some View {
        VStack {
            TextField("Filtrar por género", text: $genre)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: genre) { _ in
                    loadAlbums()
                }

            if albums.isEmpty {
                Text("No se encontraron álbumes para \"\(genre.isEmpty ? defaultGenre : genre)\".")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        HStack {
                            if let imageURL = album.imageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().frame(width: 50, height: 50).cornerRadius(8)
                                    } else {
                                        Color.gray.frame(width: 50, height: 50).cornerRadius(8)
                                    }
                                }
                            } else {
                                Color.gray.frame(width: 50, height: 50).cornerRadius(8)
                            }

                            VStack(alignment: .leading) {
                                Text(album.name).font(.headline)
                                Text(album.artist).font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("🎵 Álbumes")
        .onAppear {
            loadAlbums()
        }
    }

    private func loadAlbums() {
        let genreToUse = genre.isEmpty ? defaultGenre : genre

        lastFMService.getTopAlbums(for: genreToUse) { results in
            DispatchQueue.main.async {
                self.albums = results
            }
        }
    }
}
