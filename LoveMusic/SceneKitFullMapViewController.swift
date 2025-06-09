//
//  SceneKitFullMapViewController.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

// SceneKitFullMapViewController.swift

import UIKit
import SceneKit
import CoreLocation

class SceneKitFullMapViewController: UIViewController {

    private let radioStations: [RadioStation]
    private let onClose: () -> Void
    private let onStationTapped: (RadioStation) -> Void

    private var earthNode: SCNNode?
    private var addedStations: Set<String> = []

    init(radioStations: [RadioStation], onClose: @escaping () -> Void, onStationTapped: @escaping (RadioStation) -> Void) {
        self.radioStations = radioStations
        self.onClose = onClose
        self.onStationTapped = onStationTapped
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        // Add SCNView
        let sceneView = SCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true // Aquí sí permitimos zoom, pan, rotar
        sceneView.autoenablesDefaultLighting = true
        view.addSubview(sceneView)

        // Add Earth
        let earth = SCNSphere(radius: 1.0)
        earth.firstMaterial?.diffuse.contents = UIImage(named: "earth_texture")
        let earthNode = SCNNode(geometry: earth)
        sceneView.scene?.rootNode.addChildNode(earthNode)
        self.earthNode = earthNode

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)

        // Add radio points
        addRadioPoints()

        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Cerrar", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 8
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 80),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let scnView = gesture.view as? SCNView else { return }
        let location = gesture.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)

        if let node = hitResults.first?.node, let stationID = node.name {
            if let station = ContentViewStationCache.shared.station(for: stationID) {
                onStationTapped(station)
            }
        }
    }

    @objc private func closeTapped() {
        onClose()
        dismiss(animated: true, completion: nil)
    }

    private func addRadioPoints() {
        guard let earthNode = earthNode else { return }

        for station in radioStations {
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
