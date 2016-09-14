//
//  speedtables.swift
//  skiplists
//
//  Created by Peter da Silva on 5/31/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

import Foundation

protocol SpeedTable {
}

protocol SpeedTableRow {
}

// Skiplist errors
public enum SpeedTableError<Key>: Error {
    case keyNotUnique(key: Key)
}
