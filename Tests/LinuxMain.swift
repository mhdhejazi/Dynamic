// sourcery:inline:LinuxMain
import XCTest

import DynamicTests

extension DynamicTests {
  static var allTests = [
    ("testInit", testInit),
    ("testInitWithParameters", testInitWithParameters),
    ("testClassMethods", testClassMethods),
    ("testProperties", testProperties),
    ("testBlocks", testBlocks),
    ("testExplicitUnwrapping", testExplicitUnwrapping),
    ("testImplicitUnwrapping", testImplicitUnwrapping),
    ("testEdgeCases", testEdgeCases),
    ("testAlternativeMethodNames", testAlternativeMethodNames),
    ("testHiddenAPI", testHiddenAPI)
  ]
}

XCTMain([
  testCase(DynamicTests.allTests)
])
// sourcery:end
