## Overview

This is a work in progress. The goal of this project is to create a multi-way indexed relation in Swift. Right now creating an indexed table is pretty manual:

```swift
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
        self.nameIndex.delete(row.name, searchValue: row)
        self.ageIndex.delete(row.age, searchValue: row)
    }
}

class TableRow: SpeedTableRow, Equatable {
    let parent: Table
    var name: String {
        willSet { parent.nameIndex.delete(name, searchValue: self) }
        didSet { parent.nameIndex.insert(name, value: self) }
    }
    var age: Int {
        willSet { parent.ageIndex.delete(age, searchValue: self) }
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
```

Eventually, we would like to have this created by a little applet that takes a Tcl
speedtable definition and generates this framework.

There are a few perations you can do on an index right now. The first two are implicit
in the above definition.

* ```table.insert(column, column, column...)```

Insert a new row into the table, and all indexes, returns the row... or you can search for the row later.

* ```table.delete(row)```

Delete a row from the table, deletes it from all the indexes.

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

For more complex searches, we are anticipating creating a query object:

* ```let query = skiplist.query(lessThan: key)```
* ```let query = skiplist.query(greaterThan: key)```
* ```let query = skiplist.query(between: key, and: key)```
* ```let query = skiplist.query(equalTo: key)```
* ```let query = skiplist.query(in: [keys])```
* ```let query = skiplist.query(matching: (key) -> Bool)```

The query object will have the functions:

* ```let (key, value) = query.first```
* ```let (key, value) = query.next```
* ```for (key, value) in query { ... }```
