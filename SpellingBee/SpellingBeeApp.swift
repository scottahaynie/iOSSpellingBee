//
//  SpellingBeeApp.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/9/25.
//

import SwiftUI

@main
struct SpellingBeeApp: App {
    @StateObject private var store = GameStore()
    private var dictionary = Trie()

    private func initGame() {
        print("reading word file")
        guard let filePath = Bundle.main.path(forResource: "EWOL-Words", ofType: "txt") else {
            print("File not found")
            return
        }
        do {
            let fileContents = try String(contentsOfFile: filePath)
            let words = fileContents.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            print("building trie")
            for word in words {
                if word.count > 3 {
                    dictionary.insert(val: word)
                }
            }
            print("building trie DONE")
        } catch {
            print("Error")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(game: store.game, dictionary: dictionary)
                .task {
                    do {
                        initGame() //TODO: use async/await here
                        try await store.load()
                    } catch {
                        fatalError(error.localizedDescription)
                    }
                }
        }
    }
}
