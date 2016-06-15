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
    while drand48() < randomProbability && newLevel < maxLevel-1 {
        newLevel += 1
    }
    return newLevel
}

func SkipListMaxLevel(maxNodes: Int) -> Int {
        let logMaxNodes = log(Double(maxNodes)) / log(1.0 / randomProbability)
        return Int(round(logMaxNodes))
}

struct SLNode<Key: Comparable, Value: Equatable> {
    let key: Key?
    var values: [Value]
    var level: Int
    var next: [UnsafeMutablePointer<SLNode<Key, Value>>?]
    init(_ key: Key?, value: Value? = nil, maxLevel: Int, level: Int = 0) {
        self.key = key
        self.values = (value == nil) ? [] : [value!]
        self.level = (level > 0) ? level : SkipListRandomLevel(maxLevel)
        self.next = Array<UnsafeMutablePointer<SLNode<Key, Value>>?>(count: maxLevel, repeatedValue: nil)
    }
}

func allocateSkipListNode<Key, Value>(key: Key?, value: Value? = nil, maxLevel: Int, level: Int = 0) -> UnsafeMutablePointer<SLNode<Key, Value>> {
    let newNode = UnsafeMutablePointer<SLNode<Key, Value>>(malloc(sizeof(SLNode<Key, Value>)))
    newNode.initialize(SLNode<Key, Value>(key, value: value, maxLevel: maxLevel, level: level))
    return newNode
}

func freeSkipListNode<Key, Value>(node: UnsafeMutablePointer<SLNode<Key, Value>>) {
    node.destroy()
    free(node)
}


public class SkipList<Key: Comparable, Value: Equatable>: SequenceType {
    let head: UnsafeMutablePointer<SLNode<Key, Value>>
    let unique: Bool
    var maxLevel: Int
    var level: Int
    
    public init(maxLevel: Int, unique: Bool = false) {
        self.maxLevel = maxLevel
        self.level = 1
        self.unique = unique
        self.head = allocateSkipListNode(nil, maxLevel: maxLevel, level: maxLevel)
    }
    
    public convenience init(maxNodes: Int, unique: Bool = false) {
        self.init(maxLevel: SkipListMaxLevel(maxNodes), unique: unique)
    }
    
    deinit {
        // Walk the skiplist and release all the nodes, including head
        var x: UnsafeMutablePointer<SLNode<Key, Value>>? = head
        while x != nil {
            let xnext = x!.memory.next[0]
            freeSkipListNode(x!)
            x = xnext!
        }
    }
    
    func search(greaterThanOrEqualTo key: Key) -> UnsafeMutablePointer<SLNode<Key, Value>>? {
        var x = head
        
        // look for the key
        for i in (1 ... self.level).reverse() {
            while x.memory.next[i-1] != nil && x.memory.next[i-1]!.memory.key < key {
                x = x.memory.next[i-1]!
            }
        }
        
        // have we run off the end?
        guard x.memory.next[0] != nil else {
            return nil
        }
        
        // no, are we looking at a valid node?
        x = x.memory.next[0]!
        
        return x
    }
    
    public func search(greaterThanOrEqualTo key: Key) -> [Value] {
        let x: UnsafeMutablePointer<SLNode<Key, Value>>? = search(greaterThanOrEqualTo: key)
        if let array = x?.memory.values {
            return array
        } else {
            return []
        }
    }
    
    func search(equalTo key: Key) -> UnsafeMutablePointer<SLNode<Key, Value>>? {
        let x: UnsafeMutablePointer<SLNode<Key, Value>>? = search(greaterThanOrEqualTo: key)

        // Check for an exact match
        if x != nil && x!.memory.key == key {
            return x
        } else {
            return nil
        }
    }
    
    public func exists(key: Key) -> Bool {
        let x: UnsafeMutablePointer<SLNode<Key, Value>>? = search(equalTo: key)
        return x != nil
    }
    
    public func search(equalTo key: Key) -> [Value] {
        let x: UnsafeMutablePointer<SLNode<Key, Value>>? = search(equalTo: key)
        if let array = x?.memory.values {
            return array
        } else {
            return []
        }
    }
    
    // Replace an entry in a skiplist - for optional keys
    public func replace(newKey: Key?, inout keyStore: Key?, value: Value) throws {
        // no change - no work
        if newKey == keyStore {
            return
        }
        
        // If it's supposed to be unique, throw an error if it's not
        if unique {
            if let k = newKey {
                if exists(k) {
                    throw SkipListError.KeyNotUnique(key: k)
                }
            }
        }
        
        // showtime -- remove the old entry, update the keystore, insert the new value
        if let k = keyStore {
            delete(k, value: value)
        }
        keyStore = newKey
        if let k = newKey {
            try insert(k, value: value)
        }
    }
    
    // Replace an entry in a skiplist - for non-optional keys
    public func replace(newKey: Key, inout keyStore: Key, value: Value) throws {
        // no change - no work
        if newKey == keyStore {
            return
        }
        
        // If it's supposed to be unique, throw an error if it's not
        if unique {
            if exists(newKey) {
                throw SkipListError.KeyNotUnique(key: newKey)
            }
        }
        
        // showtime -- remove the old entry, update the keystore, insert the new value
        delete(keyStore, value: value)
        keyStore = newKey
        try insert(keyStore, value: value)
    }
        
    public func insert(key: Key, value newValue: Value) throws {
        var update = ContiguousArray<UnsafeMutablePointer<SLNode<Key, Value>>?>(count: maxLevel, repeatedValue: nil)
        var x = head
        var i: Int
        
        // look for the key, and save the previous nodes all the way down in the update[] list
        i = self.level
        while i >= 1 {
            while x.memory.next[i-1] != nil && x.memory.next[i-1]!.memory.key < key {
                x = x.memory.next[i-1]!
            }
            update[i-1] = x
            i -= 1
        }
        
        // If we haven't run off the end...
        if x.memory.next[0] != nil {
            x = x.memory.next[0]!
            
            // If we're looking at the right key already, then there's nothing to insert. Just add
            // the new value to the values array.
            if x.memory.key == key {
                if unique {
                    throw SkipListError<Key>.KeyNotUnique(key: key)
                }

                if x.memory.values.contains(newValue) {
                    return
                }

                x.memory.values += [newValue]

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
        let newNode = allocateSkipListNode(key, value: newValue, maxLevel: maxLevel, level: level)
        i = 1
        while i <= level {
            newNode.memory.next[i-1] = update[i-1]!.memory.next[i-1]
            update[i-1]!.memory.next[i-1] = newNode
            i += 1
        }
    }
    
    public func delete(key: Key, value: Value) -> Bool {
        var update = ContiguousArray<UnsafeMutablePointer<SLNode<Key, Value>>?>(count: maxLevel, repeatedValue: nil)
        var x = head
        var i: Int
        
        // look for the key, and save the previous nodes all the way down in the update[] list
        i = self.level
        while i >= 1 {
            while x.memory.next[i-1] != nil && x.memory.next[i-1]!.memory.key < key {
                x = x.memory.next[i-1]!
            }
            update[i-1] = x
            i -= 1
        }
        
        // check if run off end of list, nothing to do
        guard x.memory.next[0] != nil else {
            return false
        }
        
        // Point to the node we're maybe going to delete, if it matches
        x = x.memory.next[0]!
        
        // Look for a key match
        if x.memory.key != key {
            return false
        }
        
        // look for match in values
        let foundIndex = x.memory.values.indexOf(value)
        
        // If we didn't find a matching value, we didn't actually find a match
        if(foundIndex == nil) {
            return false
        }
        
        // Remove the value we found, and if it wasn't the last one return success
        x.memory.values.removeAtIndex(foundIndex!)
        if(x.memory.values.count > 0) {
            return true
        }

        // Now we've found a value, deleted it, and emptied the values list, we can delete this whole node

        // point all the previous node to the new next node
        i = 1
        while i <= self.level { // The skiplist paper says this goes up to list->level, not x->level ?
            if update[i-1]!.memory.next[i-1] != nil && update[i-1]!.memory.next[i-1] != x {
                break
            }
            update[i-1]!.memory.next[i-1] = x.memory.next[i-1]
            i += 1
        }
            
        // if that was the biggest node, and we can see the end of the list from the head,
        // lower the list until we're pointing at a node
        while self.level > 1 && self.head.memory.next[self.level-1] == nil {
            self.level -= 1
        }
        
        // Dispose of the node, because we're doing memory management
        freeSkipListNode(x)
        
        return true
    }
    
    public func generate() -> AnyGenerator<(Key, Value)> {
        var row = head
        var index = -1
        
        return AnyGenerator<(Key, Value)> {
            if index < 0 || index >= row.memory.values.count {
                repeat {
                    guard row.memory.next[0] != nil else { return nil }
                    row = row.memory.next[0]!
                } while row.memory.values.count == 0
                index = 0
            }
            let next = row.memory.values[index]
            index += 1
            return (row.memory.key!, next)
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

// Skiplist errors
public enum SkipListError<Key>: ErrorType {
    case KeyNotUnique(key: Key)
}
