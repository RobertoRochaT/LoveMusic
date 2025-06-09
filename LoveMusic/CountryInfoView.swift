//
//  CountryInfoView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//
import SwiftUI

struct CountryInfoView: View {
    let info: CountryInfo
    let onClose: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text(flagEmoji(for: info.countryCode))
                        .font(.system(size: 80))

                    Text("🌍 \(info.countryName)")
                        .font(.largeTitle).bold()

                    Text("🕑 Hora: \(info.currentTime)")
                    Text("🕓 Zona: \(info.timezone)")

                    HStack {
                        Text("🌡️ \(String(format: "%.1f°C", info.temperatureCelsius))")
                        Text(weatherEmoji(for: info.weatherDescription))
                    }.font(.title2)

                    Divider()

                    Text("🎙️ Radios en \(info.countryName)")
                        .font(.headline)

                    if info.radioStations.isEmpty {
                        Text("No se encontraron estaciones")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(info.radioStations.prefix(10)) { s in
                            Text("• \(s.name)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing:
                Button("Cerrar", action: onClose)
            )
        }
    }

    func flagEmoji(for code: String) -> String {
        code.uppercased().unicodeScalars
            .map { UnicodeScalar(127397 + $0.value)! }
            .map(String.init).joined()
    }

    func weatherEmoji(for desc: String) -> String {
        let d = desc.lowercased()
        return d.contains("clear") ? "☀️" :
               d.contains("cloud") ? "☁️" :
               d.contains("rain") ? "🌧️" :
               d.contains("snow") ? "❄️" :
               d.contains("storm") ? "⛈️" : "🌈"
    }
}
