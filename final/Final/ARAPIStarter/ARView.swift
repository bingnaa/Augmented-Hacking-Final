//
//  ARView.swift
//  ARAPIStarter
//
//  Created by Nien Lam on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//
//made with help of Nien/ChatGPT

//to do: specialattack ui, fix collision

//fix minus health: home tower

import SwiftUI
import ARKit
import RealityKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    let viewModel: ViewModel
    
    func makeUIView(context: Context) -> SimpleARView {
        SimpleARView(frame: .zero, viewModel: viewModel)
    }
    
    func updateUIView(_ arView: SimpleARView, context: Context) { }
}

class SimpleARView: ARView, ARSessionDelegate {
    var viewModel: ViewModel
    var arView: ARView { return self }
    var subscriptions = Set<AnyCancellable>()

    var imageAnchorToEntity: [ARImageAnchor: AnchorEntity] = [:]
    var originAnchor: AnchorEntity!
    var pov: AnchorEntity!

    //var sphere: ModelEntity!
    var playerObject: Player!
    //var myTowerEntity: Tower!
    var hCard: HomeTower!
    var playerAttackArea: AreaOfAttack!
    var enemyPool: [Enemy] = []
    
    //towers
    var fireTowerEntity: Tower!
    var grassTowerEntity: Tower!
    var waterTowerEntity: Tower!
    var fireAttackArea: AreaOfAttack!
    var waterAttackArea: AreaOfAttack!
    var grassAttackArea: AreaOfAttack!
    var homeAOA: AreaOfAttack!
    
    //detection
    var runSpecial: Bool! = false
    var playerElement: String = "normal"
    var collisionTimers = [ObjectIdentifier: Timer]()
    var collisionTimersFireTower = [ObjectIdentifier: Timer]()
    var collisionTimersWaterTower = [ObjectIdentifier: Timer]()
    var collisionTimersGrassTower = [ObjectIdentifier: Timer]()
    var collisionTimersHome = [ObjectIdentifier: Timer]()
    
    var tapGesture: UITapGestureRecognizer?
    var longGesture: UILongPressGestureRecognizer?
    
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
        // Setup world tracking and plane detection.
        //arView.debugOptions = [.showPhysics]
        let configuration = ARWorldTrackingConfiguration()
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]
        
        var set = Set<ARReferenceImage>()

        // Setup target image A.
        if let detectionImage = makeDetectionImage(named: "targetimage",
                                                   referenceName: "targetimage",
                                                   physicalWidth: 0.18415) {
            set.insert(detectionImage)
        }
        
        configuration.detectionImages = set
        configuration.maximumNumberOfTrackedImages = 1
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        arView.session.delegate = self
        
        //panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        //tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        //arView.addGestureRecognizer(tapGesture!)
                
        longGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        self.addGestureRecognizer(longGesture!)
    }

    func setupSubscriptions() {
        // Process UI signals.
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }
        .store(in: &subscriptions)
        
//        arView.scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
//            guard let self = self else { return }
//            
//            //player card & enemy
//            //water tower & enemy
//            //fire tower & enemy
//            //grass tower & enemy
//            //homecard & enemy
//        }.store(in: &subscriptions)
//        
//        arView.scene.subscribe(to: CollisionEvents.Ended.self) { [weak self] event in
//            guard let self = self else { return }
//        }.store(in: &subscriptions)
        
        // Old collisions
            arView.scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
                guard let self else { return }
                
                //Enemy hit home
                if event.entityA.name == "HomeAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        if(event.entityA.name == "home"){
                            print("my home:", event.entityA.parent)
                        }
                        myEnemy.setActiveFalse()
                        //enemy dies
                        if let myHome = event.entityA.parent as? HomeTower {
                            myHome.minusHealth()
                        }
                    } else {
                        //print("Cast failed")
                    }
                }
                
                //Player collision
                if event.entityA.name == "PlayerAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        //print("dupe")
                        myEnemy.changeStateTrue()
                        let enemyElement = myEnemy.getElement()
                        myEnemy.createDmg(multi: attackMultiplier(attackType: playerElement, enemyType: enemyElement))
                        
                        if(runSpecial){
                            myEnemy.minusSpecial(multi: attackMultiplier(attackType: playerElement, enemyType: enemyElement))
                        }
                    } else {
                        //prints "Slime"
                        //print(event.entityB.parent?.parent)
                        //prints Enemy
                        //print(event.entityB.parent?.parent?.parent)
                        //print("Cast failed")
                    }
                }
                if event.entityA.name == "FireTowerAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        //print("dupe")
                        myEnemy.changeStateTrue()
                        let enemyElement = myEnemy.getElement()
                        myEnemy.createDmgFire(multi: attackMultiplier(attackType: "fire", enemyType: enemyElement))
                    } else {
                        //print("Cast failed")
                    }
                }
                if event.entityA.name == "WaterTowerAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        //print("dupe")
                        myEnemy.changeStateTrueWaterTower()
                        let enemyElement = myEnemy.getElement()
                        myEnemy.createDmgWater(multi: attackMultiplier(attackType: "water", enemyType: enemyElement))
                    } else {
                        //print("Cast failed")
                    }
                }
                if event.entityA.name == "GrassTowerAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        //print("dupe")
                        myEnemy.changeStateTrueGrassTower()
                        let enemyElement = myEnemy.getElement()
                        myEnemy.createDmgGrass(multi: attackMultiplier(attackType: "grass", enemyType: enemyElement))
                    } else {
                        //print("Cast failed")
                    }
                }
            }.store(in: &subscriptions)
    
            arView.scene.subscribe(to: CollisionEvents.Ended.self) { [weak self] event in
                guard let self else { return }
    
                //Player
                if event.entityA.name == "PlayerAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        myEnemy.changeStateFalse()
                    } else {
                    }
                }
                
                //Towers
                if event.entityA.name == "GrassTowerAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        myEnemy.changeStateFalseGrassTower()
                    } else {
                    }
                }
                if event.entityA.name == "WaterTowerAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        myEnemy.changeStateFalseWaterTower()
                    } else {
                    }
                }
                if event.entityA.name == "FireTowerAOA" || event.entityB.name == "EnemyAOA" {
                    if let myEnemy = event.entityB.parent?.parent?.parent as? Enemy {
                        myEnemy.changeStateFalseFireTower()
                    } else {
                    }
                }
            }.store(in: &subscriptions)
    }
    
    func processUISignal(_ signal: ViewModel.UISignal) {
        switch signal {
        case .reset:
            resetScene()
        case .spawnEnemy:
            spawnEnemies(count: 5)
            spawnEnemies(count: 5)
            //spawnSlimes()
        case .spawnPlayer:
            spawnPlayer()
        case .specialAttackFire:
            triggerSpecialFire()
        case .spawnTower:
            spawnTowers()
        case .specialAttackWater:
            triggerSpecialWater()
        case .specialAttackGrass:
            triggerSpecialEarth()
        }
    }
    
    // Define entities here.
    func setupEntities() {
        // Create an anchor at scene origin.
        //originAnchor?.removeFromParent()
        //originAnchor = nil
        //originAnchor = AnchorEntity(plane: [.horizontal])
        //originAnchor?.orientation = simd_quatf(angle: .pi / 2, axis: [0,1,0])
        //originAnchor?.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
        //arView.scene.addAnchor(originAnchor)
        
        // Add pov entity that follows the camera.
        pov = AnchorEntity(.camera)
        arView.scene.addAnchor(pov)
        
        spawnPlayer()
        spawnTowers()
        print("recog2")
    }
    
    //----------------------AR Image Anchor--------------------------
    // Called when an anchor is added to scene.
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Handle image anchors.
        anchors.compactMap { $0 as? ARImageAnchor }.forEach {
            // Grab reference image name.
            guard let referenceImageName = $0.referenceImage.name else { return }

            // Create anchor and place at image location.
            originAnchor = AnchorEntity(world: $0.transform)
            arView.scene.addAnchor(originAnchor)
            
            if referenceImageName == "targetimage" {
                setupEntities()
                viewModel.imageRec = true
                print(viewModel.imageRec)
                //print("recog")
            }
        }
    }
    
    // Helper method for creating a detection image.
    func makeDetectionImage(named: String, referenceName: String, physicalWidth: CGFloat) -> ARReferenceImage? {
        guard let targetImage = UIImage(named: named)?.cgImage else {
            print("❗️ Error loading target image:", named)
            return nil
        }

        let arReferenceImage  = ARReferenceImage(targetImage, orientation: .up, physicalWidth: physicalWidth)
        arReferenceImage.name = referenceName

        return arReferenceImage
    }
    

    //----------------------RESETSCENE--------------------------
    // Reset scene.
    func resetScene() {
        //originAnchor?.removeFromParent()
//        originAnchor = nil
//        originAnchor = AnchorEntity(plane: [.horizontal])
//        originAnchor?.orientation = simd_quatf(angle: .pi / 2, axis: [0,1,0])
//        arView.scene.addAnchor(originAnchor!)
    }
    
    //----------------------SpawnTest--------------------------
    
    func spawnPlayer(){
        print("spawned")
        
        //------------HOME
        let homeCard = MeshResource.generatePlane(width: 0.3, height: 0.4)
        //let hCardTexture = PhysicallyBasedMaterial.Texture.init(try! .load(named: "targetimage"))
        //let homeCardMaterial = SimpleMaterial(color: .green, isMetallic: false)
        var homeCardMaterial = SimpleMaterial()
        homeCardMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                            texture: .init(try! .load(named: "targetimage")))
        let hCardEntity = ModelEntity(mesh: homeCard, materials: [homeCardMaterial])
        hCardEntity.generateCollisionShapes(recursive: true)
        hCard = HomeTower(modelEntity: hCardEntity, status: true, cameraView: arView, name: "home")
        
        let hMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3, cornerRadius: 0.3)
        //let cMesh = MeshResource.generateBox(size: [0.5, 0.5, 0.5], cornerRadius: 0.2)
        let hMaterial = SimpleMaterial(color: UIColor.white.withAlphaComponent(0.2), isMetallic: false)
        let hAoaEntity = ModelEntity(mesh: hMesh, materials: [hMaterial])
        hAoaEntity.generateCollisionShapes(recursive: true)
        homeAOA = AreaOfAttack(modelEntity: hAoaEntity, name: "HomeAOA")
        
        hCardEntity.orientation = simd_quatf(angle: .pi/2, axis: [-1,0,0])
        hAoaEntity.orientation = simd_quatf(angle: .pi/2, axis: [1,0,0])
        hCardEntity.position = [0, 0, 0.1]
        hCard.addChild(homeAOA)
        hAoaEntity.position = [0, 0, -0.1]
        
        originAnchor.addChild(hCardEntity)
        hCardEntity.position = [0, 0, 0]
        //hCardEntity.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
        
        //------------PLAYER
        //let mesh = try! Entity.load(named: "Happy")
        let mesh = try! ModelEntity.loadModel(named: "Happy")
        mesh.generateCollisionShapes(recursive: true)
        
        // Add child plane for area of attack (collision detection)
        let cMesh = MeshResource.generatePlane(width: 0.4, depth: 0.4, cornerRadius: 0.4)
        let cMaterial = SimpleMaterial(color: UIColor.white.withAlphaComponent(0.6), isMetallic: false)
        let aoaEntity = ModelEntity(mesh: cMesh, materials: [cMaterial])
        aoaEntity.generateCollisionShapes(recursive: true)
        
        playerAttackArea = AreaOfAttack(modelEntity: aoaEntity, name: "PlayerAOA")

        //aoaEntity.position = [0, 0, 0]
        mesh.position = [0, 0, 0]
        //mesh.addChild(playerAttackArea)
        //aoaEntity.position = [0, 0, 0]

        playerObject = Player(modelEntity: mesh, cameraView: arView, name: "Player")
        playerObject.transform.matrix = pov.transformMatrix(relativeTo: originAnchor) * float4x4(translation: [0.0, 0.0, -0.5])
        //playerObject.addChild(playerAttackArea)
        mesh.addChild(playerAttackArea)
        aoaEntity.position = [0, 0, 0]
        
        originAnchor.addChild(playerObject)
        playerObject.position = [0, 0, 0]
        playerObject.orientation = simd_quatf(angle: .pi / 2, axis: [0,1,0])
        
        //------------DRAGPLAYER
        if let longG = longGesture {
            self.addGestureRecognizer(longG)
                
            // NLAM: Use the underlying model and not the outer Entity.
            if let model = playerObject.model {
                self.installGestures([.translation, .rotation], for: model)
            }
        } else {
                    // Handle the case where tapGesture is nil
            print("longG is nil")
        }
    }
    
//    func spawnTower(){
//        let cardMesh = MeshResource.generatePlane(width: 0.2, height: 0.1)
//        let cardMaterial = SimpleMaterial(color: .green, isMetallic: false)
//        let cardEntity = ModelEntity(mesh: cardMesh, materials: [cardMaterial])
//        
//        cardEntity.generateCollisionShapes(recursive: true)
//        
//        myTowerEntity = Tower(modelEntity: cardEntity, status: true, cameraView: arView, name: "Tower", type: "fire")
//                
//        // Add the card entity to the scene
//        originAnchor.addChild(cardEntity)
//    }
    
    func spawnTowers(){
        let val: Float = 0.1
//    fireTowerEntity: Tower!
        let fireCard = MeshResource.generatePlane(width: 0.3, height: 0.4)
        var fireCardMaterial = SimpleMaterial()
        fireCardMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                            texture: .init(try! .load(named: "FireTower")))
        let fireCardEntity = ModelEntity(mesh: fireCard, materials: [fireCardMaterial])
        fireCardEntity.generateCollisionShapes(recursive: true)

        fireTowerEntity = Tower(modelEntity: fireCardEntity, status: true, cameraView: arView, name: "Tower", type: "fire")
        
//    grassTowerEntity: Tower!
        let grassCard = MeshResource.generatePlane(width: 0.3, height: 0.4)
        var grassCardMaterial = SimpleMaterial()
        grassCardMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                            texture: .init(try! .load(named: "GrassTower")))
        let grassCardEntity = ModelEntity(mesh: grassCard, materials: [grassCardMaterial])
        grassCardEntity.generateCollisionShapes(recursive: true)

        grassTowerEntity = Tower(modelEntity: grassCardEntity, status: true, cameraView: arView, name: "Tower", type: "grass")
        
//    waterTowerEntity: Tower!
        let waterCard = MeshResource.generatePlane(width: 0.3, height: 0.4)
        var waterCardMaterial = SimpleMaterial()
        waterCardMaterial.color = .init(tint: .white.withAlphaComponent(0.999),
                            texture: .init(try! .load(named: "WaterTower")))
        let waterCardEntity = ModelEntity(mesh: waterCard, materials: [waterCardMaterial])
        waterCardEntity.generateCollisionShapes(recursive: true)

        waterTowerEntity = Tower(modelEntity: waterCardEntity, status: true, cameraView: arView, name: "Tower", type: "water")
        
//        var fireAttackArea: AreaOfAttack!
        // Add child plane for area of attack (collision detection)
        let fireMesh = MeshResource.generatePlane(width: 0.6, depth: 0.6, cornerRadius: 0.6)
        //let cMesh = MeshResource.generateBox(size: [0.5, 0.5, 0.5], cornerRadius: 0.2)
        let fireMaterial = SimpleMaterial(color: UIColor.red.withAlphaComponent(0.6), isMetallic: false)
        let fireAoaEntity = ModelEntity(mesh: fireMesh, materials: [fireMaterial])
        fireAoaEntity.generateCollisionShapes(recursive: true)
        
        fireAttackArea = AreaOfAttack(modelEntity: fireAoaEntity, name: "FireTowerAOA")
        fireAoaEntity.orientation = simd_quatf(angle: .pi/2, axis: [1,0,0])
        fireCardEntity.orientation = simd_quatf(angle: .pi/2, axis: [-1,0,0])
        fireCardEntity.position = [0, 0, val]
        fireCardEntity.addChild(fireAoaEntity)
        fireAoaEntity.position = [0, 0, -val]
        
//        var waterAttackArea: AreaOfAttack!
        let waterMesh = MeshResource.generatePlane(width: 0.6, depth: 0.6, cornerRadius: 0.6)
        //let cMesh = MeshResource.generateBox(size: [0.5, 0.5, 0.5], cornerRadius: 0.2)
        let waterMaterial = SimpleMaterial(color: UIColor.blue.withAlphaComponent(0.6), isMetallic: false)
        let waterAoaEntity = ModelEntity(mesh: waterMesh, materials: [waterMaterial])
        waterAoaEntity.generateCollisionShapes(recursive: true)
        
        waterCardEntity.orientation = simd_quatf(angle: .pi/2, axis: [-1,0,0])
        waterAttackArea = AreaOfAttack(modelEntity: waterAoaEntity, name: "WaterTowerAOA")
        waterAoaEntity.orientation = simd_quatf(angle: .pi/2, axis: [1,0,0])
        waterCardEntity.position = [0, 0, val]
        waterCardEntity.addChild(waterAoaEntity)
        waterAoaEntity.position = [0, 0, -val]
        
//        var grassAttackArea: AreaOfAttack!
        let grassMesh = MeshResource.generatePlane(width: 0.6, depth: 0.6, cornerRadius: 0.6)
        //let cMesh = MeshResource.generateBox(size: [0.5, 0.5, 0.5], cornerRadius: 0.2)
        let grassMaterial = SimpleMaterial(color: UIColor.green.withAlphaComponent(0.6), isMetallic: false)
        let grassAoaEntity = ModelEntity(mesh: grassMesh, materials: [grassMaterial])
        grassAoaEntity.generateCollisionShapes(recursive: true)
        
        grassAttackArea = AreaOfAttack(modelEntity: grassAoaEntity, name: "GrassTowerAOA")
        grassAoaEntity.orientation = simd_quatf(angle: .pi/2, axis: [1,0,0])
        grassCardEntity.orientation = simd_quatf(angle: .pi/2, axis: [-1,0,0])
        grassCardEntity.position = [0, 0, val]
        grassCardEntity.addChild(grassAoaEntity)
        grassAoaEntity.position = [0, 0, -val]
        
        originAnchor.addChild(grassCardEntity)
        grassCardEntity.position = [0.5, 0, 0.5]
    
        originAnchor.addChild(waterCardEntity)
        waterCardEntity.position = [-0.5, 0, -0.5]

        originAnchor.addChild(fireCardEntity)
        fireCardEntity.position = [0.5, 0, -0.5]
        
        if let longG = longGesture {
            self.addGestureRecognizer(longG)
                
            // NLAM: Use the underlying model and not the outer Entity.
            if let model1 = grassTowerEntity.model {
                self.installGestures([.translation], for: model1)
            }
            if let model2 = waterTowerEntity.model {
                self.installGestures([.translation], for: model2)
            }
            if let model3 = fireTowerEntity.model {
                self.installGestures([.translation], for: model3)
            }
        } else {
                    // Handle the case where tapGesture is nil
            print("longG is nil")
        }
    }
    
    func spawnEnemies(count: Int) {
        for _ in 0..<count {
            let randomValX = Float.random(in: Bool.random() ? -1.0 ... -0.5 : 0.5 ... 1.0)
            let randomValZ = Float.random(in: Bool.random() ? -1.0 ... -0.5 : 0.5 ... 1.0)
            
            let randomType: String
                switch Int.random(in: 0...2) {
                case 0:
                    randomType = "fire"
                case 1:
                    randomType = "water"
                case 2:
                    randomType = "grass"
                default:
                    fatalError("Invalid random type")
            }

            let slimeMesh = MeshResource.generateSphere(radius: 0.04)
            let slimeMaterial: SimpleMaterial
                switch randomType {
                case "fire":
                    slimeMaterial = SimpleMaterial(color: .red, isMetallic: false)
                case "water":
                    slimeMaterial = SimpleMaterial(color: .blue, isMetallic: false)
                case "grass":
                    slimeMaterial = SimpleMaterial(color: .green, isMetallic: false)
                default:
                    fatalError("Invalid random type")
            }
            let sEntity = ModelEntity(mesh: slimeMesh, materials: [slimeMaterial])

            // Clone the entity before adding the child
            let clonedSEntity = sEntity.clone(recursive: true)

            // Add child plane for area of attack (collision detection)
            let cMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3, cornerRadius: 0.3)
            let cMaterial: SimpleMaterial
                switch randomType {
                case "fire":
                    cMaterial = SimpleMaterial(color: .red.withAlphaComponent(0.2), isMetallic: false)
                case "water":
                    cMaterial = SimpleMaterial(color: .blue.withAlphaComponent(0.2), isMetallic: false)
                case "grass":
                    cMaterial = SimpleMaterial(color: .green.withAlphaComponent(0.2), isMetallic: false)
                default:
                    fatalError("Invalid random type")
                }
            let aoaEntity = ModelEntity(mesh: cMesh, materials: [cMaterial])
            aoaEntity.generateCollisionShapes(recursive: true)

            let attackArea = AreaOfAttack(modelEntity: aoaEntity, name: "EnemyAOA")
            clonedSEntity.addChild(attackArea)
            aoaEntity.position = [0, -0.04, 0]

            let arSlime = Enemy(modelEntity: clonedSEntity, status: true, cameraView: arView, name: "Slime", type: randomType, homeEntity: hCard)
            originAnchor.addChild(arSlime)
//            arSlime.transform.matrix = pov.transformMatrix(relativeTo: originAnchor) * float4x4(translation: [randomVal, 0, randomVal])
            arSlime.transform.matrix = pov.transformMatrix(relativeTo: originAnchor) * float4x4(translation: [randomValX, 0, randomValZ])
            arSlime.orientation = simd_quatf(angle: .pi / 2, axis: [0,1,0])
            enemyPool.append(arSlime)
        }
    }
    
    //----------------------ATTACK--------------------------
    func triggerSpecialFire(){
        //print(playerObject.children)
        viewModel.specialReady = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.viewModel.specialReady = true
        }
        
        //print(playerObject.children[0].children[0])
        if let area = playerObject.children[0].children[0] as? AreaOfAttack {
            print("dupe")
            area.changeScaleBig()
            fireAttackArea.changeScaleBig()
            runSpecial = true
            playerElement = "fire"
            if let firstChild = playerAttackArea.children.first, let modelEntity = firstChild as? ModelEntity {
                modelEntity.model?.materials[0] = SimpleMaterial(color: UIColor.red.withAlphaComponent(0.2), isMetallic: false)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.runSpecial = false
                if let firstChild = self.playerAttackArea.children.first, let modelEntity = firstChild as? ModelEntity {
                    modelEntity.model?.materials[0] = SimpleMaterial(color: UIColor.white.withAlphaComponent(0.2), isMetallic: false)
                }
                self.playerElement = "normal"
            }
        } else {
            //print("Cast failed")
        }
    }
    
    func triggerSpecialEarth(){
        viewModel.specialReady = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.viewModel.specialReady = true
        }
        
        if let area = playerObject.children[0].children[0] as? AreaOfAttack {
            print("dupe")
            area.changeScaleBig()
            grassAttackArea.changeScaleBig()
            runSpecial = true
            playerElement = "grass"
            if let firstChild = playerAttackArea.children.first, let modelEntity = firstChild as? ModelEntity {
                modelEntity.model?.materials[0] = SimpleMaterial(color: UIColor.green.withAlphaComponent(0.2), isMetallic: false)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.runSpecial = false
                if let firstChild = self.playerAttackArea.children.first, let modelEntity = firstChild as? ModelEntity {
                    modelEntity.model?.materials[0] = SimpleMaterial(color: UIColor.white.withAlphaComponent(0.2), isMetallic: false)
                }
            }
        } else {
            //print("Cast failed")
            self.playerElement = "normal"
        }
    }
    
    func triggerSpecialWater(){
        viewModel.specialReady = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.viewModel.specialReady = true
        }
        
        if let area = playerObject.children[0].children[0] as? AreaOfAttack {
            print("dupe")
            area.changeScaleBig()
            waterAttackArea.changeScaleBig()
            runSpecial = true
            playerElement = "water"
            if let firstChild = playerAttackArea.children.first, let modelEntity = firstChild as? ModelEntity {
                modelEntity.model?.materials[0] = SimpleMaterial(color: UIColor.blue.withAlphaComponent(0.2), isMetallic: false)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.runSpecial = false
                if let firstChild = self.playerAttackArea.children.first, let modelEntity = firstChild as? ModelEntity {
                    modelEntity.model?.materials[0] = SimpleMaterial(color: UIColor.white.withAlphaComponent(0.2), isMetallic: false)
                }
                self.playerElement = "normal"
            }
        } else {
            //print("Cast failed")
        }
    }
    
    //----------------------INTERACTIONDRAG--------------------------
    @objc func handleLongPress(_ recognizer: UITapGestureRecognizer? = nil) {
        //print("long press")

        guard let touchInView = recognizer?.location(in: self) else {
            return
        }

        guard let modelEntity = self.entity(at: touchInView) as? ModelEntity else {
            //print("modelEntity not found")
            return
        }
        
        //print("Long press detected on - \(modelEntity.name)")
            
    }
    
    //----------------------Attack Logic--------------------------
    func attackMultiplier (attackType: String, enemyType: String) -> Float{
        //print("attackType:", attackType, " enemyType: ", enemyType)
        if(attackType == "water" && enemyType == "fire"){
            return 2.0
        }
        else if(attackType == "fire" && enemyType == "grass"){
            return 2.0
        }
        else if(attackType == "grass" && enemyType == "water"){
            return 2.0
        }
        else if(attackType == "fire" && enemyType == "water"){
            return 0.5
        }
        else if(attackType == "water" && enemyType == "grass"){
            return 0.5
        }
        else if(attackType == "grass" && enemyType == "fire"){
            return 0.5
        }
        else {
            // Handle same type attacks
            return 1.0
        }
    }
}
