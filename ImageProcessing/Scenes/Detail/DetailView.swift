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

struct ImageDetail: ReducerProtocol {
    struct State: Equatable {
        var image: UIImage?
        var asset: PHAsset!
        var similarPhotos: PHFetchResultCollection = .init(fetchResult: .init())
        var vectorData = ArrayResult.success(result: [VectorData]())
        init(asset: PHAsset) {
            self.asset = asset
        }
        
        
    }
    
    enum Action: Equatable {
        case loadImage
        case loadDatabase
        
        case imageLoaded(UIImage?)
        case loadSimilarPhotos
        case loadIdentifiers
        case similarPhotosLoaded(PHFetchResultCollection)
    }
    
    @Dependency(\.photoClient) var photoClient
    @Dependency(\.db) var db
    @Dependency(\.vectorClient) var vectorClient
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadImage:
                return .run { [asset = state.asset ] send in
                    let image = try await asset?.previewImage(targetSize: CGSize(width: ImageDetailView.height, height: ImageDetailView.height))
                    await send(.imageLoaded(image))
                }
            case .imageLoaded(let image):
                state.image = image
                return .none
            case .loadSimilarPhotos:
                return .run { [id = state.asset.localIdentifier] send in
                    let ids = await self.vectorClient.loadSimilarIdentifiers(id)
                    let photos = self.photoClient.loadPhotoFromIdentifier(ids)
                    await send(.similarPhotosLoaded(photos))
                }
            case .loadIdentifiers:
                return .none
            case .similarPhotosLoaded(let photos):
                state.similarPhotos = photos
                return .none
            case .loadDatabase:
                state.vectorData = ArrayResult.success(result: db.fetchAll())
                return .none
            }
        }
    }
}

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
                    .aspectRatio(contentMode: .fill)
                    .frame(width: ImageDetailView.height, height: ImageDetailView.height, alignment: .center)
                    .clipped()
                    .cornerRadius(12)
                Divider()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)) {
                    ForEach(viewStore.similarPhotos, id: \.localIdentifier) { asset in
                        NavigationLink {
                            ImageDetailView(
                                store: Store(
                                    initialState: ImageDetail.State(asset: asset),
                                    reducer: ImageDetail()._printChanges()
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
                viewStore.send(.loadDatabase)
                viewStore.send(.loadImage)
                viewStore.send(.loadSimilarPhotos)
            }
        }
    }
    
}
