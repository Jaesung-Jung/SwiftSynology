//
//  APIInfo.swift
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

// MARK: - APIInfo

public actor APIInfo: DSRequestable {
  typealias Failure = DiskStationError

  let serverURL: URL
  nonisolated let session: Session
  var sessionID: String? { nil }
  var items: [String: Item]?

  init(serverURL: URL, session: Session) {
    self.serverURL = serverURL
    self.session = session
  }

  public func item(for name: String) async throws -> Item? {
    if let items {
      return items[name]
    }
    let api = DiskStationAPI<[String: Item]>(
      name: "SYNO.API.Info",
      method: "Query",
      preferredVersion: 1,
      parameters: [
        "query": "all"
      ]
    )
    items = try await dataTask(api).data()
    return items?[name]
  }
}

// MARK: - APIInfo.Item

extension APIInfo {
  public struct Item: Decodable {
    let path: String
    let minVersion: Int
    let maxVersion: Int
  }
}
