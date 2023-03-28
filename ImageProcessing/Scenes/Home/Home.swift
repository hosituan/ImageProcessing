//
//  Home.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 29/03/2023.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Photos
import Vision

struct Home: ReducerProtocol {
    struct State: Equatable {
        var photos: PHFetchResultCollection = .init(fetchResult: .init())
        var isLoading = false
        var isProcessing = false
        var alert: AlertState<Action>?
        var processed = 0
        var errorCount = 0
    }
    
    
    enum Action: Equatable {
        static func == (lhs: Home.Action, rhs: Home.Action) -> Bool {
            return false
        }
        case alertDismissed
        case requestPermission
        case pemissionResult(PHAuthorizationStatus)
        case loadPhotos
        case photosLoaded(TaskResult<PHFetchResultCollection>)
        case processImages
        case progress(TaskResult<Bool>)
        
    }
    
    @Dependency(\.uuid) var uuid
    @Dependency(\.photoClient) var photoClient
    @Dependency(\.db) var db
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .alertDismissed:
                return .none
            case .requestPermission:
                return .task {
                    await .pemissionResult(self.photoClient.requestPermission())
                }
            case .loadPhotos:
                state.isLoading = true
                return .task {
                    await .photosLoaded(TaskResult {
                        self.photoClient.loadPhotos()
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
                state.isLoading = true
                switch status {
                case .authorized, .limited:
                    return .none
                case .denied, .notDetermined:
                    state.alert = AlertState {
                        TextState("You denied access to photos. This app needs this permission.")
                    }
                case .restricted:
                    state.alert = AlertState { TextState("Your device does not allow photo access") }
                    return .none
                default:
                    print("PHOTO: Default")
                    return .none
                }
            case .processImages:
                state.isProcessing.toggle()
                guard state.isProcessing else {
                    return .fireAndForget {
                        // Stop process
                    }
                }
                return .run { [ photos = state.photos ] send in
                    let status = await self.photoClient.requestPermission()
                    await send(.pemissionResult(status))
                    guard status == .authorized else {
                        return
                    }
                    let result = try await self.photoClient.processImages(photos)
                    await send(.progress(.success(result)))
                }
            case .progress(let result):
                switch result {
                case .success(let success):
                    if success {
                        state.processed += 1
                    } else {
                        state.errorCount += 1
                    }
                    break
                case .failure(let error):
                    state.errorCount += 1
                    state.alert = AlertState {
                        TextState("\(error.localizedDescription)")
                    }
                }
                return .none
            }
            return .none
        }
    }
}
