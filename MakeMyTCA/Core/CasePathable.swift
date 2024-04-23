//
//  CasePathable.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/23/24.
//

import Foundation

protocol CasePathable {
    associatedtype AllCasePaths
    static var allCasePaths: AllCasePaths { get }
}

@dynamicMemberLookup
struct Case<Value> {
    fileprivate let _embed: (Value) -> Any
    fileprivate let _extract: (Any) -> Value?
}

extension Case {
    subscript<AppendedValue>( dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, AppendedValue>>) -> Case<AppendedValue> where Value: CasePathable {
        Case<AppendedValue>(
            _embed: {
                self.embed(Value.allCasePaths[keyPath: keyPath].embed($0))
            },
            _extract: { 
                self.extract(from: $0)
                    .flatMap(Value.allCasePaths[keyPath: keyPath].extract)
            }
        )
    }
    
    func embed(_ value: Value) -> Any {
        self._embed(value)
    }
    
    func extract(from root: Any) -> Value? {
        self._extract(root)
    }
}

typealias PartialCaseKeyPath<Root> = PartialKeyPath<Case<Root>>
