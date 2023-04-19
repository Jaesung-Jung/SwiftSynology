//
//  SynologyService.swift
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
import KeychainAccess

// MARK: - SynologyService

public actor SynologyService {
  private var _apiInfo: [String: APIInfo]?

  let keychain: Keychain

  public nonisolated let serverURL: URL

  public nonisolated var authentication: Authentication? { obtainAuthentication() }

  public init(serverURL: URL) {
    self.serverURL = serverURL
    let protocolType: ProtocolType = serverURL.scheme?.lowercased() == "https" ? .https : .http
    self.keychain = Keychain(server: serverURL.absoluteURL, protocolType: protocolType)
  }

  public nonisolated func auth() -> AuthenticationService {
    return AuthenticationService(
      serverURL: serverURL,
      keychain: keychain,
      apiInfoProvider: apiInfo
    )
  }

  public nonisolated func system() -> SystemService {
    return SystemService(
      serverURL: serverURL,
      apiInfoProvider: apiInfo,
      authentication: authentication
    )
  }

  public nonisolated func fileStation() -> FileStationService {
    return FileStationService(
      serverURL: serverURL,
      apiInfoProvider: apiInfo,
      authentication: authentication
    )
  }
}

// MARK: - SynologyService (Internal)

extension SynologyService {
  func apiInfo(_ name: String) async throws -> APIInfo? {
    if let apiInfo = _apiInfo {
      return apiInfo[name]
    }
    _apiInfo = try await APIInfoService(serverURL: serverURL).apiInfo()
    return _apiInfo?[name]
  }

  nonisolated func obtainAuthentication() -> Authentication? {
    guard let sessionID = keychain["sessionID"], let deviceID = keychain["deviceID"] else {
      return nil
    }
    return Authentication(sessionID: sessionID, deviceID: deviceID)
  }
}
