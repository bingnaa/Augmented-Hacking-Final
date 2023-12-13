//
//  ContentView.swift
//  GameBoard
//
//  Created by Nien Lam on 9/21/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import SwiftUI
import ARKit
import RealityKit
import Combine


// MARK: - View model for handling communication between the UI and ARView.
class ViewModel: ObservableObject {
    // Boolean to track if robot is walking.
    @Published var robotIsWalking: Bool = false
    
    // Message of game status.
    @Published var gameStatus: String = "START"

    // For handling different button presses.
    enum UISignal {
        case reset
        case moveForward
        case rotateCCW
        case rotateCW
    }
    
    let uiSignal = PassthroughSubject<UISignal, Never>()
}


// MARK: - UI Layer.
struct ContentView : View {
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        ZStack {
            // AR View.
            ARViewContainer(viewModel: viewModel)

            Text(viewModel.gameStatus)
                .font(.system(.largeTitle))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(40)
            
            // Reset button.
            Button {
                viewModel.uiSignal.send(.reset)
            } label: {
                Label("Reset", systemImage: "gobackward")
                    .font(.system(.title))
                    .foregroundColor(.white)
                    .labelStyle(IconOnlyLabelStyle())
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            
            // Controls.
            HStack {
                Button {
                    viewModel.uiSignal.send(.moveForward)
                } label: {
                    buttonIcon(viewModel.robotIsWalking ? "stop.fill" : "arrow.up", color: .blue)
                }
                
                Spacer()
                
                Button {
                    viewModel.uiSignal.send(.rotateCCW)
                } label: {
                    buttonIcon("rotate.left", color: .red)
                }
                
                Button {
                    viewModel.uiSignal.send(.rotateCW)
                } label: {
                    buttonIcon("rotate.right", color: .red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }
    
    // Helper methods for rendering icon.
    func buttonIcon(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .resizable()
            .padding(10)
            .frame(width: 44, height: 44)
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(5)
    }
}


// MARK: - AR View.
struct ARViewContainer: UIViewRepresentable {
    let viewModel: ViewModel
    
    func makeUIView(context: Context) -> ARView {
        SimpleARView(frame: .zero, viewModel: viewModel)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

class SimpleARView: ARView {
    var viewModel: ViewModel
    var arView: ARView { return self }
    var subscriptions = Set<AnyCancellable>()

    var planeAnchor: AnchorEntity?

    var robotEntity: CustomModelEntity!
    var boardEntity: BoardEntity!
    var cubeEntity: CubeEntity!
    var sphereEntity: SphereEntity!
    
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
        
        setupEntities()
    }
        
    func setupScene() {
        // Setup world tracking and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]
        arView.session.run(configuration)
        
        // Called every frame.
        scene.subscribe(to: SceneEvents.Update.self) { event in
            // Call renderLoop method on every frame.
            self.renderLoop()
        }.store(in: &subscriptions)
        
        // Process UI signals.
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }.store(in: &subscriptions)
        
        // Respond to collision events 💥.
        arView.scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
            guard let self else { return }
            
            // If entity with name obstacle1 collides with anything.
            if event.entityA.name == "obstacle1" || event.entityB.name == "obstacle1" {

                // TODO: Add logic for collision.
                print("💥 something is colliding with obstacle1")
                viewModel.gameStatus = "COLLISION"
            }

        }.store(in: &subscriptions)


        // Uncomment to show collision 💥 debug .
        // arView.debugOptions = [.showPhysics]
    }

    func processUISignal(_ signal: ViewModel.UISignal) {
        switch signal {
        case .reset:
            resetGameBoard()
        case .moveForward:
            moveForwardPressed()
        case .rotateCCW:
            rotateCCWPressed()
        case .rotateCW:
            rotateCWPressed()
        }
    }

    // Define entities here.
    func setupEntities() {
        // Setup custom entities.
        robotEntity = CustomModelEntity(name: "mrRobot", usdzModelName: "toy_robot_vintage")

        boardEntity = BoardEntity(name: "gameBoard", length: 1.0, imageName: "checker-board.png")

        cubeEntity = CubeEntity(name: "obstacle1", size: 0.10, color: UIColor.red)
        
        sphereEntity = SphereEntity(name: "obstacle2", radius: 0.1, imageName: "checker-board.png")
    }
    
    // Reset plane anchor and position entities.
    func resetGameBoard() {
        // Reset plane anchor. //
        planeAnchor?.removeFromParent()
        planeAnchor = nil
        planeAnchor = AnchorEntity(plane: [.horizontal])
        planeAnchor?.orientation = simd_quatf(angle: .pi / 2, axis: [0,1,0])
        arView.scene.addAnchor(planeAnchor!)

        
        
        // Reset robot entity. //
        planeAnchor!.addChild(robotEntity)

        // .. reset transform.
        robotEntity.transform = Transform()
        
        // .. IMPORTANT: 💥 Generate collision shape for robot.
        robotEntity.generateCollisionShapes(recursive: true)

        // .. Stop any animation.
        robotEntity.animate(false)
        

        // Reset board entity. //
        planeAnchor!.addChild(boardEntity)
        boardEntity.position = [0, 0, 0]


        // Reset cube entity. //
        planeAnchor!.addChild(cubeEntity)
        cubeEntity.position.y = 0.05
        cubeEntity.position.z = 0.3

        // .. Generate collision shape cube entity.
        cubeEntity.generateCollisionShapes(recursive: true)
        

        // Reset sphere entity. //
        planeAnchor!.addChild(sphereEntity)
        sphereEntity.position.y = 0.1
        sphereEntity.position.z = 0.3
        sphereEntity.position.x = 0.4

        // .. Generate collision shape cube sphere entity.
        sphereEntity.generateCollisionShapes(recursive: true)
        

        // Reset robot walking state.
        viewModel.robotIsWalking = false

        // Reset game status message.
        viewModel.gameStatus = "START"
    }
    
    func moveForwardPressed() {
        print("👇 Did press move forward")

        viewModel.robotIsWalking.toggle()
        
        if viewModel.robotIsWalking {
            robotEntity.animate(true)
            viewModel.gameStatus = "WALKING"
        } else {
            robotEntity.animate(false)
            viewModel.gameStatus = "STOPPED"
        }
    }

    func rotateCCWPressed() {
        print("👇 Did press rotate CCW")
        
        let orientation = simd_quatf(angle: Float.pi / 2, axis: [0,1,0])
        robotEntity.transform.matrix *= Transform(rotation: orientation).matrix
    }

    func rotateCWPressed() {
        print("👇 Did press rotate CW")
        
        let orientation = simd_quatf(angle: -Float.pi / 2, axis: [0,1,0])
        robotEntity.transform.matrix *= Transform(rotation: orientation).matrix
    }
    
    func renderLoop() {
        if viewModel.robotIsWalking {
            robotEntity.transform.matrix *= Transform(translation: [0,0,0.001]).matrix
        }
    }
}


//////////////////////////////////
// Classes for custom entities. //
//////////////////////////////////

// MARK: - CustomModelEntity
class CustomModelEntity: Entity {
    let model: Entity
    
    init(name: String, usdzModelName: String) {
        model = try! Entity.load(named: usdzModelName)
        model.name = name

        super.init()

        self.addChild(model)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }

    // Play or stop animation.
    func animate(_ animate: Bool) {
        if animate {
            if let animation = model.availableAnimations.first {
                model.playAnimation(animation.repeat())
            }
        } else {
            model.stopAllAnimations()
        }
    }
}


// MARK: - Board Entity
class BoardEntity: Entity {
    let model: ModelEntity
    
    init(name: String, length: Float, color: UIColor) {
        let material = SimpleMaterial(color: color, isMetallic: false)
        model = ModelEntity(mesh: .generateBox(size: [length, 0.001, length]), materials: [material])
        model.name = name

        super.init()

        self.addChild(model)
    }

    init(name: String, length: Float, imageName: String) {
        var material = SimpleMaterial()
        material.color = .init(tint: .white.withAlphaComponent(0.999),
                            texture: .init(try! .load(named: imageName)))
        model = ModelEntity(mesh: .generateBox(size: [length, 0.001, length]), materials: [material])
        model.name = name

        super.init()

        self.addChild(model)
    }

    required init() {
        fatalError("init() has not been implemented")
    }
}


// MARK: - Cube Entity
class CubeEntity: Entity {
    let model: ModelEntity
    
    init(name: String, size: Float, color: UIColor) {
        let material = SimpleMaterial(color: color, isMetallic: false)
        model = ModelEntity(mesh: .generateBox(size: size, cornerRadius: 0.002), materials: [material])
        model.name = name

        super.init()

        self.addChild(model)
    }

    init(name: String, size: Float, imageName: String) {
        var material = SimpleMaterial()
        material.color = .init(tint: .white.withAlphaComponent(0.999),
                            texture: .init(try! .load(named: imageName)))
        model = ModelEntity(mesh: .generateBox(size: size, cornerRadius: 0.002), materials: [material])
        model.name = name

        super.init()

        self.addChild(model)
    }

    required init() {
        fatalError("init() has not been implemented")
    }
}


// MARK: - Sphere Entity
class SphereEntity: Entity {
    let model: ModelEntity
    
    init(name: String, radius: Float, color: UIColor) {
        let material = SimpleMaterial(color: color, isMetallic: false)
        model = ModelEntity(mesh: .generateSphere(radius: radius), materials: [material])
        model.name = name

        super.init()

        self.addChild(model)
    }

    init(name: String, radius: Float, imageName: String) {
        var material = SimpleMaterial()
        material.color = .init(tint: .white.withAlphaComponent(0.999),
                            texture: .init(try! .load(named: imageName)))
        model = ModelEntity(mesh: .generateSphere(radius: radius), materials: [material])
        model.name = name

        super.init()

        self.addChild(model)
    }

    required init() {
        fatalError("init() has not been implemented")
    }
}
