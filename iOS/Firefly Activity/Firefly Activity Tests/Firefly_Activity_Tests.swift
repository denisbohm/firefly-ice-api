//
//  Firefly_Activity_Tests.swift
//  Firefly Activity Tests
//
//  Created by Denis Bohm on 3/12/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import XCTest
@testable import Firefly_Activity

class Firefly_Activity_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func getSize(log: Log) -> Int {
        let url = try! log.getURL()
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes?[FileAttributeKey.size] as? UInt64 ?? 0
        return Int(fileSize)
    }
    
    func testExample() throws {
        let log = Log()
        let url = try log.getURL()
        try? FileManager.default.removeItem(at: url)
        let message = "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        for _ in 0 ..< 1000 {
            log.append(message: message) // 100 bytes
        }
        XCTAssertEqual(getSize(log: log), 100000)
        log.append(message: "last")
        XCTAssertEqual(getSize(log: log), 50000)
        let content = try String(contentsOf: url)
        XCTAssert(content.hasSuffix("last\n"))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
