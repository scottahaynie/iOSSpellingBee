//
//  Utils.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/20/25.
//

import Foundation
import Collections

class Util {
    static let MIN_CHARS_KIDS = 3
    static let MIN_CHARS_ADULTS = 4
    
    static func getWord(node: Trie.Node) -> String {
        var parent = node.parent
        var output = node.val ?? ""
        while parent != nil {
            if let val = parent?.val {
                output = val + output
            }
            parent = parent?.parent
        }
        
        return output
    }
    static func findWords(node: Trie.Node, arr: inout [String]) {
        if stopAtGlob == -1 || arr.count < stopAtGlob {
            if node.isEnd {
                let word = getWord(node: node)
                if word.count >= minLengthGlob && word.contains(requiredLetterGlob) {
                    arr.append(word)
                }
            }
            for letter in lettersGlob {
                let letterStr = String(letter)
                if let child = node.children[letterStr] {
                    findWords(node: child, arr: &arr)
                }
            }
        }
    }
    static var lettersGlob = ""
    static var requiredLetterGlob: Character = " "
    static var minLengthGlob = 4
    static var stopAtGlob = -1
    static func findPossibleWords(letters: String, requiredLetter: String, minLength: Int, trie: Trie, stopAt: Int = -1) -> [String] {
        var output: [String] = []
        lettersGlob = letters
        requiredLetterGlob = requiredLetter[requiredLetter.startIndex]
        minLengthGlob = minLength
        stopAtGlob = stopAt
        
        let node = trie.root
        findWords(node: node, arr: &output)
        return output
    }
}
