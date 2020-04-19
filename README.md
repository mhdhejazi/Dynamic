![image](https://user-images.githubusercontent.com/121827/79637117-4961c880-8185-11ea-9014-5eb7fc9dc211.png)

![Swift](https://img.shields.io/badge/Swift-5-orange?logo=Swift&logoColor=white)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

A library that uses `@dynamicMemberLookup` and `@dynamicCallable` to access ObjC API the Swifty way.

## Table of contents

  * [Introduction](#introduction)
  * [How it works](#how-it-works)
  * [How to use](#how-to-use)
  * [Use cases](#use-cases)
  * [Requirements](#requirements)
  * [Installation](#installation)
  * [TODO](#todo)
  * [Contribution](#contribution)
  * [Author](#author)

## Introduction

Assume we have the following ObjC class:
```objectivec
@interface FooBar : NSObject
- (NSString *)doSomethingWithFoo:(NSString *)foo bar:(NSString *)bar;
@end
```
There are two ways to dynamically call the method from Swift:
1.  `performSelector()`
```swift
let selector = NSSelectorFromString("doSomethingWithFoo:bar:")
let unmanaged = fooBar.perform(selector, with: "foo", with: "bar")
let result = unmanaged?.takeRetainedValue() as? String
```

2.  `methodForSelector()` + `@convention(c)`
```swift
let selector = NSSelectorFromString("doSomethingWithFoo:bar:")
let signature = (@convention(c)(NSObject, Selector, String, String) -> String).self
let method = unsafeBitCast(fooBar.method(for: selector), to: signature)
let result = method(fooBar, selector, "foo", "bar")
```

> There is actually a third way using `NSInvocation`, but it isn't available in Swift.

Now, with `Dynamic`, we can simply do the following:
```swift
Dynamic(fooBar)                          // Wrap the object with Dynamic
  .doSomethingWithFoo("foo", bar: "bar") // Call methods as you'd do with a normal object!
```

## How it works

The clean syntax is possible thanks to `@dynamicMemberLookup` and `@dynamicCallable` attributes, and the execution is done using  `NSInvocation`.

### 1. @dynamicMemberLookup

This attribute allows using the dot syntax to access arbitrary properties. With this attribute, the access to an undefined property is translated to a call to the dynamic member subscript:
```swift
@dynamicMemberLookup
public class Dynamic {
    public subscript(dynamicMember member: String) -> Dynamic {
        get {
            /// Access the property from the wrapped object
            return self.getProperty(member)
        }
        set {
            /// Update the property
            self.setProperty(member, value: newValue.resolve())
        }
    }
}
```
Now, we can write something like `Dynamic(object).foo.bar`.

> Note how the subscript returns a `Dynamic` to allow chaining calls.

### 2. @dynamicCallable

This attribute marks a type as being "callable". Instances of a callable type can be treated as functions that could be called directly by adding `()` after the object. This is translated to a call to `dynamicallyCall()` method:
```swift
@dynamicCallable
public class Dynamic {
    public func dynamicallyCall(withArguments args: [Any?]) -> Dynamic {
        let selector = self.name + repeatElement(":", count: args.count).joined(separator: "_")
        self.callMethod(selector, with: args)
        return self
    }
}
```
By adding this attribute, we can now call arbitrary methods like `Dynamic(object).foo.bar()`.

### 3. NSInvocation

Now, we have to call the actual method from the wrapped object, and to do that we need a solution that allows us to call _arbitrary methods_ with _arbitrary number of arguments_.

Our first option described above was using `performSelector()`. But that would only allow us to call methods that take no more than two arguments as it only has two slots for the arguments. And hence, this is a rejected option.

The second option was using `methodForSelector()` + `@convention(c)`. But to be able to call a method, one must know in advance the method signature and defines it in the code, and this is exactly the opposite of what we're trying to do here. We need the ability to dynamically call a method with no prior knowledge of its signature. So the second option is rejected too.

This leaves us with the third and last option, `NSInvocation`. But, as I mentioned above, this class is not even available in Swift. So, we reached a dead-end!

Well, not exactly. We still have the option to "port" `NSInvocation` into Swift ourselves. We can do that by dynamically creating instances of this class, and dynamically calling its methods that allow us to perform the actual method we are trying to call. But how can we dynamically call its methods if that's what we're trying to do in the first place? Well, we can use the second option to define the already known methods of `NSInvocation`, and call those methods from the dynamically created instance to perform the call. And that's exactly how the `Invocation` class is written.

And now that we have the `Invocation` class in Swift, the solution is complete!

### Meta Invocation

But wait! Can't we now just use `Dynamic` to create instances of the ObjC class `NSInvocation` in Swift and call its methods directly?
Absolutely!
```swift
let methodSignature: NSObject? = Dynamic(fooBar).methodSignatureForSelector(selector)
var invocation = Dynamic.NSInvocation.invocationWithMethodSignature(methodSignature)
invocation.selector = selector
invocation.target = fooBar
invocation.invoke()
```
Cool, ha?

## How to use

### Creating instances
```swift
let formatter = Dynamic.NSDateFormatter() // `formatter` is a Dynamic object
```
Or
```swift
let formatter = Dynamic.NSDateFormatter.`init`() // `formatter` is a Dynamic object
```

### Accessing properties
```swift
// Get the value as a string
let dateFormat: String? = formatter.dateFormat // `formatter` is a Dynamic object
// Set value to a string
formatter.dateFormat = "yyyy-MM-dd"            // `formatter` is a Dynamic object
```

### Calling methods
```swift
let date: Date? = formatter.dateFromString("2020 Mar 30") // `formatter` is a Dynamic object
```

### Unwrapping objects and values
Methods and properties return `Dynamic` objects by default to make it possible to chain calls. When the actual value is needed it can be unwrapped in multiple ways:

#### Implicit unwrapping

There is a second version of the `dynamicMember` subscript and `dynamicallyCall` method that takes and returns native values directly. This version is useful for setting properties, and for implicitly unwrapping the return values.

A value can be implicitly unwrapped by simply specifying the type of the variable you're assigning the result to. By doing so, the compiler will be able to choose the right version of the dynamic subscripts and methods. But remember, you should only use a nullable type (`Optional`).
```swift
let date: Date? = Dynamic.NSDateFormatter() // Implicitly unwrapped as a date
let format: String? = formatter.dateFormat // Implicitly unwrapped as a string
let number: Int? = icon.badgeNumber // Implicitly unwrapped as an integer
```

#### Explicit unwrapping

You can also explicitly unwrap values by calling one of the `as` properties:
```swift
Dynamic.NSDateFormatter().asObject // Returns the wrapped object
formatter.dateFormat.asString // Returns the wrapped string
icon.badgeNumber.asValue // Returns the wrapped value as an NSValue
```
And there are many properties for different kinds of values:
```swift
var asInt8: Int8? { get }
var asUInt8: UInt8? { get }
var asInt16: Int16? { get }
var asUInt16: UInt16? { get }
var asInt32: Int32? { get }
var asUInt32: UInt32? { get }
var asInt64: Int64? { get }
var asUInt64: UInt64? { get }
var asFloat: Float? { get }
var asDouble: Double? { get }
var asBool: Bool? { get }
var asInt: Int? { get }
var asUInt: UInt? { get }
var asSelector: Selector? { get }
```

### Logging

It's always good to understand what's happening under the hood - be it to debug a problem or just out of curiosity.
To enable logging, simply change the `loggingEnabled` property to `true`:
```swift
Dynamic.loggingEnabled = true
```

## Use cases

- Calling private API from Swift.
- Accessing `AppKit` classes from a Mac Catalyst app.
- For fun and learning!

*Got another use case? Let me know, please.*

## Requirements

#### Swift: 5.0
`Dynamic` uses the `@dynamicCallable` attribute which was introduced in Swift 5.

## Installation

You can use [Swift Package Manager](https://swift.org/package-manager)  to install  `Dynamic`  by adding it in your  `Package.swift` :

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/mhdhejazi/Dynamic.git", branch: "master")
    ]
)
```

## TODO

- [ ] Write tests
- [ ] Link the `Dynamic` objects

## Contribution

Please feel free to contribute pull requests, or create issues for bugs and feature requests.

## Author

Mhd Hejazi <a href="https://twitter.com/intent/follow?screen_name=Hejazi"><img src="https://img.shields.io/badge/@hejazi-x?color=08a0e9&logo=twitter&logoColor=white" valign="middle" /></a>
