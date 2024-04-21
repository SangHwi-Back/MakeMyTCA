//
//  Effect.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/21/24.
//

import Foundation
import Combine

struct Effect<Action>{
    @usableFromInline
    enum Operation {
        case none
        case publisher(AnyPublisher<Action, Never>)
        case run(TaskPriority? = nil, @Sendable (_ send: Send<Action>) async -> Void)
    }
    
    @usableFromInline
    let operation: Operation
    
    @usableFromInline
    init(operation: Operation) {
        self.operation = operation
    }
}
