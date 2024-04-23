//
//  Box.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/23/24.
//

import Foundation

final class Box<WrappedValue> {
    var wrappedValue: WrappedValue
    
    init(wrappedValue: WrappedValue) {
        self.wrappedValue = wrappedValue
    }
    
    var boxedValue: WrappedValue {
        _read { yield self.wrappedValue }
        _modify { yield &self.wrappedValue }
    }
}
