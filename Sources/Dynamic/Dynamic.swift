//
//  Dynamic
//  Created by Mhd Hejazi on 4/15/20.
//  Copyright © 2020 Samabox. All rights reserved.
//

import Foundation

public typealias ObjC = Dynamic

@dynamicCallable
@dynamicMemberLookup
public class Dynamic: CustomDebugStringConvertible, Loggable {
    public static var loggingEnabled: Bool = false {
        didSet {
            Invocation.loggingEnabled = loggingEnabled
        }
    }
    var loggingEnabled: Bool { Self.loggingEnabled }

    private let object: AnyObject?
    private let memberName: String?

    private var invocation: Invocation?
    private var error: Error?

    public var debugDescription: String { object?.debugDescription ?? "<nil>" }

    public init(_ object: Any?, memberName: String? = nil) {
        self.object = object as AnyObject?
        self.memberName = memberName

        log(.end).log(.start)
        log("# Dynamic")
        log("Object:", object ?? "<nil>").log("Member:", memberName ?? "<nil>")
    }

    public init(className: String) {
        self.object = NSClassFromString(className)
        self.memberName = nil

        log(.end).log(.start)
        log("# Dynamic")
        log("Class:", className)
    }

    public func `init`() -> Dynamic {
        log("Init:", "\(object?.debugDescription ?? "").init()")
        log(.end)

        return Dynamic((object as? NSObject.Type)?.init())
    }

    public static subscript(dynamicMember className: String) -> Dynamic {
        Dynamic(className: className)
    }

    public subscript(dynamicMember member: String) -> Dynamic {
        get {
            getProperty(member)
        }
        set {
            self[dynamicMember: member] = newValue.resolve()
        }
    }

    public subscript<T>(dynamicMember member: String) -> T? {
        get {
            self[dynamicMember: member].unwrap()
        }
        set {
            setProperty(member, value: newValue)
        }
    }

    @discardableResult
    public func dynamicallyCall(withKeywordArguments pairs: KeyValuePairs<String, Any?>) -> Dynamic {
        if object is AnyClass? && memberName == nil {
            return `init`()
        }

        guard let name = memberName else { return self }

        let selector = name + pairs.reduce("") { result, pair in
            if result.isEmpty {
                return (pair.key.first?.uppercased() ?? "") + pair.key.dropFirst() + ":"
            } else {
                return result + (pair.key + ":")
            }
        }
        callMethod(selector, with: pairs.map { $0.value })
        return self
    }

    @discardableResult
    public func dynamicallyCall<T>(withKeywordArguments pairs: KeyValuePairs<String, Any?>) -> T? {
        let result: Dynamic = dynamicallyCall(withKeywordArguments: pairs)
        return result.unwrap()
    }

    private func getProperty(_ name: String) -> Dynamic {
        log("Get:", "\(object?.debugDescription ?? "").\(name)")

        let resolved = resolve()
        log(.end)

        return Dynamic(resolved, memberName: name)
    }

    private func setProperty<T>(_ name: String, value: T?) {
        log("Set:", "\(object?.debugDescription ?? "").\(name)")

        let resolved = resolve()
        log(.end)

        let setter = "set" + (name.first?.uppercased() ?? "") + name.dropFirst()
        Dynamic(resolved, memberName: setter)(value)
    }

    private func callMethod(_ selector: String, with arguments: [Any?] = []) {
        guard let target = object as? NSObject, !(object is Error) else { return }
        log("Call: [\(type(of: target)) \(selector)]")

        var invocation: Invocation
        do {
            invocation = try Invocation(target: target, selector: NSSelectorFromString(selector))
        } catch {
            self.error = error
            return
        }

        self.invocation = invocation

        for index in 0..<invocation.numberOfArguments - 2 {
            var argument = arguments[index]

            if let dynamicArgument = argument as? Dynamic {
                argument = dynamicArgument.asObject
            }

            argument = TypeMapping.convertToObjCType(arguments[index]) ?? argument
            invocation.setArgument(argument, at: index + 2)
        }

        invocation.invoke()
    }

    private func resolve() -> AnyObject? {
        /// This is a class. Return it.
        if object is AnyClass? && memberName == nil {
            return object
        }

        guard let object = object else {
            return nil
        }

        /// This is a method we have called before. Return the result.
        if let result = invocation?.returnedObject() {
            return result
        }

        /// This is an error caused by a previous call. Just pass it.
        if object is Error {
            return object
        }
        if error != nil {
            return error as AnyObject?
        }

        /// This is a wrapped object. Return it.
        guard let name = memberName else {
            return object
        }

        /// This is a wrapped object with a member name. Return the member.
        if invocation?.isInvoked != true {
            callMethod(name)
        }

        return invocation?.returnedObject() ?? error as AnyObject?
    }
}

extension Dynamic {
    public var asAnyObject: AnyObject? {
        let result = resolve()
        log(.end)
        return result
    }

    public var asValue: NSValue? {
        if let object = resolve() {
            log(.end)
            return NSValue(nonretainedObject: object)
        }

        log(.end)

        guard let invocation = invocation,
            let returnType = invocation.returnType,
            invocation.returnsAny else { return nil }

        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: invocation.returnLength)
        defer { buffer.deallocate() }
        buffer.initialize(repeating: 0, count: invocation.returnLength)

        invocation.getReturnValue(result: &buffer.pointee)

        let value = NSValue(bytes: buffer, objCType: UnsafePointer<Int8>(returnType))
        return value
    }

    public var asObject: NSObject? { asAnyObject as? NSObject }
    public var asArray: NSArray? { asAnyObject as? NSArray }
    public var asDictionary: NSDictionary? { asAnyObject as? NSDictionary }
    public var asString: String? { asAnyObject?.description }
    public var asInt8: Int8? { unwrap() }
    public var asUInt8: UInt8? { unwrap() }
    public var asInt16: Int16? { unwrap() }
    public var asUInt16: UInt16? { unwrap() }
    public var asInt32: Int32? { unwrap() }
    public var asUInt32: UInt32? { unwrap() }
    public var asInt64: Int64? { unwrap() }
    public var asUInt64: UInt64? { unwrap() }
    public var asFloat: Float? { unwrap() }
    public var asDouble: Double? { unwrap() }
    public var asBool: Bool? { unwrap() }
    public var asInt: Int? { unwrap() }
    public var asUInt: UInt? { unwrap() }
    public var asSelector: Selector? { unwrap() }

    public func asInferred<T>() -> T? { unwrap() }

    private func unwrap<T>() -> T? {
        guard let value = asValue else { return nil }
        guard let invocation = invocation else {
            if let result = object as? T {
                return result
            }
            return nil
        }

        let encoding = invocation.returnTypeString
        if encoding == "^v" || encoding == "@" {
            guard let object = value.nonretainedObjectValue else { return nil }

            if type(of: object) is T.Type {
                return object as? T
            }

            if let mappedType = TypeMapping.mappedType(for: T.self) as? AnyClass,
                (object as AnyObject).isKind(of: mappedType) {
                return TypeMapping.convertType(of: object) as? T
            }

            return object as? T
        }

        var storedSize = 0
        var storedAlignment = 0
        NSGetSizeAndAlignment(invocation.returnType!, &storedSize, &storedAlignment)
        guard MemoryLayout<T>.size == storedSize && MemoryLayout<T>.alignment == storedAlignment else {
            return nil
        }

        let buffer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { buffer.deallocate() }
        value.getValue(buffer)

        return buffer.pointee
    }
}

#if canImport(UIKit)
import UIKit

extension Dynamic {
    public var asCGPoint: CGPoint? { unwrap() }
    public var asCGVector: CGVector? { unwrap() }
    public var asCGSize: CGSize? { unwrap() }
    public var asCGRect: CGRect? { unwrap() }
    public var asCGAffineTransform: CGAffineTransform? { unwrap() }
    public var asUIEdgeInsets: UIEdgeInsets? { unwrap() }
    public var asUIOffset: UIOffset? { unwrap() }

    #if !os(watchOS)
    public var asCATransform3D: CATransform3D? { unwrap() }
    #endif
}
#endif
