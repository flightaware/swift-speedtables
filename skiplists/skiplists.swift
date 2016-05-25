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

class SLNode<T: Comparable, U> {
    let key: T?
    var value: U?
    var level: Int
    var next: [SLNode<T, U>?]
    init(_ key: T?, maxLevel: Int, level: Int = 0, tail: SLNode<T, U>? = nil) {
        self.key = key
        self.value = nil
        self.level = (level != 0) ? level : SLrandomLevel(maxLevel)
        self.next = Array<SLNode<T, U>?>(count: maxLevel, repeatedValue: tail)
    }
}

class SkipList<T: Comparable, U> {
    let head: SLNode<T, U>
    let tail: SLNode<T, U>
    var maxLevel: Int
    var level: Int
    init(maxLevel: Int, largerThanMaxKey: T) {
        self.maxLevel = maxLevel
        self.level = 1
        self.tail = SLNode<T, U>(largerThanMaxKey, maxLevel: maxLevel, level: maxLevel, tail: nil)
        self.head = SLNode<T, U>(nil, maxLevel: maxLevel, level: maxLevel, tail: tail)
    }

    func Search(searchKey: T) -> SLNode<T, U>? {
        var x = head
        
        for i in maxLevel ... 1 {
            while x.next[i]!.key < searchKey {
                x = x.next[i]!
            }
        }
        x = x.next[1]!
        if x.key == searchKey {
            return x
        } else {
            return nil
        }
    }
    
    func Search(searchKey: T) -> U? {
        let x: SLNode<T, U>? = Search(searchKey)
        if let u = x?.value {
            return u
        } else {
            return nil
        }
    }
    
    func Insert(searchKey: T, newValue: U) {
        var update = [SLNode<T, U>?](count: maxLevel, repeatedValue: head)
        var x = head
        for i in level ... 1 {
            while x.next[i]!.key < searchKey {
                x = x.next[i]!
            }
            update[i] = x
        }
        x = x.next[1]!
        if x.key == searchKey {
            x.value = newValue
        } else {
            let level = SLrandomLevel(maxLevel)
            if level > self.level {
                // We don't need to set update[self.level+1 ... level] to head because it's initialized to head
                self.level = level
            }
            let newNode = SLNode<T, U>(searchKey, maxLevel: maxLevel, level: level, tail: tail)
            for i in 1 ... level {
                newNode.next[i] = update[i]!.next[i]
                update[i]!.next[i] = newNode
            }
        }
    }
}