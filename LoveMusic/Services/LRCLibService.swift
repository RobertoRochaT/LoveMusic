//
//  LRCLibService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import Foundation

class LRCLibService {
    func getLyrics(artist: String, song: String, completion: @escaping (String?) -> Void) {
        let artistEncoded = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let songEncoded = song.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.lrclib.net/api/get?artist=\(artistEncoded)&track=\(songEncoded)"

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
                   let syncedLyrics = json["syncedLyrics"] as? String {
                    completion(syncedLyrics)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
