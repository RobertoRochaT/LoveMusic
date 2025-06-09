//
//  SceneKitViewStatic.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI
import SceneKit
import CoreLocation

struct SceneKitViewStatic: UIViewRepresentable {
    let radioStations: [RadioStation]
    let onStationTapped: (RadioStation) -> Void
    let onCountryTapped: (CLLocationCoordinate2D) -> Void
    @Binding var rotationSpeed: Double
    @Binding var isRotating: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.white
        
        // Configurar cámara
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 2.5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Crear Tierra con texturas mejoradas
        let earthNode = createEarthNode()
        scene.rootNode.addChildNode(earthNode)
        
        // Añadir atmósfera
        let atmosphereNode = createAtmosphereNode()
        earthNode.addChildNode(atmosphereNode)
        
        // Configurar animación de rotación
        setupRotationAnimation(for: earthNode)
        
        // Configurar gestos y puntos de radio
        context.coordinator.earthNode = earthNode
        context.coordinator.sceneView = sceneView
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        context.coordinator.addRadioPoints(stations: radioStations)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Actualizar puntos de radio
        context.coordinator.addRadioPoints(stations: radioStations)
        
        // Actualizar animación
        if let earthNode = context.coordinator.earthNode {
            if let rotation = earthNode.action(forKey: "earthRotation") {
                rotation.speed = CGFloat(rotationSpeed)
            } else if isRotating {
                setupRotationAnimation(for: earthNode)
            }
        }
        
        // Pausar/reanudar animación
        if isRotating {
            context.coordinator.earthNode?.resumeAnimation(forKey: "earthRotation")
        } else {
            context.coordinator.earthNode?.pauseAnimation(forKey: "earthRotation")
        }
    }
    
    private func createEarthNode() -> SCNNode {
        let earth = SCNSphere(radius: 0.8)
        earth.firstMaterial?.diffuse.contents = UIImage(named: "earth_texture")
        earth.firstMaterial?.specular.contents = UIImage(named: "earth_specular")
        earth.firstMaterial?.emission.contents = UIImage(named: "earth_night")
        earth.firstMaterial?.normal.contents = UIImage(named: "earth_normal")
        earth.firstMaterial?.shininess = 0.1
        
        let earthNode = SCNNode(geometry: earth)
        earthNode.name = "earth"
        
        return earthNode
    }
    
    private func createAtmosphereNode() -> SCNNode {
        let atmosphere = SCNSphere(radius: 0.85)
        atmosphere.firstMaterial?.diffuse.contents = UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.2)
        atmosphere.firstMaterial?.transparency = 0.5
        atmosphere.firstMaterial?.blendMode = .add
        
        let atmosphereNode = SCNNode(geometry: atmosphere)
        atmosphereNode.name = "atmosphere"
        
        return atmosphereNode
    }
    
    private func setupRotationAnimation(for node: SCNNode) {
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(2 * Double.pi), z: 0, duration: 30 / rotationSpeed)
        let repeatRotation = SCNAction.repeatForever(rotation)
        node.runAction(repeatRotation, forKey: "earthRotation")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onStationTapped: onStationTapped, onCountryTapped: onCountryTapped)
    }
    
    class Coordinator: NSObject {
        var earthNode: SCNNode?
        var sceneView: SCNView?
        var addedStations: Set<String> = []
        let onStationTapped: (RadioStation) -> Void
        let onCountryTapped: (CLLocationCoordinate2D) -> Void
        
        init(onStationTapped: @escaping (RadioStation) -> Void, onCountryTapped: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onStationTapped = onStationTapped
            self.onCountryTapped = onCountryTapped
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: nil)
            
            if let node = hitResults.first?.node, let stationID = node.name {
                if let station = ContentViewStationCache.shared.station(for: stationID) {
                    onStationTapped(station)
                    return
                }
            }
            
            if let result = hitResults.first {
                let localCoordinates = result.localCoordinates
                let latLon = SceneKitViewStatic.convertToLatLon(localCoordinates)
                onCountryTapped(latLon)
            }
        }
        
        func addRadioPoints(stations: [RadioStation]) {
            guard let earthNode = earthNode else { return }
            
            for station in stations {
                if addedStations.contains(station.id) { continue }
                
                SceneKitViewStatic.geocodeCountryAndState(station: station) { coordinate in
                    guard let coordinate = coordinate else { return }
                    
                    DispatchQueue.main.async {
                        let radius: Float = 0.81
                        let lat = Float(coordinate.latitude) * .pi / 180
                        let lon = Float(coordinate.longitude) * .pi / 180
                        
                        let x = radius * cos(lat) * sin(lon)
                        let y = radius * sin(lat)
                        let z = radius * cos(lat) * cos(lon)
                        
                        // Crear marcador más atractivo
                        let marker = SCNSphere(radius: 0.02)
                        marker.firstMaterial?.diffuse.contents = UIColor.red
                        marker.firstMaterial?.emission.contents = UIColor.red.withAlphaComponent(0.5)
                        marker.firstMaterial?.emission.intensity = 0.5
                        
                        let node = SCNNode(geometry: marker)
                        node.position = SCNVector3(x, y, z)
                        node.name = station.id
                        
                        // Animación de pulso para los marcadores
                        let pulseAction = SCNAction.sequence([
                            SCNAction.scale(to: 1.5, duration: 0.5),
                            SCNAction.scale(to: 1.0, duration: 0.5)
                        ])
                        node.runAction(SCNAction.repeatForever(pulseAction))
                        
                        ContentViewStationCache.shared.register(station: station)
                        earthNode.addChildNode(node)
                        self.addedStations.insert(station.id)
                    }
                }
            }
        }
    }
    
    static func convertToLatLon(_ localCoordinates: SCNVector3) -> CLLocationCoordinate2D {
        let x = Double(localCoordinates.x)
        let y = Double(localCoordinates.y)
        let z = Double(localCoordinates.z)
        
        let radius = sqrt(x * x + y * y + z * z)
        let lat = asin(y / radius) * 180 / .pi
        let lon = atan2(x, z) * 180 / .pi
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
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
