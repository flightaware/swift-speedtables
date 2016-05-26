//
//  skiplists.swift
//  skiplists
//
//  Created by Peter da Silva on 5/25/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

let randomProbability = 0.5

func SLrandomLevel(maxLevel: Int) -> Int {
    var newLevel = 1
    while drand48() < randomProbability && newLevel < maxLevel {
        newLevel += 1
    }
    return newLevel
}

class SLNode<Key: protocol<Comparable>, Value> {
    let key: Key?
    var value: Value?
    var level: Int
    var next: [SLNode<Key, Value>?]
    init(_ key: Key?, value: Value? = nil, maxLevel: Int, level: Int = 0) {
        self.key = key
        self.value = value
        self.level = (level > 0) ? level : SLrandomLevel(maxLevel)
        self.next = Array<SLNode<Key, Value>?>(count: maxLevel, repeatedValue: nil)
    }
}

class SkipList<Key: protocol<Comparable>, Value> {
    let head: SLNode<Key, Value>
    var maxLevel: Int
    var level: Int
    
    init(maxLevel: Int) {
        self.maxLevel = maxLevel
        self.level = 1
        self.head = SLNode<Key, Value>(nil, maxLevel: maxLevel, level: maxLevel)
    }
    
    convenience init(maxNodes: Int) {
        let logMaxNodes = Int(round(log(Double(maxNodes)) / log(1 / randomProbability)))
        self.init(maxLevel: logMaxNodes)
    }

    func search(searchKey: Key) -> SLNode<Key, Value>? {
        var x = head
        
        // look for the key
        for i in (1 ... self.level).reverse() {
            while x.next[i-1] != nil && x.next[i-1]!.key < searchKey {
                x = x.next[i-1]!
            }
        }
        
        // have we run off the end?
        guard x.next[0] != nil else {
            return nil
        }

        // no, are we looking at a valis node?
        x = x.next[0]!
        if x.key == searchKey {
            return x
        } else {
            return nil
        }
    }
    
    func search(searchKey: Key) -> Value? {
        let x: SLNode<Key, Value>? = search(searchKey)
        if let u = x?.value {
            return u
        } else {
            return nil
        }
    }
    
    func insert(searchKey: Key, value newValue: Value) {
        var update: [Int: SLNode<Key, Value>] = [:]
        var x = head
        
        // look for the key, and save the previous nodes all the way down in the update[] list
        for i in (1 ... self.level).reverse() {
            while x.next[i-1] != nil && x.next[i-1]!.key < searchKey {
                x = x.next[i-1]!
            }
            update[i] = x
        }
        
        // If we haven't run off the end, and we're looking at the right key already,
        // then there's nothing to insert. Just set the new value.
        if x.next[0] != nil {
            if x.next[0]!.key == searchKey {
                x.value = newValue
                return
            }
        }
        
        // Pick a random level for the new node
        let level = SLrandomLevel(maxLevel)
        
        // If the new node is higher than the current level, fill up the update[] list
        // with head
        if level > self.level {
            for i in self.level ... level {
                update[i] = self.head
            }
            self.level = level
        }
        
        // make a new node and patch it in to the saved nodes in the update[] list
        let newNode = SLNode<Key, Value>(searchKey, value: newValue, maxLevel: maxLevel, level: level)
        for i in 1 ... level {
            newNode.next[i-1] = update[i]!.next[i-1]
            update[i]!.next[i-1] = newNode
        }
    }
    
    func delete(searchKey: Key) -> Value? {
        var update: [Int: SLNode<Key, Value>] = [:]
        var x = head
        var oldValue: Value? = nil
        
        // look for the key, and save the previous nodes all the way down in the update[] list
        for i in (1 ... level).reverse() {
            while x.next[i-1] != nil && x.next[i-1]!.key < searchKey {
                x = x.next[i-1]!
            }
            update[i] = x
        }
        
        // check if run off end of list, nothing to do
        guard x.next[0] != nil else {
            return nil
        }

        // Point to the node we're maybe going to delete, if it matches
        x = x.next[0]!
        if x.key == searchKey {
            oldValue = x.value // remember to return this
            
            // point all the previous node to the new next node
            for i in 1 ... self.level {
                if update[i]!.next[i-1]! !== x {
                    break
                }
                update[i]!.next[i-1] = x.next[i-1]
            }
            
            // if that was the biggest node, and we can see the end of the list from the head,
            // lower the list until we're pointing at a node
            while self.level > 1 && self.head.next[self.level] == nil {
                self.level -= 1
            }
        }
        return oldValue
    }
    
    func toArray() -> [(Key, Value?)] {
        var a: [(Key, Value?)] = []
        var x = head
        while x.next[0] != nil {
            x = x.next[0]!
            a += [(x.key!, x.value)]
        }
        return a
    }
}