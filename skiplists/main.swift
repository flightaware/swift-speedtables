//
//  main.swift
//  skiplists
//
//  Created by Peter da Silva on 5/25/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

print("Hello, World!")

let l = SkipList<String, String>(maxLevel: 6)

l.insert("hello", value: "I say hello")
l.insert("goodbye", value: "You say goodbye")
l.insert("yes", value: "I say yes")
l.insert("no", value: "You say no")
l.insert("high", value: "I say high")
l.insert("low", value: "you say low")
l.insert("stop", value: "You say stop")
l.insert("go", value: "I say go go go")
print(l.toArray())

l.insert("hello", value: "Hello my baby")
l.insert("hello", value: "Hello my honey")
l.insert("hello", value: "Hello my ragtime gal")
let hellos: [String] = l.search("hello")
for hello in hellos {
    print("hello is '\(hello)'")
}

l.insert("goodbye", value: "Goodnight America, and all the ships at sea")
print(l.toArray())

func delete_all(l: SkipList<String, String>, key: String) {
    for val in l.search(key) {
        print("Deleting \((key, val))")
        l.delete(key, value: val)
    }
}

delete_all(l, key: "high")
delete_all(l, key: "low")
delete_all(l, key: "goodbye")

print(l.toArray())

let t = Table(size: 100)
t.create("Nick", age: 32)
t.create("Judy", age: 22)
t.create("chip", age: 5)
t.create("dale", age: 5)
for row in t.ageIndex.search(5) {
    print("Name: \(row.name), age: \(row.age)")
}

