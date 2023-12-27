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

  public func storageInfo() async throws -> StorageInfo {
    let api = DiskStationAPI<StorageInfo>(
      name: "SYNO.Core.System",
      method: "info",
      preferredVersion: 3,
      parameters: [
        "type": "storage"
      ]
    )
    return try await dataTask(api).data()
  }
}

// MARK: - System.Health

extension System {
  public struct Health: Decodable {
    public enum Status: Int, Decodable {
      case danger
      case attention
      case normal
    }

    public struct Interface: Decodable {
      public let id: String
      public let ip: String
      public let type: String
    }

    public let hostname: String
    public let interfaces: [Interface]
    public let status: Status
    public let upTime: TimeInterval

    public init(hostname: String, interfaces: [Interface], status: Status, upTime: TimeInterval) {
      self.hostname = hostname
      self.interfaces = interfaces
      self.status = status
      self.upTime = upTime
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.hostname = try container.decode(String.self, forKey: "hostname")
      self.interfaces = try container.decode([Interface].self, forKey: "interfaces")
      do {
        let ruleContainer = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "rule")
        self.status = try ruleContainer.decodeIfPresent(Status.self, forKey: "type") ?? .normal
      } catch {
        self.status = .normal
      }
      let upTimeComponents = try container.decode(String.self, forKey: "uptime").split(separator: ":").compactMap { Int($0) }
      self.upTime = zip(upTimeComponents.reversed(), [1, 60, 3600]).map { TimeInterval($0 * $1) }.reduce(0, +)
    }
  }
}

// MARK: - System.Info

extension System {
  public struct Info: Decodable {
    public struct CPU: CustomStringConvertible {
      public let clockSpeed: Int
      public let coreCount: Int
      public let family: String
      public let series: String
      public let vendor: String

      public var description: String {
        let cpuModel = [vendor, family, series]
          .filter { !$0.isEmpty }
          .joined(separator: " ")
        let speed = Double(clockSpeed) / 1_000_000_000

        let cpuClock: String
        if #available(iOS 15.0, macCatalyst 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *) {
          let formatStyle = FloatingPointFormatStyle<Double>().precision(.fractionLength(1))
          cpuClock = speed.formatted(formatStyle)
        } else {
          cpuClock = String(format: "%.1f", Double(speed) / 1000)
        }

        return "\(cpuModel) (\(cpuClock)GHz)"
      }

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
        clockSpeed: container.decode(Int.self, forKey: "cpu_clock_speed") * 1_000_000,
        coreCount: Int(container.decode(String.self, forKey: "cpu_cores")) ?? 1,
        family: container.decode(String.self, forKey: "cpu_family"),
        series: container.decode(String.self, forKey: "cpu_series"),
        vendor: container.decode(String.self, forKey: "cpu_vendor")
      )
      self.ram = try container.decode(Int.self, forKey: "ram_size") * 1_048_576
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

extension System {
  public struct StorageInfo: Decodable {
    public struct Drive: Decodable, Hashable {
      public let order: Int
      public let no: String
      public let path: String
      public let type: String
      public let capacity: UInt64
      public let model: String
      public let status: String
      public let temp: Int

      public init(order: Int, no: String, path: String, type: String, capacity: UInt64, model: String, status: String, temp: Int) {
        self.order = order
        self.no = no
        self.path = path
        self.type = type
        self.capacity = capacity
        self.model = model
        self.status = status
        self.temp = temp
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.order = try container.decode(Int.self, forKey: "order")
        self.no = try container.decode(String.self, forKey: "diskno")
        self.path = try container.decode(String.self, forKey: "diskPath")
        self.type = try container.decode(String.self, forKey: "diskType")
        self.capacity = try UInt64(container.decode(String.self, forKey: "capacity")) ?? 0
        self.model = try container.decode(String.self, forKey: "model")
        self.status = try container.decode(String.self, forKey: "status")
        self.temp = try container.decode(Int.self, forKey: "temp")
      }
    }

    public struct Volume: Decodable, Hashable {
      public let name: String
      public let type: String
      public let status: String
      public let usedSize: UInt64
      public let totalSize: UInt64
      public let description: String
      public let volumeName: String

      public init(name: String, type: String, status: String, usedSize: UInt64, totalSize: UInt64, description: String, volumeName: String) {
        self.name = name
        self.type = type
        self.status = status
        self.usedSize = usedSize
        self.totalSize = totalSize
        self.description = description
        self.volumeName = volumeName
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.name = try container.decode(String.self, forKey: "name")
        self.type = try container.decode(String.self, forKey: "vol_desc")
        self.status = try container.decode(String.self, forKey: "status")
        self.usedSize = try UInt64(container.decode(String.self, forKey: "used_size")) ?? 0
        self.totalSize = try UInt64(container.decode(String.self, forKey: "total_size")) ?? 0
        self.description = try container.decode(String.self, forKey: "desc")
        self.volumeName =  try container.decode(String.self, forKey: "volume")
      }
    }

    public let drives: [Drive]
    public let volumes: [Volume]

    public init(drives: [Drive], volumes: [Volume]) {
      self.drives = drives
      self.volumes = volumes
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.drives = try container.decode([Drive].self, forKey: "hdd_info")
      self.volumes = try container.decode([Volume].self, forKey: "vol_info")
    }
  }
}
