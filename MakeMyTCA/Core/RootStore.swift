//
//  RootStore.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/22/24.
//

import Foundation
import Combine

final class RootStore {
    private var bufferedActions: [Any] = []
    
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
    
    func send(_ action: Any, originatingFrom originatingAction: Any? = nil) -> Task<Void, Never>? {
        
        func open<State, Action>(reducer: some Reducer<State, Action>) -> Task<Void, Never>? {
            
            self.bufferedActions.append(action)
            
            guard self.isSending == false else {
                return nil
            }
            
            self.isSending = true
            // TODO: remove as!
            var currentState = self.state as! State
            let tasks = Box<[Task<Void, Never>]>(wrappedValue: [])
            
            defer {
                withExtendedLifetime(self.bufferedActions) {
                    self.bufferedActions.removeAll()
                }
                
                self.state = currentState
                self.isSending = false
                
                if self.bufferedActions.isNotEmpty, let task = self.send(self.bufferedActions.removeLast(), originatingFrom: originatingAction) {
                    tasks.wrappedValue.append(task)
                }
            }
            
            var index = self.bufferedActions.startIndex
            
            while index < self.bufferedActions.endIndex {
                defer { index += 1 }
                // TODO: remove as!
                let action = self.bufferedActions[index] as! Action
                let effect = reducer.reduce(into: &currentState, action: action)
                
                switch effect.operation {
                case .none:
                    break
                case let .publisher(publisher):
                    var didComplete = false
                    let boxedTask = Box<Task<Void, Never>?>(wrappedValue: nil)
                    let uuid = UUID()
                    
                    // TODO: no swift-dependencies exist. Using 'withEscapedDependencies' originally.
                    
                    let effectCancellable = publisher.handleEvents(
                        receiveCancel: { [weak self] in
                            self?.effectCancellables[uuid] = nil
                        }
                    )
                        .sink { [weak self] _ in
                            boxedTask.wrappedValue?.cancel()
                            didComplete = true
                            self?.effectCancellables[uuid] = nil
                        } receiveValue: { [weak self] effectAction in
                            // TODO: no swift-dependencies exist. Using 'yield' originally.
                            if let task = self?.send(effectAction, originatingFrom: action) {
                                tasks.wrappedValue.append(task)
                            }
                        }
                    
                    if didComplete == false {
                        let task = Task<Void, Never> {
                            effectCancellable.cancel()
                        }
                        boxedTask.wrappedValue = task
                        tasks.wrappedValue.append(task)
                        self.effectCancellables[uuid] = effectCancellable
                    }
                    
                case let .run(priority, operation):
                    tasks.wrappedValue.append(Task(
                        priority: priority,
                        operation: { @MainActor in
                            let isCompleted = LockIsolated(false)
                            defer { isCompleted.setValue(true) }
                            
                            await operation(Send(send: { effectAction in
                                if isCompleted.value {
                                    // TODO: no swift-dependencies exist. Using 'yield' originally.
                                    if let task = self.send(effectAction, originatingFrom: action) {
                                        tasks.wrappedValue.append(task)
                                    }
                                }
                            }))
                        }
                    ))
                }
            }
            
            guard tasks.wrappedValue.isNotEmpty else {
                return nil
            }
            
            return Task { @MainActor in
                await withTaskCancellationHandler {
                    var index = tasks.wrappedValue.startIndex
                    while index < tasks.wrappedValue.endIndex {
                        defer { index += 1 }
                        await tasks.wrappedValue[index].value
                    }
                } onCancel: {
                    var index = tasks.wrappedValue.startIndex
                    while index < tasks.wrappedValue.endIndex {
                        defer { index += 1 }
                        tasks.wrappedValue[index].cancel()
                    }
                }

            }
        }
        
        return open(reducer: self.reducer)
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

