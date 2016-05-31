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
let hellos: [String] = l.search(equalTo: "hello")
for hello in hellos {
    print("hello is '\(hello)'")
}

l.insert("goodbye", value: "Goodnight America, and all the ships at sea")
print(l.toArray())

func delete_all(l: SkipList<String, String>, key: String) {
    for val in l.search(equalTo: key) {
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
t.insert("Nick", age: 32) // "200 dollars a day since I was twelve"
t.insert("Judy", age: 22) // Guess
t.insert("chip", age: 5) // How old can a chipmunk be?
t.insert("dale", age: 5)

// This is actually ugly: ".NSYearYalendarUnit" is deprecated, but the replacement ".NSCalendarUnitYear" is not found
let year = NSCalendar.currentCalendar().components(.NSYearCalendarUnit, fromDate: NSDate()).year
t.insert("mickey", age: year - 1928) // Steamboat Willie
t.insert("bugs", age: year - 1940) // A Wild Hare

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
t.insert("gadget", age: 5)
t.insert("monty", age: 8)

print("Adding dwarves. Dwarves are really old")
t.insert("happy", age: 500)
t.insert("sleepy", age: 500)
t.insert("grumpy", age: 500)

print("Adding vampires. They're really old too, and some have multiple ages")
t.insert("lestat", age: 500)
t.insert("dracula", age: 500)
t.insert("dracula", age: year - 1897) // Book
t.insert("dracula", age: year - 1931) // Bella Lugosi
t.insert("dracula", age: year - 1958) // Christopher Lee
t.insert("dracula", age: year - 1966) //  ""
t.insert("dracula", age: year - 1970) //  ""
t.insert("dracula", age: year - 1979) // Frank langella
t.insert("dracula", age: year - 1992) // Gary Oldman

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


