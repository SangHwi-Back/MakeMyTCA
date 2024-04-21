//
//  ContentView.swift
//  MakeMyTCA
//
//  Created by 백상휘 on 4/21/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var model = ContentModel()

    var body: some View {
        NavigationSplitView {
            List {
                ForEach($model.items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp.wrappedValue, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp.wrappedValue, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: model.removeItem(_:))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: model.addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
