//
//  queries.swift
//  skiplists
//
//  Created by Peter da Silva on 5/31/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

private class QueryState<Key: Comparable, Value: Equatable> {
    var currentNode: SLNode<Key, Value>?
    var currentIndex: Int
    let max: Key?
    let maxEqual: Bool
    
    private init(node: SLNode<Key, Value>?, max: Key?, maxEqual: Bool) {
        currentNode = node
        currentIndex = -1
        self.max = max
        self.maxEqual = maxEqual
    }
    
    private func step() {
        guard currentNode != nil else { return }
        
        // step to the next index
        currentIndex += 1
        
        // if we've stepped past the current node's values, keep stepping until we get a node with values
        while currentNode != nil && currentIndex >= currentNode!.values.count {
            currentNode = currentNode!.nextNode()
            currentIndex = 0
        }
        
        // if you ran out of nodes, our work is done
        if currentNode == nil { return }
        
        // If there's no max, our work is done
        if max == nil { return }
        
        if maxEqual {
            if max < currentNode!.key {
                currentNode = nil
            }
        } else {
            if max <= currentNode!.key {
                currentNode = nil
            }
        }
    }
}

// Query 0.1
// Initialized with min key (may be nil), max key (may be nil)
public class Query<Key: Comparable, Value: Equatable>: SequenceType {
    let list: SkipList<Key, Value>
    let min: Key?
    let max: Key?
    let minEqual: Bool
    let maxEqual: Bool
    private var state: QueryState<Key, Value>?
    
    init(list: SkipList<Key, Value>, min: Key? = nil, max: Key? = nil, minEqual: Bool = true, maxEqual: Bool = true) {
        self.list = list
        self.min = min
        self.minEqual = minEqual
        self.max = max
        self.maxEqual = maxEqual
        self.state = nil
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
        state = QueryState(node: firstNode(), max: max, maxEqual: maxEqual)
        return next()
    }
    
    
    public func next() -> (Key, Value)? {
        guard state != nil else { return nil }
        
        state!.step()

        guard state!.currentNode != nil else { return nil }
        
        return (state!.currentNode!.key!, state!.currentNode!.values[state!.currentIndex])
    }
    
    public func generate() -> AnyGenerator<(Key, Value)> {
        let state = QueryState(node: firstNode(), max: max, maxEqual: maxEqual)

        return AnyGenerator<(Key, Value)> {
            state.step()
            
            guard state.currentNode != nil else { return nil }
            
            return (state.currentNode!.key!, state.currentNode!.values[state.currentIndex])

        }
    }
}
