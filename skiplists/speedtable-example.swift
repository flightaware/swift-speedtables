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
        willSet { _ = parent!.nameIndex.delete(name, value: self) }
        didSet {
            do {
                try self.parent!.nameIndex.insert(name, value: self)
            } catch {
                
            }
        }
    }
    var age: Int {
        willSet { _ = parent!.ageIndex.delete(age, value: self) }
        didSet {
            do {
                try self.parent!.ageIndex.insert(age, value: self)
            } catch {
                
            }
        }
    }
    var school: String? // Unindexed value
    var studentIDStorage: String? // unique optional value
    func getStudentID() -> String? {
        return studentIDStorage
    }
    func setStudentID(_ ID: String?) throws {
        try parent!.studentIDIndex.replace(ID, keyStore: &studentIDStorage, value: self)
    }
    init(parent: Table, name: String, age: Int) {
        self.parent = parent
        self.name = name
        self.age = age
        // This needs to be done explicitly because the willSet/didSet doesn't
        // fire on initialization.
        do {
            try parent.nameIndex.insert(self.name, value: self)
        } catch {
            // can't happen, only reason insert can throw is if it's not unique
        }
        do {
            try parent.ageIndex.insert(self.age, value: self)
        } catch {
            // can't happen, only reason insert can throw is if it's not unique
        }
    }
    func delete() {
        _ = parent!.nameIndex.delete(name, value: self)
        _ = parent!.ageIndex.delete(age, value:self)
        if let ID = studentIDStorage {
            _ = parent!.studentIDIndex.delete(ID, value:self)
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
