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
        if node.isEnd {
            let word = getWord(node: node)
            if word.contains(requiredLetterGlob) {
                arr.append(getWord(node: node))
            }
        }
        for letter in lettersGlob {
            let letterStr = String(letter)
            if let child = node.children[letterStr] {
                findWords(node: child, arr: &arr)
            }
        }
    }
    static var lettersGlob = ""
    static var requiredLetterGlob: Character = " "
    static func findPossibleWords(letters: String, requiredLetter: String, trie: Trie) -> [String] {
        var output: [String] = []
        lettersGlob = letters
        requiredLetterGlob = requiredLetter[requiredLetter.startIndex]
        
        let node = trie.root
        findWords(node: node, arr: &output)
        return output
    }
}
