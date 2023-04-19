//
//  FileStation.swift
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

public enum FileStation {
}

// MARK: - FileStation.Info

extension FileStation {
  public struct Info: Decodable {
    public let hostname: String
    public let isAdministrator: Bool
    public let supportsSharing: Bool
    public let supportsVirtualProtocols: [String]

    public init(hostname: String, isAdministrator: Bool, supportsSharing: Bool, supportsVirtualProtocols: [String]) {
      self.hostname = hostname
      self.isAdministrator = isAdministrator
      self.supportsSharing = supportsSharing
      self.supportsVirtualProtocols = supportsVirtualProtocols
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.hostname = try container.decode(String.self, forKey: "hostname")
      self.isAdministrator = try container.decode(Bool.self, forKey: "is_manager")
      self.supportsSharing = try container.decode(Bool.self, forKey: "support_sharing")
      self.supportsVirtualProtocols = try container.decode(String.self, forKey: "support_virtual_protocol")
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
    }
  }
}

// MARK: - FileStation.SharedFolder

extension FileStation {
  public struct SharedFolder: Decodable, Hashable {
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let isReadOnly: Bool
    public let freeSpace: Int64
    public let totalSpace: Int64
    public var usesSpace: Int64 { totalSpace - freeSpace }
    public let createdTime: Date
    public let accessTime: Date
    public let changeTime: Date
    public let modifiedTime: Date

    public init(name: String, path: String, isDirectory: Bool, isReadOnly: Bool, freeSpace: Int64, totalSpace: Int64, createdTime: Date, accessTime: Date, changeTime: Date, modifiedTime: Date) {
      self.name = name
      self.path = path
      self.isDirectory = isDirectory
      self.isReadOnly = isReadOnly
      self.freeSpace = freeSpace
      self.totalSpace = totalSpace
      self.createdTime = createdTime
      self.accessTime = accessTime
      self.changeTime = changeTime
      self.modifiedTime = modifiedTime
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.path = try container.decode(String.self, forKey: "path")
      self.isDirectory = try container.decode(Bool.self, forKey: "isdir")

      let additionalContainer = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "additional")

      let volumeStatusContainer = try additionalContainer.nestedContainer(keyedBy: StringCodingKey.self, forKey: "volume_status")
      self.isReadOnly = try volumeStatusContainer.decode(Bool.self, forKey: "readonly")
      self.freeSpace = try volumeStatusContainer.decode(Int64.self, forKey: "freespace")
      self.totalSpace = try volumeStatusContainer.decode(Int64.self, forKey: "totalspace")

      let timeContainer = try additionalContainer.nestedContainer(keyedBy: StringCodingKey.self, forKey: "time")
      self.createdTime = Date(timeIntervalSince1970: try timeContainer.decode(TimeInterval.self, forKey: "crtime"))
      self.accessTime = Date(timeIntervalSince1970: try timeContainer.decode(TimeInterval.self, forKey: "atime"))
      self.changeTime = Date(timeIntervalSince1970: try timeContainer.decode(TimeInterval.self, forKey: "ctime"))
      self.modifiedTime = Date(timeIntervalSince1970: try timeContainer.decode(TimeInterval.self, forKey: "mtime"))
    }
  }
}

// MARK: - FileStation.File

extension FileStation {
  public struct File: Decodable, Hashable {
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let size: Int64
    public let createdTime: Date
    public let accessTime: Date
    public let changeTime: Date
    public let modifiedTime: Date

    public init(name: String, path: String, isDirectory: Bool, size: Int64, createdTime: Date, accessTime: Date, changeTime: Date, modifiedTime: Date) {
      self.name = name
      self.path = path
      self.isDirectory = isDirectory
      self.size = size
      self.createdTime = createdTime
      self.accessTime = accessTime
      self.changeTime = changeTime
      self.modifiedTime = modifiedTime
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.path = try container.decode(String.self, forKey: "path")
      self.isDirectory = try container.decode(Bool.self, forKey: "isdir")

      let additionalContainer = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "additional")
      self.size = try additionalContainer.decode(Int64.self, forKey: "size")

      let timeContainer = try additionalContainer.nestedContainer(keyedBy: StringCodingKey.self, forKey: "time")
      self.createdTime = Date(timeIntervalSince1970: try timeContainer.decode(TimeInterval.self, forKey: "crtime"))
      self.accessTime = Date(timeIntervalSince1970: try timeContainer.decode(TimeInterval.self, forKey: "atime"))
      self.changeTime = Date(timeIntervalSince1970: try timeContainer.decode(TimeInterval.self, forKey: "ctime"))
      self.modifiedTime = Date(timeIntervalSince1970: try timeContainer.decode(TimeInterval.self, forKey: "mtime"))
    }
  }
}

// MARK: - FileStation.SortDescriptor

extension FileStation {
  public struct SortDescriptor {
    let by: By
    let order: Order

    init(by: By, order: Order = .forward) {
      self.by = by
      self.order = order
    }

    public static func name(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .name, order: order)
    }

    public static func size(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .size, order: order)
    }

    public static func user(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .user, order: order)
    }

    public static func group(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .group, order: order)
    }

    public static func createdTime(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .createdTime, order: order)
    }

    public static func accessTime(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .accessTime, order: order)
    }

    public static func changeTime(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .changeTime, order: order)
    }

    public static func modifiedTime(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .modifiedTime, order: order)
    }

    public static func fileType(_ order: Order = .forward) -> SortDescriptor {
      return SortDescriptor(by: .fileType, order: order)
    }

    public enum By: String {
      case name
      case size
      case user
      case group
      case createdTime = "crtime"
      case accessTime = "atime"
      case changeTime = "ctime"
      case modifiedTime = "mtime"
      case fileType = "type"
    }

    public enum Order: String {
      case forward = "asc"
      case reverse = "desc"
    }
  }
}
