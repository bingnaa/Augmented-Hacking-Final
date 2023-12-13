//
//  SwiftUIView.swift
//  ARAPIStarter
//
//  Created by Briana Jones on 10/25/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//

//  fixed with help of chatgpt (to get the image as an alert)

import SwiftUI

struct CustomAlert: View {
    @Binding var isPresented: Bool
    var viewModel: ViewModel
    
    var body: some View {
        ZStack {
            VStack {
                Image("flick") // Replace with your image asset name
                    .resizable()
                    .frame(width: 200, height: 200)
                    .padding(10)
                
                Text("To swat the bugs, make a strong flick with your phone.")
                    .multilineTextAlignment(.center)
                    .padding(20)
                
                Button("OK, Spawn Bugs") {
                    viewModel.uiSignal.send(.spawnParasite)
                    isPresented = false
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
            }
            .padding()
            .background(Color.black)
            .opacity(0.8)
            .cornerRadius(40)
            }
    }
}
