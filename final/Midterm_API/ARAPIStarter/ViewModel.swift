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
    
    // For handling different button presses.
    enum UISignal {
        case reset
        case spawnParasite
    }
    let uiSignal = PassthroughSubject<UISignal, Never>()
    
    
    init() {
    }
}
