//
//  queries.swift
//  skiplists
//
//  Created by Peter da Silva on 5/31/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

private struct QueryState<Key: Comparable, Value: Equatable> {
    var node: SLNode<Key, Value>? = nil
    var index: Int = -1
    
    private init(node: SLNode<Key, Value>?) {
        self.node = node
        self.index = -1
    }
}

public class Query<Key: Comparable, Value: Equatable>: SequenceType {
    let list: SkipList<Key, Value>
    let min: Key?
    let max: Key?
    let minEqual: Bool
    let maxEqual: Bool
    private var state: QueryState<Key, Value>
    
    init(list: SkipList<Key, Value>, min: Key? = nil, max: Key? = nil, minEqual: Bool = true, maxEqual: Bool = true) {
        self.list = list
        self.min = min
        self.minEqual = minEqual
        self.max = max
        self.maxEqual = maxEqual
        self.state = QueryState<Key, Value>(node: nil)
    }
    
    private func start() -> QueryState<Key, Value> {
        var node: SLNode<Key, Value>?

        if min == nil {
            node = list.head.nextNode()
        } else {
            node = list.search(greaterThanOrEqualTo: min!)
            if node != nil && minEqual == false && node!.key == min {
                node = node!.nextNode()
            }
        }
        return QueryState<Key, Value>(node: node)
    }
    
    private func step(inout state: QueryState<Key, Value>) {
        guard state.node != nil else { return }
        
        // step to the next index
        state.index += 1
        
        // if we've stepped past the current node's values, keep stepping until we get a node with values
        while state.node != nil && state.index >= state.node!.values.count {
            state.node = state.node!.nextNode()
            state.index = 0
        }
        
        // if you ran out of nodes, our work is done
        if state.node == nil { return }
        
        // If there's no max, our work is done
        if max == nil { return }
        
        if maxEqual {
            if max < state.node!.key {
                state.node = nil
            }
        } else {
            if max <= state.node!.key {
                state.node = nil
            }
        }
    }
    
    public func first() -> (Key, Value)? {
        state = start()
        return next()
    }
    
    public func next() -> (Key, Value)? {
        step(&state)
        
        guard state.node != nil else { return nil }
        
        return (state.node!.key!, state.node!.values[state.index])
    }
    
    public func generate() -> AnyGenerator<(Key, Value)> {
        var state = start()
        
        return AnyGenerator<(Key, Value)> {
            self.step(&state)
            
            guard state.node != nil else { return nil }
            
            return (state.node!.key!, state.node!.values[state.index])
        }
    }
}