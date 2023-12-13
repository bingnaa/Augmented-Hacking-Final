//
//  ViewModel.swift
//  APIStarter
//
//  Created by Nien Lam on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import Foundation
import Combine

@MainActor
class ViewModel: ObservableObject {
    //do specials on a timer?
    @Published var imageRec: Bool = false
    @Published var gameOver: Bool = false
    @Published var specialReady: Bool = true
    
    // For handling different button presses.
    enum UISignal {
        case reset
        case spawnEnemy
        case spawnPlayer
        case specialAttackFire
        case specialAttackWater
        case specialAttackGrass
        case spawnTower
    }
    let uiSignal = PassthroughSubject<UISignal, Never>()
    
    
    init() {
        
    }
}
