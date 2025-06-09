//
//  WeatherView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 08/06/25.
//

import SwiftUI

struct WeatherView: View {
    // después puedes traer los datos del WeatherService
    var body: some View {
        VStack {
            Text("☀️ Clima Actual")
                .font(.title)

            Text("Ciudad: París")
            Text("Temperatura: 25 °C")
            Text("Estado: Soleado")
        }
        .padding()
    }
}
