//
//  DiskStation.swift
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

//#if canImport(AppKit)
//public typealias Image = NSImage
//#else
//public typealias Image = UIImage
//#endif

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

// MARK: - DiskStation

public class DiskStation {
  let session: Session
  let authStore: AuthStore

  public let serverURL: URL
  public let apiInfo: APIInfo
  public let region: Region

  public init(serverURL: URL, enableEventLog: Bool = true) {
    #if DEBUG
    self.session = Session(eventMonitors: enableEventLog ? [SessionEventLogger()] : [])
    #else
    self.session = Session()
    #endif
    self.authStore = AuthStore(serverURL: serverURL)
    self.serverURL = serverURL
    self.apiInfo = APIInfo(serverURL: serverURL, session: session)
    self.region = Region(serverURL: serverURL, session: session, apiInfo: apiInfo, auth: authStore)
  }
}

// MARK: - DiskStation (Connection)

extension DiskStation {
  public var connection: Connection { Connection() }
}

// MARK: - DiskStation (Auth)

extension DiskStation {
  public func auth() -> Auth {
    return Auth(
      serverURL: serverURL,
      session: session,
      apiInfo: apiInfo,
      auth: authStore
    )
  }
}

// MARK: - DiskStation (FileStation)

extension DiskStation {
  public func fileStation() -> FileStation {
    return FileStation(
      serverURL: serverURL,
      session: session,
      apiInfo: apiInfo,
      auth: authStore,
      region: region
    )
  }
}
