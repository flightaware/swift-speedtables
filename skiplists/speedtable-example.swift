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
        nameIndex = SkipList<String, TableRow>(maxLevel: maxLevel)
        ageIndex = SkipList<Int, TableRow>(maxLevel: maxLevel)
        studentIDIndex = SkipList<String, TableRow>(maxLevel: maxLevel)
    }
    init(size: Int) {
        nameIndex = SkipList<String, TableRow>(maxNodes: size)
        ageIndex = SkipList<Int, TableRow>(maxNodes: size)
        studentIDIndex = SkipList<String, TableRow>(maxNodes: size)
    }
    func insert(_ name: String, age: Int) -> TableRow {
        // Creating the table row does all the insertion stuff
        return TableRow(parent: self, name: name, age: age)
    }
    func delete(_ row: TableRow) {
        // delegate to row
        row.delete()
    }
}

// Each speedtable requires two classes, one for the table as a whole, one for
// the row holding the data
class TableRow: SpeedTableRow, Equatable {
    var parent: Table?
    var name: String {
        willSet { _ = parent!.nameIndex.delete(key: name, value: self) }
        didSet { self.parent!.nameIndex.insert(key: name, value: self) }
    }
    var age: Int {
        willSet { _ = parent!.ageIndex.delete(key: age, value: self) }
        didSet { self.parent!.ageIndex.insert(key: age, value: self) }
    }
    var school: String? // Unindexed value
    var studentIDStorage: String? // unique optional value
    func getStudentID() -> String? {
        return studentIDStorage
    }
    func setStudentID(_ ID: String?) throws {
        if let key = ID {
            if parent!.studentIDIndex.exists(key: key) {
                throw SpeedTableError.keyNotUnique(key: key);
            }
        }
        parent!.studentIDIndex.replace(newKey: ID, keyStore: &studentIDStorage, value: self)
    }
    init(parent: Table, name: String, age: Int) {
        self.parent = parent
        self.name = name
        self.age = age
        // This needs to be done explicitly because the willSet/didSet doesn't
        // fire on initialization.
        parent.nameIndex.insert(key: self.name, value: self)
        parent.ageIndex.insert(key: self.age, value: self)
    }
    func delete() {
        _ = parent!.nameIndex.delete(key: name, value: self)
        _ = parent!.ageIndex.delete(key: age, value:self)
        if let ID = studentIDStorage {
            _ = parent!.studentIDIndex.delete(key: ID, value:self)
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
