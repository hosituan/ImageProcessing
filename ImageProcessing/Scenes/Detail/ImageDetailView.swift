//
//  DetailView.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 28/03/2023.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Photos

struct ImageDetailView: View {
    let store: StoreOf<ImageDetail>
    init(store: StoreOf<ImageDetail>) {
        self.store = store
    }
    static let height: CGFloat = (UIScreen.main.bounds.width - 48)
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView(showsIndicators: false) {
                Image(uiImage: viewStore.image ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: ImageDetailView.height, height: ImageDetailView.height, alignment: .center)
                    .clipped()
                    .cornerRadius(12)
                Divider()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)) {
                    ForEach(viewStore.similarPhotos, id: \.localIdentifier) { asset in
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
            .navigationTitle("Similar Photos")
            .onAppear {
                viewStore.send(.loadImage)
                viewStore.send(.loadSimilarPhotos)
            }
        }
    }
    
}
