//
//  queries.swift
//  skiplists
//
//  Created by Peter da Silva on 5/31/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

// Query 0.1
// Initialized with min key (may be nil), max key (may be nil)
public class Query<Key: Comparable, Value: Equatable>: SequenceType {
    let list: SkipList<Key, Value>
    let min: Key?
    let max: Key?
    let minEqual: Bool
    let maxEqual: Bool
    var currentNode: SLNode<Key, Value>?
    var currentIndex: Int
    
    init(list: SkipList<Key, Value>, min: Key? = nil, max: Key? = nil, minEqual: Bool = true, maxEqual: Bool = true) {
        self.list = list
        self.min = min
        self.minEqual = minEqual
        self.max = max
        self.maxEqual = maxEqual
        self.currentNode = nil
        self.currentIndex = -1
    }
    
    private func firstNode() -> SLNode<Key, Value>? {
        var node: SLNode<Key, Value>?
        
        if min == nil {
            node = list.head.nextNode()
        } else {
            node = list.search(greaterThanOrEqualTo: min!)
            if node != nil && minEqual == false && node!.key == min {
                node = node!.nextNode()
            }
        }
        
        return node
    }
    
    public func first() -> (Key, Value)? {
        currentNode = firstNode()
        currentIndex = -1
        return next()
    }
    
    private func step() {
        guard currentNode != nil else { return }
        
        // step to the next index
        currentIndex += 1
        
        // if we've stepped past the curent node's values, keep stepping until we get a node with values
        while currentNode != nil && currentIndex >= currentNode!.values.count {
            currentNode = currentNode!.nextNode()
            currentIndex = 0
        }
        // if you ran out of nodes, byebye
        if currentNode == nil { return }
        
        // check if we need to stop before the end
        if max != nil {
            if maxEqual {
                if max >= currentNode!.key {
                    currentNode = nil
                    return
                }
            } else {
                if max > currentNode!.key {
                    currentNode = nil
                    return
                }
            }
        }
        return
    }
    
    // placeholder
    public func next() -> (Key, Value)? {
        step()

        guard currentNode != nil else { return nil }
        
        return (currentNode!.key!, currentNode!.values[currentIndex])
    }
    
    // placeholder
    public func generate() -> AnyGenerator<(Key, Value)> {
        return AnyGenerator<(Key, Value)> {
            return nil
        }
    }
}
