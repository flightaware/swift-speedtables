//
//  speedtable-example.swift
//  skiplists
//
//  Created by Peter da Silva on 5/27/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

// Manually generated speedtable definition. This can be automatically generated
// from something SQL-ish like:
// TABLE Table (
//     String name indexed
//     Int age indexed
//     String school optional
//     String studentID unique primary
// )
class Table: SpeedTable {
    let nameIndex: SkipList<String, TableRow>
    let ageIndex: SkipList<Int, TableRow>
    init(size: Int) {
        nameIndex = SkipList<String, TableRow>(maxLevel: size)
        ageIndex = SkipList<Int, TableRow>(maxLevel: size)
    }
    func insert(name: String, age: Int, school: String? = nil) -> TableRow {
        // Creating the table row does all the insertion stuff
        return TableRow(parent: self, name: name, age: age, school: school)
    }
    func delete(row: TableRow) {
        // Have to manually unthread the row from all lists -- possibly
        // this should be moved into the row definition?
        self.nameIndex.delete(row.name, value: row)
        self.ageIndex.delete(row.age, value: row)
        // break the link to myself 
        row.parent = nil
    }
}

// Each speedtable requires two classes, one for the table as a whole, one for
// the row holding the data
class TableRow: SpeedTableRow, Equatable {
    var parent: Table?
    var name: String {
        willSet { parent!.nameIndex.delete(name, value: self) }
        didSet { parent!.nameIndex.insert(name, value: self) }
    }
    var age: Int {
        willSet { parent!.ageIndex.delete(age, value: self) }
        didSet { parent!.ageIndex.insert(age, value: self) }
    }
    var school: String? // Unindexed value
    init(parent: Table, name: String, age: Int, school: String? = nil) {
        self.parent = parent
        self.name = name
        self.age = age
        // This needs to be done  explicitly because the willSet/didSet doesn't
        // fire on initialization.
        parent.nameIndex.insert(self.name, value: self)
        parent.ageIndex.insert(self.age, value: self)
    }
    // possibly do this here? Then Table.delete(row) just becomes row.delete()?
    func delete() {
        parent!.nameIndex.delete(name, value: self)
        parent!.ageIndex.delete(age, value:self)
        parent = nil
    }
}

// This function can be anything guaranteed unique for the table. We're using === here
// but it can be a unique key within the row instead, if there is one. Possibly a "primary
// key" field in the generator can be used to drive this.
func ==(lhs: TableRow, rhs: TableRow) -> Bool {
    return lhs === rhs
}
