//
//  DiskStationAPI.swift
//
//  Copyright © 2023 Jaesung Jung. All rights reserved.
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
import Alamofire

// MARK: - DiskStationAPI

struct DiskStationAPI<Output> {
  let name: String
  let method: String
  let preferredVersion: Int
  let parameters: DiskStationAPIParameters?
  let httpMethod: HTTPMethod
  let timeoutInterval: TimeInterval?

  init(
    name: String,
    method: String,
    preferredVersion: Int,
    parameters: DiskStationAPIParameters? = nil,
    httpMethod: HTTPMethod = .get,
    timeoutInterval: TimeInterval? = nil
  ) {
    self.name = name
    self.method = method
    self.preferredVersion = preferredVersion
    self.parameters = parameters
    self.httpMethod = httpMethod
    self.timeoutInterval = timeoutInterval
  }
}

// MARK: - DiskStationAPIParameters

enum DiskStationAPIParameters: ExpressibleByDictionaryLiteral, ExpressibleByArrayLiteral {
  init(dictionaryLiteral elements: (String, Any?)...) {
    self = .dictionary(.static(elements.reduce(into: [:]) { $0[$1.0] = $1.1 }))
  }

  init(arrayLiteral elements: FormData.Item...) {
    self = .formData(.static(Array(elements)))
  }

  static func dictionary(_ closure: @escaping (Int) -> [String: Any?]) -> DiskStationAPIParameters {
    return .dictionary(.conditional(closure))
  }

  static func formData(_ closure: @escaping (Int) -> [FormData.Item?]) -> DiskStationAPIParameters {
    return .formData(.conditional(closure))
  }

  case dictionary(KeyValueData, ParameterEncoding = URLEncoding.default)
  case formData(FormData)

  enum KeyValueData: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, Any?)...) {
      self = .static(elements.reduce(into: [:]) { $0[$1.0] = $1.1 })
    }

    case `static`([String: Any?])
    case conditional((Int) -> [String: Any?])
  }

  enum FormData: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: FormData.Item...) {
      self = .static(elements)
    }

    case `static`([FormData.Item?])
    case conditional((Int) -> [FormData.Item?])

    enum Item {
      case text(String, name: String)
      case fileData(Data, fileName: String, name: String)
      case fileURL(URL, name: String)
    }
  }
}
