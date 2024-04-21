//
//  Reduce.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/21/24.
//

import Foundation

struct Reduce<State, Action>: Reducer {
    @usableFromInline let reduce: (inout State, Action) -> Effect<Action>
    
    @usableFromInline init(internal reduce: @escaping (inout State, Action) -> Effect<Action>) {
        self.reduce = reduce
    }
    
    @inlinable init(_ reduce: @escaping (_ state: inout State, _ action: Action) -> Effect<Action>) {
        self.init(internal: reduce)
    }
    
    @inlinable init<R: Reducer>(_ reducer: R) where R.State == State, R.Action == Action {
        self.init(internal: reducer.reduce)
    }
    
    @inlinable func reduce(into state: inout State, action: Action) -> Effect<Action> {
        self.reduce(&state, action)
    }
}
