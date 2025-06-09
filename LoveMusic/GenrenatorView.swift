//
//  📄 GenrenatorView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI

struct GenrenatorView: View {
    @State private var genres: [String] = []
    @State private var stories: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button("🎲 Generar Géneros") {
                    fetchGenres()
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                Divider()

                Button("📚 Generar Historias de Géneros") {
                    fetchStories()
                }
                .font(.headline)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                ForEach(stories, id: \.self) { story in
                    Text(story)
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("🎲 Generador de Géneros")
        }
    }

    private func fetchGenres() {
        guard let url = URL(string: "https://binaryjazz.us/wp-json/genrenator/v1/genre/10") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let decoded = try? JSONDecoder().decode([String].self, from: data) {
                DispatchQueue.main.async {
                    self.genres = decoded
                }
            }
        }.resume()
    }

    private func fetchStories() {
        guard let url = URL(string: "https://binaryjazz.us/wp-json/genrenator/v1/story/5") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let decoded = try? JSONDecoder().decode([String].self, from: data) {
                DispatchQueue.main.async {
                    self.stories = decoded
                }
            }
        }.resume()
    }
}
