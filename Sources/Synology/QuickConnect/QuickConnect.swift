//
//  QuickConnect.swift
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

// MARK: - QuickConnect (Public)

public class QuickConnect {
  private var _task: DataTask<[QuickConnect.ServerInfo]>?

  let session: Session = .shared

  public init() {
  }

  public func serverURL(for serverID: String) async throws -> URL {
    let serverInfos = try await serverInfo(serverID: serverID)
    let connectInfos = zip(["https", "http"], serverInfos).flatMap { $1.connectInfos(scheme: $0) }
    let availables = await availableConnectInfos(for: connectInfos).sorted()
    guard let first = availables.first else {
      throw QuickConnect.Error.availableServerNotFound
    }
    return try first.url.asURL()
  }
}

// MARK: - QuickConnect (Internal)

extension QuickConnect {
  func serverInfo(serverID: String) async throws -> [QuickConnect.ServerInfo] {
    let url = "https://global.QuickConnect.to/Serv.php"
    let parameters = [
      QuickConnect.ServerInfoParameter(id: "dsm_portal_https", serverID: serverID),
      QuickConnect.ServerInfoParameter(id: "dsm_portal", serverID: serverID)
    ]

    _task?.cancel()

    let task = session
      .request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
      .serializingDecodable([QuickConnect.ServerInfo].self)

    _task = task

    return try await task.value
  }

  func availableConnectInfos(for connectInfos: [QuickConnect.ConnectInfo]) async -> [QuickConnect.ConnectInfo] {
    await withTaskGroup(of: QuickConnect.ConnectInfo?.self) { group in
      for info in connectInfos {
        group.addTask {
          do {
            let pong = try await ping(to: info.url)
            return pong.success ? info : nil
          } catch {
            return nil
          }
        }
      }
      return await group.compactMap { $0 }.reduce(into: []) {
        $0.append($1)
      }
    }
  }
}
