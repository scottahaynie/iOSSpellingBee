//
//  Trie.swift
//  SpellingBee
//
//  Created by Scott Haynie on 2/20/25.
//

import Foundation

class Trie {
    
    class Node {
        
        var val: String?
        
        var parent: Node?
        
        var children: [String: Node] = [:]
        
        var isEnd: Bool = false
        
        init(val: String?) {
            self.val = val
        }
        
    }

    var root: Node
    
    init() {
        self.root = Node(val: nil)
    }
    
    // insert string
    internal func insert(val: String) {
        guard !val.isEmpty else { return }
        
        var node = self.root
        for (index, char) in val.enumerated() {
            let charStr = String(char)

            if let child = node.children[charStr] {
                node = child
            } else {
                node.children[charStr] = Node(val: charStr)
                node.children[charStr]?.parent = node
                node = node.children[charStr]!
            }
            
            if index == val.count-1 {
                node.isEnd = true
            }
        }
    }
    
    // check if it contains a string
    internal func contains(val: String) -> Bool {
        guard !val.isEmpty else { return false }
        
        var node = self.root
        for (index, char) in val.enumerated() {
            let charStr = String(char)
            if let child = node.children[charStr] {
                node = child
                
//                if charStr == node.val && node.isEnd {
                // if we're at end of a word AND the end of our input
                if node.isEnd && index == val.count-1 {
                    return true
                }
            }
        }
        
        return false
    }
    
    // check if given prefix exists
    internal func contains(prefix: String) -> Bool {
        guard !prefix.isEmpty else { return false }
        
        var node = self.root
        for (index, char) in prefix.enumerated() {
            let charStr = String(char)
            if let child = node.children[charStr] {
                node = child
                
                // if it's at the end of the count
                if charStr == node.val && index == prefix.count-1 {
                    return true
                }
            }
        }
        
        return false
    }
    
    // find all words with given prefix
    internal func find(prefix: String) -> [String] {
        guard !prefix.isEmpty else { return [] }
        var output: [String] = []
        
        var node = self.root
        for (index, char) in prefix.enumerated() {
            let charStr = String(char)
            if let child = node.children[charStr] {
                node = child
                if charStr == node.val && index == prefix.count-1 {
                    self.getWords(node: node, arr: &output)
                }
            }
        }
        
        return output
    }
    
    private func getWords(node: Node, arr: inout [String]) {
        if node.isEnd {
            arr.append(self.getWord(node: node))
        } else {
            for child in node.children {
                self.getWords(node: child.value, arr: &arr)
            }
        }
    }
    
    private func getWord(node: Node) -> String {
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
}

/*
let trie = Trie()

trie.insert(val: "hello")
trie.insert(val: "hella")
trie.insert(val: "helpme")


trie.contains(val: "helpme")
trie.contains(prefix: "hel")
trie.contains(val: "hel")

trie.find(prefix: "hel")
*/
