## Overview

This is a work in progress. The goal of this project is to create a multi-way indexed relation in Swift. Right now creating an indexed table is pretty manual:

```swift
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
    init(size: Int) {
        nameIndex = SkipList<String, TableRow>(maxLevel: size, unique: false)
        ageIndex = SkipList<Int, TableRow>(maxLevel: size, unique: false)
        studentIDIndex = SkipList<String, TableRow>(maxLevel: size, unique: true)
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
    var name: String {
        willSet { parent!.nameIndex.delete(name, value: self) }
        didSet { parent!.nameIndex.insert(name, value: self) }
    }
    var age: Int {
        willSet { parent!.ageIndex.delete(age, value: self) }
        didSet { parent!.ageIndex.insert(age, value: self) }
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
        self.name = name
        self.age = age
        // This needs to be done  explicitly because the willSet/didSet doesn't
        // fire on initialization.
        parent.nameIndex.insert(self.name, value: self)
        parent.ageIndex.insert(self.age, value: self)
    }
    func delete() {
        parent!.nameIndex.delete(name, value: self)
        parent!.ageIndex.delete(age, value:self)
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

Indexes are skiplists:
 
* ```thingIndex = SkipList<Type, TableRow>(maxLevel, unique, errorHandler)```
* ```thingIndex = SkipList<Type, TableRow>(maxSize, unique, errorHandler)```

** maxLevel - maximum depth of the list, at least log(2) maximum nodes
** maxSize - maximum number of nodes (convenience init)
** unique - true if the index is unique
** errorHandler: A function to handle background errors: ((SkipListError<Key>) -> Void) - required for catching non-unique entries on a unique index.

The operations on indexes are:

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

Performance:

Currently performance of Skiplists in Swift are about 1/10th the performance of Skiplists in C. There are a number of reasons for this:

1. It's proving very difficult to avoid redundant retains and releases while stepping through the list. Various code tweaks have reduced this by a factor of about 10 from the original implementation, at the cost of safety. The best performance is in the "unmanaged" branch..

2. Similarly, the C code does no bounds checking on arrays. Swift does so on every access.

3. The C code is using completely preallocated arrays, so an insert only needs to allocate a fixed length record and possibly a copy of the key. Swift has to call initializers for arrays, strings, keys, and values.


Notes:

On performing a deletion, it would seem only necessary to update the next pointer as far as the level of the node being deleted. The Skiplist paper updated all the way to the highest level in the list. 
