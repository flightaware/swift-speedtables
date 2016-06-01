## Overview

This is a work in progress. The goal of this project is to create a multi-way indexed relation in Swift. Right now creating an indexed table is pretty manual:

```swift
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
```

Eventually, we would like to have this created by a little applet that takes a Tcl
or SQL-ish speedtable definition and generates this framework.

There are a few operations you can do on a table right now. The first two are implicit
in the above definition.

* ```table.insert(column, column, column...)```

Insert a new row into the table, and all indexes, returns the row... or you can search for the row later.

* ```table.delete(row)```

Delete a row from the table, unthreads it from all the indexes and unlinks it from the table.

* ```row.column = value```

When you update a column in a row, it updates the index on the column automatically.

The rest of the operations are implied by the behaviour of the indexes (skiplists), for
example:

```swift
for row in table.nameIndex.search(equal: myName) {
	if(row.age > = 16) {
		row.school = "senior"
	}
}
```

The operations are:

* ```skiplist.search(key)```

Search looks up a key and returns an array of rows that match the key. This is just a simple skiplist lookup.

* ```skiplist.insert(key, value)```
* ```skiplist.delete(key, value)```

You will not be using these directly in speedtables. The insert and delete a key-value pair from the index.

* ```for (key, value) in skiplist```

Walks the entire skiplist and returns all the key-value pairs. The value in a speedtable will be a speedtable row.

* ```for (key, value) in skiplist.query(lessThan: key)```
* ```for (key, value) in skiplist.query(lessThanOrEqual: key)```
* ```for (key, value) in skiplist.query(greaterThan: key)```
* ```for (key, value) in skiplist.query(greaterThanOrEqual: key)```
* ```for (key, value) in skiplist.query(from: key, to: key)```
* ```for (key, value) in skiplist.query(from: key, through: key)```

There is no "equalTo" because skiplist.search() already provides this functionality
directly.

These are all convenience functions on the general:

* ```for (key value) in skiplist.query(min: key, max: key, minEquals: Bool, maxEquals: Bool)```

The query object actually suports two mechanisms for walking the results, either the
generator implied above, or the functions:

* ```(key, value)? = query.first()```
* ```(key, value)? = query.next()```

