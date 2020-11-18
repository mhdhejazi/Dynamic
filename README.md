![image](https://user-images.githubusercontent.com/121827/79637117-4961c880-8185-11ea-9014-5eb7fc9dc211.png)

![Swift](https://img.shields.io/badge/Swift-5.2-orange?logo=Swift&logoColor=white)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
![Build](https://github.com/mhdhejazi/Dynamic/workflows/Build/badge.svg)
![Tests](https://github.com/mhdhejazi/Dynamic/workflows/Tests/badge.svg)

A library that uses `@dynamicMemberLookup` and `@dynamicCallable` to access Objective-C API the Swifty way.

## Table of contents

  * [Introduction](#introduction)
  * [Examples](#examples)
  * [Installation](#installation)
  * [How to use](#how-to-use)
  * [Requirements](#requirements)
  * [Contribution](#contribution)
  * [Author](#author)

## Introduction

Assume we have the following private Objective-C class that we want to access in Swift:
```objectivec
@interface Toolbar : NSObject
- (NSString *)titleForItem:(NSString *)item withTag:(NSString *)tag;
@end
```
There are three ways to dynamically call the method in this class:

**1. Using `performSelector()`**
```swift
let selector = NSSelectorFromString("titleForItem:withTag:")
let unmanaged = toolbar.perform(selector, with: "foo", with: "bar")
let result = unmanaged?.takeRetainedValue() as? String
```

**2. Using `methodForSelector()` with `@convention(c)`**
```swift
typealias titleForItemMethod = @convention(c)
    (NSObject, Selector, NSString, NSString) -> NSString
  
let selector = NSSelectorFromString("titleForItem:withTag:")
let methodIMP = toolbar.method(for: selector)
let method = unsafeBitCast(methodIMP, to: titleForItemMethod.self)
let result = method(toolbar, selector, "foo", "bar")
```

**3. Using `NSInvocation`**
<details>
<summary>It's only available in Objective-C.</summary>

```objectivec
SEL selector = @selector(titleForItem:withTag:);
NSMethodSignature *signature = [toolbar methodSignatureForSelector:selector];

NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
invocation.target = toolbar;
invocation.selector = selector;

NSString *argument1 = @"foo";
NSString *argument2 = @"bar";
[invocation setArgument:&argument1 atIndex:2];
[invocation setArgument:&argument2 atIndex:3];

[invocation invoke];

NSString *result;
[invocation getReturnValue:&result];
```
</details>

**Or, we can use Dynamic** 🎉 

```swift
let result = Dynamic(toolbar)            // Wrap the object with Dynamic
    .titleForItem("foo", withTag: "bar") // Call the method directly!
```

> More details on how the library is designed and how it works [here](https://medium.com/swlh/calling-ios-and-macos-hidden-api-in-style-1a924f244ad1).

## Examples
The main use cases for  `Dynamic`  is accessing private/hidden iOS and macOS API in Swift. And with the introduction of Mac Catalyst, the need to access hidden API arose as Apple only made a very small portion of the macOS AppKit API visible to Catalyst apps.

What follows are examples of how easy it is to access AppKit API in a Mac Catalyst with the help of Dynamic.

#### 1. Get the `NSWindow` from a `UIWindow` in a MacCatalyst app
```swift
extension UIWindow {
    var nsWindow: NSObject? {
        var nsWindow = Dynamic.NSApplication.sharedApplication.delegate.hostWindowForUIWindow(self)
        if #available(macOS 11, *) {
            nsWindow = nsWindow.attachedWindow
        }
        return nsWindow.asObject
    }
}
```

#### 2. Enter fullscreen in a MacCatalyst app
```swift
// macOS App
window.toggleFullScreen(nil)

// Mac Catalyst (with Dynamic)
window.nsWindow.toggleFullScreen(nil)
```

#### 3. Using `NSOpenPanel` in a MacCatalyst app
```swift
// macOS App
let panel = NSOpenPanel()
panel.beginSheetModal(for: view.window!, completionHandler: { response in
    if let url: URL = panel.urls.first {
        print("url: ", url)
    }
})

// Mac Catalyst (with Dynamic)
let panel = Dynamic.NSOpenPanel()
panel.beginSheetModalForWindow(self.view.window!.nsWindow, completionHandler: { response in
    if let url: URL = panel.URLs.firstObject {
        print("url: ", url)
    }
} as ResponseBlock)

typealias ResponseBlock = @convention(block) (_ response: Int) -> Void
```

#### 4. Change the window scale factor in MacCatalyst apps
iOS views in Mac Catalyst apps are automatically scaled down to 77%. To change the scale factor we need to access a hidden property:
```swift
override func viewDidAppear(_ animated: Bool) {
  view.window?.scaleFactor = 1.0 // Default value is 0.77
}

extension UIWindow {
  var scaleFactor: CGFloat {
    get {
      Dynamic(view.window?.nsWindow).contentView
        .subviews.firstObject.scaleFactor ?? 1.0
    }
    set {
      Dynamic(view.window?.nsWindow).contentView
        .subviews.firstObject.scaleFactor = newValue
    }
  }
}
```

## Installation
You can use [Swift Package Manager](https://swift.org/package-manager)  to install  `Dynamic`  by adding it in your  `Package.swift` :

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/mhdhejazi/Dynamic.git", branch: "master")
    ]
)
```

## How to use
The following diagram shows how we use Dynamic to access private properties and methods from the Objective-C object `obj`:
![Diagram](https://user-images.githubusercontent.com/121827/83970645-7312b280-a8df-11ea-87bf-d69682f8627d.png)


### 1. Wrap Objective-C objects
To work with Objective-C classes and instances, we need to wrap them with Dynamic first

#### Wrapping an existing object
If we have a reference for an existing Objective-C object, we can simply wrap it with `Dynamic`:
```swift
let dynamicObject = Dynamic(objcObject)
```

#### Creating new instances
To create a new instance from a hidden class, we prepend its name with `Dynamic` (or `ObjC`):
```swift
// Objective-C:
[[NSDateFormatter alloc] init];

// Swift:
let formatter = Dynamic.NSDateFormatter()
// Or maybe:
let formatter = ObjC.NSDateFormatter()
// Or the longer form:
let formatter = ObjC.NSDateFormatter.`init`()
```
> **Note 1**: The `formatter` is an instance of `Dynamic` that wraps the new instance of `NSDateFormatter`

> **Note 2**: `ObjC` is just a typealias for `Dynamic`. Whatever you choose to use, stay consistent.

If the initializer takes parameters, we can pass them directly:
```swift
// Objective-C:
[[NSProgress alloc] initWithParent:foo userInfo:bar];

// Swift:
let progress = Dynamic.NSProgress(parent: foo, userInfo: bar)
// Or the longer form:
let progress = Dynamic.NSProgress.initWithParent(foo, userInfo: bar)
```
> Both forms are equivalent because the library adds the prefix `initWith` to the method selector in the first case.
> If you choose to use the shorter form, remember that you can only drop the prefix `initWith` from the original initializer name. Whatever comes after `initWith` should be the label of the first parameter.

#### Singletons
Accessing singletons is also straightforward:
```swift
// Objective-C:
[NSApplication sharedApplication];

// Swift:
let app = Dynamic.NSApplication.sharedApplication()
// Or we can drop the parenthesizes, as if `sharedApplication` was a static property:
let app = Dynamic.NSApplication.sharedApplication
```

> **Important Note**: Although the syntax looks very similar to the Swift API, it's not always identical to the Swift version of the used API. For instance, the name of the above singleton in Swift is [`shared`](https://developer.apple.com/documentation/appkit/nsapplication/1428360-shared) not `sharedApplication`, but we can only use [`sharedApplicaton`](https://developer.apple.com/documentation/appkit/nsapplication/1428360-sharedapplication) here as we're internally taking with the Objective-C classes.
> Always refer to the Objective-C documentation of the method you're trying to call to make sure you're using the right name.

### 2. Call the private API
After wrapping the Objective-C object, we can now access its properties and methods directly from the Dynamic object.

#### Accessing properties
```swift
// Objective-C:
@interface NSDateFormatter {
  @property(copy) NSString *dateFormat;
}

// Swift:
let formatter = Dynamic.NSDateFormatter()
// Getting the property value:
let format = formatter.dateFormat // `format` is now a Dynamic object
// Setting the property value:
formatter.dateFormat = "yyyy-MM-dd"
// Or the longer version:
formatter.dateFormat = NSString("yyyy-MM-dd")
```
> **Note 1**: The variable `format` above is now a `Dynamic` object that wraps the actual property value. The reason for returning a `Dynamic` object and not the actual value is to allow call chaining. We'll see later how we can unwrap the actual value from a `Dynamic` object.

> **Note 2**: Although the property `NSDateFormatter.dataFormat` is of the type `NSString`, we can set it to a Swift `String` and the library will convert it to `NSString` automatically.

#### Calling methods
```swift
let formatter = Dynamic.NSDateFormatter()
let date = formatter.dateFromString("2020 Mar 30") // `date` is now a Dynamic object
```
```swift
// Objective-C:
[view resizeSubviewsWithOldSize:size];
[view beginPageInRect:rect atPlacement:point];

// Swift:
view.resizeSubviewsWithOldSize(size) // OR ⤸
view.resizeSubviews(withOldSize: size)

view.beginPageInRect(rect, atPlacement: point) // OR ⤸
view.beginPage(inRect: rect, atPlacement: point)
```
> Calling the same method in different forms is possible because the library combines the method name (e.g. `resizeSubviews`) with the first parameter label (e.g. `withOldSize`) to form the method selector (e.g. `resizeSubviewsWithOldSize:`). This means you can also call: `view.re(sizeSubviewsWithOldSize: size)`, but please don't.

#### Objective-C block arguments
To pass a Swift closure for a block argument, we need to add `@convention(block)` to the closure type, and then cast the passed closure to this type.
```swift
// Objective-C:
- (void)beginSheetModalForWindow:(NSWindow *)sheetWindow 
               completionHandler:(void (^)(NSModalResponse returnCode))handler;

// Swift:
let panel = Dynamic.NSOpenPanel.openPanel()
panel.beginSheetModal(forWindow: window, completionHandler: { result in
    print("result: ", result)
} as ResultBlock)

typealias ResultBlock = @convention(block) (_ result: Int) -> Void
```

### 3. Unwrap the result
Methods and properties return `Dynamic` objects by default to make it possible to chain calls. When the actual value is needed it can be unwrapped in multiple ways:

#### Implicit unwrapping
A value can be implicitly unwrapped by simply specifying the type of the variable we're assigning the result to. 
```swift
let formatter = Dynamic.NSDateFormatter()
let date: Date? = formatter.dateFromString("2020 Mar 30") // Implicitly unwrapped as Date?
let format: String? = formatter.dateFormat // Implicitly unwrapped as String?

let progress = Dynamic.NSProgress()
let total: Int? = progress.totalUnitCount // Implicitly unwrapped as Int?
```
Note that we should always use a nullable type (`Optional`) for the variable type or we may see a compiler error:
```swift
let total = progress.totalUnitCount // No unwrapping. `total` is a Dynamic object
let total: Int? = progress.totalUnitCount // Implicit unwrapping as Int?
let total: Int = progress.totalUnitCount // Compiler error
let total: Int = progress.totalUnitCount! // Okay, but dangerous
```

> Assigning to a variable of an optional type isn't the only way for implicitly unwrapping a value. Other ways include returning the result of a method call or comparing it with a variable of an optional type.

Note that the implicit unwrapping only works with properties and method calls since the compiler can choose the proper overloading method based on the expected type. This isn't the case when we simply return a Dynamic variable or assign it to another variable:
```swift
// This is okay:
let format: Date? = formatter.dateFromString("2020 Mar 30")

// But this is not:
let dynamicObj = formatter.dateFromString("2020 Mar 30")
let format: Date? = dynamicObj // Compiler error
```

#### Explicit unwrapping
We can also explicitly unwrap values by calling one of the `as<Type>` properties:
```swift
Dynamic.NSDateFormatter().asObject // Returns the wrapped value as NSObject?
formatter.dateFormat.asString // Returns the wrapped value as String?
progress.totalUnitCount.asInt // Returns the wrapped value as Int?
```
And there are many properties for different kinds of values:
```swift
var asAnyObject: AnyObject? { get }
var asValue: NSValue? { get }
var asObject: NSObject? { get }
var asArray: NSArray? { get }
var asDictionary: NSDictionary? { get }
var asString: String? { get }
var asFloat: Float? { get }
var asDouble: Double? { get }
var asBool: Bool? { get }
var asInt: Int? { get }
var asSelector: Selector? { get }
var asCGPoint: CGPoint? { get }
var asCGVector: CGVector? { get }
var asCGSize: CGSize? { get }
var asCGRect: CGRect? { get }
var asCGAffineTransform: CGAffineTransform? { get }
var asUIEdgeInsets: UIEdgeInsets? { get }
var asUIOffset: UIOffset? { get }
var asCATransform3D: CATransform3D? { get }
```
### Edge cases
#### Unrecognized methods and properties
If you try to access undefined properties or methods the app won't crash, but you'll get `InvocationError.unrecognizedSelector` wrapped with a `Dynamic` object. You can use `Dynamic.isError` to check for such an error.
```swift
let result = Dynamic.NSDateFormatter().undefinedMethod()
result.isError // -> true
```
And you'll also see a warning in the console:
```nasm
WARNING: Trying to access an unrecognized member: NSDateFormatter.undefinedMethod
```
> Note that a crash may expectedly happen if you pass random parameters of unexpected types to a method that doesn't expect them.

#### Setting a property to `nil`
You can use one the following ways to set a property to `nil`:
```swift
formatter.dateFormat = .nil           // The custom Dynamic.nil constant
formatter.dateFormat = nil as String? // A "typed" nil
formatter.dateFormat = String?.none   // The Optional.none case
```

### Logging
It's always good to understand what's happening under the hood - be it to debug a problem or just out of curiosity.
To enable extensive logging, simply change the `loggingEnabled` property to `true`:
```swift
Dynamic.loggingEnabled = true
```

## Requirements

#### Swift: 5.0
`Dynamic` uses the `@dynamicCallable` attribute which was introduced in Swift 5.

## Contribution
Please feel free to contribute pull requests, or create issues for bugs and feature requests.

## Author
Mhd Hejazi <a href="https://twitter.com/intent/follow?screen_name=Hejazi"><img src="https://img.shields.io/badge/@hejazi-x?color=08a0e9&logo=twitter&logoColor=white" valign="middle" /></a>
