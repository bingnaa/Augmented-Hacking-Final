//
//  ARView.swift
//  ARAPIStarter
//
//  Created by Nien Lam on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

//if action in update, pushpara called
//fixed with chatgpt

import SwiftUI
import ARKit
import RealityKit
import Combine

//interaction: flick your camera

struct ARViewContainer: UIViewRepresentable {
    let viewModel: ViewModel
    
    func makeUIView(context: Context) -> SimpleARView {
        SimpleARView(frame: .zero, viewModel: viewModel)
    }
    
    func updateUIView(_ arView: SimpleARView, context: Context) { }
}

class SimpleARView: ARView {
    var viewModel: ViewModel
    var arView: ARView { return self }
    var subscriptions = Set<AnyCancellable>()
    
    var spawnedObject: AnchorEntity?
    var planeAnchor: AnchorEntity?
    var originAnchor: AnchorEntity!
    var pov: AnchorEntity!

    var manager = MotionManager()

    init(frame: CGRect, viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        
        
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupScene()
        setupSubscriptions()
    }
        
    func setupScene() {
        pov = AnchorEntity(.camera)
        arView.scene.addAnchor(pov)
        
        originAnchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(originAnchor)
        
        // Setup world tracking and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        configuration.environmentTexturing = .automatic
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]
        arView.session.run(configuration)
        
        // DEBUG
        arView.environment.sceneUnderstanding.options.insert(.physics)
        arView.debugOptions.insert(.showSceneUnderstanding)
    }

    func setupSubscriptions() {
        // Process UI signals.
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }
        .store(in: &subscriptions)
        
        scene.subscribe(to: SceneEvents.Update.self) { event in
            // Call renderLoop method on every frame.
            self.renderTime()
        }.store(in: &subscriptions)
        
//        arView.scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
//            guard let self else { return }
//            
//            // If entity with name obstacle1 collides with anything.
//            if event.entityA.name == "A" || event.entityB.name == "P" {
//                print("collision")
//                //print(manager.deviceMotion?.attitude.pitch)
//                if let pitch = manager.deviceMotion?.attitude.pitch, pitch > 0.6 {
//                    print("action")
//                    triggerEntity(ent: event.entityB)
//                }
//            }
//        }.store(in: &subscriptions)
    }
    
    func processUISignal(_ signal: ViewModel.UISignal) {
        switch signal {
        case .reset:
            resetScene()
        case .spawnParasite:
            instantiateParasitesPool(count: 40)
        }
    }
    

    // Reset plane anchor and position entities.
    func resetScene() {
        // Reset plane anchor. //
        planeAnchor?.removeFromParent()
        planeAnchor = nil
        planeAnchor = AnchorEntity(plane: [.vertical])
        arView.scene.addAnchor(planeAnchor!)
    }
    
    func renderTime(){
        if let gyroX = manager.gyroData?.rotationRate.x, gyroX > 1 {
            //print("gyroX:", gyroX)
            if let userAccelerationX = manager.deviceMotion?.userAcceleration.x, userAccelerationX >  0.65 {
            //if let userAccelerationY = manager.deviceMotion?.userAcceleration.y, userAccelerationY >  0.3 {
            //if let userAccelerationZ = manager.deviceMotion?.userAcceleration.z, userAccelerationZ >  0.3 {
                print("user accelr8:", userAccelerationX)
                //print("user accelr8:", userAccelerationY)
                //print("user accelr8:", userAccelerationZ)
                for originAnchor in arView.scene.anchors {
                    // Check the anchor's entities
                    for entity in originAnchor.children {
                        // Perform checks or actions on each entity
                        //print("Entity name: \(entity.name ?? "Unnamed Entity")")
                        // You can access other properties of the entity as needed
                        //pushPara(movePara: entity.parent as! Parasites)
                        pushPara(movePara: entity as! Parasites)
                    }
                }
                
            }
        }
    }
    
    // Function to spawn an object close to the AR camera.
//    func spawnObjectNearCamera() {
//        if var cameraTransform = arView.session.currentFrame?.camera.transform {
//            print("spawn")
//            // Create a translation matrix to represent the desired forward distance (e.g., 1 meter).
//            let forwardDistance: Float = 0.01 // You can adjust this value as needed.
//            let translationMatrix = simd_float4x4(float4([1, 0, 0, 0]),
//                                                float4([0, 1, 0, 0]),
//                                                float4([0, 0, 1, forwardDistance]),
//                                                float4([0, 0, 0, 1]))
//                
//            cameraTransform = simd_mul(cameraTransform, translationMatrix)
//            let position = simd_make_float3(cameraTransform.columns.3)
//            let mesh = MeshResource.generateSphere(radius: 0.1)
//
//            let material = SimpleMaterial(color: .red, isMetallic: false)
//            let mEntity = ModelEntity(mesh: mesh, materials: [material])
//                
//            let arObject = Parasites(modelEntity: mEntity, active: true, cameraView: self)
//            //let arObject = SphereEntity(name: "sphere", radius: 0.1, imageName: "checker.png")
//            arObject.position = position
//
//            let objectAnchor = AnchorEntity(world: position)
//            objectAnchor.addChild(arObject)
//            arView.scene.addAnchor(objectAnchor)
//        }
//    }
    
    func instantiateParasitesPool(count: Int) {
        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let mesh = MeshResource.generateSphere(radius: 0.07)
            var material = SimpleMaterial(color: .white, isMetallic: false)
            
            material.color = .init(tint: .white.withAlphaComponent(0.999),
                                   texture: .init(try! .load(named: "beeTexture")))
            
            let radius: Float = 0.05
            let mass: Float   = 5.0

            for _ in 0..<count {
                let forwardDistance: Float = 0.01
                let translationMatrix = simd_float4x4(float4([1, 0, 0, 0]),
                                                       float4([0, 1, 0, 0]),
                                                       float4([0, 0, 1, forwardDistance]),
                                                       float4([0, 0, 0, 1]))

                let transformedCamera = simd_mul(cameraTransform, translationMatrix)

                // Extract the position from the updated camera transform.
                let position = simd_make_float3(transformedCamera.columns.3)

                // Create a new Parasite entity
                let meshEntity = ModelEntity(mesh: mesh, materials: [material])
                meshEntity.name = "P"
                //meshEntity.collision = CollisionComponent(shapes: [.generateSphere(radius: radius)])
                meshEntity.generateCollisionShapes(recursive: true)
                meshEntity.physicsBody = PhysicsBodyComponent(shapes: [.generateSphere(radius: radius)], mass: mass)
                meshEntity.physicsBody?.mode = .static

                let newParasite = Parasites(modelEntity: meshEntity, status: true, cameraView: arView, name: "P")
                                
                newParasite.position = position
                let randomRotationAngle = Float.random(in: 0...2 * .pi)
                newParasite.transform.rotation = simd_quatf(angle: randomRotationAngle, axis: [0, 1, 0])

                // Add the Parasite entity to the AR scene
//                let parasiteAnchor = AnchorEntity(world: transformedCamera)
//                parasiteAnchor.addChild(newParasite)
                originAnchor.addChild(newParasite)
            }
        }
    }
    
//    func triggerEntity(ent: Entity) {
//        print(ent.name)
//        //print("triggerEntity entity:",ent)
//       //print("triggerEntity entity parent:",ent.parent!)
//        if let myPara = ent.parent as? Parasites {
//            print("dupe")
//            myPara.changeState(state: false)
//        } else {
//            print("Cast failed")
//        }
//    }
    
    func pushPara(movePara: Parasites) {
        //  written/fixed with help of nien
            // Test to check if Parasite is front of the camera.
            // Otherwise return.
        //if let pitch = manager.deviceMotion?.attitude.pitch, pitch > 0.6 {
            guard let screenPoint = arView.project(movePara.position),
            arView.bounds.contains(screenPoint),
                  movePara.position(relativeTo: pov).z < 0  else {
                
                print("Parasite is not in front of camera")
                return
            }


            // Set Parasite body to dynamic.
            movePara.model?.physicsBody?.mode = .dynamic

            // Create force vector for cameraPOV to sphere.
            let forceAmount: Float = 1000
            let spherePosition = movePara.position
            let povPosition    = pov.position(relativeTo: originAnchor)
            let forceVector    = normalize(spherePosition - povPosition) * forceAmount
            
            // Add force.
            movePara.changeState(state: false, anchor: originAnchor, force: forceVector)
            //(movePara as HasPhysics).addForce(forceVector, relativeTo: originAnchor)
    }
}
