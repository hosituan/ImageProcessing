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
    init(store: StoreOf<Home>) {
        self.store = store
    }
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)) {
                    ForEach(viewStore.photos, id: \.localIdentifier) { asset in
                        NavigationLink {
                            ImageDetailView(
                                store: Store(
                                    initialState: ImageDetail.State(tree: viewStore.tree, asset: asset),
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
                viewStore.send(.loadDatabase)
            }
        }
    }
    
    func actionStackView(_ store: ViewStore<Home.State, Home.Action>) -> some View {
        HStack {
            Button {
                store.send(.processImages)
            } label: {
                ZStack {
                    Text("Process Images")
                        .foregroundColor(.white)
                        .font(.system(.headline))
                    ProgressView()
                        .foregroundColor(.white)
                        .frame(width: 40)
                        .hidden(!store.isProcessing)
                }
                .frame(height: 56)
                .padding(.horizontal)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
    }
    
}
