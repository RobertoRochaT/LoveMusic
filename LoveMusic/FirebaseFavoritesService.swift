//
//  FirebaseFavoritesService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import FirebaseFirestore

class FirebaseFavoritesService {
    static let shared = FirebaseFavoritesService()
    private let db = Firestore.firestore()

    func saveFavorite(station: RadioStation, userId: String) {
        db.collection("users").document(userId).collection("favorites").document(station.id).setData([
            "name": station.name,
            "url": station.url,
            "favicon": station.favicon,
            "tags": station.tags
        ]) { error in
            if let error = error {
                print("Error saving favorite to Firebase: \(error)")
            } else {
                print("Favorite saved to Firebase!")
            }
        }
    }

    func loadFavorites(userId: String, completion: @escaping ([RadioStation]) -> Void) {
        db.collection("users").document(userId).collection("favorites").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading favorites from Firebase: \(error)")
                completion([])
                return
            }

            let stations = snapshot?.documents.compactMap { doc -> RadioStation? in
                let data = doc.data()
                return RadioStation(
                    stationuuid: doc.documentID,
                    name: data["name"] as? String ?? "",
                    url: data["url"] as? String ?? "",
                    favicon: data["favicon"] as? String ?? "",
                    tags: data["tags"] as? String ?? "",
                    countrycode: "XX",
                    country: "",
                    state: nil,
                    language: "es"
                )
            } ?? []
            completion(stations)
        }
    }
}
