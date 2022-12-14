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

/// A local server capable of serving predetermined routes with local data.
///
/// Useful in cases where mocking is needed or can even be used to validate
/// requests sent to specific destination that it contains certain headers. It will
/// only itercept requests and do not interfere with any other system
///
/// - Note: It will intercept all URL requests even ones that are issues by 3rd parties
public class LocalServer {

    private init() {}

    /// Starts intercepting requests. Only request on URLSession.shared will be intercepted
    public static func resumeLocalServerOnSharedSession() {
        URLProtocol.registerClass(LocalServerImpl.self)
    }

    /// Stops intercepting requests
    public static func pauseLocalServer() {
        URLProtocol.unregisterClass(LocalServerImpl.self)
    }

    // MARK: - Data Providers

    /// The list of response providers currently registered.
    ///
    /// There is no guarantee that all registered providers will be consulted.
    /// Providers are consulted in the reverse order of their registration until a match is found
    public private(set) static var responseProviders: [ResponseProvider] = []

    /// Adds a new response provider
    /// - Parameter responseProvider: The response provider to add
    public static func add(responseProvider: ResponseProvider) {
        responseProviders.append(responseProvider)
    }

    /// Removes a response provider and stops it from receiving any requests
    /// - Parameter responseProvider: The response provider to remove
    public static func remove(responseProvider: ResponseProvider) {
        responseProviders.removeAll(where: { $0.id == responseProvider.id })
    }

    /// Removes all response providers
    public static func removeAllResponseProviders() {
        responseProviders.removeAll()
    }

    /// Finds a matching Response Provider for the given request
    /// - Parameter request: The request to match
    /// - Returns: A matching Response Provider. `nil` if none is found
    static func getMatchingDataProvider(for request: URLRequest) -> (any ResponseProvider)? {
        responseProviders.reversed().first(where: { $0.canHandle(request: request) })
    }
}

/// An implementation of URLProtocol
private final class LocalServerImpl: URLProtocol {

    /// The provider associated with this copy of the interceptor
    private let provider: ResponseProvider

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        LocalServer.getMatchingDataProvider(for: request) != nil
    }

    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        guard let provider = LocalServer.getMatchingDataProvider(for: request) else {
            fatalError("No matching provider")
        }
        self.provider = provider
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }

    /// The loading task for cancelation
    private var loadingTask: Task<(), Never>? {
        willSet {
            loadingTask?.cancel()
        }
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        loadingTask = Task {
            do {
                if Task.isCancelled { return }
                let response = try await provider.response(for: request)
                if Task.isCancelled { return }
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                let data = try await provider.body(for: request)
                if Task.isCancelled { return }
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                if Task.isCancelled { return }
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {
        loadingTask?.cancel()
    }
}
