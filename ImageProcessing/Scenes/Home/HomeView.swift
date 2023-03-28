//
//  HomeView.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 27/03/2023.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Photos
import Vision

struct HomeView: View {
    let store: StoreOf<Home>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)) {
                    ForEach(viewStore.photos, id: \.localIdentifier) { asset in
                        NavigationLink {
                            ImageDetailView(
                                store: Store(
                                    initialState: ImageDetail.State(asset: asset),
                                    reducer: ImageDetail()
                                )
                            )
                        } label: {
                            ImageStackView(asset: asset)
                        }
                    }
                }

            }
            .overlay(actionStackView(viewStore), alignment: .bottom)
            .navigationTitle("Photos")
            .alert(self.store.scope(state: \.alert), dismiss: .alertDismissed)
            .onAppear {
                viewStore.send(.requestPermission)
            }
        }
    }
    
    func actionStackView(_ store: ViewStore<Home.State, Home.Action>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button {
                    store.send(.loadPhotos)
                } label: {
                    Text("Load Photos")
                        .foregroundColor(.white)
                        .font(.system(.headline))
                        .frame(height: 56)
                        .padding(.horizontal)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                Button {
                    store.send(.processImages)
                } label: {
                    Text("Process Images")
                        .foregroundColor(.white)
                        .font(.system(.headline))
                        .frame(height: 56)
                        .padding(.horizontal)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
}
