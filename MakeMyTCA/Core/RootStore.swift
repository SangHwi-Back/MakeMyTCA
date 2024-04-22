//
//  RootStore.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/22/24.
//

import Foundation
import Combine

final class RootStore {
    private(set) var state: Any
    private let reducer: any Reducer
    private var isSending = false
    
    var effectCancellables: [UUID: AnyCancellable] = [:]
    
    let currentStateRelay = CurrentValueRelay(())
    
    init<State, Action>(
        state: State,
        reducer: some Reducer<State, Action>
    ) {
        self.state = state
        self.reducer = reducer
//        threadCheck(status: .`init`)
    }
    
    func setState(_ newState: Any) {
        self.state = newState
        currentStateRelay.send(())
    }
}

final class CurrentValueRelay<Output>: Publisher {
    typealias Failure = Never
    
    private var currentValue: Output
    private var subscriptions: [Subscription<AnySubscriber<Output, Failure>>] = []
    
    var value: Output {
        get { self.currentValue }
        set { self.send(newValue) }
    }
    
    init(_ currentValue: Output) {
        self.currentValue = currentValue
    }
    
    func receive<S>( subscriber: S )
    where S : Subscriber,
          Never == S.Failure,
          Output == S.Input
    {
        
        
    }
    
    func send(_ value: Output) {
        self.currentValue = value
        for subscription in subscriptions {
            subscription.forwardValueToBuffer(value)
        }
    }
}

extension CurrentValueRelay {
    final class Subscription< Downstream: Subscriber >: Combine.Subscription
    where Downstream.Input == Output,
          Downstream.Failure == Failure 
    {
        private var demandBuffer: DemandBuffer<Downstream>?
        
        init(downstream: Downstream) {
            self.demandBuffer = DemandBuffer<Downstream>(subscriber: downstream)
        }
        
        func forwardValueToBuffer(_ value: Output) {
            _ = demandBuffer?.buffer(value: value)
        }
        
        func request(_ demand: Subscribers.Demand) {
            _ = demandBuffer?.demand(demand)
        }
        
        func cancel() {
            demandBuffer = nil
        }
    }
}

