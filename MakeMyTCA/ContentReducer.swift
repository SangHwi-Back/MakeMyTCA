//
//  ContentReducer.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/21/24.
//

import Foundation

struct ContentReducer: Reducer {
    struct State {
        var items: [Item] = []
    }
    
    enum Action {
        case addItem
        case removeItem(Int)
    }
    
    var body: some ReducerOf<Self> {
        Reduce({ state, action in
            switch action {
            case .addItem:
                state.items.append(.init(timestamp: Date()))
                return .none
            case .removeItem(let index):
                state.items.remove(at: index)
                return .none
            }
        })
    }
}
