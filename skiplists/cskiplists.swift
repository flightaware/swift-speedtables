//
//  cskiplists.swift
//  skiplists
//
//  Created by Peter da Silva on 6/13/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation;

class SkipListValue<Value> {
    var a: [Value];
    init(v: [Value]?) {
        if let a = v {
            self.a = a
        } else {
            self.a = []
        }
    }
}

enum GenState {
    case New
    case Traversing
    case Done
}

public class CSkipList<Value: Equatable>: SequenceType {
    var list: UnsafeMutablePointer<C_SkipList>
    let unique: Bool
    init(maxLevel: Int, unique: Bool = false, type: Int = Int(SKIPLIST_STRING)) {
        self.list = newSkipList(Int32(maxLevel), Int32(type))
        self.unique = unique
    }
    deinit
    {
        // release values
        let s = newSkipListSearch(list);
        traverseSkipList(s)
        repeat {
            deleteMatchedValues(s)
        } while advanceSearchNode(s) != 0;
        
        // deallocate nodes
        destroySkipList(list)
        list = nil
    }

    func deleteMatchedValues(s: UnsafeMutablePointer<C_SkipListSearch>) {
        let p = getMatchedValue(s)
        guard p != nil else { return; }
        // Takeretainedvalue so it gets released when it goes out of scope.
        let _: SkipListValue<Value> = Unmanaged.fromOpaque(COpaquePointer(p)).takeRetainedValue()
        setMatchedValue(s, nil)
    }

    func search(greaterThanOrEqualTo key: String) -> UnsafeMutablePointer<C_SkipListSearch> {
        let s = newSkipListSearch(list);
        guard s != nil else { return nil }
        if searchSkipListString(s, key) == 0 {
            destroySkipListSearch(s)
            return nil;
        }
        return s
    }
    
    public func search(greaterThanOrEqualTo key: String) -> [Value] {
        let s: UnsafeMutablePointer<C_SkipListSearch> = search(greaterThanOrEqualTo: key)
        guard s != nil else { return [] }
        defer { destroySkipListSearch(s); }
        let p = getMatchedValue(s)
        guard p != nil else { return [] }
        let v: SkipListValue<Value> = Unmanaged.fromOpaque(COpaquePointer(p)).takeUnretainedValue();
        return v.a;
    }

    public func search(equalTo key: String) -> UnsafeMutablePointer<C_SkipListSearch> {
        let s = newSkipListSearch(list);
        guard s != nil else { return nil }
        if searchSkipListString(s, key) == 0 {
            destroySkipListSearch(s)
            return nil;
        }
        if searchMatchedExactString(s, key) == 0 {
            destroySkipListSearch(s)
            return nil;
        }
        return s
    }
    
    public func search(equalTo key: String) -> [Value] {
        let s: UnsafeMutablePointer<C_SkipListSearch> = search(equalTo: key)
        guard s != nil else { return [] }
        defer { destroySkipListSearch(s); }
        let p = getMatchedValue(s)
        guard p != nil else { return [] }
        let v: SkipListValue<Value> = Unmanaged.fromOpaque(COpaquePointer(p)).takeUnretainedValue();
        return v.a;
    }

    public func insert(key: String, value newValue: Value) -> Bool {
        let s = newSkipListSearch(list);
        guard s != nil else { return false }
        defer { destroySkipListSearch(s); }

        // Check if it's already a match, if so just add a new value
        if searchSkipListString(s, key) != 0 {
            if searchMatchedExactString(s, key) != 0 {
                let p = getMatchedValue(s)
                if p != nil {
                    let v: SkipListValue<Value> = Unmanaged.fromOpaque(COpaquePointer(p)).takeUnretainedValue();
                    if !v.a.contains(newValue) {
                        v.a += [newValue]
                    } else {
                        // TODO - deal with unique
                    }
                    return true
                } else { // can't happen
                    return false
                }
            }
        }
        
        guard searchCanInsert(s) != 0 else { return false } // can't happen
        
        let v = SkipListValue(v: [newValue])
        
        return insertBeforePossibleMatchString(s, key, UnsafeMutablePointer(Unmanaged.passRetained(v).toOpaque())) != 0
    }
    
    public func delete(key: String, value: Value) -> Bool {
        let s = newSkipListSearch(list);
        guard s != nil else { return false }
        defer { destroySkipListSearch(s); }
        
        // Look for the key, exit if no match
        if searchSkipListString(s, key) == 0 { return false }
        
        if searchMatchedExactString(s, key) == 0 { return false }
        
        let p = getMatchedValue(s)
        if p != nil {
            let v: SkipListValue<Value> = Unmanaged.fromOpaque(COpaquePointer(p)).takeUnretainedValue();
            if let i = v.a.indexOf(value) {
                v.a.removeAtIndex(i)
                if v.a.count > 0 {
                    return true
                }
            } else {
                return false
            }
        }
        
        // release any swift-level data in the matched node
        deleteMatchedValues(s);
        
        // call c for the heavy lifting - remove the matched node from the list and free it
        deleteMatchedNode(s);
        
        // p == nil is a "can't happen", but if it did that means we didn't find a match.
        return p != nil;
    }
    
    public func generate() -> AnyGenerator<(String, Value)> {
        let s = newSkipListSearch(list);
        var state: GenState = .New
        var v: SkipListValue<Value>? = nil;
        var i = -1;
        var k: String? = nil
        
        return AnyGenerator<(String, Value)> {
            if state == .New {
                if s == nil {
                    return nil
                }
                traverseSkipList(s)
                state = .Traversing
            }
            while state == .Traversing {
                if v != nil {
                    i += 1
                    if v!.a.count > i {
                        return (k!, v!.a[i])
                    }
                    v = nil
                    i = -1
                    advanceSearchNode(s)
                }

                let kp = getMatchedKeyString(s)
                if kp == nil {
                    state = .Done
                    return nil
                }
                k = NSString(UTF8String: kp)! as String
                
                let p = getMatchedValue(s)
                if p == nil {
                    state = .Done
                    return nil
                }
                let tmp: SkipListValue<Value> = Unmanaged.fromOpaque(COpaquePointer(p)).takeUnretainedValue()
                v = tmp
            }
            return nil
        }
    }
}
