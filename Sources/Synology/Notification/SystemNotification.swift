//
//  Notification.swift
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
import Alamofire

// MARK: - SystemNotification

public struct SystemNotification: DSRequestable, AuthenticationProviding {
  typealias Failure = DiskStationError

  let serverURL: URL
  let session: Session
  let apiInfo: APIInfo?
  let auth: AuthStore
  let stringStore: StringStore

  init(serverURL: URL, session: Session, apiInfo: APIInfo?, auth: AuthStore, stringStore: StringStore) {
    self.serverURL = serverURL
    self.session = session
    self.apiInfo = apiInfo
    self.auth = auth
    self.stringStore = stringStore
  }

  public func messages() async throws -> [Message] {
    let api = DiskStationAPI<[RawMessage]>(
      name: "SYNO.Core.DSMNotify",
      method: "notify",
      preferredVersion: 1,
      parameters: [
        "action": "load"
      ]
    )
    let uiStrings = try await stringStore.uiStrings()
    let templates = try await stringStore.notificationMessageTemplates()
    let messages = try await dataTask(api).data(path: "items")
    return messages.compactMap { message in
      templates[message.key].map { Message(template: $0, message: message, uiStrings: uiStrings) }
    }
  }
}

// MARK: - SystemNotification.Message

extension SystemNotification {
  public struct Message {
    let template: StringStore.NotificationMessageTemplate
    let variables: [String: String]

    public let className: String
    public let level: Level
    public let date: Date

    public var title: String
    public var detail: String {
      let variablePattern = "%[A-Za-z0-9_]+%"
      let htmlPattern = "<([^>]+)>"
      guard let regex = try? NSRegularExpression(pattern: variablePattern) else {
        return template.message
      }
      let message = regex
        .matches(
          in: template.message,
          range: NSRange(location: 0, length: template.message.count)
        )
        .reversed()
        .reduce(into: template.message) { template, match in
          let startIndex = template.index(template.startIndex, offsetBy: match.range.lowerBound)
          let endIndex = template.index(template.startIndex, offsetBy: match.range.upperBound)
          let output = String(template[startIndex..<endIndex])
          if let variable = variables[String(output)] {
            template.replaceSubrange(startIndex..<endIndex, with: variable)
          }
        }

      guard let regex = try? NSRegularExpression(pattern: htmlPattern) else {
        return message
      }
      let mutableString = NSMutableString(string: message)
      regex.replaceMatches(in: mutableString, range: NSRange(location: 0, length: mutableString.length), withTemplate: "")
      return String(mutableString)
    }

    init(template: StringStore.NotificationMessageTemplate, message: RawMessage, uiStrings: JSON) {
      self.template = template
      let variables = message.variables

      self.variables = variables.compactMapValues { value in
        guard value.starts(with: "%"), let range = value.range(of: "%[A-Za-z0-9_]+%", options: .regularExpression) else {
          return value
        }
        let key = String(value[range])
        guard let referenceValue = variables[key] else {
          return value
        }
        let paths = referenceValue.split(separator: ":").filter { $0 != "dsm" }
        let result = paths.reduce(uiStrings) { uiStrings, path in
          uiStrings[String(path)]
        }
        return result.value(String.self).map { value.replacingOccurrences(of: key, with: $0) } ?? value
      }
      self.className = message.className
      self.level = Level(message.level)
      self.date = Date(timeIntervalSince1970: message.time)
      self.title = template.title
    }
  }
}

// MARK: - SystemNotification.Level

extension SystemNotification {
  public enum Level {
    case info
    case warning
    case error
    case unknown

    init<S: StringProtocol>(_ string: S) {
      switch string {
      case "NOTIFICATION_INFO":
        self = .info
      case "NOTIFICATION_WARN":
        self = .warning
      case "NOTIFICATION_ERROR":
        self = .error
      default:
        self = .unknown
      }
    }
  }
}

// MARK: - SystemNotification.RawMessage

extension SystemNotification {
  struct RawMessage: Decodable {
    let className: String
    let level: String
    let time: TimeInterval
    let key: String
    let variables: [String: String]

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.className = try container.decode(String.self, forKey: "className")
      self.level = try container.decode(String.self, forKey: "level")
      self.time = try container.decode(TimeInterval.self, forKey: "time")
      self.key = try container.decode(String.self, forKey: "title")
      let jsonStrings = try container.decode([String].self, forKey: "msg")
      if let json = jsonStrings.first?.data(using: .utf8), let variables = try? JSONDecoder().decode([String: String].self, from: json) {
        self.variables = variables
      } else {
        self.variables = [:]
      }
    }
  }
}
