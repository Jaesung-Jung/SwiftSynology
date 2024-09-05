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

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

public typealias NetworkingError = AFError

// MARK: - DiskStation

public class DiskStation {
  let session: Session
  let authStore: AuthStore
  let stringStore: StringStore

  public let serverURL: URL
  public let apiInfo: APIInfo
  public let region: Region
  public let codePage: CodePage

  public convenience init(serverURL: URL, sessionID: String? = nil, locale: Locale = .current, enableEventLog: Bool = true) {
    let codePage: CodePage = if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, tvOS 13.0, watchOS 9.0, visionOS 1.0, *) {
      locale.language.languageCode.map { CodePage(languageCode: $0.identifier) } ?? .englishUS
    } else {
      locale.languageCode.map { CodePage(languageCode: $0) } ?? .englishUS
    }
    self.init(serverURL: serverURL, sessionID: sessionID, codePage: codePage, enableEventLog: enableEventLog)
  }

  public init(serverURL: URL, sessionID: String? = nil, codePage: CodePage, enableEventLog: Bool = true) {
    #if DEBUG
    self.session = Session(eventMonitors: enableEventLog ? [SessionEventLogger()] : [])
    #else
    self.session = Session()
    #endif
    self.authStore = AuthStore(serverURL: serverURL, sessionID: sessionID)
    self.serverURL = serverURL
    self.apiInfo = APIInfo(serverURL: serverURL, session: session)
    self.region = Region(serverURL: serverURL, session: session, apiInfo: apiInfo, auth: authStore)
    self.codePage = codePage
    self.stringStore = StringStore(serverURL: serverURL, session: session, apiInfo: apiInfo, auth: authStore, codePage: codePage)
  }
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

// MARK: - DiskStation (System)

extension DiskStation {
  public func system() -> System {
    return System(
      serverURL: serverURL,
      session: session,
      apiInfo: apiInfo,
      auth: authStore
    )
  }
}

// MARK: - DiskStation (PersonalSettings)

extension DiskStation {
  public func personalSettings() -> PersonalSettings {
    return PersonalSettings(
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

// MARK: - DiskStation (SystemNotification)

extension DiskStation {
  public func notification() -> SystemNotification {
    return SystemNotification(
      serverURL: serverURL,
      session: session,
      apiInfo: apiInfo,
      auth: authStore,
      stringStore: stringStore
    )
  }
}
