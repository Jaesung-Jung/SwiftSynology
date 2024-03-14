//
//  QuickConnct+ServerInfo.swift
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

extension QuickConnect {
  struct ServerInfo: Decodable {
    let port: Int
    let externalPort: Int?
    let availablePorts: [Int]

    let server: KeyedDecodingContainer<StringCodingKey>
    let smartdns: KeyedDecodingContainer<StringCodingKey>?

    var hasSmartDNS: Bool { smartdns != nil }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      let service = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "service")

      let port = try service.decode(Int.self, forKey: "port")
      let externalPort = try service.decodeIfPresent(Int.self, forKey: "ext_port").flatMap { $0 == 0 || $0 == port ? nil : $0 }
      let availablePorts = [port, externalPort].compactMap { $0 }

      self.port = port
      self.externalPort = externalPort
      self.availablePorts = availablePorts

      self.server = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "server")
      self.smartdns = try? container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "smartdns")
    }

    func connectInfos(scheme: String) -> [ConnectInfo] {
      if hasSmartDNS {
        return [
          connectTypesForSmartDNS(scheme: scheme),
          connectTypesForDDNS(scheme: scheme),
          connectTypesForFQDN(scheme: scheme)
        ]
        .flatMap { $0 }
      } else {
        return [
          connectTypesForInternalIP(scheme: scheme),
          connectTypesForExternalIP(scheme: scheme),
          connectTypesForDDNS(scheme: scheme),
          connectTypesForFQDN(scheme: scheme)
        ]
        .flatMap { $0 }
      }
    }

    func connectTypesForSmartDNS(scheme: String) -> [ConnectInfo] {
      guard let smartdns, scheme.lowercased() == "https" else {
        return []
      }

      let ipv4: [ConnectInfo]
      if let hosts = try? smartdns.decode([String].self, forKey: "lan") {
        ipv4 = hosts.flatMap { host in
          if host.starts(with: "syn4-") {
            return availablePorts.map { ConnectInfo(type: .smartDNSWanIPv4, scheme: scheme, host: host, port: $0) }
          }
          return [ConnectInfo(type: .smartDNSLanIPv4, scheme: scheme, host: host, port: port)]
        }
      } else {
        ipv4 = []
      }

      let ipv6: [ConnectInfo]
      if let hosts = try? smartdns.decode([String].self, forKey: "lanv6") {
        ipv6 = hosts.flatMap { host in
          if host.starts(with: "syn6-") {
            return availablePorts.map { ConnectInfo(type: .smartDNSWanIPv6, scheme: scheme, host: host, port: $0) }
          }
          return [ConnectInfo(type: .smartDNSLanIPv6, scheme: scheme, host: host, port: port)]
        }
      } else {
        ipv6 = []
      }

      let hosts: [ConnectInfo]
      if let host = try? smartdns.decode(String.self, forKey: "host") {
        hosts = availablePorts.map { ConnectInfo(type: .smartDNSHost, scheme: scheme, host: host, port: $0) }
      } else {
        hosts = []
      }

      return [ipv4, ipv6, hosts].flatMap { $0 }
    }

    func connectTypesForDDNS(scheme: String) -> [ConnectInfo] {
      guard let ddns = try? server.decode(String.self, forKey: "ddns"), ddns != "NULL" else {
        return []
      }
      return availablePorts.map { ConnectInfo(type: .ddns, scheme: scheme, host: ddns, port: $0) }
    }

    func connectTypesForFQDN(scheme: String) -> [ConnectInfo] {
      guard let fqdn = try? server.decode(String.self, forKey: "fqdn"), fqdn != "NULL" else {
        return []
      }
      return availablePorts.map { ConnectInfo(type: .fqdn, scheme: scheme, host: fqdn, port: $0) }
    }

    func connectTypesForExternalIP(scheme: String) -> [ConnectInfo] {
      guard let external = try? server.nestedContainer(keyedBy: StringCodingKey.self, forKey: "external") else {
        return []
      }
      guard let ip = try? external.decode(String.self, forKey: "ip"), ip != "NULL" else {
        return []
      }
      return availablePorts.map { ConnectInfo(type: .wanIPv4, scheme: scheme, host: ip, port: $0) }
    }

    func connectTypesForInternalIP(scheme: String) -> [ConnectInfo] {
      guard let interfaces = try? server.nestedUnkeyedContainer(forKey: "interface").nestedContainers(keyedBy: StringCodingKey.self) else {
        return []
      }
      return interfaces.flatMap { interface in
        let ipv6: [ConnectInfo]
        if let containers = try? interface.nestedUnkeyedContainer(forKey: "ipv6").nestedContainers(keyedBy: StringCodingKey.self) {
          ipv6 = containers.flatMap { container -> [ConnectInfo] in
            guard let address = try? container.decode(String.self, forKey: "address") else {
              return []
            }
            if let scope = try? container.decode(String.self, forKey: "scope"), scope == "link" {
              return [ConnectInfo(type: .lanIPv6, scheme: scheme, host: address, port: port)]
            }
            return availablePorts.map { ConnectInfo(type: .wanIPv4, scheme: scheme, host: address, port: $0) }
          }
        } else {
          ipv6 = []
        }

        let ipv4: [ConnectInfo]
        if let ip = try? interface.decode(String.self, forKey: "ip") {
          ipv4 = isPrivateIP(ip)
          ? [ConnectInfo(type: .lanIPv4, scheme: scheme, host: ip, port: port)]
          : availablePorts.map { ConnectInfo(type: .wanIPv4, scheme: scheme, host: ip, port: $0) }
        } else {
          ipv4 = []
        }

        return [ipv6, ipv4].flatMap { $0 }
      }
    }

    func isPrivateIP(_ ip: String) -> Bool {
      guard !ip.isEmpty else {
        return false
      }
      let regularExpressions = [
        "^(::f{4}:)?10\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})$",
        "^(::f{4}:)?192\\.168\\.([0-9]{1,3})\\.([0-9]{1,3})$",
        "^(::f{4}:)?172\\.(1[6-9]|2\\d|30|31)\\.([0-9]{1,3})\\.([0-9]{1,3})$",
        "^(::f{4}:)?127\\.([0-9]{1,3})\\.([0-9]{1,3})\\.([0-9]{1,3})$",
        "^(::f{4}:)?169\\.254\\.([0-9]{1,3})\\.([0-9]{1,3})$",
        "^f[cd][0-9a-f]{2}:",
        "^fe80:",
        "^::1$",
        "^::$"
      ]
      return regularExpressions.first { NSPredicate(format: "SELF MATCHES %@", $0).evaluate(with: ip) } != nil
    }
  }
}
