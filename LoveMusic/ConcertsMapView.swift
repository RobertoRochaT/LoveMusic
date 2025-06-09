//
//  ConcertsMapView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI
import MapKit

struct ConcertsMapView: View {
    let artistName: String
    let artistLocation: CLLocationCoordinate2D?
    let concerts: [Concert]

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
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
            .navigationTitle("🌍 Mapa de \(artistName)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
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
                center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
                span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
            )
        }
    }
}
