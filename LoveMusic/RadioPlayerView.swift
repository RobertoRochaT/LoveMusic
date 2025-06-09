//
//  RadioPlayerView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 08/06/25.
//

import SwiftUI
import AVKit

struct RadioPlayerView: View {
    let station: RadioStation

    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    @State private var isFavorite = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Imagen de la estación
            if let url = URL(string: station.favicon), !station.favicon.isEmpty {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .cornerRadius(20)
                    } else {
                        Color.gray
                            .frame(width: 200, height: 200)
                            .cornerRadius(20)
                    }
                }
            } else {
                Color.gray
                    .frame(width: 200, height: 200)
                    .cornerRadius(20)
            }

            // Nombre
            Text(station.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Descripción / tags
            Text(station.tags.isEmpty ? "Estación de radio en vivo" : station.tags.capitalized)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Botones
            HStack(spacing: 40) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.green)
                    .font(.title2)

                Button(action: {
                    if isPlaying {
                        player?.pause()
                    } else {
                        guard let streamURL = URL(string: station.url) else { return }
                        player = AVPlayer(url: streamURL)
                        player?.play()

                        // GUARDAR EN HISTORIAL
                        LocalDatabase.shared.saveToHistory(station: station)
                    }
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .foregroundColor(.green)
                        .frame(width: 70, height: 70)
                }

                // BOTÓN FAVORITOS
                Button(action: {
                    LocalDatabase.shared.saveFavorite(station: station)
                    isFavorite = true
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .resizable()
                        .foregroundColor(.green)
                        .frame(width: 30, height: 30)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.white.ignoresSafeArea())
        .onDisappear {
            player?.pause()
        }
    }
}
