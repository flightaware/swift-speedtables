## Overview

This is a work in progress. The goal of this project is to create a multi-way indexed relation in Swift. The API is expected to be something like...

```swift
class Table: SpeedTable {
	let nameIndex: Skiplist<String, TableRow>
	let ageIndex: Skiplist<Int, TableRow>
	init(size: Int) {
		nameIndex = Skiplist<String, TableRow>(size)>
		ageIndex = Skiplist<Int, TableRow>(size)>
	}
	func create(name: String, age: Int, school: string = nil) -> TableRow{
		return TableRow(parent: self, name: name, age: age, school: school)
	}
	func destroy(row: TableRow) {
		row.nameIndex.delete(row.name, row)
		row.ageIndex.delete(row.age, row)
	}
}

class TableRow: SpeedTableRow {
	let parent: Table
	var name: String {
		willSet { parent.nameIndex.delete(name, self) }
		didSet { parent.nameIndex.insert(name, self) }
	}
	var age: Int {
		willSet { parent.ageIndex.delete(age, self) }
		didSet { parent.ageIndex.insert(age, self) }
	}
	var school: String? // Unindexed value
	init(parent: Table, name: String, age: Int, school: string = nil) {
		self.parent=parent
		self.name = name
		parent.nameIndex.insert(self.name, self)
		self.age = age
		parent.ageIndex.insert(self.age, self)
	}
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

Searches are not initially going to be transcationalized, modifying the indexed value or inserting or deleting rows in a search is not supported.

Keys will be duplicated in the table. If the key is a mutable type, changing the key through a mutating function will not change the index... you will have to delete before the change and re-insert afterwards.
