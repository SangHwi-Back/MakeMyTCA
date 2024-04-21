//
//  Reducer.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/21/24.
//

import Foundation
import SwiftUI

protocol Reducer<State, Action> {
    associatedtype State
    associatedtype Action
    associatedtype Body
    
    func reduce(into state: inout State, action: Action) -> Effect<Action>
    
    var body: Body { get }
}

extension Reducer where Body == Never {
    var body: Body {
        fatalError()
    }
}

extension Reducer where Body: Reducer, Body.State == State, Body.Action == Action {
    @inlinable func reduce(into state: inout Body.State, action: Body.Action) -> Effect<Body.Action> {
        self.body.reduce(into: &state, action: action)
    }
}

typealias ReducerOf<R: Reducer> = Reducer<R.State, R.Action>
