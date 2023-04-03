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

/// Provides a response header
@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public protocol ResponseProviderHeader {
    /// Returns an `HTTPURLResponse` in response to a `URLRequest`
    /// - Parameter request: The request that needs a response
    /// - Returns: A response to the given request
    func response(for request: URLRequest) async throws -> HTTPURLResponse
}

/// Provides a response body
@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public protocol ResponseProviderBody {
    /// Returns a `Data` in response to a `URLRequest`
    /// - Parameter request: The request that needs a response body
    /// - Returns: A response body to the given request
    func body(for request: URLRequest) async throws -> Data
}

/// Provides a response
@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public protocol ResponseProvider: ResponseProviderHeader, ResponseProviderBody {
    /// Uniquely identifies a provider
    var id: UUID { get }

    /// Checks if a provider can handle a request
    /// - Parameter request: The request to handle
    /// - Returns: `true` if the provider can handle the request
    func canHandle(request: URLRequest) -> Bool
}

@available(iOS 13.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension ResponseProvider {
    /// Adds the provider to the local server
    public func addToLocalServer() {
        LocalServer.add(responseProvider: self)
    }

    /// Removes a provider from the local server
    public func removeFromLocalServer() {
        LocalServer.remove(responseProvider: self)
    }
}
