//
//  URL+isDirectory.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/20/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import Foundation

extension URL {
    var isDirectory: Bool {
        let values = try? resourceValues(forKeys: [.isDirectoryKey])
        return values?.isDirectory ?? false
    }
}
