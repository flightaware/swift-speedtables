//
//  queries-strings.swift
//  skiplists
//
//  Created by Peter da Silva on 6/11/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

private struct StringQueryState<Value: Equatable> {
    var node: UnsafeMutablePointer<SLStringNode<Value>>? = nil
    var index: Int = -1
    
    private init(node: UnsafeMutablePointer<SLStringNode<Value>>?) {
        self.node = node
        self.index = -1
    }
}

public class StringQuery<Value: Equatable>: SequenceType {
    let list: StringSkipList<Value>
    let min: String?
    let max: String?
    let minEqual: Bool
    let maxEqual: Bool
    private var state: StringQueryState<Value>
    
    init(list: StringSkipList<Value>, min: String? = nil, max: String? = nil, minEqual: Bool = true, maxEqual: Bool = true) {
        self.list = list
        self.min = min
        self.minEqual = minEqual
        self.max = max
        self.maxEqual = maxEqual
        self.state = StringQueryState<Value>(node: nil)
    }
    
    private func start() -> StringQueryState<Value> {
        var node: UnsafeMutablePointer<SLStringNode<Value>>?

        if min == nil {
            node = list.head.memory.next[0]
        } else {
            node = list.search(greaterThanOrEqualTo: min!)
            if node != nil && minEqual == false && node!.memory.key == min {
                node = node!.memory.next[0]
            }
        }
        return StringQueryState<Value>(node: node)
    }
    
    private func step(inout state: StringQueryState<Value>) {
        guard state.node != nil else { return }
        
        // step to the next index
        state.index += 1
        
        // if we've stepped past the current node's values, keep stepping until we get a node with values
        while state.node != nil && state.index >= state.node!.memory.values.count {
            state.node = state.node!.memory.next[0]
            state.index = 0
        }
        
        // if you ran out of nodes, our work is done
        if state.node == nil { return }
        
        // If there's no max, our work is done
        if max == nil { return }
        
        if maxEqual {
            if max < state.node!.memory.key {
                state.node = nil
            }
        } else {
            if max <= state.node!.memory.key {
                state.node = nil
            }
        }
    }
    
    public func reset() {
        state = start()
    }
    
    public func first() -> (String, Value)? {
        state = start()
        return next()
    }
    
    public func next() -> (String, Value)? {
        step(&state)
        
        guard state.node != nil else { return nil }
        
        return (state.node!.memory.key!, state.node!.memory.values[state.index])
    }
    
    public func generate() -> AnyGenerator<(String, Value)> {
        var state = start()
        
        return AnyGenerator<(String, Value)> {
            self.step(&state)
            
            guard state.node != nil else { return nil }
            
            return (state.node!.memory.key!, state.node!.memory.values[state.index])
        }
    }
}
