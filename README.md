# Websync

[![CI Status](https://img.shields.io/travis/cholaitnj@gmail.com/Websync.svg?style=flat)](https://travis-ci.org/cholaitnj@gmail.com/Websync)
[![Version](https://img.shields.io/cocoapods/v/Websync.svg?style=flat)](https://cocoapods.org/pods/Websync)
[![License](https://img.shields.io/cocoapods/l/Websync.svg?style=flat)](https://cocoapods.org/pods/Websync)
[![Platform](https://img.shields.io/cocoapods/p/Websync.svg?style=flat)](https://cocoapods.org/pods/Websync)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Websync is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Websync'
```

How to use
----------

**STEP 1**:

Your API Url
```swift
Websync.websynch_baseUrl = "https://tyre-buzzar-dev.webappstesting.com/api/"
```

Create structure for post data
```swift
struct pLogin: Codable {
var userName: String
var password: String
}
```

Create structure for response data
```swift
struct rLogin: Codable {
var success: Bool
var access_token: String
}
```

**STEP 2**:

Excecute simple API call
```swift
import Websync

let user = pLogin(userName: "raj@xyz.com", password: "raj123456")

Websync().post(postBody: user, methodName: "users", expected: rLogin.self) { response, error in

if response != nil {

let userResponse = response as! rLogin
print(userResponse.success)

} else {

// Error message here..

}

}
```

Excecute API call with cache and header
```swift
Websync().post(postBody: user, methodName: "users", expected: rLogin.self, header: ["auth":"12121"], cache: true) { response, error in

if response != nil {

let userResponse = response as! rLogin
print(userResponse.success)

} else {

// Error message here..

}

}
```


## Author

chola, cholaitnj@gmail.com

## License

Websync is available under the MIT license. See the LICENSE file for more info.
