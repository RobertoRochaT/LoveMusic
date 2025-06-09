///
//  CountryInfoService.swift
//  LoveMusic
//

import Foundation
import CoreLocation

struct CountryInfo: Identifiable {
    let id = UUID() // Para que sea Identifiable

    let countryName: String
    let countryCode: String
    let timezone: String
    let currentTime: String
    let temperatureCelsius: Double
    let weatherDescription: String
    let radioStations: [RadioStation]
}

class CountryInfoService {
    static let shared = CountryInfoService()

    func getCountryInfo(from coordinate: CLLocationCoordinate2D, completion: @escaping (CountryInfo?) -> Void) {
        reverseGeocode(coordinate: coordinate) { countryName, countryCode in
            guard let countryName = countryName,
                  let countryCode = countryCode else {
                completion(nil)
                return
            }

            self.fetchWeather(lat: coordinate.latitude, lon: coordinate.longitude) { temp, weatherDesc in
                self.fetchTime(lat: coordinate.latitude, lon: coordinate.longitude) { timezone, currentTime in
                    RadioBrowserService().fetchStationsByCountry(countryCode: countryCode) { stations in
                        let info = CountryInfo(
                            countryName: countryName,
                            countryCode: countryCode,
                            timezone: timezone ?? "Desconocido",
                            currentTime: currentTime ?? "Desconocido",
                            temperatureCelsius: temp ?? 0.0,
                            weatherDescription: weatherDesc ?? "Desconocido",
                            radioStations: stations
                        )
                        completion(info)
                    }
                }
            }
        }
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D, completion: @escaping (String?, String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { placemarks, error in
            if let placemark = placemarks?.first,
               let country = placemark.country,
               let isoCountryCode = placemark.isoCountryCode {
                completion(country, isoCountryCode)
            } else {
                completion(nil, nil)
            }
        }
    }

    private func fetchWeather(lat: Double, lon: Double, completion: @escaping (Double?, String?) -> Void) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true"

        guard let url = URL(string: urlString) else {
            completion(nil, nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil, nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let currentWeather = json["current_weather"] as? [String: Any],
                   let temp = currentWeather["temperature"] as? Double,
                   let weatherCode = currentWeather["weathercode"] as? Int {

                    let weatherDesc = self.weatherDescription(from: weatherCode)
                    completion(temp, weatherDesc)
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, nil)
            }
        }.resume()
    }

    private func fetchTime(lat: Double, lon: Double, completion: @escaping (String?, String?) -> Void) {
        let urlString = "https://timeapi.io/api/TimeZone/coordinate?latitude=\(lat)&longitude=\(lon)"

        guard let url = URL(string: urlString) else {
            completion(nil, nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil, nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let timezone = json["timeZone"] as? String,
                   let currentTime = json["currentLocalTime"] as? String {

                    // Extract HH:mm:ss from ISO format
                    let time = currentTime.split(separator: "T").count > 1 ?
                        String(currentTime.split(separator: "T")[1].prefix(8)) : currentTime

                    completion(timezone, time)
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, nil)
            }
        }.resume()
    }

    private func weatherDescription(from code: Int) -> String {
        // Simple mapping of Open-Meteo weather codes:
        switch code {
        case 0: return "Clear sky"
        case 1, 2, 3: return "Partly cloudy"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 71, 73, 75: return "Snow"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Unknown"
        }
    }
}


    private func fetchWeatherDetails(woeid: Int, completion: @escaping (Double?, String?) -> Void) {
        let urlString = "https://www.metaweather.com/api/location/\(woeid)/"

        guard let url = URL(string: urlString) else {
            completion(nil, nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil, nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let consolidatedWeather = json["consolidated_weather"] as? [[String: Any]],
                   let firstWeather = consolidatedWeather.first,
                   let temp = firstWeather["the_temp"] as? Double,
                   let weatherDesc = firstWeather["weather_state_name"] as? String {

                    completion(temp, weatherDesc.capitalized)
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, nil)
            }
        }.resume()
    }

    private func fetchCurrentTime(for timezone: String, completion: @escaping (String?) -> Void) {
        let urlString = "http://worldtimeapi.org/api/timezone/\(timezone)"

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
                   let datetime = json["datetime"] as? String {

                    let time = String(datetime.split(separator: "T")[1].prefix(8))
                    completion(time)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }

