//
//  StubResponse.swift
//
//  Copyright © 2024 Jaesung Jung. All rights reserved.
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
import OHHTTPStubs

// MARK: - StubResponse

struct StubResponse {
  enum ResponseData {
    case file(String)
    case data(Data)
    case json(Any)
  }

  let data: ResponseData
  let statusCode: Int32
  let headers: [String: String]?

  func makeResponse() -> HTTPStubsResponse {
    switch data {
    case .file(let name):
      return HTTPStubsResponse(
        fileAtPath: assetPath(name),
        statusCode: statusCode,
        headers: headers
      )
    case .data(let data):
      return HTTPStubsResponse(
        data: data,
        statusCode: statusCode,
        headers: headers
      )
    case .json(let jsonObject):
      return HTTPStubsResponse(
        jsonObject: jsonObject,
        statusCode: statusCode,
        headers: headers
      )
    }
  }

  func assetPath(_ fileName: String) -> String {
    guard let path = OHPathForFile(fileName, NSObject.self) else {
      fatalError("\(fileName) not found.")
    }
    return path
  }
}

// MARK: - StubResponse (Creation)

extension StubResponse {
  static func file(_ name: String, statusCode: Int32 = 200, headers: [String: String]? = nil) -> StubResponse {
    return StubResponse(data: .file(name), statusCode: statusCode, headers: headers)
  }

  static func data(_ data: Data, statusCode: Int32 = 200, headers: [String: String]? = nil) -> StubResponse {
    return StubResponse(data: .data(data), statusCode: statusCode, headers: headers)
  }

  static func json(_ jsonObject: Any, statusCode: Int32 = 200, headers: [String: String]? = nil) -> StubResponse {
    return StubResponse(data: .json(jsonObject), statusCode: statusCode, headers: headers)
  }
}
