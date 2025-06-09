//
//  RadioBrowserService.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 08/06/25.
//

import Foundation

class RadioBrowserService {
    static let shared = RadioBrowserService() // Singleton (ahora sí puedes usar .shared)

    private let servers = [
        "https://de2.api.radio-browser.info"
    ]

    private var selectedServer: String {
        servers.first ?? "https://de2.api.radio-browser.info"
    }

    func fetchStationsByCountry(countryCode: String, completion: @escaping ([RadioStation]) -> Void) {
        let urlString = "\(selectedServer)/json/stations/bycountrycodeexact/\(countryCode)"
        fetchStations(from: urlString, completion: completion)
    }

    func getTopStations(limit: Int = 50, completion: @escaping ([RadioStation]) -> Void) {
        let urlString = "\(selectedServer)/json/stations/topclick/\(limit)"
        fetchStations(from: urlString, completion: completion)
    }

    private func fetchStations(from urlString: String, completion: @escaping ([RadioStation]) -> Void) {
        guard let url = URL(string: urlString) else {
            print("❌ URL inválida")
            completion([])
            return
        }

        var request = URLRequest(url: url)
        request.setValue("LoveMusic/1.0", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error de red: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            guard let data = data else {
                print("❌ No se recibió data")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            do {
                let stations = try JSONDecoder().decode([RadioStation].self, from: data)
                print("🎙️ Estaciones recibidas: \(stations.count)")
                DispatchQueue.main.async {
                    completion(stations)
                }
            } catch {
                print("❌ Error al parsear JSON: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
}
