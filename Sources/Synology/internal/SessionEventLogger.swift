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
  let printLog: (String...) -> Void

  init() {
    if #available(iOS 14.0, macCatalyst 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, visionOS 1.0, *) {
      let logger = Logger()
      printLog = {
        logger.debug("\($0.joined(separator: "\n"))")
      }
    } else {
      printLog = {
        debugPrint($0)
      }
    }
  }

  func requestDidResume(_ request: Request) {
    request.cURLDescription {
        printLog("\($0)")
    }
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    printLog(
      dataTask.currentRequest.flatMap(\.url?.absoluteString) ?? "",
      String(data: data, encoding: .utf8) ?? data.base64EncodedString()
    )
  }
}

#endif
