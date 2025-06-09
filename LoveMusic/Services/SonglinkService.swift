//
//  SonglinkService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import Foundation

class SonglinkService {
    private let baseURL = "https://api.song.link/v1-alpha.1/links"

    func getSongLinks(url: String, completion: @escaping ([String: String], String?) -> Void) {
        let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?url=\(encodedURL)&userCountry=US"

        guard let url = URL(string: urlString) else {
            completion([:], nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion([:], nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let linksByPlatform = json["linksByPlatform"] as? [String: Any],
                   let entitiesByUniqueId = json["entitiesByUniqueId"] as? [String: Any] {

                    // obtener links
                    var links: [String: String] = [:]
                    for (platform, platformData) in linksByPlatform {
                        if let platformDict = platformData as? [String: Any],
                           let linkURL = platformDict["url"] as? String {
                            links[platform] = linkURL
                        }
                    }

                    // obtener primer thumbnail disponible
                    var thumbnailURL: String? = nil
                    for (_, entity) in entitiesByUniqueId {
                        if let entityDict = entity as? [String: Any],
                           let thumb = entityDict["thumbnailUrl"] as? String,
                           !thumb.isEmpty {
                            thumbnailURL = thumb
                            break
                        }
                    }

                    completion(links, thumbnailURL)
                } else {
                    completion([:], nil)
                }
            } catch {
                completion([:], nil)
            }
        }.resume()
    }
}
