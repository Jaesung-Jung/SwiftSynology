//
//  QuickConnect.swift
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

// MARK: - QuickConnect

public actor QuickConnect {
  private var _task: DataTask<[ServerInfo]>?

  let session: Session
  let pingPong: PingPoing

  public init(enableEventLog: Bool = true) {
    #if DEBUG
    self.session = Session(eventMonitors: enableEventLog ? [SessionEventLogger()] : [])
    #else
    self.session = Session()
    #endif
    self.pingPong = PingPoing(session: session)
  }

  public func connect(id serverID: String) async throws -> DiskStation {
    let serverInfos = try await serverInfo(serverID: serverID)
    let connectInfos = zip(["https", "http"], serverInfos).flatMap { $1.connectInfos(scheme: $0) }
    let availables = await availableConnectInfos(for: connectInfos).sorted()
    guard let first = availables.first else {
      throw QuickConnectError.availableServerNotFound
    }
    return DiskStation(serverURL: try first.url.asURL())
  }
}

// MARK: - QuickConnect (Internal)

extension QuickConnect {
  func serverInfo(serverID: String) async throws -> [ServerInfo] {
    let url = "https://global.QuickConnect.to/Serv.php"
    let parameters = [
      ServerInfoParameter(id: "dsm_portal_https", serverID: serverID),
      ServerInfoParameter(id: "dsm_portal", serverID: serverID)
    ]

    _task?.cancel()

    let task = session
      .request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
      .serializingDecodable([ServerInfo].self)

    _task = task

    return try await task.value
  }

  func availableConnectInfos(for connectInfos: [ConnectInfo]) async -> [ConnectInfo] {
    await withTaskGroup(of: ConnectInfo?.self) { group in
      for info in connectInfos {
        group.addTask {
          do {
            let pong = try await self.pingPong.ping(to: info.url)
            return pong.success ? info : nil
          } catch {
            return nil
          }
        }
      }
      var results: [ConnectInfo] = []
      for await result in group.compactMap({ $0 }) {
        results.append(result)
      }
      return results
    }
  }
}

// MARK: - QuickConnect.ServerInfoParameter

extension QuickConnect {
  struct ServerInfoParameter: Encodable {
    let id: String
    let serverID: String

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: StringCodingKey.self)
      try container.encode(id, forKey: "id")
      try container.encode(serverID, forKey: "serverID")
      try container.encode(1, forKey: "version")
      try container.encode("get_server_info", forKey: "command")
      try container.encode(false, forKey: "stop_when_error")
      try container.encode(false, forKey: "stop_when_success")
    }
  }
}

// MARK: - QuickConnect.ConnectType

extension QuickConnect {
  enum ConnectType: Int, CaseIterable {
    case smartDNSLanIPv4
    case smartDNSLanIPv6
    case lanIPv4
    case lanIPv6
    case fqdn
    case ddns
    case smartDNSHost
    case smartDNSWanIPv6
    case smartDNSWanIPv4
    case wanIPv6
    case wanIPv4
  }
}
