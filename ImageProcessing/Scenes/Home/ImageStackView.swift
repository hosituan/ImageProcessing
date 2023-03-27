//
//  ImageStackView.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 27/03/2023.
//

import Foundation
import SwiftUI
import Photos
import ComposableArchitecture

struct ImageStackView: View {
    var height: CGFloat = (UIScreen.main.bounds.width - 12) / 4
    var asset: PHAsset?
    @State var image: UIImage? = nil
    var body: some View {
        Image(uiImage: image ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(
                width: height,
                height: height,
                alignment: .center
            )
            .clipped()
            .onAppear {
                Task(priority: .background) {
                    self.image = try await asset?.previewImage(targetSize: CGSize(width: height, height: height))
                }
            }
    }
}

struct AssetStoreReducer: ReducerProtocol {
    
    struct State: Equatable, Identifiable {
        let id: UUID
        var image: UIImage?
        var asset: PHAsset?
    }
    
    enum Action: Equatable {
        case tap
    }
    
    func reduce(into state: inout State, action: Action) -> ComposableArchitecture.EffectTask<Action> {
        switch action {
        case .tap:
            return .none
        }
    }
    
    
}
