//
//  AnimatedEarthView.swift
//  LoveMusic
//
//  Created by Carlos Roberto Rocha Trejo on 09/06/25.
//

import SwiftUI
import SceneKit

struct AnimatedEarthView: View {
    @State private var rotationSpeed: Double = 1.0
    @State private var showAtmosphere: Bool = true
    @State private var isRotating: Bool = true
    
    var body: some View {
        VStack {
            // Vista 3D de la Tierra
            EarthSceneView(
                rotationSpeed: $rotationSpeed,
                showAtmosphere: $showAtmosphere,
                isRotating: $isRotating
            )
            .frame(width: 300, height: 300)
            .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 0)
            
            // Controles interactivos
            VStack(spacing: 15) {
                HStack {
                    Text("Velocidad:")
                    Slider(value: $rotationSpeed, in: 0.1...3.0)
                        .accentColor(.blue)
                }
                
                Toggle("Mostrar atmósfera", isOn: $showAtmosphere)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Button(action: {
                    withAnimation {
                        isRotating.toggle()
                    }
                }) {
                    Text(isRotating ? "⏸ Pausar rotación" : "▶ Reanudar rotación")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(isRotating ? Color.orange : Color.green)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding()
    }
}

struct EarthSceneView: UIViewRepresentable {
    @Binding var rotationSpeed: Double
    @Binding var showAtmosphere: Bool
    @Binding var isRotating: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.clear
        sceneView.allowsCameraControl = true
        
        // Configurar cámara
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 2.5)
        scene.rootNode.addChildNode(cameraNode)
        
        // Crear Tierra
        let earthNode = createEarthNode()
        scene.rootNode.addChildNode(earthNode)
        
        // Configurar animación de rotación
        setupRotationAnimation(for: earthNode)
        
        // Añadir atmósfera
        let atmosphereNode = createAtmosphereNode()
        earthNode.addChildNode(atmosphereNode)
        
        // Guardar referencias para actualizaciones
        context.coordinator.earthNode = earthNode
        context.coordinator.atmosphereNode = atmosphereNode
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Actualizar velocidad de rotación
        if let earthNode = context.coordinator.earthNode {
            if let rotation = earthNode.action(forKey: "earthRotation") {
                rotation.speed = CGFloat(rotationSpeed)
            } else if isRotating {
                setupRotationAnimation(for: earthNode)
            }
        }
        
        // Actualizar visibilidad de la atmósfera
        context.coordinator.atmosphereNode?.isHidden = !showAtmosphere
        
        // Pausar/reanudar animación
        if isRotating {
            context.coordinator.earthNode?.resumeAnimation(forKey: "earthRotation")
        } else {
            context.coordinator.earthNode?.pauseAnimation(forKey: "earthRotation")
        }
    }
    
    private func createEarthNode() -> SCNNode {
        let earth = SCNSphere(radius: 1.0)
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
        let atmosphere = SCNSphere(radius: 1.05)
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
        Coordinator()
    }
    
    class Coordinator {
        var earthNode: SCNNode?
        var atmosphereNode: SCNNode?
    }
}

// Vista previa
struct AnimatedEarthView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedEarthView()
            .preferredColorScheme(.dark)
    }
}
