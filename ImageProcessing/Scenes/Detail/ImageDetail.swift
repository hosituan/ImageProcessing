//
//  ImageDetail.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 29/03/2023.
//

import Foundation
import ComposableArchitecture
import Photos
import UIKit
import KDTree

struct ImageDetail: ReducerProtocol {
    struct State: Equatable {
        var image: UIImage?
        var asset: PHAsset!
        var similarPhotos: PHFetchResultCollection = .init(fetchResult: .init())
        var vectorData = ArrayResult.success(result: [VectorData]())
        var tree: KDTree<Vector2048>
        init(tree: KDTree<Vector2048>, asset: PHAsset) {
            self.asset = asset
            self.tree = tree
        }
    }
    
    enum Action: Equatable {
        case loadImage
        
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
                return .run { [id = state.asset.localIdentifier, tree = state.tree ] send in
                    let ids = await self.vectorClient.loadSimilarIdentifiers(tree, id)
                    let photos = self.photoClient.loadPhotoFromIdentifier(ids)
                    await send(.similarPhotosLoaded(photos))
                }
            case .loadIdentifiers:
                return .none
            case .similarPhotosLoaded(let photos):
                state.similarPhotos = photos
                return .none
            }
        }
    }
}
