//
//  UBLocalServer
//
//  Copyright (c) 2022-Present Ubique Team - https://ubique.ch
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// A response provider that validates
@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public protocol RegexRuleResponseProvider: ResponseProvider {
    /// A rule to check for matching requests
    var rule: RegexRule { get }
}

@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension RegexRuleResponseProvider {
    public func canHandle(request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString else {
            return false
        }
        do {
            return try rule.ruleSatified(for: url)
        } catch {
            return false
        }
    }
}

/// A regex rule
public protocol RegexRule {
    /// Can the rule be satified with the given value
    /// - Parameter value: The value to check
    /// - Returns: `true` if the value satisfy the rule
    func ruleSatified(for value: String) throws -> Bool
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension Regex: RegexRule {
    public func ruleSatified(for value: String) throws -> Bool {
        try wholeMatch(in: value) != nil
    }
}

extension NSRegularExpression: RegexRule {
    public func ruleSatified(for value: String) throws -> Bool {
        numberOfMatches(in: value, range: NSMakeRange(0, value.count)) != 0
    }
}

/// A wrapper that allows us to use the latest `Regex` class without leaving behind older OS
struct AnyRegexRule: RegexRule {
    private let rule: RegexRule

    init(_ pattern: String) throws {
        if #available(iOS 16, macOS 13, watchOS 9, tvOS 16, *) {
            rule = try Regex(pattern)
        } else {
            rule = try NSRegularExpression(pattern: pattern)
        }
    }

    func ruleSatified(for value: String) throws -> Bool {
        try rule.ruleSatified(for: value)
    }
}

