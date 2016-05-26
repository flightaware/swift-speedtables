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
    init(_ key: Key?, value: Value? = nil, maxLevel: Int, level: Int = 0, tail: SLNode<Key, Value>? = nil) {
        self.key = key
        self.value = value
        self.level = (level > 0) ? level : SLrandomLevel(maxLevel)
        self.next = Array<SLNode<Key, Value>?>(count: maxLevel, repeatedValue: tail)
    }
}

class SkipList<Key: protocol<Comparable>, Value> {
    let head: SLNode<Key, Value>
    let tail: SLNode<Key, Value>
    var maxLevel: Int
    var level: Int
    init(maxLevel: Int, largerThanMaxKey: Key) {
        self.maxLevel = maxLevel
        self.level = 1
        self.tail = SLNode<Key, Value>(largerThanMaxKey, maxLevel: maxLevel, level: maxLevel, tail: nil)
        self.head = SLNode<Key, Value>(nil, maxLevel: maxLevel, level: maxLevel, tail: tail)
    }

    func search(searchKey: Key) -> SLNode<Key, Value>? {
        var x = head
        
        for i in (1 ... self.level).reverse() {
            while x.next[i-1]!.key < searchKey {
                x = x.next[i-1]!
            }
        }
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
        for i in (1 ... level).reverse() {
            while x.next[i-1]!.key < searchKey {
                x = x.next[i-1]!
            }
            update[i] = x
        }
        x = x.next[0]!
        if x.key == searchKey {
            x.value = newValue
        } else {
            let level = SLrandomLevel(maxLevel)
            if level > self.level {
                for i in self.level ... level {
                    update[i] = self.head
                }
                self.level = level
            }
            let newNode = SLNode<Key, Value>(searchKey, value: newValue, maxLevel: maxLevel, level: level, tail: tail)
            for i in 1 ... level {
                newNode.next[i-1] = update[i]!.next[i-1]
                update[i]!.next[i-1] = newNode
            }
        }
    }
    func delete(searchKey: Key) -> Value? {
        var update: [Int: SLNode<Key, Value>] = [:]
        var x = head
        var oldValue: Value? = nil
        for i in (1 ... level).reverse() {
            while x.next[i-1]!.key < searchKey {
                x = x.next[i-1]!
            }
            update[i] = x
        }
        x = x.next[0]!
        if x.key == searchKey {
            oldValue = x.value
            for i in 1 ... self.level {
                if update[i]!.next[i-1]! !== x {
                    break
                }
                update[i]!.next[i-1] = x.next[i-1]
            }
            while self.level > 1 && self.head.next[self.level]! === self.tail {
                self.level -= 1
            }
        }
        return oldValue
    }
    func toArray() -> [(Key, Value?)] {
        var a: [(Key, Value?)] = []
        var x = head
        while x.next[0] !== tail {
            x = x.next[0]!
            a += [(x.key!, x.value)]
        }
        return a
    }
}