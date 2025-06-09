//
//  SongDetailView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI

struct SongDetailView: View {
    let artistName: String
    let trackName: String

    @State private var lyricsText: String? = nil
    @State private var coverArtURL: String? = nil
    @State private var songLinks: [String: String] = [:]

    private let lrcLibService = LRCLibService()
    private let songlinkService = SonglinkService()
    private let spotifyService = SpotifyService()
    private let iTunesService = ITunesAPIService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // cover art
                if let coverArtURL = coverArtURL, let url = URL(string: coverArtURL), !coverArtURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit().frame(height: 200).cornerRadius(20)
                        } else {
                            Color.gray.frame(height: 200).cornerRadius(20)
                        }
                    }
                } else {
                    Color.gray.frame(height: 200).cornerRadius(20)
                }

                // song title
                Text(trackName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("de \(artistName)")
                    .font(.headline)
                    .foregroundColor(.gray)

                Divider()

                // lyrics
                Text("Letra")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let lyricsText = lyricsText {
                    Text(lyricsText)
                        .padding()
                } else {
                    Text("Buscando letra...")
                        .foregroundColor(.gray)
                        .padding()
                }

                Divider()

                Text("Reproducir en:")
                    .font(.headline)

                if songLinks.isEmpty {
                    Text("Buscando enlaces...")
                        .foregroundColor(.gray)
                } else {
                    ForEach(Array(songLinks.keys.sorted().prefix(10)), id: \.self) { platform in
                        if let url = songLinks[platform] {
                            Link("🎵 \(platform.capitalized)", destination: URL(string: url)!)
                                .padding(.vertical, 4)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("🎵 \(trackName)")
        .onAppear {
            loadLyrics()
            loadSongLinks()
        }
    }

    private func loadLyrics() {
        let cleanName = cleanTrackName(trackName)
        lrcLibService.getLyrics(artist: artistName, song: cleanName) { lyrics in
            DispatchQueue.main.async {
                if let lyrics = lyrics {
                    self.lyricsText = lyrics
                } else {
                    self.lyricsText = "No se encontró letra disponible."
                }
            }
        }
    }

    private func loadSongLinks() {
        let cleanName = cleanTrackName(trackName)

        // primero intenta Spotify
        spotifyService.searchTrack(artist: artistName, track: cleanName) { trackId in
            if let trackId = trackId {
                let spotifyTrackURL = "https://open.spotify.com/track/\(trackId)"
                songlinkService.getSongLinks(url: spotifyTrackURL) { links, thumb in
                    DispatchQueue.main.async {
                        self.songLinks = links
                        self.coverArtURL = thumb
                    }
                }
            } else {
                // fallback → iTunes
                iTunesService.searchTrack(artist: artistName, track: cleanName) { trackURL in
                    if let trackURL = trackURL {
                        songlinkService.getSongLinks(url: trackURL) { links, thumb in
                            DispatchQueue.main.async {
                                self.songLinks = links
                                self.coverArtURL = thumb
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.songLinks = [:]
                            self.coverArtURL = nil
                        }
                    }
                }
            }
        }
    }

    private func cleanTrackName(_ name: String) -> String {
        var cleaned = name

        // quita (feat. X)
        if let range = cleaned.range(of: #"(\s*\(feat\. .*?\))"#, options: .regularExpression) {
            cleaned.removeSubrange(range)
        }

        // quita (with X)
        if let range = cleaned.range(of: #"(\s*\(with .*?\))"#, options: .regularExpression) {
            cleaned.removeSubrange(range)
        }

        // quita - X
        if let range = cleaned.range(of: #"(\s*-\s*.*)"#, options: .regularExpression) {
            cleaned.removeSubrange(range)
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
