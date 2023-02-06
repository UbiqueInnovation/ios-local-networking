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

/// A basic implementation of a response provider
@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct BasicResponseProvider: RegexRuleResponseProvider {
    public let id = UUID()

    public let rule: RegexRule

    /// A response header provider
    public let header: ResponseProviderHeader
    /// A response body provider
    public let body: ResponseProviderBody?
    /// How timing works
    public let timing: Timing

    /// Creates a response provider
    /// - Parameters:
    ///   - rule: The rule to decide which request to handle
    ///   - body: A body provider
    ///   - header: A header provider
    ///   - timing: A timing profile
    public init(rule: String, body: ResponseProviderBody? = nil, header: ResponseProviderHeader = Header.success, timing: Timing = .init()) throws {
        self.rule = try AnyRegexRule(rule)
        self.body = body
        self.header = header
        self.timing = timing
    }

    public func response(for request: URLRequest) async throws -> HTTPURLResponse {
        if let timing = timing.headerResponseDelay {
            try await Task.sleep(nanoseconds: UInt64(timing * 1_000_000_000))
        }
        return try await header.response(for: request)
    }

    public func body(for request: URLRequest) async throws -> Data {
        if let timing = timing.bodyResponseDelay {
            try await Task.sleep(nanoseconds: UInt64(timing * 1_000_000_000))
        }
        return try await body?.body(for: request) ?? Data()
    }

}

@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension BasicResponseProvider {
    /// Creates a response provider that returns JSON objects
    /// - Parameters:
    ///   - rule: The rule to decide which request to handle
    ///   - encodable: An encodable object to send
    ///   - header: A header provider
    ///   - jsonEncoder: A JSON Encoder to use
    ///   - timing: A timing profile
    public init<E: Encodable>(rule: String, encodable: E, header: Header = .success, jsonEncoder: JSONEncoder = .init(), timing: Timing = .init()) throws {

        let payload = try jsonEncoder.encode(encodable)
        var jsonHeader = header
        jsonHeader.headerFields["Content-Type"] = "application/json"
        jsonHeader.headerFields["Content-Length"] = "\(payload.count)"

        try self.init(rule: rule, body: payload, header: jsonHeader, timing: timing)
    }

    /// Creates a response provider that returns an error on header load
    /// - Parameters:
    ///   - rule: The rule to decide which request to handle
    ///   - header: An error to return during the header fetch response
    ///   - timing: A timing profile
    public init(rule: String, header: Error, timing: Timing = .init()) throws {
        try self.init(rule: rule, header: ErrorResponseProvider(error: header), timing: timing)
    }

    /// Creates a response provider that returns an error on body load
    /// - Parameters:
    ///   - rule: The rule to decide which request to handle
    ///   - body: An error to return during the body fetch response
    ///   - header: A header provider
    ///   - timing: A timing profile
    public init(rule: String, body: Error, header: ResponseProviderHeader = Header.success, timing: Timing = .init()) throws {
        try self.init(rule: rule, body: ErrorResponseProvider(error: body), header: header, timing: timing)
    }

}

@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension Int: ResponseProviderHeader {
    public func response(for request: URLRequest) async throws -> HTTPURLResponse {
        try await BasicResponseProvider.Header(statusCode: self).response(for: request)
    }
}

@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension Data: ResponseProviderBody {
    public func body(for request: URLRequest) async throws -> Data {
        self
    }
}

@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension String: ResponseProviderBody {
    public func body(for request: URLRequest) async throws -> Data {
        data(using: .utf8)!
    }
}

@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension URL: ResponseProviderBody {
    public func body(for request: URLRequest) async throws -> Data {
        try Data(contentsOf: self)
    }
}

@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension BasicResponseProvider {
    /// A header implementation of a response provider
    public struct Header: ResponseProviderHeader {
        public var statusCode: Int
        public var headerFields: [String: String]

        public init(statusCode: Int, headerFields: [String : String] = [:]) {
            self.statusCode = statusCode
            self.headerFields = headerFields
        }

        public static let success = Header(statusCode: 200)

        public func response(for request: URLRequest) async throws -> HTTPURLResponse {
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headerFields) else {
                throw URLError(.cannotParseResponse)
            }
            return response
        }
    }

    /// The timing profile
    public struct Timing {
        /// How long to delay the response for the header
        public let headerResponseDelay: TimeInterval?
        /// How long to delay the body for the header
        public let bodyResponseDelay: TimeInterval?

        /// Creates a timing profile
        /// - Parameters:
        ///   - headerResponseDelay: How long to delay the response for the header
        ///   - bodyResponseDelay: How long to delay the body for the header
        public init(headerResponseDelay: TimeInterval? = nil, bodyResponseDelay: TimeInterval? = nil) {
            self.headerResponseDelay = headerResponseDelay
            self.bodyResponseDelay = bodyResponseDelay
        }
    }

    /// A wrapper for errors
    struct ErrorResponseProvider: ResponseProviderHeader, ResponseProviderBody {
        /// The error to throw
        let error: Error

        func response(for request: URLRequest) async throws -> HTTPURLResponse {
            throw error
        }

        func body(for request: URLRequest) async throws -> Data {
            throw error
        }
    }
}
