//
//  QuickConnect+ConnectInfo.swift
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

extension QuickConnect {
  struct ConnectInfo: Comparable, CustomStringConvertible {
    let type: QuickConnect.ConnectType
    let url: String
    let priority: Int

    init(type: QuickConnect.ConnectType, scheme: String, host: String, port: Int) {
      self.type = type
      switch type {
      case .smartDNSLanIPv6, .smartDNSWanIPv6, .lanIPv6, .wanIPv6:
        let isV6Format = NSPredicate(format: "SELF MATCHES %@", "^(::)?(((\\d{1,3}\\.){3}(\\d{1,3}){1})?([0-9a-f]){0,4}:{0,2}){1,8}(::)?$").evaluate(with: host)
        self.url = isV6Format ? "\(scheme)://[\(host.lowercased())]:\(port)" : "\(scheme)://\(host.lowercased()):\(port)"

      default:
        self.url = "\(scheme)://\(host.lowercased()):\(port)"
      }

      let isHTTPS = scheme == "https"
      let isDynamicPort = port >= 49152
      self.priority = (isHTTPS ? 0 : 100) + type.rawValue * 10 + (isDynamicPort ? 1 : 0)
    }

    var description: String {
      return ".\(type)(\(url)) - (\(priority))"
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
      return lhs.priority == rhs.priority
    }

    static func < (lhs: QuickConnect.ConnectInfo, rhs: QuickConnect.ConnectInfo) -> Bool {
      return lhs.priority < rhs.priority
    }
  }
}
