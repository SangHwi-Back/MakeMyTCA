//
//  EmptyReducer.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/23/24.
//

import Foundation

struct EmptyReducer<State, Action>: Reducer {
    @inlinable
    init() {
        self.init(internal: ())
    }
    
    @usableFromInline
    init(internal: Void) {}
    
    @inlinable
    func reduce(into _: inout State, action _: Action) -> Effect<Action> {
        .none
    }
}
