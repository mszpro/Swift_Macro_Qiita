// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "ExampleSwiftMacroMacros", type: "StringifyMacro")

@freestanding(expression)
public macro urlFromString(_ str: String) -> URL = #externalMacro(module: "ExampleSwiftMacroMacros", type: "URLMacro")

@freestanding(expression)
public macro systemImage(_ str: String) -> Image = #externalMacro(module: "ExampleSwiftMacroMacros", type: "SwiftUISystemImageMacro")

@attached(accessor)
public macro iCloudKeyValue<T>() = #externalMacro(module: "ExampleSwiftMacroMacros", type: "NSUbiquitousKeyValueStoreMacro")
