//
//  DemandBuffer.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/22/24.
//

import Foundation
import Combine
import Darwin

final class DemandBuffer<S: Subscriber>: Sendable {
    typealias _Demand = Subscribers.Demand
    
    private var buffer = [S.Input]()
    private let subscriber: S
    private var completion: Subscribers.Completion<S.Failure>?
    private var demandState = Demand()
    private let lock: os_unfair_lock_t
    
    init(subscriber: S) {
        self.subscriber = subscriber
        self.lock = os_unfair_lock_t.allocate(capacity: 1)
        self.lock.initialize(to: os_unfair_lock())
    }
    
    deinit {
        self.lock.deinitialize(count: 1)
        self.lock.deallocate()
    }
    
    func buffer(value: S.Input) -> _Demand {
        precondition(completion == nil, "Publisher that sent value already completed.")
        
        switch demandState.requested {
        case .unlimited:
            return subscriber.receive(value)
        default:
            buffer.append(value)
            return flush()
        }
    }
    
    func complete(completion: Subscribers.Completion<S.Failure>) {
        precondition(completion == nil, "Completion already occured.")
        
        self.completion = completion
        _ = flush()
    }
    
    func demand(_ demand: _Demand) -> _Demand {
        flush(adding: demand)
    }
    
    // Flush already sent requested from buffer.
    func flush(adding newDemand: _Demand? = nil) -> _Demand {
        self.lock.sync {
            
            if let newDemand = newDemand {
                demandState.requested += newDemand
            }
            
            guard demandState.requested > 0 || newDemand == _Demand.none else {
                return .none
            }
            
            while buffer.isNotEmpty, demandState.processed < demandState.requested {
                demandState.requested += subscriber.receive(buffer.remove(at: 0))
                demandState.processed += 1
            }
            
            if let completion = completion {
                buffer = []
                demandState = .init()
                self.completion = nil
                subscriber.receive(completion: completion)
                return .none
            }
            
            let sentDemand = demandState.requested - demandState.sent
            demandState.sent += sentDemand
            return sentDemand
        }
    }
    
    struct Demand {
        var processed: _Demand = .none
        var requested: _Demand = .none
        var sent: _Demand = .none
    }
}

extension UnsafeMutablePointer where Pointee == os_unfair_lock_s {
    @inlinable @discardableResult
    func sync<R>(_ work: () -> R) -> R {
        // lock
        os_unfair_lock_lock(self)
        
        // unlock after returns
        defer { os_unfair_lock_unlock(self) }
        
        // execute work
        return work()
    }
}

extension NSRecursiveLock {
//    @inlinable @discardableResult
//    func sync<R>(work: () -> R) -> R {
//        self.lock()
//        defer { self.unlock() }
//        return work()
//    }
    
    @inlinable @discardableResult
    func sync<R>(work: () throws -> R) rethrows -> R {
        self.lock()
        defer { self.unlock() }
        return try work()
    }
}
