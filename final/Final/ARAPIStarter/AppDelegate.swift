//
//  AppDelegate.swift
//  ARAPIStarter
//
//  Created by Nien Lam on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

import SwiftUI

@main
struct APIStarterApp: App {
    @StateObject var viewModel = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
                .statusBar(hidden: true)
        }
    }
}
