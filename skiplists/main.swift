//
//  main.swift
//  skiplists
//
//  Created by Peter da Silva on 5/25/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

print("Basic skiplist test")

let l = SkipList<String, String>(maxLevel: 20)

print("\nPopulating list.")
l.insert(key: "hello", value: "I say hello")
l.insert(key: "goodbye", value: "You say goodbye")
l.insert(key: "yes", value: "I say yes")
l.insert(key: "no", value: "You say no")
l.insert(key: "high", value: "I say high")
l.insert(key: "low", value: "you say low")
l.insert(key: "stop", value: "You say stop")
l.insert(key: "go", value: "I say go go go")
l.insert(key: "hello", value: "Hello my baby")
l.insert(key: "hello", value: "Hello my honey")
l.insert(key: "hello", value: "Hello my ragtime gal")
l.insert(key: "goodbye", value: "Goodnight America, and all the ships at sea")
print("Dumping list:")
for (key, value) in l {
    print("    \(key): \(value)")
}

func delete_all(_ l: SkipList<String, String>, key: String) {
    for val in l.search(equalTo: key) {
        print("Deleting \((key, val))")
        _ = l.delete(key: key, value: val)
    }
}

print("Delete test")
delete_all(l, key: "high")
delete_all(l, key: "low")
delete_all(l, key: "goodbye")

print("Dumping list:")
for (key, value) in l {
    print("\(key): \(value)")
}

print("\n\nSpeedtables test")

let t = Table(maxLevel: 20)

print("Adding cartoon characters")
_ = t.insert("Nick", age: 32) // "200 dollars a day since I was twelve"
_ = t.insert("Judy", age: 22) // Guess
_ = t.insert("chip", age: 5) // How old can a chipmunk be?
_ = t.insert("dale", age: 5)

// Just use a fixed year for repeatability.
let year = 2016
_ = t.insert("mickey", age: year - 1928) // Steamboat Willie
_ = t.insert("bugs", age: year - 1940) // A Wild Hare

print("Looking for 5 year olds")
for row in t.ageIndex.search(equalTo: 5) {
    print("Name: \(row.name), age: \(row.age)")
}

print("Change chip's age to 6,, and make sure there is only one chip")
let chips: [TableRow] = t.nameIndex.search(equalTo: "chip")
if(chips.count == 1) {
    chips[0].age = 6
} else {
    print("OOPS! chips.count(\(chips.count)) should be 1")
}

print("Adding more cartoon characters")
_ = t.insert("gadget", age: 5)
_ = t.insert("monty", age: 8)

print("Adding dwarves. Dwarves are really old")
_ = t.insert("happy", age: 500)
_ = t.insert("sleepy", age: 500)
_ = t.insert("grumpy", age: 500)

print("Adding vampires. They're really old too, and some have multiple ages")
_ = t.insert("lestat", age: 500)
_ = t.insert("dracula", age: 500)
_ = t.insert("dracula", age: year - 1897) // Book
_ = t.insert("dracula", age: year - 1931) // Bella Lugosi
_ = t.insert("dracula", age: year - 1958) // Christopher Lee
_ = t.insert("dracula", age: year - 1966) //  ""
_ = t.insert("dracula", age: year - 1970) //  ""
_ = t.insert("dracula", age: year - 1979) // Frank langella
_ = t.insert("dracula", age: year - 1992) // Gary Oldman

print("Wait on, we can't have 500 year old schoolkids!")
for row in t.ageIndex.search(equalTo: 500) {
    print("Deleting impossible entry \(row.name), \(row.age)")
    t.delete(row)
}

print("Walking nameIndex:")
var lastName = ""
for (key, row) in t.nameIndex {
    if key != lastName {
        print("  Key: \(key)")
        lastName = key
    }
    print("    Name: \(row.name), age: \(row.age)")
}
print("Walking ageIndex:")
var lastAge = -1
for (key, row) in t.ageIndex {
    if key != lastAge {
        print("  Key: \(key)")
        lastAge = key
    }
    print("    Name: \(row.name), age: \(row.age)")
}

print("Queries...")
print("  Query: age from: 8 to: 50 // not including 50")
for (key, row) in t.ageIndex.query(from: 8, to: 50) {
    print("    Name: \(row.name), age: \(row.age)")
}
print("  Query: age from: 8 through: 50 // including 50")
for (key, row) in t.ageIndex.query(from: 8, through: 50) {
    print("    Name: \(row.name), age: \(row.age)")
}
print("  Query: name from: \"A\" through: \"Z~\")")
for (key, row) in t.nameIndex.query(from: "A", through: "Z~") {
    print("    Name: \(row.name), age: \(row.age)")
}

print("Unique and optional columns")
var nextID = 627846
for (key, row) in t.nameIndex {
    try row.setStudentID("CC\(nextID)")
    nextID += 1
}
print("Initial student IDs")
for (key, row) in t.studentIDIndex {
    print("Name: \(row.name) ID: \(key)")
}
print("Setting dracula to XXXXXXXX - should have several failures")
for row in t.nameIndex.search(equalTo: "dracula") {
    do {
        try row.setStudentID("XXXXXXXX")
    } catch {
        print(error)
    }
}
print("Setting dracula to nil - should always succeed")
for row in t.nameIndex.search(equalTo: "dracula") {
    do {
        try row.setStudentID(nil)
    } catch {
        print(error)
    }
}
print("Deleting rats and mice (fully indexed)")
for row in t.nameIndex.search(equalTo: "monty") { t.delete(row) }
for row in t.nameIndex.search(equalTo: "gadget") { t.delete(row) }
for row in t.nameIndex.search(equalTo: "mickey") { t.delete(row) }
print("Deleting young draculas (no Student ID index)")
var rows: [TableRow] = t.nameIndex.search(equalTo: "dracula")
for row in rows {
    if row.age < 50 {
        t.delete(row)
    }
}
print("Final entries")
for (key, row) in t.nameIndex {
    print("Name: \(key), Age: \(row.age), ID: \(row.getStudentID())")
}
print("Final student IDs")
for (key, row) in t.studentIDIndex {
    print("Name: \(row.name) ID: \(key)")
}

print("\nSpeed test")
func randomString(_ length: Int = 6) -> String {
    let letters = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    var string = ""
    for _ in 0..<length {
        let j = Int(drand48() * 26)
        string += letters[j]
    }
    return string
}
func forfake () -> Int {
    let t0 = clock()
    var tLast = t0 - t0
    for i in 1...1000000 {
        let name = randomString(6)
        if i % 100000 == 0 {
            let tNext = clock() - t0
            print("Not inserting \(name), \(i) at \(Int(tNext) - Int(tLast))µs")
            tLast = tNext
        }
    }
    let tFinal = clock() - t0
    print("Total for fake \(tFinal)µs")
    return Int(tFinal)
}
let overhead = forfake()
func forskiplists() -> Int {
    let t0 = clock()
    var tLast = t0 - t0
    for i in 1...1000000 {
        let name = randomString(6)
        if i % 100000 == 0 {
            let tNext = clock() - t0
            print("Inserting \(name), \(i) at \(Int(tNext) - Int(tLast))µs")
            tLast = tNext
        }
        l.insert(key: name, value: String(i))
    }
    let tFinal = clock() - t0
    print("Total for skiplists \(tFinal)µs")
    return Int(tFinal)
}
let skiplists = forskiplists()
print("Skiplists delta: \(skiplists - overhead)µs, \(((skiplists - overhead) / overhead) * 100)%")
func forspeedtables() -> Int {
    let t0 = clock()
    var tLast = t0 - t0
    for i in 1...1000000 {
        let name = randomString(6)
        if i % 100000 == 0 {
            let tNext = clock() - t0
            print("Inserting \(name), \(i) at \(Int(tNext) - Int(tLast))µs")
            tLast = tNext
        }
        _ = t.insert(name, age: i)
    }
    let tFinal = clock() - t0
    print("Total for speedtables \(tFinal)µs")
    return Int(tFinal)
}
let speedtables = forspeedtables()
print("Speedtables delta: \(speedtables - overhead)µs, \(((speedtables - overhead) / overhead) * 100)%")

