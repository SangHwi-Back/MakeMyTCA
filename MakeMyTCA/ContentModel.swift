//
//  ContentModel.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/21/24.
//

import Foundation

class ContentModel: ObservableObject {
    @Published var items: [Item] = []
    
    func addItem() {
        self.items.append(Item(timestamp: Date()))
    }
    
    func removeItem(_ offsets: IndexSet) {
        for inx in offsets {
            self.items.remove(at: inx)
        }
    }
}
