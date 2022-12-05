//
//  AuthenticationService.swift
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

public struct AuthenticationService: SynologyAPIClient {
  typealias Error = AuthenticationError

  let serverURL: URL
  let keychain: Keychain
  let apiInfoProvider: APIInfoProvider

  init(serverURL: URL, keychain: Keychain, apiInfoProvider: @escaping APIInfoProvider) {
    self.serverURL = serverURL
    self.keychain = keychain
    self.apiInfoProvider = apiInfoProvider
  }

  public func login(account: String, password: String, deviceName: String? = nil, otp: String? = nil) async throws -> Authentication {
    let api = SynologyAPI<Authentication>(
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
    let authentication = try await request(api).data()
    saveAuthentication(authentication)
    return authentication
  }

  public func login(account: String, password: String, deviceName: String, deviceID: String) async throws -> Authentication {
    let api = SynologyAPI<Authentication>(
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
    saveAuthentication(authorization)
    return authorization
  }

  public func logout(_ authentication: Authentication) async throws {
    let api = SynologyAPI<Void>(
      name: "SYNO.API.Auth",
      method: "logout",
      parameters: [
        "_sid": authentication.sessionID
      ]
    )
    try await request(api)
    removeAuthentication()
  }

  public func sendRecoveryCodeFor2FA(account: String) async throws {
    let api = SynologyAPI<Void>(
      name: "SYNO.Core.OTP.Mail",
      method: "send",
      parameters: [
        "username": account
      ]
    )
    try await request(api)
  }
}

// MARK: - AuthenticationService (Internal)

extension AuthenticationService {
  func saveAuthentication(_ authentication: Authentication) {
    keychain["sessionID"] = authentication.sessionID
    keychain["deviceID"] = authentication.deviceID
  }

  func removeAuthentication() {
    keychain["sessionID"] = nil
    keychain["deviceID"] = nil
  }
}
