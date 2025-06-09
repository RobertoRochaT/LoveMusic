//
//  RadioListView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//
import SwiftUI

struct RadioListView: View {
    @State private var stations: [RadioStation] = []
    @State private var selectedCountry = "US" // default USA
    @State private var selectedTag = "Todos"

    private let service = RadioBrowserService()

    private let countries = [
        "US", // 🇺🇸
        "MX", // 🇲🇽
        "GB", // 🇬🇧
        "DE", // 🇩🇪
        "FR", // 🇫🇷
        "IT", // 🇮🇹
        "JP", // 🇯🇵
        "CN", // 🇨🇳
        "KR", // 🇰🇷 Corea del Sur
        "KP", // 🇰🇵 Corea del Norte
        "MN", // 🇲🇳 Mongolia
        "TH", // 🇹🇭 Tailandia
        "VN", // 🇻🇳 Vietnam
        "PH", // 🇵🇭 Filipinas
        "MY", // 🇲🇾 Malasia
        "ID", // 🇮🇩 Indonesia
        "SG", // 🇸🇬 Singapur
        "AE", // 🇦🇪 Emiratos Árabes
        "ZA", // 🇿🇦 Sudáfrica
        "NG", // 🇳🇬 Nigeria
        "KE", // 🇰🇪 Kenia
        "RU", // 🇷🇺 Rusia
        "UA", // 🇺🇦 Ucrania
        "AR", // 🇦🇷 Argentina
        "BR", // 🇧🇷 Brasil
        "CL", // 🇨🇱 Chile
        "PE", // 🇵🇪 Perú
        "CO", // 🇨🇴 Colombia
        "VE", // 🇻🇪 Venezuela
        "AU", // 🇦🇺 Australia
        "NZ", // 🇳🇿 Nueva Zelanda
        "SA", // 🇸🇦 Arabia Saudita
        "IR", // 🇮🇷 Irán
        "IQ", // 🇮🇶 Irak
        "IL", // 🇮🇱 Israel
        "EG", // 🇪🇬 Egipto
        "MA", // 🇲🇦 Marruecos
        "DZ", // 🇩🇿 Argelia
        "TN", // 🇹🇳 Túnez
        "IS"  // 🇮🇸 Islandia
    ]


    private let tags = ["Todos", "pop", "rock", "jazz", "classical", "electronic", "hiphop", "blues", "country", "reggae", "news"]

    private let countryFlags: [String: String] = [
        "US": "🇺🇸",
        "MX": "🇲🇽",
        "GB": "🇬🇧",
        "DE": "🇩🇪",
        "FR": "🇫🇷",
        "IT": "🇮🇹",
        "JP": "🇯🇵",
        "CN": "🇨🇳",
        "KR": "🇰🇷",
        "KP": "🇰🇵",
        "MN": "🇲🇳",
        "TH": "🇹🇭",
        "VN": "🇻🇳",
        "PH": "🇵🇭",
        "MY": "🇲🇾",
        "ID": "🇮🇩",
        "SG": "🇸🇬",
        "AE": "🇦🇪",
        "ZA": "🇿🇦",
        "NG": "🇳🇬",
        "KE": "🇰🇪",
        "RU": "🇷🇺",
        "UA": "🇺🇦",
        "AR": "🇦🇷",
        "BR": "🇧🇷",
        "CL": "🇨🇱",
        "PE": "🇵🇪",
        "CO": "🇨🇴",
        "VE": "🇻🇪",
        "AU": "🇦🇺",
        "NZ": "🇳🇿",
        "SA": "🇸🇦",
        "IR": "🇮🇷",
        "IQ": "🇮🇶",
        "IL": "🇮🇱",
        "EG": "🇪🇬",
        "MA": "🇲🇦",
        "DZ": "🇩🇿",
        "TN": "🇹🇳",
        "IS": "🇮🇸"
    ]

    var body: some View {
        VStack {
            HStack {
                Picker("País", selection: $selectedCountry) {
                    ForEach(countries, id: \.self) { country in
                        Text(country)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Picker("Género", selection: $selectedTag) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding()

            if stations.isEmpty {
                Text("No se encontraron estaciones.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(stations) { station in
                    NavigationLink(destination: RadioPlayerView(station: station)) {
                        VStack(alignment: .leading) {
                            Text(station.name)
                                .font(.headline)
                            Text("🎵 \(station.tags) \(countryFlags[station.countrycode] ?? "🏳️") \(station.countrycode)")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("📻 Radios")
        .onAppear {
            fetchStations()
        }
        // cuando cambias país o tag → recarga solo
        .onChange(of: selectedCountry) { _ in
            fetchStations()
        }
        .onChange(of: selectedTag) { _ in
            fetchStations()
        }
    }

    private func fetchStations() {
        service.fetchStationsByCountry(countryCode: selectedCountry) { fetchedStations in
            if selectedTag == "Todos" {
                self.stations = fetchedStations
            } else {
                self.stations = fetchedStations.filter {
                    $0.tags.localizedCaseInsensitiveContains(selectedTag)
                }
            }
        }
    }
}
