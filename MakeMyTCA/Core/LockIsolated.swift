//
//  LockIsolated.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/23/24.
//

import Foundation

@dynamicMemberLookup
final class LockIsolated<Value>: Sendable {
    private var _value: Value
    private let lock = NSRecursiveLock()
    
    init(_ value: @autoclosure @Sendable () throws -> Value) rethrows {
        self._value = try value()
    }
    
    subscript<Subject: Sendable>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
        self.lock.sync {
            self._value[keyPath: keyPath]
        }
    }
    
    func withValue<T: Sendable>(_ operation: @Sendable (inout Value) throws -> T) rethrows -> T {
        try self.lock.sync {
            var value = self._value
            defer { self._value = value }
            return try operation(&value)
        }
    }
    
    func setValue(_ newValue: @autoclosure @Sendable () throws -> Value) rethrows {
        try self.lock.sync {
            self._value = try newValue()
        }
    }
}

extension LockIsolated where Value: Sendable {
    var value: Value {
        self.lock.sync {
            self._value
        }
    }
}
