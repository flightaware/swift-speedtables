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
    
    init(node: SLNode<Key, Value>?) {
        self.node = node
        self.index = -1
    }
}

public class Query<Key: Comparable, Value: Equatable>: Sequence {
    let list: SkipList<Key, Value>
    let minKey: Key?
    let maxKey: Key?
    let minEqual: Bool
    let maxEqual: Bool
    private var state: QueryState<Key, Value>
    
    init(list: SkipList<Key, Value>, min minKey: Key? = nil, max maxKey: Key? = nil, minEqual: Bool = true, maxEqual: Bool = true) {
        self.list = list
        self.minKey = minKey
        self.minEqual = minEqual
        self.maxKey = maxKey
        self.maxEqual = maxEqual
        self.state = QueryState<Key, Value>(node: nil)
    }
    
    private func start() -> QueryState<Key, Value> {
        var node: SLNode<Key, Value>?

        if let minKey = self.minKey {
            node = list.search(greaterThanOrEqualTo: minKey)
            if node != nil && minEqual == false && node!.key == minKey {
                node = node!.next[0]
            }
        } else {
            node = list.head.next[0]
        }
        return QueryState<Key, Value>(node: node)
    }
    
    private func step(state: inout QueryState<Key, Value>) {
        guard state.node != nil else { return }
        
        // step to the next index
        state.index += 1
        
        // if we've stepped past the current node's values, keep stepping until we get a node with values
        while
            let node = state.node,
            state.index >= node.values.count
        {
            state.node = node.next[0]
            state.index = 0
        }
        
        // if you ran out of nodes, our work is done
        guard let node = state.node else { return }
        
        if
            let maxKey = maxKey,
            let thisKey = node.key
        {
            // If there's a max, and we've hit it, we're done
            if maxEqual {
                if maxKey < thisKey {
                    state.node = nil
                }
            } else {
                if maxKey <= thisKey {
                    state.node = nil
                }
            }
        }
    }
    
    public func reset() {
        state = start()
    }
    
    public func first() -> (Key, Value)? {
        state = start()
        return next()
    }
    
    public func next() -> (Key, Value)? {
        step(state: &state)
        
        guard let node = state.node else { return nil }
        
        return (node.key!, node.values[state.index])
    }
    
    public func makeIterator() -> AnyIterator<(Key, Value)> {
        var state = start()
        
        return AnyIterator<(Key, Value)> {
            self.step(state: &state)
            
            guard let node = state.node else { return nil }
            
            return (node.key!, node.values[state.index])
        }
    }
}
