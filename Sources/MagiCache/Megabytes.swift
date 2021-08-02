//
//  Megabytes.swift
//  
//
//  Created by Michael Critz on 8/1/21.
//

typealias Megabytes = Double

extension Megabytes {
    var bytesInt: Int {
        Int(self * 1048576) // (1024 * 1024)
    }
}
