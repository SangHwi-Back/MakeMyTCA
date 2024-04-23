//
//  ViewStore.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/23/24.
//

import Foundation
import Combine

@dynamicMemberLookup
final class ViewStore<ViewState, ViewAction>: ObservableObject {
    private(set) lazy var objectWillChange = ObservableObjectPublisher()
    private var viewCancellable: AnyCancellable?
    let store: Store<ViewState, ViewAction>
    
    private let _state: CurrentValueRelay<ViewState>
    
    var state: ViewState {
        self._state.value
    }
    
    subscript<Value>(dynamicMember keyPath: KeyPath<ViewState, Value>) -> Value {
        self.state[keyPath: keyPath]
    }
    
    init<State, Action>(
        _ store: Store<State, Action>,
        observe toViewState: @escaping (_ state: State) -> ViewState,
        send fromViewAction: @escaping (_ viewAction: ViewAction) -> Action,
        removeDuplicates isDuplicate: @escaping (_ lhs: ViewState, _ rhs: ViewState) -> Bool
    ) {
        // TODO: remove as!
        self.store = store.scope(
            id: nil,
            state: ToState(base: .closure({ toViewState($0 as! State) })),
            action: fromViewAction,
            isInvalid: nil
        )
        
        self._state = CurrentValueRelay(self.store.withState { $0 })
        
        self.viewCancellable = self.store.rootStore.currentStateRelay
            .compactMap({ [weak self] in self?.store.withState({$0}) })
            .removeDuplicates(by: isDuplicate)
            .dropFirst()
            .sink(receiveValue: { [weak self] in
                self?.objectWillChange.send()
                self?._state.value = $0
            })
    }
}
