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

typealias ReducerOf<R: Reducer> = Reducer<R.State, R.Action>
