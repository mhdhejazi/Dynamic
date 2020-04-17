import XCTest

import DynamicTests

var tests = [XCTestCaseEntry]()
tests += DynamicTests.allTests()
XCTMain(tests)
