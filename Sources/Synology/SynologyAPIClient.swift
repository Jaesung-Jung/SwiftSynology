//
//  SynologyAPIClient.swift
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

protocol SynologyAPIClient {
  associatedtype Error: SynologyError

  var serverURL: URL { get }
  var apiInfo: [String: APIInfo] { get }

  var session: Session { get }
  var authorization: Authorization? { get }
}

extension SynologyAPIClient {
  var session: Session { .shared }

  var authorization: Authorization? { nil }

  func request(_ api: SynologyAPI<Void>) async throws {
    _ = try await dataRequest(api).serializingDecodable(SynologyEmptyResponse<Error>.self).value
  }

  func request<Data: Decodable>(_ api: SynologyAPI<Data>) async throws -> SynologyResponse<Data, Error> {
    return try await dataRequest(api).serializingDecodable(SynologyResponse<Data, Error>.self).value
  }

  func dataRequest<Data>(_ api: SynologyAPI<Data>) -> DataRequest {
    let info = apiInfo[api.name]
    let version = [api.version, info?.maxVersion].compactMap { $0 }.min()
    let additionalParameters: Parameters = [
      "_sid": authorization?.sessionID,
      "api": api.name,
      "method": api.method,
      "version": version.map { "\($0)" }
    ].compactMapValues { $0 }

    let url: URL
    let path = info?.path ?? "entry.cgi"
    if #available(iOS 16.0, *) {
      url = serverURL
        .appending(path: "webapi")
        .appending(path: path)
    } else {
      url = serverURL
        .appendingPathComponent("webapi")
        .appendingPathComponent(path)
    }
    return session
      .request(
        url,
        method: api.httpMethod,
        parameters: api.parameters
          .compactMapValues { $0 }
          .merging(additionalParameters) { $1 },
        encoding: api.encoding,
        headers: api.headers
      ) {
        if let timeoutInterval = api.timeoutInterval {
          $0.timeoutInterval = timeoutInterval
        }
      }
  }
}
