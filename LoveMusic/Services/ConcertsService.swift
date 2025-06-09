//
//  ConcertsService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import Foundation

import Foundation

class ConcertsService {
    private let appId = "LoveMusicApp"

    func getConcerts(for artist: String, completion: @escaping ([Concert]) -> Void) {
        // Limpieza básica del nombre
        let cleanArtist = artist.replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: " ", with: "%20")

        let urlString = "https://rest.bandsintown.com/artists/\(cleanArtist)/events?app_id=\(appId)"

        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let concerts = jsonArray.compactMap { item -> Concert? in
                        guard
                            let id = item["id"] as? Int,
                            let datetime = item["datetime"] as? String,
                            let venue = item["venue"] as? [String: Any],
                            let venueName = venue["name"] as? String,
                            let city = venue["city"] as? String,
                            let country = venue["country"] as? String,
                            let latitude = venue["latitude"] as? Double,
                            let longitude = venue["longitude"] as? Double
                        else {
                            return nil
                        }

                        return Concert(
                            id: String(id),
                            date: String(datetime.prefix(10)),
                            venueName: venueName,
                            city: city,
                            country: country,
                            latitude: latitude,
                            longitude: longitude
                        )
                    }

                    DispatchQueue.main.async {
                        completion(concerts)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                }
            } catch {
                print("JSON parsing error: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
}

