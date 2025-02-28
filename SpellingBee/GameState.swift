//
//  GameState.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/27/25.
//

import Foundation

class GameState: ObservableObject, Codable {
    
    var createDate: Date = Date.now
    @Published var outerLetters: String = "" // uppercased
    @Published var centerLetter: String = "" // uppercased
    @Published var possibleWords: [String] = []
    @Published var guessedWords: [String] = []
    @Published var enteredWord = ""
    @Published var numWordsWithPrefix = -1
    @Published var difficultyLevel = DifficultyLevel.easy

    enum DifficultyLevel: String, Codable {
        case easy
        case medium
        case hard
    }

    // Codable
    enum CodingKeys: CodingKey {
        case 
        outerLetters,
        centerLetter,
        possibleWords,
        guessedWords,
        enteredWord,
        numWordsWithPrefix,
        difficultyLevel
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        outerLetters = try container.decode(String.self, forKey: .outerLetters)
        centerLetter = try container.decode(String.self, forKey: .centerLetter)
        possibleWords = try container.decode([String].self, forKey: .possibleWords)
        guessedWords = try container.decode([String].self, forKey: .guessedWords)
        enteredWord = try container.decode(String.self, forKey: .enteredWord)
        numWordsWithPrefix = try container.decode(Int.self, forKey: .numWordsWithPrefix)
        difficultyLevel = try container.decode(DifficultyLevel.self, forKey: .difficultyLevel)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(outerLetters, forKey: .outerLetters)
        try container.encode(centerLetter, forKey: .centerLetter)
        try container.encode(possibleWords, forKey: .possibleWords)
        try container.encode(guessedWords, forKey: .guessedWords)
        try container.encode(enteredWord, forKey: .enteredWord)
        try container.encode(numWordsWithPrefix, forKey: .numWordsWithPrefix)
        try container.encode(difficultyLevel, forKey: .difficultyLevel)
    }

    //TODO: remove me?
    func save() async throws {
        let encoder = JSONEncoder()
        
        if let data = try? encoder.encode(self) {
            UserDefaults.standard.set(data, forKey: "currentGame")
        }
    }

    init() {}
}

class GameStore: ObservableObject {
    @Published var game: GameState = GameState()

    func load() async throws {
        let task = Task<GameState, Error> {
            let decoder = JSONDecoder()
            
            if let data = UserDefaults.standard.data(forKey: "currentGame") {
                let game = try decoder.decode(GameState.self, from: data)
                return game
            } else {
                return GameState()
            }
        }
        let game = try await task.value
        self.game = game
    }
    
    func save() async throws {
        let encoder = JSONEncoder()
        
        if let data = try? encoder.encode(game) {
            UserDefaults.standard.set(data, forKey: "currentGame")
        }
    }


}
