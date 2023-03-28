//
//  View+.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 29/03/2023.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }
}
