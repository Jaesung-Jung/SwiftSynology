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
  let result: Result<Data, Error>

  func data() throws -> Data {
    switch result {
    case .success(let data):
      return data
    case .failure(let error):
      throw error
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: StringCodingKey.self)
    let success = try container.decode(Bool.self, forKey: "success")
    if success {
      result = .success(try container.decode(Data.self, forKey: "data"))
    } else {
      result = .failure(try container.decode(Error.self, forKey: "error"))
    }
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
