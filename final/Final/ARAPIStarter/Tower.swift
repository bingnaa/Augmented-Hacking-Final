//
//  Tower.swift
//  ARAPIStarter
//
//  Created by Briana Jones on 11/18/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//
//code credit: https://medium.com/@literalpie/dragging-objects-in-scenekit-and-arkit-3568212a90e5

//drag around

import Foundation
import ARKit
import RealityKit

class Tower: Entity {
    private var timer: Timer?
    private var cameraView: ARView?
    private var position: SIMD3<Float>?
    private var attackDmg: Int?
    private var element : String?
    
    var active: Bool = true {
        didSet {
            // physics
            if active {
            } else {
            }
        }
    }

    var model: ModelEntity? {
        didSet {
            if let model = self.model {
                // Set the model entity's initial properties
                model.scale = [1.0, 1.0, 1.0]
                model.generateCollisionShapes(recursive: true)
                model.isEnabled = active // Enable the model if 'active' is true
            }
        }
    }

    init(modelEntity: ModelEntity, status: Bool, cameraView: ARView, name: String, type: String) {
        super.init()
        self.active = status
        self.element = type
        self.model = modelEntity
        self.model?.name = name
        
        if let model = self.model {
            self.addChild(model)
        }

        self.cameraView = cameraView
        
        // Start a timer to update the position at random intervals
//        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
//        }
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }
}
