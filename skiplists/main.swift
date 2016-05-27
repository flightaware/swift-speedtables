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

print("Adding cartoon characters")
t.insert("Nick", age: 32)
t.insert("Judy", age: 22)
t.insert("chip", age: 5)
t.insert("dale", age: 5)

print("Looking for 5 year olds")
for row in t.ageIndex.search(5) {
    print("Name: \(row.name), age: \(row.age)")
}

print("Change chip's age to 6,, and make sure there is only one chip")
let chips: [TableRow] = t.nameIndex.search("chip")
if(chips.count == 1) {
    chips[0].age = 6
} else {
    print("OOPS! chips.count(\(chips.count)) should be 1")
}

print("Adding more cartoon characters")
t.insert("gadget", age: 5)
t.insert("monty", age: 8)

print("Adding dwarves. Dwarves are really old")
t.insert("happy", age: 500)
t.insert("sleepy", age: 500)
t.insert("grumpy", age: 500)

print("Adding vampires. They're really old too, and some have multiple ages")
t.insert("lestat", age: 500)
t.insert("dracula", age: 500)
t.insert("dracula", age: 80)
t.insert("dracula", age: 120)

print("Wait on, we can't have 500 year old schoolkids!")
for row in t.ageIndex.search(500) {
    print("Deleting impossible entry \(row.name), \(row.age)")
    t.delete(row)
}

print("Walking nameIndex:")
for (key, rows) in t.nameIndex.toArray() {
    print("  Key: \(key)")
    for row in rows {
        print("    Name: \(row.name), age: \(row.age)")
    }
}
print("Walking ageIndex:")
for (key, rows) in t.ageIndex.toArray() {
    print("Key: \(key)")
    for row in rows {
        print("    Name: \(row.name), age: \(row.age)")
    }
}


