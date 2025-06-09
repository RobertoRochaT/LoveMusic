//
//  DiscogsService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import Foundation

class DiscogsService {
    private let token = "YOUR_DISCOGS_TOKEN"

    func searchArtist(artist: String, completion: @escaping ([String]) -> Void) {
        let query = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.discogs.com/database/search?q=\(query)&type=artist&token=\(token)"

        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    let names = results.compactMap { $0["title"] as? String }
                    completion(names)
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }.resume()
    }
}
