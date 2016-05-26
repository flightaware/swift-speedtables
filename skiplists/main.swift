//
//  main.swift
//  skiplists
//
//  Created by Peter da Silva on 5/25/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

print("Hello, World!")

let l = SkipList<String, String>(maxLevel: 6, largerThanMaxKey: "zzzzzzzzzz")

l.insert("hello", value: "I say hello")
l.insert("goodbye", value: "You say goodbye")
if let hello: String = l.search("hello") {
    print("hello is '\(hello)'")
}
print(l.toArray())
l.insert("yes", value: "I say yes")
l.insert("no", value: "You say no")
l.insert("high", value: "I say high")
l.insert("low", value: "you say low")
l.insert("stop", value: "You say stop")
l.insert("go", value: "I say go go go")

print(l.toArray())
print("Delete high = '\(l.delete("high"))'")
print("Delete low = '\(l.delete("low"))'")

print(l.toArray())

