//
//  AuthStore.swift
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
import KeychainAccess

// MARK: - AuthStore

actor AuthStore {
  private(set) var sessionID: String?
  private(set) var deviceID: String?

  let keychain: Keychain

  init(serverURL: URL) {
    let protocolType: ProtocolType = serverURL.scheme?.lowercased() == "https" ? .https : .http
    let keychain = Keychain(server: serverURL.absoluteURL, protocolType: protocolType)
//    self.sessionID = keychain["sessionID"]
    self.sessionID = "K3hlF9jnfx6dgo4O5Sbm7yeVJy_m0WVn9Av4NSyllD43SbKMInLgjOv9Z-k0-AMVmzmwoMGqFJ1EH2a1kToHo0"
    self.deviceID = keychain["deviceID"]
    self.keychain = keychain
  }

  func setSessionID(_ sessionID: String?) {
    self.sessionID = sessionID
    self.keychain["sessionID"] = sessionID
  }

  func setDeviceID(_ deviceID: String?) {
    self.deviceID = deviceID
    self.keychain["deviceID"] = deviceID
  }
}
