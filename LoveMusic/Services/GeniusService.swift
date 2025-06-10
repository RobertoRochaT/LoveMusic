//
//  GeniusService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import Foundation

class GeniusService {
    private let accessToken = "tu api token"

    func searchLyricsURL(artist: String, song: String, completion: @escaping (String?) -> Void) {
        let query = "\(artist) \(song)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.genius.com/search?q=\(query)&access_token=\(accessToken)"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = json["response"] as? [String: Any],
                   let hits = response["hits"] as? [[String: Any]],
                   let firstHit = hits.first,
                   let result = firstHit["result"] as? [String: Any],
                   let url = result["url"] as? String {
                    completion(url)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
