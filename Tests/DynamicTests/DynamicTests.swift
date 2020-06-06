import XCTest

@testable import Dynamic

final class DynamicTests: XCTestCase {
    class override func setUp() {
        Dynamic.loggingEnabled = true
        Logger.enabled = false
    }

    func testInit() {
        let className = "NSDateFormatter"

        let formatter1 = ObjC.NSDateFormatter()
        XCTAssertEqual(formatter1.asObject?.className, className, "Parameterless init")
        XCTAssert(formatter1.asObject is DateFormatter, "Parameterless init - Bridging")

        let formatter2 = ObjC.NSDateFormatter.`init`()
        XCTAssertEqual(formatter2.asObject?.className, className, "Parameterless init with explicit init")
    }

    func testInitWithParameters() {
        let uuidString = "68753A44-4D6F-1226-9C60-0050E4C00067"
        let className = "__NSConcreteUUID"

        let uuid1 = ObjC.NSUUID(UUIDString: uuidString)
        XCTAssertEqual(uuid1.asObject?.className, className, "Parameterized init")
        XCTAssertEqual(uuid1.UUIDString.asString, uuidString)

        let uuid2 = ObjC.NSUUID.initWithUUIDString(uuidString)
        XCTAssertEqual(uuid2.asObject?.className, className, "Parameterized init with explicit init")
        XCTAssertEqual(uuid2.UUIDString.asString, uuidString)
    }

    func testClassMethods() {
        let uuidClassName = "__NSConcreteUUID"
        let uuid = ObjC.NSUUID.UUID()
        XCTAssertEqual(uuid.asObject?.className, uuidClassName, "Class methods")

        let exceptionClassName = "NSException"
        let name = "Dummy"
        let reason = "Testing"
        let userInfo = ["Foo": "Bar"] as NSDictionary
        let exception = ObjC.NSException.exceptionWithName(name, reason: reason, userInfo: userInfo)
        XCTAssertEqual(exception.asObject?.className, exceptionClassName, "Class methods")
        XCTAssertEqual(exception.name.asString, name, "Properties passed to the constructor")
        XCTAssertEqual(exception.reason.asString, reason, "Properties passed to the constructor")
        XCTAssertEqual(exception.userInfo.asDictionary, userInfo, "Properties passed to the constructor")
    }

    func testProperties() {
        let host = "example.com"
        let urlString = "https://\(host)/"
        let urlComponents = ObjC.NSURLComponents.componentsWithString(urlString)
        XCTAssertEqual(urlComponents.host.asString, host, "Properties passed to the constructor")

        let host2 = "example2.com"
        urlComponents.host = host2
        XCTAssertEqual(urlComponents.host.asString, host2, "Setting properties")

        let queryItems = [NSURLQueryItem(name: "foo", value: "bar")] as NSArray
        urlComponents.queryItems = queryItems
        XCTAssertEqual(urlComponents.queryItems.asArray, queryItems, "Setting properties")
        XCTAssertEqual(urlComponents.URL, NSURL(string: "https://example2.com/?foo=bar"))

        let progress = ObjC.NSProgress.progressWithTotalUnitCount(100)
        progress.completedUnitCount = 50
        XCTAssertEqual(progress.fractionCompleted, 0.5, "Setting numeric properties")
    }

    func testBlocks() {
        // swiftlint:disable:next nesting
        typealias VoidBlock = @convention(block) () -> Void

        let closure1Called = expectation(description: "Closure 1")
        let progress = ObjC.NSProgress.progressWithTotalUnitCount(100)
        progress.cancellationHandler = {
            closure1Called.fulfill()
        } as VoidBlock
        progress.cancel()

        let closure2Called = expectation(description: "Closure 2")
        let operation = ObjC.NSBlockOperation.blockOperationWithBlock({
            closure2Called.fulfill()
        } as VoidBlock)
        ObjC.NSOperationQueue.mainQueue.addOperation(operation)

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testExplicitUnwrapping() {
        // swiftlint:disable:next nesting
        struct NSOperatingSystemVersion {
            var majorVersion: Int
            var minorVersion: Int
            var patchVersion: Int
        }

        let processInfo1 = ProcessInfo.processInfo
        let processInfo2 = ObjC.NSProcessInfo.processInfo

        XCTAssertEqual(processInfo1.processIdentifier,
                       processInfo2.processIdentifier.asInt32, "Int32")
        XCTAssertEqual(processInfo1.processorCount,
                       processInfo2.processorCount.asInt, "Int")
        XCTAssertEqual(processInfo1.physicalMemory,
                       processInfo2.physicalMemory.asUInt64, "UInt64")
        XCTAssertEqual(processInfo1.systemUptime,
                       processInfo2.systemUptime.asDouble ?? 0, accuracy: 1, "Double")
        XCTAssertEqual(processInfo1.arguments as NSArray,
                       processInfo2.arguments.asArray, "Array")
        XCTAssertEqual(processInfo1.arguments,
                       processInfo2.arguments.asInferred(), "Array")
        XCTAssertEqual(processInfo1.environment as NSDictionary,
                       processInfo2.environment, "Dictionary")
        XCTAssertEqual(processInfo1.processName,
                       processInfo2.processName.asString, "String")

        let version1 = processInfo1.operatingSystemVersion
        let version2: NSOperatingSystemVersion? = processInfo2.operatingSystemVersion.asInferred()
        XCTAssertEqual(version1.majorVersion,
                       version2?.majorVersion, "Struct")

        XCTAssertEqual(processInfo1.isOperatingSystemAtLeast(version1),
                       processInfo2.isOperatingSystemAtLeastVersion(version2).asBool, "Bool")
    }

    func testImplicitUnwrapping() {
        // swiftlint:disable:next nesting
        struct NSOperatingSystemVersion {
            var majorVersion: Int
            var minorVersion: Int
            var patchVersion: Int
        }

        let processInfo1 = ProcessInfo.processInfo
        let processInfo2 = ObjC.NSProcessInfo.processInfo

        XCTAssertEqual(processInfo1.processIdentifier,
                       processInfo2.processIdentifier, "Int32")
        XCTAssertEqual(processInfo1.processorCount,
                       processInfo2.processorCount, "Int")
        XCTAssertEqual(processInfo1.physicalMemory,
                       processInfo2.physicalMemory, "UInt64")
        XCTAssertEqual(processInfo1.systemUptime,
                       processInfo2.systemUptime ?? 0, accuracy: 1, "Double")
        XCTAssertEqual(processInfo1.arguments,
                       processInfo2.arguments, "Array")
        XCTAssertEqual(processInfo1.environment,
                       processInfo2.environment, "Dictionary")
        XCTAssertEqual(processInfo1.processName,
                       processInfo2.processName, "String")

        let version1 = processInfo1.operatingSystemVersion
        let version2: NSOperatingSystemVersion? = processInfo2.operatingSystemVersion
        XCTAssertEqual(version1.majorVersion,
                       version2?.majorVersion, "Struct")

        XCTAssertEqual(processInfo1.isOperatingSystemAtLeast(version1),
                       processInfo2.isOperatingSystemAtLeastVersion(version2), "Bool")

        let formatter1 = ObjC.NSDateFormatter()
        XCTAssertTrue(type(of: formatter1) == Dynamic.self)

        let formatter2: NSObject? = ObjC.NSDateFormatter()
        XCTAssertEqual(formatter2?.className, "NSDateFormatter")

        let formatter3 = { () -> NSObject? in
            ObjC.NSDateFormatter()
        }()
        XCTAssertEqual(formatter3?.className, "NSDateFormatter")

        formatter1.dateFormat = ObjC("yyyy-MM-dd HH:mm:ss")
        let date = ObjC.NSDate(timeIntervalSince1970: 1_600_000_000)
        let string: String? = formatter1.stringFromDate(date)
        let newDate: Date? = formatter1.dateFromString(string)
        XCTAssertEqual(date.asInferred(), newDate)
        XCTAssertEqual(date.asObject, formatter1.dateFromString(formatter1.stringFromDate(date)))
    }

    func testEdgeCases() {
        let error = ObjC.NSDateFormatter().invalidMethod()
        XCTAssertTrue(error.asObject is Error)
    }
}

extension NSObject {
    var className: String { String(describing: type(of: self)) }
}
