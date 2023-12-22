//
//  System.swift
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

// MARK: - System

public struct System: DSRequestable, AuthenticationProviding {
  typealias Failure = DiskStationError

  let serverURL: URL
  let session: Session
  let apiInfo: APIInfo?
  let auth: AuthStore

  init(serverURL: URL, session: Session, apiInfo: APIInfo?, auth: AuthStore) {
    self.serverURL = serverURL
    self.session = session
    self.apiInfo = apiInfo
    self.auth = auth
  }

  public func health() async throws -> Health {
    let api = DiskStationAPI<Health>(
      name: "SYNO.Core.System.SystemHealth",
      method: "get",
      preferredVersion: 1
    )
    return try await dataTask(api).data()
  }

  public func info() async throws -> Info {
    let api = DiskStationAPI<Info>(
      name: "SYNO.Core.System",
      method: "info",
      preferredVersion: 3
    )
    return try await dataTask(api).data()
  }
}

// MARK: - System.Health

extension System {
  public struct Health: Decodable {
    public struct Interface: Decodable {
      public let id: String
      public let ip: String
      public let type: String
    }

    public let hostname: String
    public let interfaces: [Interface]

    public init(hostname: String, interfaces: [Interface]) {
      self.hostname = hostname
      self.interfaces = interfaces
    }
  }
}

// MARK: - System.Info

extension System {
  public struct Info: Decodable {
    public struct CPU {
      public let clockSpeed: Int
      public let coreCount: Int
      public let family: String
      public let series: String
      public let vendor: String

      public init(clockSpeed: Int, coreCount: Int, family: String, series: String, vendor: String) {
        self.clockSpeed = clockSpeed
        self.coreCount = coreCount
        self.family = family
        self.series = series
        self.vendor = vendor
      }
    }

    public struct USB: Decodable {
      public let cls: String
      public let pid: String
      public let vendor: String
      public let product: String
      public let rev: String
      public let vid: String

      public init(cls: String, pid: String, vendor: String, product: String, rev: String, vid: String) {
        self.cls = cls
        self.pid = pid
        self.vendor = vendor
        self.product = product
        self.rev = rev
        self.vid = vid
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.cls = try container.decode(String.self, forKey: "cls")
        self.pid = try container.decode(String.self, forKey: "pid")
        self.vendor = try container.decode(String.self, forKey: "producer")
        self.product = try container.decode(String.self, forKey: "product")
        self.rev = try container.decode(String.self, forKey: "rev")
        self.vid = try container.decode(String.self, forKey: "vid")
      }
    }

    public let model: String
    public let serial: String
    public let cpu: CPU
    public let ram: Int
    public let firmwareVersion: String

    public let supportsESATA: Bool
    public let ntpEnabled: Bool
    public let ntpServer: String

    public let temperature: Int
    public let temperatureWarning: Bool

    public let upTime: TimeInterval
    public let usbDevices: [USB]

    public init(model: String, serial: String, cpu: CPU, ram: Int, firmwareVersion: String, supportsESATA: Bool, ntpEnabled: Bool, ntpServer: String, temperature: Int, temperatureWarning: Bool, upTime: TimeInterval, usbDevices: [USB]) {
      self.model = model
      self.serial = serial
      self.cpu = cpu
      self.ram = ram
      self.firmwareVersion = firmwareVersion
      self.supportsESATA = supportsESATA
      self.ntpEnabled = ntpEnabled
      self.ntpServer = ntpServer
      self.temperature = temperature
      self.temperatureWarning = temperatureWarning
      self.upTime = upTime
      self.usbDevices = usbDevices
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.model = try container.decode(String.self, forKey: "model")
      self.serial = try container.decode(String.self, forKey: "serial")
      self.cpu = try CPU(
        clockSpeed: container.decode(Int.self, forKey: "cpu_clock_speed"),
        coreCount: Int(container.decode(String.self, forKey: "cpu_cores")) ?? 1,
        family: container.decode(String.self, forKey: "cpu_family"),
        series: container.decode(String.self, forKey: "cpu_series"),
        vendor: container.decode(String.self, forKey: "cpu_vendor")
      )
      self.ram = try container.decode(Int.self, forKey: "ram_size")
      self.firmwareVersion = try container.decode(String.self, forKey: "firmware_ver")

      self.supportsESATA = try container.decode(String.self, forKey: "support_esata") == "yes"
      self.ntpEnabled = try container.decode(Bool.self, forKey: "enabled_ntp")
      self.ntpServer = try container.decodeIfPresent(String.self, forKey: "ntp_server") ?? ""

      self.temperature = try container.decode(Int.self, forKey: "sys_temp")
      self.temperatureWarning = try container.decode(Bool.self, forKey: "sys_tempwarn")

      let upTimeComponents = try container.decode(String.self, forKey: "up_time").split(separator: ":").compactMap { Int($0) }
      self.upTime = zip(upTimeComponents.reversed(), [1, 60, 3600]).map { TimeInterval($0 * $1) }.reduce(0, +)
      self.usbDevices = try container.decode([USB].self, forKey: "usb_dev")
    }
  }
}
