//
//  Enemy.swift
//  ARAPIStarter
//
//  Created by Briana Jones on 11/18/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import Foundation
import ARKit
import RealityKit

class Enemy: Entity {
    private var timer1: Timer?
    private var timer2: Timer?
    private var cameraView: ARView?
    private var currentPosition: SIMD3<Float>?
    private var playerPosition: SIMD3<Float>?
    private var health: Float = 40
    private var attackDmg: Int?
    private var element : String?
    private var movementSpeed: Float = 0.03
    
    //attackstuff
    private var playerIsColliding: Bool = false
    private var waterIsColliding: Bool = false
    private var fireIsColliding: Bool = false
    private var grassIsColliding: Bool = false
    private var dmg: Float = 0.0
    private var specialIsRun: Bool = false
    
    private var timers: [Timer] = []
    private var grassCreated: Bool = false
    private var waterCreated: Bool = false
    private var fireCreated: Bool = false
    private var playerCreated: Bool = false
    
//    private var onFrameUpdate: (() -> Void)?

    var active: Bool = true {
        didSet {
            // physics
            if active {
            } else {
                self.model?.isEnabled = false
                //print("didSet", active)
            }
        }
    }

    var model: ModelEntity? {
        didSet {
            if let model = self.model {
                // Set the model entity's initial properties
                model.scale = [1.0, 1.0, 1.0]
                //model.generateCollisionShapes(recursive: true)
                model.isEnabled = active // Enable the model if 'active' is true
            }
        }
    }
    
    var trackModel: HomeTower?

    init(modelEntity: ModelEntity, status: Bool, cameraView: ARView, name: String, type: String, homeEntity: HomeTower) {
        super.init()
        self.active = status
        self.element = type
        self.model = modelEntity
        self.model?.name = name
        self.trackModel = homeEntity
        
        if let model = self.model {
            self.addChild(model)
        }

        self.cameraView = cameraView

        //Start a timer to update the position at random intervals
        timer1 = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        timer2 = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkHealth()
        }
        
        timers.append(timer1!)
        timers.append(timer2!)
        
//        cameraView.scene.subscribe(
//                to: SceneEvents.Update.self,
//                on: self
//            ) { [weak self] event in
//            self?.updatePerFrame()
//        }
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    deinit {
//        timer1?.invalidate()
//        timer2?.invalidate()
        timers.forEach { $0.invalidate() }
        timers.removeAll()
    }
    
//    func setDmg(multi: Float){
//        dmg = multi
//    }
//    func createDmg(multi: Float) {
//        createTimerIfNeeded(for: &playerCreated, action: { [weak self] in
//            self?.minusHealth(multi: multi)
//        })
//    }
//
//    func createDmgFire(multi: Float) {
//        createTimerIfNeeded(for: &fireCreated, action: { [weak self] in
//            self?.minusHealthFireTower(multi: multi)
//        })
//    }
//
//    func createDmgWater(multi: Float) {
//        createTimerIfNeeded(for: &waterCreated, action: { [weak self] in
//            self?.minusHealthWaterTower(multi: multi)
//        })
//    }
//
//    func createDmgGrass(multi: Float) {
//        createTimerIfNeeded(for: &grassCreated, action: { [weak self] in
//            self?.minusHealthGrassTower(multi: multi)
//        })
//    }
//
//    private func createTimerIfNeeded(for createdFlag: inout Bool, action: @escaping () -> Void) {
//        if !createdFlag {
//            let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
//                action()
//            }
//            timers.append(timer)
//        }
//        createdFlag = true
//    }
    
    func createDmg(multi: Float){
        if(!playerCreated){
            let time = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                self?.minusHealth(multi: multi)
            }
        }
        playerCreated = true
    }
    
    func createDmgFire(multi: Float){
        if(!fireCreated){
            let time = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                self?.minusHealthFireTower(multi: multi)
            }
        }
        fireCreated = true
    }
    
    func createDmgWater(multi: Float){
        if(!waterCreated){
            let time = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                self?.minusHealthWaterTower(multi: multi)
            }
        }
        waterCreated = true
    }
    
    func createDmgGrass(multi: Float){
        if(!grassCreated){
            let time = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                self?.minusHealthGrassTower(multi: multi)
            }
            grassCreated = true
        }
    }
    
    func minusHealth(multi: Float){
        if(playerIsColliding){
            health -= 5.0*multi
            //print("health: ", health)
        }
    }
    
    func minusHealthWaterTower(multi: Float){
        if(waterIsColliding){
            health -= 5.0*multi
           //print("health: ", health)
        }
    }
    
    func minusHealthFireTower(multi: Float){
        if(fireIsColliding){
            health -= 5.0*multi
            //print("health: ", health)
        }
    }
    
    func minusHealthGrassTower(multi: Float){
        if(grassIsColliding){
            health -= 5.0*multi
            //print("health: ", health)
        }
    }
    
    func minusSpecial(multi: Float){
        if(playerIsColliding && !specialIsRun){
            health -= 20.0*multi
            specialIsRun = true
        }
        //print("health: ", health)
    }
    
    func changeStateTrue(){
        playerIsColliding = true
    }
    
    func changeStateFalse(){
        playerIsColliding = false
    }
    
    func changeStateTrueWaterTower(){
        waterIsColliding = true
    }
    
    func changeStateFalseWaterTower(){
        waterIsColliding = false
    }
    
    func changeStateTrueFireTower(){
        fireIsColliding = true
    }
    
    func changeStateFalseFireTower(){
        fireIsColliding = false
    }
    
    func changeStateTrueGrassTower(){
        grassIsColliding = true
    }
    
    func changeStateFalseGrassTower(){
        grassIsColliding = false
    }
    
    func checkHealth(){
        if(health <= 0){
            //print("dead")
            setActiveFalse()
            return
        }
        
        //print("health: ", health)
    }
    
    func getElement() -> String{
        return element!
    }
    
    func setActiveFalse(){
        active = false
        removeFromParent()
    }
    
    //get to home
    func updatePosition() {
            guard trackModel != nil, self.position != nil else {
                return
            }

            // Now you can safely use trackModel and self.position without optional binding
            let playerPosition = trackModel!.position
            let currentPosition = self.position


            // Calculate the direction from the current position to the player's position
            let direction = simd_normalize(playerPosition - currentPosition)

            // Calculate the new position using smoothstep for smooth movement
            let newPosition = currentPosition + direction * movementSpeed

            // Update the position of the enemy
            self.position = newPosition
    }
}
