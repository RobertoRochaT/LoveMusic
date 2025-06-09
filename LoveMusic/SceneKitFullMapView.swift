//
//  SceneKitFullMapView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI
import SceneKit
import CoreLocation

struct SceneKitFullMapView: UIViewControllerRepresentable {
    let radioStations: [RadioStation]
    let onClose: () -> Void
    let onStationTapped: (RadioStation) -> Void
    let onCountryTapped: (CLLocationCoordinate2D) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()

        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.black
        sceneView.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            sceneView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])

        // Earth node
        let earth = SCNSphere(radius: 1.0)
        earth.firstMaterial?.diffuse.contents = UIImage(named: "earth_texture")
        let earthNode = SCNNode(geometry: earth)
        earthNode.name = "earth"
        sceneView.scene?.rootNode.addChildNode(earthNode)

        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 30 // centrado para que la tierra no se corte
        cameraNode.position = SCNVector3(0, 0, 3.0)
        sceneView.scene?.rootNode.addChildNode(cameraNode)

        // Save reference in coordinator
        context.coordinator.earthNode = earthNode
        context.coordinator.sceneView = sceneView

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        context.coordinator.addRadioPoints(stations: radioStations)

        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Cerrar", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 8
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(context.coordinator, action: #selector(Coordinator.closeTapped), for: .touchUpInside)

        vc.view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.addRadioPoints(stations: radioStations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onStationTapped: onStationTapped,
            onCountryTapped: onCountryTapped,
            onClose: onClose
        )
    }

    class Coordinator: NSObject {
        var earthNode: SCNNode?
        var sceneView: SCNView?
        var addedStations: Set<String> = []
        let onStationTapped: (RadioStation) -> Void
        let onCountryTapped: (CLLocationCoordinate2D) -> Void
        let onClose: () -> Void

        init(onStationTapped: @escaping (RadioStation) -> Void, onCountryTapped: @escaping (CLLocationCoordinate2D) -> Void, onClose: @escaping () -> Void) {
            self.onStationTapped = onStationTapped
            self.onCountryTapped = onCountryTapped
            self.onClose = onClose
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: nil)

            if let node = hitResults.first?.node {
                if node.name == "earth" {
                    let point = hitResults.first!.localCoordinates
                    let radius: Float = sqrt(point.x * point.x + point.y * point.y + point.z * point.z)

                    let lat = asin(point.y / radius) * 180 / .pi
                    let lon = atan2(point.x, point.z) * 180 / .pi

                    let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude: CLLocationDegrees(lon))
                    onCountryTapped(coordinate)
                } else if let stationID = node.name, let station = ContentViewStationCache.shared.station(for: stationID) {
                    onStationTapped(station)
                }
            }
        }

        @objc func closeTapped() {
            onClose()
        }

        func addRadioPoints(stations: [RadioStation]) {
            guard let earthNode = earthNode else { return }

            for station in stations {
                if addedStations.contains(station.id) { continue }

                SceneKitViewStatic.geocodeCountryAndState(station: station) { coordinate in
                    guard let coordinate = coordinate else { return }

                    DispatchQueue.main.async {
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
}

