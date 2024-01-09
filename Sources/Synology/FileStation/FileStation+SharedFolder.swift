//
//  FileStation+SharedFolder.swift
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

// MARK: - FileStation (SharedFolder)

extension FileStation {
  public func sharedFolders(
    offset: Int? = nil,
    limit: Int? = nil,
    sortBy sortDescriptor: SortBy<SharedFolderSortAttribute>? = nil,
    additionalInfo: Set<SharedFolderAdditionalInfo>? = nil,
    onlyWritable: Bool = false
  ) async throws -> Page<SharedFolder> {
    let api = DiskStationAPI<Page<SharedFolder>>(
      name: "SYNO.FileStation.List",
      method: "list_share",
      preferredVersion: 2,
      parameters: [
        "offset": offset,
        "limit": limit,
        "sort_by": sortDescriptor?.attribute.rawValue,
        "sort_direction": sortDescriptor?.direction,
        "additional": additionalInfo.map { "[\($0.map { #""\#($0.rawValue)""# }.joined(separator: ","))]" },
        "onlywritable": "\(onlyWritable)"
      ]
    )
    return try await dataTask(api).elements(path: "shares")
  }
}

// MARK: - FileStation.SharedFolder

extension FileStation {
  public struct SharedFolder: Decodable, Hashable {
    public let name: String
    public let path: String
    public let isDirectory: Bool

    // Additional info
    public let absolutePath: String?
    public let mountPointType: String?
    public let owner: Owner?
    public let dates: Dates?
    public let permission: Permission?

    public let isReadOnly: Bool?
    public let freeSpace: UInt64?
    public let totalSpace: UInt64?
    public var usesSpace: UInt64? {
      guard let totalSpace, let freeSpace else {
        return nil
      }
      return totalSpace - freeSpace
    }

    public init(name: String, path: String, isDirectory: Bool, absolutePath: String?, mountPointType: String?, owner: Owner?, dates: Dates?, permission: Permission?, isReadOnly: Bool?, freeSpace: UInt64?, totalSpace: UInt64?) {
      self.name = name
      self.path = path
      self.isDirectory = isDirectory
      self.absolutePath = absolutePath
      self.mountPointType = mountPointType
      self.owner = owner
      self.dates = dates
      self.permission = permission
      self.isReadOnly = isReadOnly
      self.freeSpace = freeSpace
      self.totalSpace = totalSpace
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.path = try container.decode(String.self, forKey: "path")
      self.isDirectory = try container.decode(Bool.self, forKey: "isdir")

      if let additional = try? container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "additional") {
        self.absolutePath = try additional.decodeIfPresent(String.self, forKey: "real_path")
        self.mountPointType = try additional.decodeIfPresent(String.self, forKey: "mount_point_type")
        self.owner = try additional.decodeIfPresent(Owner.self, forKey: "owner")
        self.dates = try additional.decodeIfPresent(Dates.self, forKey: "time")
        self.permission = try additional.decodeIfPresent(Permission.self, forKey: "perm")

        let volume = try? additional.nestedContainer(keyedBy: StringCodingKey.self, forKey: "volume_status")
        self.isReadOnly = try volume?.decode(Bool.self, forKey: "readonly")
        self.freeSpace = try volume?.decode(UInt64.self, forKey: "freespace")
        self.totalSpace = try volume?.decode(UInt64.self, forKey: "totalspace")
      } else {
        self.absolutePath = nil
        self.mountPointType = nil
        self.owner = nil
        self.dates = nil
        self.permission = nil
        self.isReadOnly = nil
        self.freeSpace = nil
        self.totalSpace = nil
      }
    }
  }
}

// MARK: - FileStation.SharedFolderSortAttribute

extension FileStation {
  public enum SharedFolderSortAttribute: String, CustomStringConvertible {
    case name
    case size
    case user
    case group
    case modifiedTime = "mtime"
    case accessTime = "atime"
    case changedTime = "ctime"
    case createdTime = "crtime"
    case posix

    public var description: String { rawValue }
  }
}

// MARK: - FileStation.SharedFolderAdditionalInfo

extension FileStation {
  public enum SharedFolderAdditionalInfo: String {
    case absolutePath = "real_path"
    case owner
    case time
    case permission = "perm"
    case mountPointType = "mount_point_type"
    case volumeStatus = "volume_status"
  }
}
