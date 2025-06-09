//
//  LastFMService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//  12fa71bb05c02475e810ad000fe97441
import Foundation

class LastFMService {
    private let apiKey = "12fa71bb05c02475e810ad000fe97441"
    private let baseURL = "https://ws.audioscrobbler.com/2.0/"

    func getTopArtists(completion: @escaping ([Artist]) -> Void) {
        let urlString = "\(baseURL)?method=chart.gettopartists&api_key=\(apiKey)&format=json&limit=10"

        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let artistsDict = (json["artists"] as? [String: Any])?["artist"] as? [[String: Any]] {

                    let artists = artistsDict.map { item in
                        let name = item["name"] as? String ?? "Desconocido"
                        let images = item["image"] as? [[String: Any]] ?? []
                        let imageURL = images.first(where: { ($0["size"] as? String) == "extralarge" })?["#text"] as? String
                        let cleanedImageURL = (imageURL?.isEmpty == false) ? imageURL : nil

                        return Artist(name: name, imageURL: cleanedImageURL)
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


    func searchArtist(query: String, completion: @escaping ([Artist]) -> Void) {
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?method=artist.search&artist=\(queryEncoded)&api_key=\(apiKey)&format=json&limit=50"

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
                   let results = json["results"] as? [String: Any],
                   let artistMatches = results["artistmatches"] as? [String: Any],
                   let artistArray = artistMatches["artist"] as? [[String: Any]] {

                    let artists = artistArray.compactMap { artistDict -> Artist? in
                        guard let name = artistDict["name"] as? String else { return nil }

                        let imageURL = self.extractLargeImageURL(from: artistDict)

                        return Artist(name: name, imageURL: imageURL)
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

    // MARK: - Helper

    private func extractLargeImageURL(from artistDict: [String: Any]) -> String? {
        if let imageArray = artistDict["image"] as? [[String: Any]] {
            // buscar primero "extralarge", si no hay, "large", si no hay, nil
            let preferredSizes = ["extralarge", "large", "medium", "small"]
            for size in preferredSizes {
                if let imageDict = imageArray.first(where: { ($0["size"] as? String) == size }),
                   let urlText = imageDict["#text"] as? String,
                   !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return urlText
                }
            }
        }

        return nil
    }
    
    func getArtistInfo(artist: String, completion: @escaping (ArtistInfo?) -> Void) {
        let queryEncoded = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?method=artist.getinfo&artist=\(queryEncoded)&api_key=\(apiKey)&format=json"

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
                   let artistDict = json["artist"] as? [String: Any] {

                    let name = artistDict["name"] as? String ?? ""
                    let bioContent = ((artistDict["bio"] as? [String: Any])?["summary"] as? String)?
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) ?? ""
                    let tagsArray = (artistDict["tags"] as? [String: Any])?["tag"] as? [[String: Any]] ?? []
                    let tags = tagsArray.compactMap { $0["name"] as? String }

                    let imageURL = self.extractLargeImageURL(from: artistDict)

                    let artistInfo = ArtistInfo(name: name, bio: bioContent, imageURL: imageURL, tags: tags)
                    completion(artistInfo)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }

    func getTopTracks(artist: String, completion: @escaping ([String]) -> Void) {
        let queryEncoded = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)?method=artist.gettoptracks&artist=\(queryEncoded)&api_key=\(apiKey)&format=json&limit=50"

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
                   let topTracksDict = json["toptracks"] as? [String: Any],
                   let trackArray = topTracksDict["track"] as? [[String: Any]] {

                    let tracks = trackArray.compactMap { $0["name"] as? String }
                    completion(tracks)
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }.resume()
    }
    
    func getTopAlbums(for genre: String, completion: @escaping ([Album]) -> Void) {
        let apiKey = apiKey
        let urlString = "https://ws.audioscrobbler.com/2.0/?method=tag.gettopalbums&tag=\(genre)&api_key=\(apiKey)&format=json"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let albumsDict = (json["albums"] as? [String: Any])?["album"] as? [[String: Any]] {

                    let albums = albumsDict.map { item in
                        let name = item["name"] as? String ?? "Unknown"
                        let artist = (item["artist"] as? [String: Any])?["name"] as? String ?? "Unknown"
                        let images = item["image"] as? [[String: Any]] ?? []
                        let imageURL = images.last?["#text"] as? String

                        return Album(name: name, artist: artist, imageURL: imageURL)
                    }

                    completion(albums)
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }.resume()
    }

    func getAlbumInfo(artist: String, album: String, completion: @escaping ([String]) -> Void) {
        let apiKey = apiKey
        let artistEncoded = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let albumEncoded = album.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "https://ws.audioscrobbler.com/2.0/?method=album.getinfo&artist=\(artistEncoded)&album=\(albumEncoded)&api_key=\(apiKey)&format=json"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let albumDict = json["album"] as? [String: Any],
                   let tracksDict = albumDict["tracks"] as? [String: Any],
                   let trackList = tracksDict["track"] as? [[String: Any]] {

                    let tracks = trackList.compactMap { $0["name"] as? String }
                    completion(tracks)
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }.resume()
    }


}

