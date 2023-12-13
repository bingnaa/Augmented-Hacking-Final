//
//  ContentView.swift
//  ARAPIStarter
//
//  Created by Nien Lam on 10/19/23.
//  Copyright © 2023 Line Break, LLC. All rights reserved.
//place card ->buttons appear (spawn enemies, specials) -> special change states

import SwiftUI
import RealityKit

struct ContentView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            // AR View.
            ARViewContainer(viewModel: viewModel)

            if(viewModel.imageRec){
                VStack{
                    Button(action: {
                        viewModel.uiSignal.send(.spawnEnemy)
                    }) {
                        Text("Create Enemy Wave")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.top, 50)
                    }
                    
                    Spacer()
                    
                    if(!viewModel.specialReady){
                        HStack{
                            Button {
                                //viewModel.uiSignal.send(.specialAttackFire)
                            } label: {
                                Image("FireButton")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                        .background(Color.clear) // Optional: Set the background color to clear if needed
                            }
                            Button {
                                //viewModel.uiSignal.send(.specialAttackGrass)
                            } label: {
                                Image("GrassButton")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                        .background(Color.clear) // Optional: Set the background color to clear if needed
                            }
                            Button {
                                //viewModel.uiSignal.send(.specialAttackWater)
                            } label: {
                                Image("WaterButton")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                        .background(Color.clear) // Optional: Set the background color to clear if needed
                            }
                        }
                        .padding(15)
                    }
                    else{
                        HStack{
                            Button {
                                viewModel.uiSignal.send(.specialAttackFire)
                            } label: {
                                Image("FireButtonActive")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                        .background(Color.clear) // Optional: Set the background color to clear if needed
                            }
                            Button {
                                viewModel.uiSignal.send(.specialAttackGrass)
                            } label: {
                                Image("GrassButtonActive")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                        .background(Color.clear) // Optional: Set the background color to clear if needed
                            }
                            Button {
                                viewModel.uiSignal.send(.specialAttackWater)
                            } label: {
                                Image("WaterButtonActive")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                        .background(Color.clear) // Optional: Set the background color to clear if needed
                            }
                        }
                        .padding(15)
                    }
                }
            }
            else{
                VStack {
                    Image("targetimage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 350) // Adjust the size as needed
                        .opacity(0.4)
                        .padding(10)

                    Text("Find image to start game")
                        .foregroundColor(.white)
                        .font(.title)
                        .padding()
                        .background(
                            ZStack {
                                Color.black.opacity(0.6)
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(width: 300)
                }
            }
        }
    }
}

#Preview {
    ContentView(viewModel: ViewModel())
}
