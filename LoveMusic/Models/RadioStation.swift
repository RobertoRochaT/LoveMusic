//
//  RadioStation.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 08/06/25.
//


import Foundation

struct RadioStation: Identifiable, Codable, Hashable {
    var id: String { stationuuid }

    let stationuuid: String
    let name: String
    let url: String
    let favicon: String
    let tags: String
    let countrycode: String
    let country: String
    let state: String?
    let language: String?
}


