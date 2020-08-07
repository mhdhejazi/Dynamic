import XCTest

@testable import Dynamic

final class DynamicTests: XCTestCase {
    class override func setUp() {
        Dynamic.loggingEnabled = true
//        Logger.enabled = false
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

        let queue = ObjC.NSOperationQueue()
        XCTAssertFalse(queue.isSuspended!)
        queue.isSuspended = true
        XCTAssertTrue(queue.isSuspended!, "Setting boolean properties with 'is' prefix")
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
        XCTAssertTrue(type(of: formatter1) == Dynamic.self, "Type should be Dynamic")

        let formatter2: NSObject? = ObjC.NSDateFormatter()
        XCTAssertEqual(formatter2?.className, "NSDateFormatter", "Value isn't unwrapped")

        let formatter3 = { () -> NSObject? in
            ObjC.NSDateFormatter()
        }()
        XCTAssertEqual(formatter3?.className, "NSDateFormatter", "Value isn't unwrapped")

        formatter1.dateFormat = ObjC("yyyy-MM-dd HH:mm:ss")
        let date = ObjC.NSDate(timeIntervalSince1970: 1_600_000_000)
        let string: String? = formatter1.stringFromDate(date)
        let newDate: Date? = formatter1.dateFromString(string)
        XCTAssertEqual(date.asInferred(),
                       newDate, "Value isn't unwrapped")

        XCTAssertEqual(date.asObject,
                       formatter1.dateFromString(formatter1.stringFromDate(date)), "Value isn't unwrapped")
    }

    func testEdgeCases() {
        let error = ObjC.NSDateFormatter().invalidMethod()
        XCTAssertTrue(error.asObject is Error, "Calling non existing method should return error")
        XCTAssertTrue(error.isError, "isError should return true for errors")

        let errorChained = error.thisMethodCallHasNoEffect(123).randomProperty
        XCTAssertTrue(errorChained === error, "Calling methods and properties form error should return the same object")

        let null = ObjC.nil
        XCTAssertNil(null.asObject, "Wrapped nil should return nil")

        let nullChained = null.thisMethodCallHasNoEffect(123).randomProperty
        XCTAssertTrue(nullChained === null, "Calling methods and properties form <nil> should return the same object")

        let formatter = ObjC.NSDateFormatter()
        XCTAssertEqual(formatter.stringFromDate(Date()), "", "Should return an empty string")
        formatter.dateFormat = ObjC("yyyy-MM-dd HH:mm:ss")
        XCTAssertNotEqual(formatter.stringFromDate(Date()), "", "Should NOT return an empty string")

        formatter.dateFormat = .nil
        XCTAssertEqual(formatter.stringFromDate(Date()), "", "Should return an empty string")
        formatter.dateFormat = ObjC("yyyy-MM-dd HH:mm:ss")
        XCTAssertNotEqual(formatter.stringFromDate(Date()), "", "Should NOT return an empty string")

        formatter.dateFormat = nil as String? // or String?.none
        XCTAssertEqual(formatter.stringFromDate(Date()), "", "Should return an empty string")
    }

    func testAlternativeMethodNames() {
        let formatter = ObjC.NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        XCTAssertEqual(formatter.stringFromDate(Date()).asString,
                       formatter.stringFrom(date: Date()), "Alternative methods should work as the original")

        XCTAssertEqual(formatter.stringFromDate(Date()).asString,
                       formatter.string(fromDate: Date()), "Alternative methods should work as the original")

        let progress1 = ObjC.NSProgress.progressWithTotalUnitCount(99)
        let progress2 = ObjC.NSProgress.progress(withTotalUnitCount: 99)
        XCTAssertEqual(progress1.totalUnitCount.asInt,
                       progress2.totalUnitCount.asInt, "Alternative methods should work as the original")
    }

    func testHiddenAPI() {
        do {
            let selector = NSSelectorFromString("lowercaseString")
            let target = NSString("ABC")
            let methodSignature: NSObject? = ObjC(target).methodSignatureForSelector(selector)
            let invocation = ObjC.NSInvocation.invocationWithMethodSignature(methodSignature)
            invocation.selector = selector
            invocation.invokeWithTarget(target)
            var result: NSString?
            _ = withUnsafeMutablePointer(to: &result) { pointer in
                invocation.getReturnValue(pointer)
            }
            XCTAssertEqual(result, "abc", "Can't use hidden API")
            if let string = result {
                _ = Unmanaged.passRetained(string).takeUnretainedValue()
            }
        }

        do {
            let selector = NSSelectorFromString("stringByPaddingToLength:withString:startingAtIndex:")
            let target = NSString("ABC")
            let methodSignature: NSObject? = ObjC(target).methodSignatureForSelector(selector)
            let invocation = ObjC.NSInvocation.invocationWithMethodSignature(methodSignature)
            invocation.selector = selector

            let length: Int = 6
            let padString = "0123" as NSString
            let index: Int = 1
            _ = withUnsafePointer(to: length) { pointer in
                invocation.setArgument(pointer, atIndex: 2)
            }
            _ = withUnsafePointer(to: padString) { pointer in
                invocation.setArgument(pointer, atIndex: 3)
            }
            _ = withUnsafePointer(to: index) { pointer in
                invocation.setArgument(pointer, atIndex: 4)
            }
            invocation.invokeWithTarget(target)
            var result: NSString?
            _ = withUnsafeMutablePointer(to: &result) { pointer in
                invocation.getReturnValue(pointer)
            }
            XCTAssertEqual(result, "ABC123", "Can't use hidden API")
            if let string = result {
                _ = Unmanaged.passRetained(string).takeUnretainedValue()
            }
        }
    }
}

extension NSObject {
    var className: String { String(describing: type(of: self)) }
}
