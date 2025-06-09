//
//  SpotifyService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import Foundation

class SpotifyService {
    private let accessToken = "f0c31eb5d058446493ee37f677a61b03"

    func searchTrack(artist: String, track: String, completion: @escaping (String?) -> Void) {
        let query = "\(artist) \(track)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=1"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tracks = json["tracks"] as? [String: Any],
                   let items = tracks["items"] as? [[String: Any]],
                   let firstItem = items.first,
                   let id = firstItem["id"] as? String {
                    completion(id)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
    
    func searchArtists(query: String, completion: @escaping ([SpotifyArtist]) -> Void) {
         let token = accessToken

        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.spotify.com/v1/search?q=\(queryEncoded)&type=artist&limit=50"

        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else {
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let artistsDict = (json["artists"] as? [String: Any])?["items"] as? [[String: Any]] {

                    let artists = artistsDict.map { item in
                        let id = item["id"] as? String ?? UUID().uuidString
                        let name = item["name"] as? String ?? "Desconocido"
                        let images = item["images"] as? [[String: Any]] ?? []
                        let imageURL = images.first?["url"] as? String

                        return SpotifyArtist(id: id, name: name, imageURL: imageURL)
                    }

                    completion(artists)
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }.resume()
    }

    
}
