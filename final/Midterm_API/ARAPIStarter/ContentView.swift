//
//  ContentView.swift
//  ARAPIStarter
//
//  Created by Nien Lam on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.

//  Did initial alert with help from Hank's code

import SwiftUI
import RealityKit

struct ContentView: View {
    @State var viewModel: ViewModel
    
    @State var flickMotion = true

    var body: some View {
        ZStack {
            // AR View.
            ARViewContainer(viewModel: viewModel)
            
            Button(action: {
                viewModel.uiSignal.send(.spawnParasite)
                //flickMotion = true
            })  {
                Text("Spawn More Bugs")
                    .font(.system(size: 18))
                    .foregroundColor(Color(white: 1))
            }
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 80)
            
//            .alert("Motion Tutorial", isPresented: $flickMotion) {
//                Image("flick") // Replace with your image asset name
//                    .resizable()
//                    .frame(width: 100, height: 100)
//                Button("OK, Spawn Bugs") {
//                    viewModel.uiSignal.send(.spawnParasite)
//                }
//            } message: {
//                VStack{
//                    Text("To swat the bugs, flick your phone.")
//                        .multilineTextAlignment(.center)
//                }
//            }
            
            CustomAlert(isPresented: $flickMotion, viewModel: viewModel)
                .opacity(flickMotion ? 1 : 0)
            
            //Spacer()

        }
    }
}

#Preview {
    ContentView(viewModel: ViewModel())
}
