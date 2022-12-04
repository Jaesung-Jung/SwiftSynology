//
//  SynologyResponse.swift
//
//  Copyright © 2022 Jaesung Jung. All rights reserved.
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

struct SynologyResponse<Data: Decodable, Error: SynologyError>: Decodable {
  let success: Bool
  let container: KeyedDecodingContainer<StringCodingKey>

  func data() throws -> Data {
    if success {
      return try container.decode(Data.self, forKey: "data")
    } else {
      throw try container.decode(Error.self, forKey: "error")
    }
  }

  func data(path: StringCodingKey...) throws -> Data {
    if success {
      if let key = path.last {
        return try [["data"], path.dropLast(1)]
          .flatMap { $0 }
          .reduce(container) {
            try $0.nestedContainer(keyedBy: StringCodingKey.self, forKey: $1)
          }
          .decode(Data.self, forKey: key)
      } else {
        return try container.decode(Data.self, forKey: "data")
      }
    } else {
      throw try container.decode(Error.self, forKey: "error")
    }
  }

  init(from decoder: Decoder) throws {
    self.container = try decoder.container(keyedBy: StringCodingKey.self)
    self.success = try container.decode(Bool.self, forKey: "success")
  }
}

struct SynologyEmptyResponse<Error: SynologyError>: Decodable {
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: StringCodingKey.self)
    let success = try container.decode(Bool.self, forKey: "success")
    if !success {
      throw try container.decode(Error.self, forKey: "error")
    }
  }
}
