//
//  Store.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/22/24.
//

import SwiftUI
import Combine

final class Store<State, Action> {
    var canCacheChildren = true
    private var children: [ScopeID<State, Action>: AnyObject] = [:]
    
    var rootStore: RootStore
    var toState: PartialToState<State>
    var fromAction: (Action) -> Any
    
    var _isInvalidated = { false }
    
    var currentState: State {
        return self.toState(self.rootStore.state)
    }
    
    func scope<ChildState, ChildAction>(
        id: ScopeID<State, Action>?,
        state: ToState<State, ChildState>,
        action fromChildAction: @escaping (ChildAction) -> Action,
        isInvalid: ((State) -> Bool)?
    ) -> Store<ChildState, ChildAction> {
        // If using already cached Store...
        if self.canCacheChildren,
           let id = id,
           let childStore = self.children[id] as? Store<ChildState, ChildAction>
        {
            return childStore
        }
        
        // Else create new one...
        let childStore = Store<ChildState, ChildAction>(
            rootStore: self.rootStore,
            toState: self.toState.appending(state.base),
            fromAction: { [fromAction] in fromAction(fromChildAction($0)) }
        )
        
        childStore._isInvalidated = {
            if id == nil || !self.canCacheChildren {
                return {
                    isInvalid?(self.currentState) == true || self._isInvalidated()
                }
            } else {
                return { [weak self] in
                    guard let self else { return true }
                    return isInvalid?(self.currentState) == true || self._isInvalidated()
                }
            }
        }()
        
        childStore.canCacheChildren = self.canCacheChildren && id != nil
        
        if let id = id, self.canCacheChildren {
            self.children[id] = childStore
        }
        
        return childStore
    }
    
    private init(
        rootStore: RootStore,
        toState: PartialToState<State>,
        fromAction: @escaping (Action) -> Any
    ) {
        self.rootStore = rootStore
        self.toState = toState
        self.fromAction = fromAction
    }
    
    convenience init<R: Reducer>(initialState: R.State, reducer: R) where R.State == State, R.Action == Action {
        self.init(
            rootStore: RootStore(state: initialState, reducer: reducer),
            toState: .keyPath(\State.self),
            fromAction: { $0 }
        )
    }
    
    init() {
        self._isInvalidated = { true }
        self.rootStore = RootStore(state: (), reducer: EmptyReducer<Void, Never>())
        self.toState = .keyPath(\State.self)
        self.fromAction = { $0 }
    }
    
    func withState<R>(_ body: (_ state: State) -> R) -> R {
        body(self.currentState)
    }
    
    func send(_ action: Action, originatingFrom originatingAction: Action?) -> Task<Void, Never>? {
        return self.rootStore.send(self.fromAction(action))
    }
    
    func send(_ action: Action) -> StoreTask {
        .init(rawValue: self.send(action, originatingFrom: nil))
    }
}

struct ScopeID<State, Action>: Hashable {
    let state: PartialKeyPath<State>
    let action: PartialCaseKeyPath<Action>
}

struct ToState<State, ChildState> {
    let base: PartialToState<ChildState>
}

enum PartialToState<State> {
    case closure((Any) -> State)
    case keyPath(AnyKeyPath)
    case appended((Any) -> Any, AnyKeyPath)
    
    func callAsFunction(_ state: Any) -> State {
        switch self {
        case let .closure(closure):
            return closure(state)
        case let .keyPath(keyPath):
            // TODO: remove as!
            return state[keyPath: keyPath] as! State
        case let .appended(closure, keyPath):
            // TODO: remove as!
            return closure(state)[keyPath: keyPath] as! State
        }
    }
    
    func appending<ChildState>(_ state: PartialToState<ChildState>) -> PartialToState<ChildState> {
        switch (self, state) {
        case let (.keyPath(lhs), .keyPath(rhs)):
            return .keyPath(lhs.appending(path: rhs)!)
        case let (.closure(lhs), .keyPath(rhs)):
            return .appended(lhs, rhs)
        case let (.appended(lhsClosure, lhsKeyPath), .keyPath(rhs)):
            // TODO: remove as!
            return .appended(lhsClosure, lhsKeyPath.appending(path: rhs)!)
        default:
            return .closure { state(self($0)) }
        }
    }
}
