//
//  Player.swift
//  ARAPIStarter
//
//  Created by Briana Jones on 11/18/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//
//tap to move

import Foundation
import ARKit
import RealityKit
import SceneKit

class Player: Entity {
    private var timer: Timer?
    private var cameraView: ARView?
    private var health: Int?
    private var attackDmg: Int?

    var model: ModelEntity? {
        didSet {
            if let model = self.model {
                // Set the model entity's initial properties
                //model.scale = [0.00001, 0.00001, 0.00001]
                //model.generateCollisionShapes(recursive: true)
                model.isEnabled = true // Enable the model if 'active' is true
            }
        }
    }

    init(modelEntity: ModelEntity, cameraView: ARView, name: String) {
        super.init()
        self.model = modelEntity
        self.model?.scale = [0.001, 0.001, 0.001]
        self.model?.name = name
        
        if let model = self.model {
            self.addChild(model)
        }

        self.cameraView = cameraView

        // Start a timer to update the position at random intervals
//        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
//        }
        self.animate(true)
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
//    public func getEnt() -> Entity? {
//        return model
//    }

    deinit {
        timer?.invalidate()
    }
    
    func animate(_ animate: Bool) {
        if animate {
            if let animation = model?.availableAnimations.first {
                model?.playAnimation(animation.repeat())
            }
        } else {
            model?.stopAllAnimations()
        }
    }
}

