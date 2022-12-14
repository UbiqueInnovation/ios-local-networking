# ios-local-networking

UBLocalNetworking can provide mocks and intercepts requests at runtime in any iOS or MacOS application.

## Installation

### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

> Xcode 11+ is required to build UBLocalServer using Swift Package Manager.

To integrate UBLocalServer into your Xcode project using Swift Package Manager, add it to the dependencies value of your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/UbiqueInnovation/ios-local-networking", .upToNextMajor(from: "1.0.0"))
]
```

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate UBLocalServer into your project manually.

---

## Usage

### Quick Start

```swift
import UBLocalNetworking

class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Start the server
        LocalServer.resumeLocalServerOnSharedSession()

        // The object that you wish to send
        let jhon = Person(name: "Jhon", age: 31)
        
        // Create a basic response provider that intercepts URLs containing persons
        // You can use here any Regex that you like
        let responseProvider = try! BasicResponseProvider(rule: #"https://.*/persons/.*"#, encodable: jhon)

        // Add the provider to the local server
        responseProvider.addToLocalServer()

        // All set now you can issue any URLSessionDataTask and it will get your object back
        _ = URLSession.shared.dataTask(with: URL(string: "https://int.ubique.ch/persons/123")!)
    }

}
```

### Pausing and Cleanup

You can at any time pause the server so that requests go through the normal flow.

```swift
import UBLocalNetworking

class MyViewController: UIViewController {
    override func viewWillDisappear() {
        super.viewWillDisappear()

        LocalServer.pauseLocalServer()
    }
}
```

Alternatively if you wish to remove a response provider that you don't need anymore, you can call 
`LocalServer.remove(responseProvider: ResponseProvider)` or to remove all providers `LocalServer.removeAllResponseProviders()`

### Cusomization and Features

All the power of customization lies in the `ResponseProvider` protocol. This is an asynchronous interface allowing you
to fully cusomize the response to your networking layer. It relies on 3 `async function` to determin if it can handle a request,
and to fulfill the request's response.

You do not need to always implement a custom `ResponseProvider`, sometimes the provided `BasicResponseProvider` can fit your needs.

### BasicResponseProvider

The `BasicResponseProvider` can return custom `JSON` from `Encodable` objects, errors on load, empty responses with only a header...

> It is also by itself a customizable object as it relies on protocols to fulfill it's header and body response, also does Regex matching for determining if it can handle a URL.

Also the `BasicResponseProvider` can provide delays to simulate real networks, to test loading screens or timout errors.
Use the `Timing` object in any initializer to control the delays

## Documentation

The package is fully documented. The documentation can be build and consulted using Xcode's `build documentation` action under the Product Tab.

## Issues and Contribution

Please use github Issues to submit bugs or requests. Regarding further contributions, please submit a pull request after forking the repo.

## License

UBLocalServer is released under the MIT license. See LICENSE for details.
