//
//  Region.swift
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

// MARK: - Region

public actor Region: DSRequestable, AuthenticationProviding {
  typealias Failure = DiskStationError

  private var _timeZoneInfo: TimeZoneInfo?
  private var _timeZones: [String: TimeZone]?

  let serverURL: URL
  let session: Session
  let apiInfo: APIInfo?
  let auth: AuthStore

  init(serverURL: URL, session: Session, apiInfo: APIInfo?, auth: AuthStore) {
    self.serverURL = serverURL
    self.session = session
    self.apiInfo = apiInfo
    self.auth = auth
  }

  public func timeZone() async throws -> TimeZone? {
    if let timeZones = _timeZones, let timeZoneInfo = _timeZoneInfo {
      return timeZones[timeZoneInfo.identifier]
    }

    async let fetchTimeZones = dataTask(
      DiskStationAPI<[TimeZoneItem]>(
        name: "SYNO.Core.Region.NTP",
        method: "listzone",
        preferredVersion: 1
      )
    )

    async let fetchTimeZoneInfo = dataTask(
      DiskStationAPI<TimeZoneInfo>(
        name: "SYNO.Core.Region.NTP",
        method: "get",
        preferredVersion: 1
      )
    )

    let results = try await (fetchTimeZones.data(path: "zonedata"), fetchTimeZoneInfo.data())
    let timeZones = results.0.reduce(into: [:]) { $0[$1.name] = TimeZone(secondsFromGMT: $1.offset) }
    let timeZoneInfo = results.1
    _timeZones = timeZones
    _timeZoneInfo = timeZoneInfo
    return timeZones[timeZoneInfo.identifier]
  }
}

// MARK: - Region.TimeZoneInfo

extension Region {
  struct TimeZoneInfo: Decodable {
    let identifier: String

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.identifier = try container.decode(String.self, forKey: "timezone")
    }
  }
}

// MARK: - Region.TimeZoneItem

extension Region {
  struct TimeZoneItem: Decodable {
    let name: String
    let offset: Int

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.name = try container.decode(String.self, forKey: "value")
      self.offset = try container.decode(Int.self, forKey: "offset")
    }
  }
}
