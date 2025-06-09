//
//  Album.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import Foundation

struct Album: Identifiable {
    let id = UUID()
    let name: String
    let artist: String
    let imageURL: String?
}
