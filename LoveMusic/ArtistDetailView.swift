//
//  ArtistDetailView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 08/06/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct ArtistDetailView: View {
    let artistName: String

    @State private var artistInfo: ArtistInfo? = nil
    @State private var topTracks: [String] = []
    @State private var concerts: [Concert] = []
    @State private var showFullMap = false
    @State private var artistLocation: CLLocationCoordinate2D? = nil

    private let lastFMService = LastFMService()
    private let concertsService = ConcertsService()

    // Default location → Londres (por si no se puede sacar la ubicación real)
    private let defaultLocation = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Imagen
                if let imageURL = artistInfo?.imageURL, let url = URL(string: imageURL), !imageURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit().frame(height: 200).cornerRadius(20)
                        }
                    }
                }

                // Nombre
                Text(artistName)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Bio
                if let bio = artistInfo?.bio {
                    Text(bio)
                        .font(.body)
                        .padding()
                }

                // Tags
                if let tags = artistInfo?.tags, !tags.isEmpty {
                    Text("Tags: \(tags.joined(separator: ", "))")
                        .font(.subheadline)
                        .padding()
                }

                Divider()

                // Top Canciones
                Text("🎵 Top Canciones")
                    .font(.headline)

                ForEach(Array(topTracks.prefix(10)), id: \.self) { track in
                    NavigationLink(destination: SongDetailView(artistName: artistName, trackName: track)) {
                        Text(track)
                            .padding(.vertical, 4)
                    }
                }

                Divider()

                // Conciertos
                Text("🎫 Próximos Conciertos")
                    .font(.headline)

                if concerts.isEmpty {
                    Text("No se encontraron conciertos.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(concerts.prefix(10)) { concert in
                        VStack(alignment: .leading) {
                            Text("\(concert.date) - \(concert.venueName)")
                                .font(.subheadline)
                            Text("\(concert.city), \(concert.country)")
                                .font(.caption)

                            Button(action: {
                                openInMaps(lat: concert.latitude, lon: concert.longitude)
                            }) {
                                Text("🌍 Ver en Google Maps")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }

                            Divider()
                        }
                        .padding(.vertical, 4)
                    }
                }

                Divider()

                // Mapa
                Text("🌍 Mapa de ubicación")
                    .font(.headline)

                Map(coordinateRegion: .constant(makeRegion()), annotationItems: mapAnnotations()) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            Text(item.label)
                                .font(.caption)
                                .fixedSize()
                        }
                    }
                }
                .frame(height: 300)
                .cornerRadius(10)

                // Botón mapa completo
                Button(action: {
                    showFullMap = true
                }) {
                    Text("🗺️ Ver Mapa Completo")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
                .sheet(isPresented: $showFullMap) {
                    ConcertsMapView(artistName: artistName, artistLocation: artistLocation ?? defaultLocation, concerts: concerts)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("🎵 \(artistName)")
            .onAppear {
                loadArtistInfo()
                loadTopTracks()
                loadConcerts()
            }
        }
    }

    private func loadArtistInfo() {
        lastFMService.getArtistInfo(artist: artistName) { info in
            DispatchQueue.main.async {
                self.artistInfo = info

                if let bio = info?.bio {
                    self.geocodeLocation(from: bio)
                }
            }
        }
    }

    private func loadTopTracks() {
        lastFMService.getTopTracks(artist: artistName) { tracks in
            DispatchQueue.main.async {
                self.topTracks = tracks
            }
        }
    }

    private func loadConcerts() {
        concertsService.getConcerts(for: artistName) { results in
            DispatchQueue.main.async {
                self.concerts = results
            }
        }
    }

    private func openInMaps(lat: Double, lon: Double) {
        let urlString = "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func makeRegion() -> MKCoordinateRegion {
        if let artistLocation = artistLocation {
            return MKCoordinateRegion(
                center: artistLocation,
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
        } else if let first = concerts.first {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
        } else {
            return MKCoordinateRegion(
                center: defaultLocation,
                span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
            )
        }
    }

    private func mapAnnotations() -> [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []

        if let artistLocation = artistLocation {
            annotations.append(MapAnnotationItem(coordinate: artistLocation, label: "Origen del Artista"))
        }

        for concert in concerts {
            let coord = CLLocationCoordinate2D(latitude: concert.latitude, longitude: concert.longitude)
            annotations.append(MapAnnotationItem(coordinate: coord, label: concert.venueName))
        }

        return annotations
    }

    private func geocodeLocation(from bio: String) {
        let geocoder = CLGeocoder()

        // Lista de patrones para encontrar la ciudad en la bio
        let patterns = [
            #"born in ([A-Za-z\s,]+)"#,
            #"from ([A-Za-z\s,]+)"#,
            #"formed in ([A-Za-z\s,]+)"#,
            #"originating from ([A-Za-z\s,]+)"#,
            #"nacido en ([A-Za-z\s,]+)"#,
            #"de ([A-Za-z\s,]+)"#
        ]

        var locationString: String? = nil

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: bio, range: NSRange(bio.startIndex..., in: bio))

                if let match = matches.first, match.numberOfRanges >= 2 {
                    if let range = Range(match.range(at: 1), in: bio) {
                        locationString = String(bio[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }
            }
        }

        guard let location = locationString, !location.isEmpty else {
            print("No se encontró ubicación en la bio, usando default.")
            artistLocation = defaultLocation
            return
        }

        print("Buscando coordenadas de: \(location)")

        geocoder.geocodeAddressString(location) { placemarks, error in
            if let coordinate = placemarks?.first?.location?.coordinate {
                DispatchQueue.main.async {
                    self.artistLocation = coordinate
                    print("Ubicación geocodificada: \(coordinate.latitude), \(coordinate.longitude)")
                }
            } else {
                print("No se pudo geocodificar ubicación, usando default.")
                DispatchQueue.main.async {
                    self.artistLocation = defaultLocation
                }
            }
        }
    }
}
