//
//  LocalDatabase.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//
//
//  LocalDatabase.swift
//  LoveMusic
//

import SQLite
import SwiftUI

class LocalDatabase {
    static let shared = LocalDatabase()
    
    private var db: Connection?
    
    private let favoritesTable = Table("favorites")
    private let historyTable = Table("history")
    
    private let id = Expression<String>(value: "id")
    private let name = Expression<String>(value: "name")
    private let url = Expression<String>(value: "url")
    private let favicon = Expression<String>(value: "favicon")
    private let tags = Expression<String>(value: "tags")
    
    init() {
        do {
            let dbURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("radio.sqlite3")
            db = try Connection(dbURL.path)
            print("✅ SQLite DB Initialized at \(dbURL.path)")
            
            try db?.run(favoritesTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(name)
                t.column(url)
                t.column(favicon)
                t.column(tags)
            })
            
            try db?.run(historyTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(name)
                t.column(url)
                t.column(favicon)
                t.column(tags)
            })
        } catch {
            print("❌ SQLite DB init error: \(error)")
        }
    }
    
    func saveFavorite(station: RadioStation) {
        guard let database = db else {
            print("❌ Database connection is nil")
            return
        }
        
        do {
            print("🟡 Inserting Favorite: \(station.name)")
            
            let cleanName = station.name
            let cleanUrl = station.url
            let cleanFavicon = station.favicon.isEmpty ? "N/A" : station.favicon
            let cleanTags = station.tags.isEmpty ? "N/A" : String(station.tags.prefix(1000))
            
            try database.transaction {
                try database.run(favoritesTable.insert(or: .replace,
                    id <- station.stationuuid,
                    name <- cleanName,
                    url <- cleanUrl,
                    favicon <- cleanFavicon,
                    tags <- cleanTags
                ))
            }
            
            print("✅ Favorite saved: \(station.name)")
        } catch {
            print("❌ Error saving favorite to SQLite: \(error)")
        }
    }
    
    func loadFavorites() -> [RadioStation] {
        var stations: [RadioStation] = []
        
        guard let database = db else {
            print("❌ Database connection is nil when loading favorites")
            return stations
        }
        
        do {
            let query = favoritesTable.select(*)
            for row in try database.prepare(query) {
                let station = RadioStation(
                    stationuuid: row[id],
                    name: row[name],
                    url: row[url],
                    favicon: row[favicon],
                    tags: row[tags],
                    countrycode: "XX",    // ← estos son dummy valores, OK
                    country: "",          // ← estos también OK
                    state: nil,           // ← OK
                    language: "es"        // ← OK
                )

                stations.append(station)
            }
            print("✅ Favorites loaded: \(stations.count)")
        } catch {
            print("❌ Error loading favorites from SQLite: \(error)")
        }
        return stations
    }
    
    func saveToHistory(station: RadioStation) {
        guard let database = db else {
            print("❌ Database connection is nil")
            return
        }
        
        do {
            print("🟡 Inserting History: \(station.name)")
            
            let cleanName = station.name.replacingOccurrences(of: "'", with: "''")
            let cleanUrl = station.url.replacingOccurrences(of: "'", with: "''")
            let cleanFavicon = station.favicon.isEmpty ? "N/A" : station.favicon.replacingOccurrences(of: "'", with: "''")
            let cleanTags = station.tags.isEmpty ? "N/A" : String(station.tags.prefix(1000)).replacingOccurrences(of: "'", with: "''")
            
            let deleteSQL = "DELETE FROM history WHERE id = '\(station.stationuuid)'"
            let insertSQL = """
                INSERT INTO history (id, name, url, favicon, tags) 
                VALUES ('\(station.stationuuid)', '\(cleanName)', '\(cleanUrl)', '\(cleanFavicon)', '\(cleanTags)')
                """
            
            try database.transaction {
                try database.execute(deleteSQL)
                try database.execute(insertSQL)
            }
            
            print("✅ History saved: \(station.name)")
        } catch {
            print("❌ Error saving to history in SQLite: \(error)")
        }
    }
    
    func loadHistory() -> [RadioStation] {
        var stations: [RadioStation] = []
        
        guard let database = db else {
            print("❌ Database connection is nil when loading history")
            return stations
        }
        
        do {
            for row in try database.prepare(historyTable) {
                stations.append(
                    RadioStation(
                        stationuuid: row[id],
                        name: row[name],
                        url: row[url],
                        favicon: row[favicon],
                        tags: row[tags],
                        countrycode: "XX",
                        country: "",
                        state: nil,
                        language: "es"
                    )
                )
            }
            print("✅ History loaded: \(stations.count)")
        } catch {
            print("❌ Error loading history from SQLite: \(error)")
        }
        return stations
    }
}
