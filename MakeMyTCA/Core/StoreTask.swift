//
//  StoreTask.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/23/24.
//

import Foundation

struct StoreTask: Hashable, Sendable {
    let rawValue: Task<Void, Never>?
    
    init(rawValue: Task<Void, Never>?) {
        self.rawValue = rawValue
    }
    
    func cancel() {
        self.rawValue?.cancel()
    }
    
    func finish() async {
        await self.rawValue?.cancellableValue
    }
    
    var isCancelled: Bool {
        self.rawValue?.isCancelled ?? true
    }
}

extension Task where Failure == Never {
    var cancellableValue: Success {
        get async {
            await withTaskCancellationHandler {
                await self.value
            } onCancel: {
                self.cancel()
            }
        }
    }
}

extension Task where Failure == Error {
    var cancellableValue: Success {
        get async throws {
            try await withTaskCancellationHandler {
                try await self.value
            } onCancel: {
                self.cancel()
            }
        }
    }
}
