//
//  SpellingBeeApp.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/9/25.
//

import SwiftUI
import OSLog

@main
struct SpellingBeeApp: App {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                        category: String(describing: SpellingBeeApp.self))

    @StateObject private var store = GameStore()
    private var dictionary = Trie()
    private var kidsDictionary = Trie()

    private func initGame() {
        // taken from https://github.com/BartMassey/wordlists/blob/main/eowl.txt.gz
        logger.debug("reading word file")
        guard let filePath = Bundle.main.path(forResource: "EOWL-Words", ofType: "txt") else {
            logger.fault("File not found")
            return
        }
        do {
            let fileContents = try String(contentsOfFile: filePath)
            let words = fileContents.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            logger.debug("building trie")
            for word in words {
                if word.count >= Util.MIN_CHARS_ADULTS {
                    dictionary.insert(val: word)
                }
            }
            logger.debug("building trie DONE")
        } catch {
            logger.fault("Error reading words file: \(error.localizedDescription)")
        }

        // taken from https://github.com/powerlanguage/word-lists/blob/master/1000-most-common-words.txt
        logger.debug("reading word file - kids")
        guard let filePath = Bundle.main.path(forResource: "1000-most-common-words", ofType: "txt") else {
            logger.fault("File not found")
            return
        }
        do {
            let fileContents = try String(contentsOfFile: filePath)
            let words = fileContents.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            logger.debug("building trie")
            for word in words {
                // for kids, allow 3-letter words
                if word.count >= Util.MIN_CHARS_KIDS {
                    kidsDictionary.insert(val: word)
                }
            }
            logger.debug("building trie DONE")
        } catch {
            logger.fault("Error reading words file: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(game: store.game, dictionary: dictionary, kidsDictionary: kidsDictionary)
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
