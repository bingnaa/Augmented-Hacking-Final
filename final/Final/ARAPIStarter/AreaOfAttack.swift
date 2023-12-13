//
//  AreaOfAttack.swift
//  ARAPIStarter
//
//  Created by Briana Jones on 11/27/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved./
//maybe?
//

import Foundation
import ARKit
import RealityKit

class AreaOfAttack: Entity{
    private var position: SIMD3<Float>?

    var model: ModelEntity? {
        didSet {
            if let model = self.model {
                // Set the model entity's initial properties
                model.scale = [1.0, 1.0, 1.0]
                model.generateCollisionShapes(recursive: true)
            }
        }
    }

    init(modelEntity: ModelEntity, name: String) {
        super.init()
        self.model = modelEntity
        self.model?.name = name
        //print(self.model?.name)
        
        if let model = self.model {
            self.addChild(model)
        }
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    func changeScaleBig(){
        model?.scale = [1.5, 1.5, 1.5]
        print("scaleup")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.model?.scale = [1.0, 1.0, 1.0]
            print("scaledown")
        }
    }
    
    func changeScaleSmall(){
        model?.scale = [0.5, 0.5, 0.5]
    }

    deinit {
    }
}
