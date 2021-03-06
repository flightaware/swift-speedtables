//
//  skiplists.swift
//  skiplists
//
//  Created by Peter da Silva on 5/25/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

let randomProbability = 0.5

func SkipListRandomLevel(maxLevel: Int) -> Int {
    var newLevel = 1
    while drand48() < randomProbability && newLevel < maxLevel {
        newLevel += 1
    }
    return newLevel
}

func SkipListMaxLevel(maxNodes: Int) -> Int {
        let logMaxNodes = log(Double(maxNodes)) / log(1.0 / randomProbability)
        return Int(round(logMaxNodes))
}

class SLNode<Key: Comparable, Value: Equatable> {
    let key: Key?
    var values: [Value]
    var level: Int
    var next: [SLNode<Key, Value>?]
    init(_ key: Key?, value: Value? = nil, maxLevel: Int, level: Int = 0) {
        self.key = key
        if let v = value {
            self.values = [v]
        } else {
            self.values = []
        }
        self.level = (level > 0) ? level : SkipListRandomLevel(maxLevel)
        self.next = Array<SLNode<Key, Value>?>(count: maxLevel, repeatedValue: nil)
    }
}

public class SkipList<Key: Comparable, Value: Equatable>: SequenceType {
    let head: SLNode<Key, Value>
    var maxLevel: Int
    var level: Int
    
    public init(maxLevel: Int) {
        self.maxLevel = maxLevel
        self.level = 1
        self.head = SLNode<Key, Value>(nil, maxLevel: maxLevel, level: maxLevel)
    }
    
    public convenience init(maxNodes: Int) {
        self.init(maxLevel: SkipListMaxLevel(maxNodes))
    }
    
    func search(greaterThanOrEqualTo key: Key) -> SLNode<Key, Value>? {
        var x = head
        
        // look for the key
        for i in (1 ... self.level).reverse() {
            while let next = x.next[i-1] where next.key < key {
                x = next
            }
        }
        
        return x.next[0]
    }
    
    public func search(greaterThanOrEqualTo key: Key) -> [Value] {
        if let array = search(greaterThanOrEqualTo: key)?.values {
            return array
        } else {
            return []
        }
    }
    
    func search(equalTo key: Key) -> SLNode<Key, Value>? {
        // Check for an exact match
        if let x: SLNode<Key, Value> = search(greaterThanOrEqualTo: key) where x.key == key {
            return x
        } else {
            return nil
        }
    }
    
    public func exists(key: Key) -> Bool {
        let x: SLNode<Key, Value>? = search(equalTo: key)
        return x != nil
    }
    
    public func exists(key: Key, value: Value) -> Bool {
        if let array = search(equalTo: key)?.values {
            return array.contains(value)
        }
        return false;
    }
    
    public func search(equalTo key: Key) -> [Value] {
        if let array = search(equalTo: key)?.values {
            return array
        } else {
            return []
        }
    }
    
    // Replace an entry in a skiplist - for optional keys
    public func replace(newKey: Key?, inout keyStore: Key?, value: Value) {
        // no change - no work
        if newKey == keyStore {
            return
        }
        
        // showtime -- remove the old entry, update the keystore, insert the new value
        if let k = keyStore {
            delete(k, value: value)
        }
        keyStore = newKey
        if let k = newKey {
            insert(k, value: value)
        }
    }
    
    // Replace an entry in a skiplist - for non-optional keys
    public func replace(newKey: Key, inout keyStore: Key, value: Value) {
        // no change - no work
        if newKey == keyStore {
            return
        }
        
        // showtime -- remove the old entry, update the keystore, insert the new value
        delete(keyStore, value: value)
        keyStore = newKey
        insert(keyStore, value: value)
    }
        
    public func insert(key: Key, value newValue: Value) {
        var update = Array<SLNode<Key, Value>?>(count: maxLevel, repeatedValue: nil)
        var x = head
        var i: Int
        
        // look for the key, and save the previous nodes all the way down in the update[] list
        i = self.level
        while i >= 1 {
            while let next = x.next[i-1] where next.key < key {
                x = next
            }
            update[i-1] = x
            i -= 1
        }
        
        // If we haven't run off the end...
        if let next = x.next[0]  {
            x = next
            
            // If we're looking at the right key already, then there's nothing to insert. Just add
            // the new value to the values array.
            if x.key == key {
                if x.values.contains(newValue) {
                    return
                }
                
                x.values += [newValue]
                
                return
            }
        }
        
        // Pick a random level for the new node
        let level = SkipListRandomLevel(maxLevel)
        
        // If the new node is higher than the current level, fill up the update[] list
        // with head
        while level > self.level {
            self.level += 1
            update[self.level-1] = self.head
        }
        
        // make a new node and patch it in to the saved nodes in the update[] list
        let newNode = SLNode<Key, Value>(key, value: newValue, maxLevel: maxLevel, level: level)
        i = 1
        while i <= level {
            newNode.next[i-1] = update[i-1]!.next[i-1]
            update[i-1]!.next[i-1] = newNode
            i += 1
        }
    }
    
    public func delete(key: Key, value: Value) -> Bool {
        var update = Array<SLNode<Key, Value>?>(count: maxLevel, repeatedValue: nil)
        var x = head
        var i: Int
        
        // look for the key, and save the previous nodes all the way down in the update[] list
        i = self.level
        while i >= 1 {
            while let next = x.next[i-1] where next.key < key {
                x = next
            }
            update[i-1] = x
            i -= 1
        }
        
        // check if run off end of list, nothing to do,
        guard let next = x.next[0] else {
            return false
        }
        
        // Point to the node we're maybe going to delete, if it matches
        x = next
        
        // Look for a key match
        if x.key != key {
            return false
        }
        
        // look for match in values
        guard let foundIndex = x.values.indexOf(value) else {
            // If we didn't find a matching value, we didn't actually find a match
            return false
        }
        
        // Remove the value we found, and if it wasn't the last one return success
        x.values.removeAtIndex(foundIndex)
        if(x.values.count > 0) {
            return true
        }

        // Now we've found a value, deleted it, and emptied the values list, we can delete this whole node

        // point all the previous node to the new next node
        i = 1
        while i <= self.level {
            if update[i-1]!.next[i-1] != nil && update[i-1]!.next[i-1] !== x {
                break
            }
            update[i-1]!.next[i-1] = x.next[i-1]
            i += 1
        }
            
        // if that was the biggest node, and we can see the end of the list from the head,
        // lower the list until we're pointing at a node
        while self.level > 1 && self.head.next[self.level-1] == nil {
            self.level -= 1
        }
        
        return true
    }
    
    public func generate() -> AnyGenerator<(Key, Value)> {
        var row = head
        var index = -1
        
        return AnyGenerator<(Key, Value)> {
            if index < 0 || index >= row.values.count {
                repeat {
                    guard let next = row.next[0] else { return nil }
                    row = next
                } while row.values.count == 0
                index = 0
            }
            let next = row.values[index]
            index += 1
            return (row.key!, next)
        }
    }
    
    func query(from start: Key?, through end: Key?) -> Query<Key, Value> {
        return query(min: start, max: end, minEqual: true, maxEqual: true)
    }
    
    func query(from start: Key?, to end: Key?) -> Query<Key, Value> {
        return query(min: start, max: end, minEqual: true, maxEqual: false)
    }

    func query(greaterThanOrEqual key: Key?) -> Query<Key, Value> {
        return query(min: key, minEqual: true)
    }
    
    func query(greaterThan key: Key?) -> Query<Key, Value> {
        return query(min: key, minEqual: false)
    }

    func query(lessThanOrEqual key: Key?) -> Query<Key, Value> {
        return query(max: key, maxEqual: true)
    }
    
    func query(lessThan key: Key?) -> Query<Key, Value> {
        return query(max: key, maxEqual: false)
    }
    
    func query(min min: Key? = nil, max: Key? = nil, minEqual: Bool = false, maxEqual: Bool = false) -> Query<Key, Value> {
        return Query<Key, Value>(list: self, min: min, max: max, minEqual: minEqual, maxEqual: maxEqual)
    }
}
