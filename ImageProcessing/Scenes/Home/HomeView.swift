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

struct Home: ReducerProtocol {
    struct State: Equatable {
        var photos: PHFetchResultCollection = .init(fetchResult: .init())
        var isLoading = false
        var alert: AlertState<Action>?
        var process = Progress(totalUnitCount: 1000)
    }
    
    
    enum Action: Equatable {
        static func == (lhs: Home.Action, rhs: Home.Action) -> Bool {
            return false
        }
        case requestPermission
        case pemissionResult(PHAuthorizationStatus)
        case loadPhotos
        case photosLoaded(TaskResult<PHFetchResultCollection>)
        case processImages
        case processingResult(TaskResult<Bool>)
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.photoClient) var photoClient
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .requestPermission:
                return .task {
                    await .pemissionResult(try self.photoClient.requestPermission())
                }
            case .loadPhotos:
                return .task {
                    await .photosLoaded(TaskResult {
                        try await self.photoClient.loadPhotos()
                    })
                }
                .cancellable(id: uuid.callAsFunction())
            case .photosLoaded(let result):
                    state.isLoading = false
                    switch result {
                    case .success(let photos):
                        state.photos = photos
                    case .failure(let error):
                        state.alert = AlertState(
                            title: TextState("Error"),
                            message: TextState(error.localizedDescription),
                            dismissButton: .cancel(TextState("OK"))
                        )
                    }
                    return .none
            case .pemissionResult(let status):
                switch status {
                case .authorized, .limited:
                    print("PHOTO: Authorized")
                case .denied, .restricted, .notDetermined:
                    print("PHOTO: Not allowed")
                default:
                    print("PHOTO: Default")
                }
                return .none
            case .processImages:
                return .task { [
                    photos = state.photos,
                    process = state.process
                ] in
                    await .processingResult(TaskResult {
                        try await photoClient.processImages(photos)
                    })
                }
            case .processingResult(let _):
//                switch result {
//                case .success(_):
////                    state.process = process
//                    break
//                case .failure(let error):
//                    print(error.localizedDescription)
//                }
                return .none
            }
        }
    }
}


struct HomeView: View {
    let store: StoreOf<Home>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView(.vertical) {
                Text("\(viewStore.process.completedUnitCount)")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)) {
                    ForEach(viewStore.photos, id: \.localIdentifier) {
                        ImageStackView(asset: $0)
                    }
                }

            }
            .overlay(actionStackView(viewStore), alignment: .bottom)
            .navigationTitle("Photos")
            .onAppear {
                viewStore.send(.requestPermission)
            }
        }
    }
    
    func actionStackView(_ store: ViewStore<Home.State, Home.Action>) -> some View {
        HStack {
            Button {
                store.send(.requestPermission)
            } label: {
                Text("Request Permission")
                    .foregroundColor(.white)
                    .font(.system(.headline))
                    .frame(height: 56)
                    .padding(.horizontal)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
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
    }
    
}
