// ContentView.swift

import SwiftUI
import SceneKit
import CoreLocation

struct ContentView: View {
    @State private var radioStations: [RadioStation] = []
    @State private var selectedStation: RadioStation? = nil
    @State private var showFullMap = false
    @State private var countryInfo: CountryInfo? = nil

    @State private var rotationSpeed: Double = 1.0
    @State private var isRotating: Bool = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("🌎 Radio World")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    // SCENEKIT VIEW
                    SceneKitViewStatic(
                        radioStations: radioStations,
                        onStationTapped: { station in
                            selectedStation = station
                        },
                        onCountryTapped: { coordinate in
                            loadCountryInfo(for: coordinate)
                        },
                        rotationSpeed: $rotationSpeed,
                        isRotating: $isRotating
                    )
                    .frame(width: 300, height: 300)
                    .padding(.bottom)


                    // BOTON VER MAPA
                    Button(action: {
                        showFullMap = true
                    }) {
                        Text("🗺️ Ver Mapa Completo")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }

                    // GRID DE OPCIONES
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        NavigationLink(destination: RadioListView()) {
                            GridButton(label: "📻 Explorar Radios", color: .blue)
                        }
                        NavigationLink(destination: ArtistsListView()) {
                            GridButton(label: "🎤 Explorar Artistas", color: .green)
                        }
                        NavigationLink(destination: AlbumsListView()) {
                            GridButton(label: "🎵 Explorar Álbumes", color: .orange)
                        }
                        NavigationLink(destination: GenrenatorView()) {
                            GridButton(label: "🎲 Generador de Géneros", color: .red)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .navigationTitle("")
                .onAppear {
                    loadStations()
                }
                .sheet(item: $selectedStation) { station in
                    RadioPlayerView(station: station)
                }
                .sheet(item: $countryInfo) { info in
                    CountryInfoView(info: info, onClose: {
                        countryInfo = nil
                    })
                }
                .fullScreenCover(isPresented: $showFullMap) {
                    SceneKitFullMapView(
                        radioStations: radioStations,
                        onClose: {
                            showFullMap = false
                        },
                        onStationTapped: { station in
                            selectedStation = station
                            showFullMap = false
                        },
                        onCountryTapped: { coordinate in
                            loadCountryInfo(for: coordinate)
                            showFullMap = false
                        }
                    )
                }
            }
        }
    }

    func loadStations() {
        RadioBrowserService.shared.getTopStations(limit: 200) { stations in
            DispatchQueue.main.async {
                self.radioStations = stations
            }
        }
    }

    func loadCountryInfo(for coordinate: CLLocationCoordinate2D) {
        CountryInfoService.shared.getCountryInfo(from: coordinate) { info in
            DispatchQueue.main.async {
                self.countryInfo = info
            }
        }
    }
}

// MARK: - GridButton reusable view

struct GridButton: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(color)
            .cornerRadius(12)
    }
}



// MARK: - SceneKitView with Coordinator for tap detection

struct SceneKitView: UIViewRepresentable {
    let radioStations: [RadioStation]
    let onStationTapped: (RadioStation) -> Void
    let onCountryTapped: (CLLocationCoordinate2D) -> Void
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        
        sceneView.allowsCameraControl = false  // desactivado para que la rotación sea visible siempre
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.white
        
        // Camera setup
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 3.0) // alejada para que se vea la rotación
        scene.rootNode.addChildNode(cameraNode)
        
        // Earth node
        let earth = SCNSphere(radius: 1.0)
        earth.firstMaterial?.diffuse.contents = UIImage(named: "earth_texture")
        earth.firstMaterial?.specular.contents = UIColor.white
        earth.firstMaterial?.shininess = 0.1
        
        let earthNode = SCNNode(geometry: earth)
        scene.rootNode.addChildNode(earthNode)
        
        // Important: center pivot (para que rote bien)
        let min = earth.boundingBox.min
        let max = earth.boundingBox.max
        earthNode.pivot = SCNMatrix4MakeTranslation((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2)
        
        // Rotation animation (REAL)
        let rotation = CABasicAnimation(keyPath: "rotation")
        rotation.fromValue = SCNVector4(0, 1, 0, 0) // eje Y
        rotation.toValue = SCNVector4(0, 1, 0, Float(2 * Double.pi))
        rotation.duration = 20 // duración en segundos
        rotation.repeatCount = .infinity
        earthNode.addAnimation(rotation, forKey: "earth rotation")
        
        // Save reference
        context.coordinator.earthNode = earthNode
        context.coordinator.sceneView = sceneView
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Add radio points
        context.coordinator.addRadioPoints(stations: radioStations)
        
        return sceneView
    }



    func updateUIView(_ uiView: SCNView, context: Context) {
        // If radioStations changed → add new points
        context.coordinator.addRadioPoints(stations: radioStations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onStationTapped: onStationTapped)
    }

    class Coordinator: NSObject {
        var earthNode: SCNNode?
        var sceneView: SCNView?
        var addedStations: Set<String> = []
        let onStationTapped: (RadioStation) -> Void

        init(onStationTapped: @escaping (RadioStation) -> Void) {
            self.onStationTapped = onStationTapped
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: nil)

            if let node = hitResults.first?.node, let stationID = node.name {
                if let station = ContentViewStationCache.shared.station(for: stationID) {
                    onStationTapped(station)
                }
            }
        }

        func addRadioPoints(stations: [RadioStation]) {
            guard let earthNode = earthNode else { return }

            for station in stations {
                // Skip if already added
                if addedStations.contains(station.id) { continue }

                // Geocode
                SceneKitView.geocodeCountryAndState(station: station) { coordinate in
                    guard let coordinate = coordinate else { return }

                    DispatchQueue.main.async {
                        // Add point
                        let radius: Float = 1.01
                        let lat = Float(coordinate.latitude) * .pi / 180
                        let lon = Float(coordinate.longitude) * .pi / 180

                        let x = radius * cos(lat) * sin(lon)
                        let y = radius * sin(lat)
                        let z = radius * cos(lat) * cos(lon)

                        let sphere = SCNSphere(radius: 0.02)
                        sphere.firstMaterial?.diffuse.contents = UIColor.red
                        let node = SCNNode(geometry: sphere)
                        node.position = SCNVector3(x, y, z)
                        node.name = station.id

                        ContentViewStationCache.shared.register(station: station)

                        earthNode.addChildNode(node)
                        self.addedStations.insert(station.id)
                    }
                }
            }
        }
    }

    // Static cache + geocode
    static func geocodeCountryAndState(station: RadioStation, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let key = "\(station.country), \(station.state ?? "")" as NSString
        if let cachedValue = ContentViewStationCache.shared.locationCache.object(forKey: key)?.cgPointValue {
            completion(CLLocationCoordinate2D(latitude: CLLocationDegrees(cachedValue.x), longitude: CLLocationDegrees(cachedValue.y)))
            return
        }

        let address = "\(station.state ?? ""), \(station.country)"
        CLGeocoder().geocodeAddressString(address) { placemarks, error in
            if let coord = placemarks?.first?.location?.coordinate {
                let point = CGPoint(x: coord.latitude, y: coord.longitude)
                ContentViewStationCache.shared.locationCache.setObject(NSValue(cgPoint: point), forKey: key)
                completion(coord)
            } else {
                completion(nil)
            }
        }
    }
}


// MARK: - Simple cache to map station id -> station (needed for tap detection)

class ContentViewStationCache {
    static let shared = ContentViewStationCache()

    private var stationDict: [String: RadioStation] = [:]
    let locationCache = NSCache<NSString, NSValue>()

    func register(station: RadioStation) {
        stationDict[station.id] = station
    }

    func station(for id: String) -> RadioStation? {
        stationDict[id]
    }
}

#Preview {
    ContentView()
}
