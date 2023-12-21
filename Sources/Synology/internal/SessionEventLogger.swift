//
//  SessionEventLogger.swift
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
#if canImport(OSLog)
import OSLog
#endif

// MARK: - SessionEventLogger

#if DEBUG

struct SessionEventLogger: EventMonitor {
  let printLog: (String?...) -> Void

  init() {
    let makeLog: ([String?]) -> String = {
      $0.compactMap{ $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
    }
    if #available(iOS 14.0, macCatalyst 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *) {
      let logger = Logger()
      printLog = {
        logger.debug("\(makeLog($0))")
      }
    } else {
      printLog = {
        debugPrint(makeLog($0))
      }
    }
  }

  func requestDidResume(_ request: Request) {
    printLog(
      "🌐 \(requestString(request: request))",
      request.request.flatMap(\.httpBody).map { dataString(data: $0) }
    )
  }

  func request(_ request: DataRequest, didParseResponse response: DataResponse<Data?, AFError>) {
    printLog(
      "💬 \(requestString(request: request))",
      request.data.map { dataString(data: $0) }
    )
  }

  func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
    printLog(
      "💬 \(requestString(request: request))",
      request.data.map { dataString(data: $0) }
    )
  }

  @inlinable func requestString(request: Request) -> String {
    let components = [
      request.request?.httpMethod,
      request.request?.url?.absoluteString,
      request.response.map { "(\($0.statusCode))" }
    ]
    return components
      .compactMap { $0 }
      .joined(separator: " ")
  }

  @inlinable func dataString(data: Data) -> String {
    if let string = String(data: data, encoding: .utf8) {
      return string
    }
    let size: String
    if #available(iOS 15.0, macCatalyst 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
      size = data.count.formatted(.byteCount(style: .memory, includesActualByteCount: true))
    } else {
      size = "\(data.count) bytes"
    }
    return "[DATA] \(size)"
  }
}

#endif
