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

import XCTest
import Combine
import UBLocalNetworking
import Foundation

final class LocalServerTests: XCTestCase {

    override func setUp() {
        LocalServer.resumeLocalServer()
    }

    override func tearDown() {
        LocalServer.removeAllResponseProviders()
        LocalServer.pauseLocalServer()
    }

    struct Person: Codable, Equatable {
        let name: String
        let age: Int
    }

    func testJSON() throws {
        let jhon = Person(name: "Jhon", age: 31)
        try BasicResponseProvider(rule: #"https://.*/persons/.*"#, encodable: jhon).addToLocalServer()

        let ex = expectation(description: "Loading")
        let task = URLSession.shared.dataTaskPublisher(for: URL(string: "https://int.ubique.ch/persons/123")!)
            .map({ $0.data })
            .decode(type: Person.self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                    case .finished: ex.fulfill()
                    case .failure(let error): XCTFail(error.localizedDescription)
                }
            } receiveValue: { person in
                XCTAssertEqual(person, jhon)
            }

        waitForExpectations(timeout: 10)
        task.cancel()
    }

    func testString() throws {
        let jhon = Person(name: "Jhon", age: 31)
        let jhonString = "{\"name\": \"Jhon\", \"age\": 31}"
        try BasicResponseProvider(rule: #"https://.*/persons/.*"#, body: jhonString).addToLocalServer()

        let ex = expectation(description: "Loading")
        let task = URLSession.shared.dataTaskPublisher(for: URL(string: "https://int.ubique.ch/persons/123")!)
            .map({ $0.data })
            .decode(type: Person.self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                    case .finished: ex.fulfill()
                    case .failure(let error): XCTFail(error.localizedDescription)
                }
            } receiveValue: { person in
                XCTAssertEqual(person, jhon)
            }

        waitForExpectations(timeout: 10)
        task.cancel()
    }

    func testFile() throws {
        let jhon = Person(name: "Jhon", age: 31)
        guard let jsonUrl = Bundle.module.url(forResource: "Resources/test", withExtension: "json") else {
            XCTFail("Could not load JSON")
            return
        }
        
        try BasicResponseProvider(rule: #"https://.*/persons/.*"#, body: jsonUrl).addToLocalServer()

        let ex = expectation(description: "Loading")
        let task = URLSession.shared.dataTaskPublisher(for: URL(string: "https://int.ubique.ch/persons/123")!)
            .map({ $0.data })
            .decode(type: Person.self, decoder: JSONDecoder())
            .sink { completion in
                switch completion {
                    case .finished: ex.fulfill()
                    case .failure(let error): XCTFail(error.localizedDescription)
                }
            } receiveValue: { person in
                XCTAssertEqual(person, jhon)
            }

        waitForExpectations(timeout: 10)
        task.cancel()
    }

    func testEmptyResponse() throws {
        try BasicResponseProvider(rule: #"https://.*/baseball"#, header: 404).addToLocalServer()
        let ex = expectation(description: "Loading")
        let task = URLSession.shared.dataTaskPublisher(for: URL(string: "https://int.ubique.ch/baseball")!)
            .map({ data, response in
                (data, response as! HTTPURLResponse)
            })
            .sink { completion in
                switch completion {
                    case .finished: ex.fulfill()
                    case .failure(let error): XCTFail(error.localizedDescription)
                }
            } receiveValue: { (data, response) in
                XCTAssertTrue(data.isEmpty)
                XCTAssertEqual(response.statusCode, 404)
            }

        waitForExpectations(timeout: 10)
        task.cancel()
    }

    func testErrorResponse() throws {
        try BasicResponseProvider(rule: #"https://.*/horse"#, header: URLError(URLError.Code.notConnectedToInternet)).addToLocalServer()
        let ex = expectation(description: "Loading")
        let task = URLSession.shared.dataTaskPublisher(for: URL(string: "https://int.ubique.ch/horse")!)
            .sink { completion in
                switch completion {
                    case .finished:
                        XCTFail("Not expected to finish")
                    case .failure(let error):
                        XCTAssertEqual(error.code, URLError.Code.notConnectedToInternet)
                        ex.fulfill()
                }
            } receiveValue: { (data, response) in
                XCTFail("Not expected response")
            }

        waitForExpectations(timeout: 10)
        task.cancel()
    }

    func testHeaderDelay() throws {
        try BasicResponseProvider(rule: #"https://.*/baseball"#, header: 404, timing: .init(headerResponseDelay: 3)).addToLocalServer()

        let ex1 = expectation(description: "Loading")
        let ex2 = expectation(description: "Loading")
        let task = URLSession.shared.dataTaskPublisher(for: URL(string: "https://int.ubique.ch/baseball")!)
            .map({ data, response in
                (data, response as! HTTPURLResponse)
            })
            .sink { completion in
                switch completion {
                    case .finished:
                        ex1.fulfill()
                        ex2.fulfill()
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            } receiveValue: { (data, response) in
                XCTAssertTrue(data.isEmpty)
                XCTAssertEqual(response.statusCode, 404)
            }

        let result = XCTWaiter.wait(for: [ex1], timeout: 2.5)
        if result != .timedOut {
            XCTFail("Did not wait long enough")
        } else {
            wait(for: [ex2], timeout: 10, enforceOrder: false)
        }
        task.cancel()
    }

    func testBodyDelay() throws {
        try BasicResponseProvider(rule: #"https://.*/baseball"#, header: 404, timing: .init(bodyResponseDelay: 3)).addToLocalServer()

        let ex1 = expectation(description: "Loading")
        let ex2 = expectation(description: "Loading")
        let task = URLSession.shared.dataTaskPublisher(for: URL(string: "https://int.ubique.ch/baseball")!)
            .map({ data, response in
                (data, response as! HTTPURLResponse)
            })
            .sink { completion in
                switch completion {
                    case .finished:
                        ex1.fulfill()
                        ex2.fulfill()
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            } receiveValue: { (data, response) in
                XCTAssertTrue(data.isEmpty)
                XCTAssertEqual(response.statusCode, 404)
            }

        let result = XCTWaiter.wait(for: [ex1], timeout: 2.5)
        if result != .timedOut {
            XCTFail("Did not wait long enough")
        } else {
            wait(for: [ex2], timeout: 10, enforceOrder: false)
        }
        task.cancel()
    }

    func testHeaderAndBodyDelay() throws {
        try BasicResponseProvider(rule: #"https://.*/baseball"#, header: 404, timing: .init(headerResponseDelay: 2, bodyResponseDelay: 2)).addToLocalServer()

        let ex1 = expectation(description: "Loading")
        let ex2 = expectation(description: "Loading")
        let task = URLSession.shared.dataTaskPublisher(for: URL(string: "https://int.ubique.ch/baseball")!)
            .map({ data, response in
                (data, response as! HTTPURLResponse)
            })
            .sink { completion in
                switch completion {
                    case .finished:
                        ex1.fulfill()
                        ex2.fulfill()
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            } receiveValue: { (data, response) in
                XCTAssertTrue(data.isEmpty)
                XCTAssertEqual(response.statusCode, 404)
            }

        let result = XCTWaiter.wait(for: [ex1], timeout: 3.5)
        if result != .timedOut {
            XCTFail("Did not wait long enough")
        } else {
            wait(for: [ex2], timeout: 10, enforceOrder: false)
        }
        task.cancel()
    }

}
