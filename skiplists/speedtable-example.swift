//
//  speedtable-example.swift
//  skiplists
//
//  Created by Peter da Silva on 5/27/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

// Manually generated speedtable definition. This could be automatically generated
// from something SQL-ish like:
// TABLE Table (
//     String name indexed
//     Int age indexed
//     String school optional
//     String studentID unique optional indexed
// )
class Table: SpeedTable {
    let nameIndex: SkipList<String, TableRow>
    let ageIndex: SkipList<Int, TableRow>
    let studentIDIndex: SkipList<String, TableRow>
    init(maxLevel: Int) {
        nameIndex = SkipList<String, TableRow>(maxLevel: maxLevel, unique: false)
        ageIndex = SkipList<Int, TableRow>(maxLevel: maxLevel, unique: false)
        studentIDIndex = SkipList<String, TableRow>(maxLevel: maxLevel, unique: true)
    }
    init(size: Int) {
        nameIndex = SkipList<String, TableRow>(maxNodes: size, unique: false)
        ageIndex = SkipList<Int, TableRow>(maxNodes: size, unique: false)
        studentIDIndex = SkipList<String, TableRow>(maxNodes: size, unique: true)
    }
    func insert(name: String, age: Int) -> TableRow {
        // Creating the table row does all the insertion stuff
        return TableRow(parent: self, name: name, age: age)
    }
    func delete(row: TableRow) {
        // delegate to row
        row.delete()
    }
}

// Each speedtable requires two classes, one for the table as a whole, one for
// the row holding the data
class TableRow: SpeedTableRow, Equatable {
    var parent: Table?
    var nameStorage: String
    func getName() -> String {
        return nameStorage
    }
    func setName(name: String) throws {
        try parent!.nameIndex.replace(name, keyStore: &nameStorage, value: self)
    }
    var ageStorage: Int
    func getAge() -> Int {
        return ageStorage
    }
    func setAge(age: Int) throws {
        try parent!.ageIndex.replace(age, keyStore: &ageStorage, value: self)
    }
    var school: String? // Unindexed value
    var studentIDStorage: String? // unique optional value
    func getStudentID() -> String? {
        return studentIDStorage
    }
    func setStudentID(ID: String?) throws {
        try parent!.studentIDIndex.replace(ID, keyStore: &studentIDStorage, value: self)
    }
    init(parent: Table, name: String, age: Int) {
        self.parent = parent
        // We set these directly because the setter requires the index key be initialized
        self.nameStorage = name
        self.ageStorage = age
        parent.nameIndex.insert(name, value: self)
        parent.ageIndex.insert(age, value: self)
    }
    func delete() {
        parent!.nameIndex.delete(nameStorage, value: self)
        parent!.ageIndex.delete(ageStorage, value:self)
        if let ID = studentIDStorage {
            parent!.studentIDIndex.delete(ID, value:self)
        }
        parent = nil // do not modify a row after it's deleted!
    }
}

// This function can be anything guaranteed unique for the table. We're using === here
// but it can be a unique key within the row instead, if there is one. Possibly a "primary
// key" field in the generator can be used to drive this.
func ==(lhs: TableRow, rhs: TableRow) -> Bool {
    return lhs === rhs
}
