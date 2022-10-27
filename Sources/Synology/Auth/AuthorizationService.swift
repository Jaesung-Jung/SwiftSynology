//
//  AuthorizationProvider.swift
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
import KeychainAccess

public struct AuthorizationService: SynologyAPIClient {
  typealias Error = AuthorizationError

  let serverURL: URL
  let apiInfo: [String: APIInfo]
  let keychain: Keychain

  public var authorization: Authorization? { obtainAuthorization() }

  init(serverURL: URL, apiInfo: [String: APIInfo]) {
    self.serverURL = serverURL
    self.apiInfo = apiInfo

    let protocolType: ProtocolType = serverURL.scheme == "https" ? .https : .http
    self.keychain = Keychain(server: serverURL.absoluteString, protocolType: protocolType)
  }

  public func login(account: String, password: String, deviceName: String? = nil, otp: String? = nil) async throws -> Authorization {
    let api = SynologyAPI<Authorization>(
      name: "SYNO.API.Auth",
      method: "login",
      parameters: [
        "account": account,
        "passwd": password,
        "session": "synology-swift-api",
        "format": "sid",
        "device_name": deviceName,
        "otp_code": otp,
        "enable_device_token": deviceName != nil ? "yes" : "no"
      ]
    )
    let authorization = try await request(api).data()
    saveAuthorization(authorization)
    return authorization
  }

  public func login(account: String, password: String, deviceName: String, deviceID: String) async throws -> Authorization {
    let api = SynologyAPI<Authorization>(
      name: "SYNO.API.Auth",
      method: "login",
      parameters: [
        "account": account,
        "passwd": password,
        "session": "synology-swift-api",
        "format": "sid",
        "device_name": deviceName,
        "device_id": deviceID,
        "enable_device_token": "yes"
      ]
    )
    let authorization = try await request(api).data()
    saveAuthorization(authorization)
    return authorization
  }

  public func logout(_ authorization: Authorization) async throws {
    let api = SynologyAPI<Void>(
      name: "SYNO.API.Auth",
      method: "logout",
      parameters: [
        "_sid": authorization.sessionID
      ]
    )
    try await request(api)
    removeAuthorization()
  }
}

// MARK: - AuthorizationService (Internal)

extension AuthorizationService {
  func saveAuthorization(_ authorization: Authorization) {
    keychain["sessionID"] = authorization.sessionID
    keychain["deviceID"] = authorization.deviceID
  }

  func obtainAuthorization() -> Authorization? {
    guard let sessionID = keychain["sessionID"], let deviceID = keychain["deviceID"] else {
      return nil
    }
    return Authorization(sessionID: sessionID, deviceID: deviceID)
  }

  func removeAuthorization() {
    keychain["sessionID"] = nil
    keychain["deviceID"] = nil
  }
}
