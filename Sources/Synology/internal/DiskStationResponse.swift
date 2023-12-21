//
//  DiskStationResponse.swift
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
import Alamofire

// MARK: - DiskStationResponse

struct DiskStationResponse<Data: Decodable, Error: DiskStationError>: Decodable {
  let container: KeyedDecodingContainer<StringCodingKey>
  let success: Bool

  init(from decoder: Decoder) throws {
    self.container = try decoder.container(keyedBy: StringCodingKey.self)
    self.success = try container.decode(Bool.self, forKey: "success")
  }

  func data(path: String? = nil) throws -> Data {
    if success {
      let rootKey: StringCodingKey = "data"
      let paths = path?.split(separator: ".").compactMap { StringCodingKey($0) } ?? []
      if let lastKey = paths.last {
        let nestedKeys = [[rootKey], paths.dropLast(1)].flatMap { $0 }
        return try nestedKeys
          .reduce(container) { try $0.nestedContainer(keyedBy: StringCodingKey.self, forKey: $1) }
          .decode(Data.self, forKey: lastKey)
      } else {
        return try container.decode(Data.self, forKey: rootKey)
      }
    } else {
      throw try container.decode(Error.self, forKey: "error")
    }
  }
}

// MARK: - DiskStationEmptyResponse

struct DiskStationEmptyResponse<Error: DiskStationError>: Decodable {
  let container: KeyedDecodingContainer<StringCodingKey>
  let success: Bool

  init(from decoder: Decoder) throws {
    self.container = try decoder.container(keyedBy: StringCodingKey.self)
    self.success = try container.decode(Bool.self, forKey: "success")
  }

  @inlinable func result() throws -> Void {
    guard !success else {
      return
    }
    throw try container.decode(Error.self, forKey: "error")
  }
}

// MARK: - DiskStationPageResponse

struct DiskStationPageResponse<Element: Decodable, Error: DiskStationError>: Decodable {
  let container: KeyedDecodingContainer<StringCodingKey>
  let success: Bool

  func elements(path: StringCodingKey) throws -> Page<Element> {
    if success {
      let dataContainer = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "data")
      let offset = try dataContainer.decode(Int.self, forKey: "offset")
      let total = try dataContainer.decode(Int.self, forKey: "total")
      let elements = try dataContainer.decode([Element].self, forKey: path)
      return Page(offset: offset, totalCount: total, elements: elements)
    } else {
      throw try container.decode(Error.self, forKey: "error")
    }
  }

  init(from decoder: Decoder) throws {
    self.container = try decoder.container(keyedBy: StringCodingKey.self)
    self.success = try container.decode(Bool.self, forKey: "success")
  }
}

// MARK: - DiskStationLazyDataResponse

struct DiskStationLazyDataResponse<Error: DiskStationError>: DataRepresentable {
  private struct _ErrorResponse: Decodable {
    let error: Error
    let success: Bool
  }

  let source: Data

  var data: Data {
    get throws {
      do {
        let decoder = JSONDecoder()
        let errorResponse = try decoder.decode(_ErrorResponse.self, from: source)
        throw errorResponse.error
      } catch is DecodingError {
        return source
      }
    }
  }

  init(data: Data) {
    self.source = data
  }
}

// MARK: - DiskStationDataResponseSerializer

final class DiskStationDataResponseSerializer<T: DataRepresentable>: ResponseSerializer {
  let dataPreprocessor: DataPreprocessor
  let emptyResponseCodes: Set<Int>
  let emptyRequestMethods: Set<HTTPMethod>

  init(dataPreprocessor: DataPreprocessor = DataResponseSerializer.defaultDataPreprocessor,
       emptyResponseCodes: Set<Int> = DataResponseSerializer.defaultEmptyResponseCodes,
       emptyRequestMethods: Set<HTTPMethod> = DataResponseSerializer.defaultEmptyRequestMethods) {
    self.dataPreprocessor = dataPreprocessor
    self.emptyResponseCodes = emptyResponseCodes
    self.emptyRequestMethods = emptyRequestMethods
  }

  func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
    if let error {
      throw error
    }
    guard var data else {
      guard emptyResponseAllowed(forRequest: request, response: response) else {
        throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
      }
      return T(data: Data())
    }
    data = try dataPreprocessor.preprocess(data)
    return T(data: data)
  }
}
