//
//  StringStore.swift
//
//  Copyright © 2024 Jaesung Jung. All rights reserved.
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
import JavaScriptCore
import Alamofire

actor StringStore: DSRequestable, AuthenticationProviding {
  typealias Failure = DiskStationError

  private var _notificationMessageTemplates: [String: NotificationMessageTemplate]?
  private var _uiStrings: JSON?

  let serverURL: URL
  nonisolated let session: Session
  let apiInfo: APIInfo?
  let auth: AuthStore
  let codePage: CodePage

  init(serverURL: URL, session: Session, apiInfo: APIInfo?, auth: AuthStore, codePage: CodePage) {
    self.serverURL = serverURL
    self.session = session
    self.apiInfo = apiInfo
    self.auth = auth
    self.codePage = codePage
  }

  func notificationMessageTemplates() async throws -> [String: NotificationMessageTemplate] {
    if let templates = _notificationMessageTemplates {
      return templates
    }
    let api = DiskStationAPI<[String: NotificationMessageTemplate]>(
      name: "SYNO.Core.DSMNotify.Strings",
      method: "get",
      preferredVersion: 1,
      parameters: [
        "lang": "krn"
      ]
    )
    let templates = try await dataTask(api).data()
    _notificationMessageTemplates = templates
    return templates
  }

  func uiStrings() async throws -> JSON {
    if let strings = _uiStrings {
      return strings
    }
    let api = DiskStationAPI<String>(
      name: "SYNO.Core.Desktop.UIString",
      method: "getjs",
      preferredVersion: 1,
      parameters: [
        "lang": "krn"
      ]
    )
    let js = try await stringTask(api, encoding: .utf8)

    guard let context = JSContext() else {
      return JSON(.null)
    }
    context.evaluateScript("\(js)\nfunction _GET(){return SYNO_WebManager_Strings}")

    guard let value = context.evaluateScript("_GET()")?.toObject() as? [String: Any] else {
      return JSON(.null)
    }
    return JSON(value)
  }
}

// MARK: - StringStore.NotificationMessageTemplate

extension StringStore {
  struct NotificationMessageTemplate: Decodable {
    let title: String
    let message: String

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.title = try container.decode(String.self, forKey: "title")
      self.message = try container.decode(String.self, forKey: "msg")
    }
  }
}
