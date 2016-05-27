## Overview

This is a work in progress. The goal of this project is to create a multi-way indexed relation in Swift. The API is expected to be something like...

```swift
class Table: SpeedTable {
    let nameIndex: SkipList<String, TableRow>
    let ageIndex: SkipList<Int, TableRow>
    init(size: Int) {
        nameIndex = SkipList<String, TableRow>(maxLevel: size)
        ageIndex = SkipList<Int, TableRow>(maxLevel: size)
    }
    func create(name: String, age: Int, school: String? = nil) -> TableRow{
        return TableRow(parent: self, name: name, age: age, school: school)
    }
    func destroy(row: TableRow) {
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

Then you would be able to do operations like:

```swift
for row in table.nameIndex.search(equal: myName) {
	if(row.age > = 16) {
		row.school = "senior"
	}
}
```

Anticipated operations include search(equal: exactValue), search(min: min, max: max), search(in: [value, value, value])...

Searches are not initially going to be transactionalized, modifying the indexed value or inserting or deleting rows in a search is not supported.

Keys will be duplicated in the table. If the key is a mutable type, changing the key through a mutating function will not change the index... you will have to delete before the change and re-insert afterwards.
