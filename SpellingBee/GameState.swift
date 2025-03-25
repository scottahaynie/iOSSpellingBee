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
    @Published var remainingWords: [String] = []
    @Published var guessedWords: [String] = []
    @Published var possiblePoints: Int = 0
    @Published var guessedPoints: Int = 0
    @Published var enteredWord = ""
    @Published var numWordsWithPrefix = -1

    @Published var difficultyLevel = DifficultyLevel.easy
    var minCharacters: Int {
        get {
            return difficultyLevel == DifficultyLevel.kids ? Util.MIN_CHARS_KIDS : Util.MIN_CHARS_ADULTS
        }
    }
    var rank: Rank {
        get {
            if possiblePoints > 0 {
                let progressPct = Double(guessedPoints) / Double(possiblePoints)
                switch progressPct {
                case 0.00..<0.02:
                    return Rank.Beginner
                case 0.02..<0.05:
                    return Rank.GoodStart
                case 0.05..<0.08:
                    return Rank.MovingUp
                case 0.08..<0.15:
                    return Rank.Good
                case 0.15..<0.25:
                    return Rank.Solid
                case 0.25..<0.40:
                    return Rank.Nice
                case 0.40..<0.50:
                    return Rank.Great
                case 0.50..<0.70:
                    return Rank.Amazing
                case 0.70..<1.0:
                    return Rank.Genius
                default:
                    return Rank.Queen
                }
            } else {
                return Rank.Beginner
            }
        }
    }

    enum Rank: String {
        case Beginner = "Beginner"
        case GoodStart = "Good Start"
        case MovingUp = "Moving Up"
        case Good = "Good"
        case Solid = "Solid"
        case Nice = "Nice"
        case Great = "Great"
        case Amazing = "Amazing"
        case Genius = "Genius"
        case Queen = "QUEEN"
    }

    enum DifficultyLevel: String, Codable {
        case kids
        case easy
        case medium
        case hard
    }

    // Codable
    enum CodingKeys: CodingKey {
        case 
        outerLetters,
        centerLetter,
        remainingWords,
        guessedWords,
        possiblePoints,
        guessedPoints,
        enteredWord,
        numWordsWithPrefix,
        difficultyLevel
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        outerLetters = try container.decode(String.self, forKey: .outerLetters)
        centerLetter = try container.decode(String.self, forKey: .centerLetter)
        remainingWords = try container.decode([String].self, forKey: .remainingWords)
        guessedWords = try container.decode([String].self, forKey: .guessedWords)
        possiblePoints = try container.decode(Int.self, forKey: .possiblePoints)
        guessedPoints = try container.decode(Int.self, forKey: .guessedPoints)
        enteredWord = try container.decode(String.self, forKey: .enteredWord)
        numWordsWithPrefix = try container.decode(Int.self, forKey: .numWordsWithPrefix)
        difficultyLevel = try container.decode(DifficultyLevel.self, forKey: .difficultyLevel)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(outerLetters, forKey: .outerLetters)
        try container.encode(centerLetter, forKey: .centerLetter)
        try container.encode(remainingWords, forKey: .remainingWords)
        try container.encode(guessedWords, forKey: .guessedWords)
        try container.encode(possiblePoints, forKey: .possiblePoints)
        try container.encode(guessedPoints, forKey: .guessedPoints)
        try container.encode(enteredWord, forKey: .enteredWord)
        try container.encode(numWordsWithPrefix, forKey: .numWordsWithPrefix)
        try container.encode(difficultyLevel, forKey: .difficultyLevel)
    }

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
    
    //TODO: not used
    func save() async throws {
        let encoder = JSONEncoder()
        
        if let data = try? encoder.encode(game) {
            UserDefaults.standard.set(data, forKey: "currentGame")
        }
    }


}
