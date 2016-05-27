//
//  speedtable-example.swift
//  skiplists
//
//  Created by Peter da Silva on 5/27/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

class Table: SpeedTable {
    let nameIndex: SkipList<String, TableRow>
    let ageIndex: SkipList<Int, TableRow>
    init(size: Int) {
        nameIndex = SkipList<String, TableRow>(maxLevel: size)
        ageIndex = SkipList<Int, TableRow>(maxLevel: size)
    }
    func insert(name: String, age: Int, school: String? = nil) -> TableRow{
        return TableRow(parent: self, name: name, age: age, school: school)
    }
    func delete(row: TableRow) {
        self.nameIndex.delete(row.name, value: row)
        self.ageIndex.delete(row.age, value: row)
    }
}

class TableRow: SpeedTableRow, Equatable {
    let parent: Table
    var name: String {
        willSet { parent.nameIndex.delete(name, value: self) }
        didSet { parent.nameIndex.insert(name, value: self) }
    }
    var age: Int {
        willSet { parent.ageIndex.delete(age, value: self) }
        didSet { parent.ageIndex.insert(age, value: self) }
    }
    var school: String? // Unindexed value
    init(parent: Table, name: String, age: Int, school: String? = nil) {
        self.parent=parent
        self.name = name
        self.age = age
        parent.nameIndex.insert(self.name, value: self)
        parent.ageIndex.insert(self.age, value: self)
    }
}

// We need to provide this to allow the comparison in Skiplist.insert to work
func ==(lhs: TableRow, rhs: TableRow) -> Bool {
    return lhs === rhs
}
