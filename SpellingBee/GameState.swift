//
//  GameState.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/27/25.
//

import Foundation
import OSLog

class GameState: ObservableObject, Codable {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                        category: String(describing: GameState.self))
    
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
    var isKids: Bool {
        get {
            return difficultyLevel == DifficultyLevel.kids
        }
    }
    var minCharacters: Int {
        get {
            return isKids ? Util.MIN_CHARS_KIDS : Util.MIN_CHARS_ADULTS
        }
    }
    var rank: Rank {
        get {
            if possiblePoints > 0 {
                let progressPct = Float(guessedPoints) / Float(possiblePoints)
                for rank in Rank.allCases {
                    if isKids {
                        if rank.kidsRange.contains(progressPct) {
                            return rank
                        }
                    } else if rank.range.contains(progressPct) {
                        return rank
                    }
                }
                fatalError("Could not find a matching rank for percentage: \(progressPct)")
            } else {
                return Rank.Beginner
            }
        }
    }
    func getRankThresholds() -> [Int] {
        return Rank.allCases.map { Int(Float(self.possiblePoints) * Float(isKids ? $0.kidsRange.lowerBound : $0.range.lowerBound)) }
    }
    func getRankRangeMarks() -> [Float] {
        return Rank.allCases.map { isKids ? $0.kidsRange.lowerBound : $0.range.lowerBound }
    }
    func getRanksAndThresholds() -> [(Rank, Int)] {
        return Rank.allCases.map { ($0, Int(Float(self.possiblePoints) * Float(isKids ? $0.kidsRange.lowerBound : $0.range.lowerBound))) }
    }

    enum Rank: String, CaseIterable {
        case Beginner = "Beginner"
        case GoodStart = "Good Start"
        case MovingUp = "Moving Up"
        case Good = "Good"
        case Solid = "Solid"
        case Nice = "Nice"
        case Great = "Great"
        case Amazing = "Amazing"
        case Genius = "Genius"
        
        var kidsRange: Range<Float> {
            switch(self) {
            case .Beginner:
                return 0.00..<0.01
            case .GoodStart:
                return 0.01..<0.02
            case .MovingUp:
                return 0.02..<0.04
            case .Good:
                return 0.04..<0.08
            case .Solid:
                return 0.08..<0.12
            case .Nice:
                return 0.12..<0.18
            case .Great:
                return 0.18..<0.25
            case .Amazing:
                return 0.25..<0.35
            case .Genius:
                return 0.35..<1.00
            }
        }
        var range: Range<Float> {
            switch(self) {
            case .Beginner:
                return 0.00..<0.02
            case .GoodStart:
                return 0.02..<0.05
            case .MovingUp:
                return 0.05..<0.08
            case .Good:
                return 0.08..<0.15
            case .Solid:
                return 0.15..<0.25
            case .Nice:
                return 0.25..<0.40
            case .Great:
                return 0.40..<0.50
            case .Amazing:
                return 0.50..<0.70
            case .Genius:
                return 0.70..<1.00
            }
        }
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
