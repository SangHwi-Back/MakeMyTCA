//
//  AnyCasePath.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/23/24.
//

import Foundation

@dynamicMemberLookup
struct AnyCasePath<Root, Value> {
    private let _embed: (Value) -> Root
    private let _extract: (Root) -> Value?
    
    init(
        embed: @escaping (Value) -> Root,
        extract: @escaping (Root) -> Value?
    ) {
        self._embed = embed
        self._extract = extract
    }
    
    func embed(_ value: Value) -> Root {
        self._embed(value)
    }
    
    func extract(from root: Root) -> Value? {
        self._extract(root)
    }
}

extension AnyCasePath where Value: CasePathable {
    subscript<AppendedValue>(
        dynamicMember keyPath: KeyPath<Value.AllCasePaths, AnyCasePath<Value, AppendedValue>>
    ) -> AnyCasePath<Root, AppendedValue> {
        AnyCasePath<Root, AppendedValue>(
            embed: {
                self.embed(Value.allCasePaths[keyPath: keyPath].embed($0))
            },
            extract: {
                self.extract(from: $0)
                    .flatMap(Value.allCasePaths[keyPath: keyPath].extract(from:))
            }
        )
    }
}
