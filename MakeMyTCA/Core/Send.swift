//
//  Send.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/21/24.
//

import Foundation

@MainActor
struct Send<Action>: Sendable {
    let send: @MainActor @Sendable (Action) -> Void
    
    init(send: @escaping @MainActor @Sendable (Action) -> Void) {
        self.send = send
    }
}
