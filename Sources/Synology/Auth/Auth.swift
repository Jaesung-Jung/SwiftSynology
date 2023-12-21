//
//  Auth.swift
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

public actor Auth: DSRequestable, AuthenticationProviding {
  typealias Failure = AuthError

  let serverURL: URL
  let session: Session
  let apiInfo: APIInfo?
  let auth: AuthStore

  var deviceName: String { Bundle.main.bundleIdentifier ?? "synology-swift" }

  init(serverURL: URL, session: Session, apiInfo: APIInfo, auth: AuthStore) {
    self.serverURL = serverURL
    self.session = session
    self.apiInfo = apiInfo
    self.auth = auth
  }

  public func login(account: String, password: String, deviceID: String? = nil) async throws -> Authorization {
    let api = DiskStationAPI<Authorization>(
      name: "SYNO.API.Auth",
      method: "login",
      preferredVersion: 7,
      parameters: [
        "account": account,
        "passwd": password,
        "session": "synology-swift-api",
        "format": "sid",
        "device_name": deviceName,
        "device_id": deviceID
      ]
    )
    let authorization = try await dataTask(api).data()
    await auth.setSessionID(authorization.sessionID)
    return authorization
  }

  public func login(account: String, password: String, otp: OTP) async throws -> Authorization {
    let api = DiskStationAPI<Authorization>(
      name: "SYNO.API.Auth",
      method: "login",
      preferredVersion: 7,
      parameters: [
        "account": account,
        "passwd": password,
        "session": "synology-swift-api",
        "format": "sid",
        "device_name": deviceName,
        "otp_code": otp.code,
        "enable_device_token": otp.enableDeviceToken ? "yes" : "no"
      ]
    )
    let authorization = try await dataTask(api).data()
    await auth.setSessionID(authorization.sessionID)
    return authorization
  }

  public func logout() async throws {
    guard let sid = await auth.sessionID else {
      return
    }
    let api = DiskStationAPI<Void>(
      name: "SYNO.API.Auth",
      method: "logout",
      preferredVersion: 7,
      parameters: [
        "_sid": sid
      ]
    )
    try await dataTask(api).result()
    await auth.setSessionID(nil)
  }

  public func authorized() async -> Bool {
    let sessionID = await auth.sessionID
    return sessionID != nil
  }
}

// MARK: - Auth.OTP

extension Auth {
  public struct OTP {
    public let code: String
    public let enableDeviceToken: Bool

    public init(code: String, enableDeviceToken: Bool) {
      self.code = code
      self.enableDeviceToken = enableDeviceToken
    }
  }
}

// MARK: - Auth.Authorization

extension Auth {
  public struct Authorization: Decodable, Hashable {
    public let sessionID: String
    public let deviceID: String

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.sessionID = try container.decode(String.self, forKey: "sid")
      self.deviceID = try container.decodeIfPresent(String.self, forKey: "device_id") ?? container.decode(String.self, forKey: "did")
    }
  }
}
