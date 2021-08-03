//
//  Megabytes.swift
//  
//
//  Created by Michael Critz on 8/1/21.
//

public typealias Megabytes = Double

extension Megabytes {
    public var bytesInt: Int {
        Int(self * 1048576) // (1024 * 1024)
    }
}
