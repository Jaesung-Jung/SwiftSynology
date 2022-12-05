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
  typealias APIInfoProvider = (String) async throws -> APIInfo?

  associatedtype Error: SynologyError

  var serverURL: URL { get }
  var apiInfoProvider: APIInfoProvider { get }

  var session: Session { get }
  var authentication: Authentication? { get }
}

extension SynologyAPIClient {
  var session: Session { .shared }

  var authentication: Authentication? { nil }

  func request(_ api: SynologyAPI<Void>) async throws {
    let apiInfo = try await apiInfoProvider(api.name)
    _ = try await dataRequest(api, apiInfo: apiInfo).serializingDecodable(SynologyEmptyResponse<Error>.self).value
  }

  func request<Data: Decodable>(_ api: SynologyAPI<Data>) async throws -> SynologyResponse<Data, Error> {
    let apiInfo = try await apiInfoProvider(api.name)
    return try await dataRequest(api, apiInfo: apiInfo).serializingDecodable(SynologyResponse<Data, Error>.self).value
  }

  func dataRequest<Data>(_ api: SynologyAPI<Data>, apiInfo: APIInfo?) -> DataRequest {
    let version = [api.version, apiInfo?.maxVersion].compactMap { $0 }.min()
    let additionalParameters: Parameters = [
      "_sid": authentication?.sessionID,
      "api": api.name,
      "method": api.method,
      "version": version.map { "\($0)" }
    ].compactMapValues { $0 }

    let url: URL
    let path = apiInfo?.path ?? "entry.cgi"
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
