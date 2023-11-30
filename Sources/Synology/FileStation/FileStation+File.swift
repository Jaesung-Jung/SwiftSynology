//
//  FileStation+File.swift
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

extension FileStation {
  public func files(
    at path: String,
    pattern: String? = nil,
    offset: Int? = nil,
    limit: Int? = nil,
    sortBy sortDescriptor: SortDescriptor<FileSortAttribute>? = nil,
    additionalInfo: Set<FileAdditionalInfo>? = nil,
    type: FileTypeFilter? = nil
  ) async throws -> Page<File> {
    let api = DiskStationAPI<Page<File>>(
      name: "SYNO.FileStation.List",
      method: "list",
      preferredVersion: 2,
      parameters: [
        "folder_path": path,
        "pattern": pattern,
        "offset": offset,
        "limit": limit,
        "sort_by": sortDescriptor?.value,
        "sort_direction": sortDescriptor?.direction,
        "additional": additionalInfo?.map { #""\#($0)""# }.joined(separator: ",").map { "[\($0)]" },
        "filetype": type?.rawValue
      ]
    )
    return try await dataTask(api).elements(path: "files")
  }

  public func fileInfo(for path: String, additionalInfo: Set<FileAdditionalInfo>? = nil) async throws -> File {
    guard let file = try await fileInfo(for: [path]).first else {
      throw Failure.invalidResponse
    }
    return file
  }

  public func fileInfo(for paths: [String], additionalInfo: Set<FileAdditionalInfo>? = nil) async throws -> [File] {
    guard !paths.isEmpty else {
      return []
    }
    let api = DiskStationAPI<[File]>(
      name: "SYNO.FileStation.List",
      method: "getinfo",
      preferredVersion: 2,
      parameters: [
        "path": "[\(paths.map { #""\#($0)""# }.joined(separator: ","))]",
        "additional": additionalInfo?.map { #""\#($0)""# }.joined(separator: ",").map { "[\($0)]" },
      ]
    )
    return try await dataTask(api).data(path: "files")
  }

  public func create(directoryPath: String, name: String, createIntermediateDirectories: Bool? = nil, additionalInfo: Set<FileAdditionalInfo>? = nil) async throws -> File {
    return try await create(directory: NewDirectoryInfo(path: directoryPath, name: name))
  }

  public func create(directory: NewDirectoryInfo, createIntermediateDirectories: Bool? = nil, additionalInfo: Set<FileAdditionalInfo>? = nil) async throws -> File {
    guard let directory = try await create(directories: [directory], createIntermediateDirectories: createIntermediateDirectories, additionalInfo: additionalInfo).first else {
      throw Failure.invalidResponse
    }
    return directory
  }

  public func create(directories: [NewDirectoryInfo], createIntermediateDirectories: Bool? = nil, additionalInfo: Set<FileAdditionalInfo>? = nil) async throws -> [File] {
    let api = DiskStationAPI<[File]>(
      name: "SYNO.FileStation.CreateFolder",
      method: "create",
      preferredVersion: 2,
      parameters: [
        "folder_path": "[\(directories.map { #""\#($0.path)""# }.joined(separator: ","))]",
        "name": "[\(directories.map { #""\#($0.name)""# }.joined(separator: ","))]",
        "force_parent": createIntermediateDirectories,
        "additional": additionalInfo?.map { #""\#($0)""# }.joined(separator: ",").map { "[\($0)]" },
      ]
    )
    return try await dataTask(api).data(path: "folders")
  }

  public func rename(filePath: String, to name: String, additionalInfo: Set<FileAdditionalInfo>? = nil, searchTaskID: String? = nil) async throws -> File {
    return try await rename(RenameInfo(path: filePath, name: name))
  }

  public func rename(file: File, to name: String, additionalInfo: Set<FileAdditionalInfo>? = nil, searchTaskID: String? = nil) async throws -> File {
    return try await rename(RenameInfo(path: file.path, name: name))
  }

  public func rename(_ renameInfo: RenameInfo, additionalInfo: Set<FileAdditionalInfo>? = nil, searchTaskID: String? = nil) async throws -> File {
    guard let file = try await rename([renameInfo], additionalInfo: additionalInfo, searchTaskID: searchTaskID).first else {
      throw Failure.invalidResponse
    }
    return file
  }

  public func rename(_ renameInfos: [RenameInfo], additionalInfo: Set<FileAdditionalInfo>? = nil, searchTaskID: String? = nil) async throws -> [File] {
    let api = DiskStationAPI<[File]>(
      name: "SYNO.FileStation.Rename",
      method: "rename",
      preferredVersion: 2,
      parameters: [
        "path": "[\(renameInfos.map { #""\#($0.path)""# }.joined(separator: ","))]",
        "name": "[\(renameInfos.map { #""\#($0.name)""# }.joined(separator: ","))]",
        "additional": additionalInfo?.map { #""\#($0)""# }.joined(separator: ",").map { "[\($0)]" },
        "search_taskid": searchTaskID
      ]
    )
    return try await dataTask(api).data(path: "files")
  }

  public func delete(file: File, recursive: Bool? = nil, searchTaskID: String? = nil) async throws {
    return try await delete(filePaths: [file.path], recursive: recursive, searchTaskID: searchTaskID)
  }

  public func delete(files: [File], recursive: Bool? = nil, searchTaskID: String? = nil) async throws {
    return try await delete(filePaths: files.map(\.path), recursive: recursive, searchTaskID: searchTaskID)
  }

  public func delete(filePath: String, recursive: Bool? = nil, searchTaskID: String? = nil) async throws {
    return try await delete(filePaths: [filePath], recursive: recursive, searchTaskID: searchTaskID)
  }

  public func delete(filePaths: [String], recursive: Bool? = nil, searchTaskID: String? = nil) async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Delete",
      method: "delete",
      preferredVersion: 2,
      parameters: [
        "path": "[\(filePaths.map { #""\#($0)""# }.joined(separator: ","))]",
        "recursive": recursive,
        "search_taskid": searchTaskID
      ]
    )
    return try await dataTask(api).result()
  }

  public func directorySize(of file: File) async throws -> BackgroundTask<DirectoryInfo, DirectoryInfo> {
    return try await directorySize(at: file.path)
  }

  public func directorySize(at path: String) async throws -> BackgroundTask<DirectoryInfo, DirectoryInfo> {
    return try await BackgroundTask {
      let api = DiskStationAPI<TaskID>(
        name: "SYNO.FileStation.DirSize",
        method: "start",
        preferredVersion: 2,
        parameters: [
          "path": #"["\#(path)"]"#
        ]
      )
      return try await dataTask(api).data()
    } status: { taskID in
      let api = DiskStationAPI<DirectoryInfo>(
        name: "SYNO.FileStation.DirSize",
        method: "status",
        preferredVersion: 2,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await backgroundDataTask(api).data()
    } stop: { taskID in
      let api = DiskStationAPI<Void>(
        name: "SYNO.FileStation.DirSize",
        method: "stop",
        preferredVersion: 2,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await dataTask(api).result()
    }
  }
}

// MARK: - FileStation.File

extension FileStation {
  public struct File: Decodable, Hashable {
    public let name: String
    public let path: String
    public let isDirectory: Bool

    // Additional info
    public let absolutePath: String?
    public let mountPointType: String?
    public let size: UInt64?
    public let owner: Owner?
    public let dates: Dates?
    public let permission: Permission?
    public let type: String?

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.path = try container.decode(String.self, forKey: "path")
      self.isDirectory = try container.decode(Bool.self, forKey: "isdir")

      if let additional = try? container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "additional") {
        self.absolutePath = try additional.decodeIfPresent(String.self, forKey: "real_path")
        self.mountPointType = try additional.decodeIfPresent(String.self, forKey: "mount_point_type")
        self.size = try additional.decodeIfPresent(UInt64.self, forKey: "size")
        self.owner = try additional.decodeIfPresent(Owner.self, forKey: "owner")
        self.dates = try additional.decodeIfPresent(Dates.self, forKey: "time")
        self.permission = try additional.decodeIfPresent(Permission.self, forKey: "perm")
        self.type = try additional.decodeIfPresent(String.self, forKey: "type")
      } else {
        self.absolutePath = nil
        self.mountPointType = nil
        self.size = nil
        self.owner = nil
        self.dates = nil
        self.permission = nil
        self.type = nil
      }
    }
  }
}

// MARK: - FileStation.Owner

extension FileStation {
  public struct Owner: Decodable, Hashable {
    public let gid: Int
    public let group: String
    public let uid: Int
    public let user: String
  }
}

// MARK: - FileStation.Permission

extension FileStation {
  public struct Permission: Decodable, Hashable {
    public let acl: FileStation.ACL
    public let isACLMode: Bool
    public let posix: Int

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.acl = try container.decode(ACL.self, forKey: "acl")
      self.isACLMode = try container.decode(Bool.self, forKey: "is_acl_mode")
      self.posix = try container.decode(Int.self, forKey: "posix")
    }
  }
}

// MARK: - FileStation.ACL

extension FileStation {
  public struct ACL: Decodable, Hashable {
    public let append: Bool
    public let delete: Bool
    public let execute: Bool
    public let read: Bool
    public let write: Bool

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.append = try container.decode(Bool.self, forKey: "append")
      self.delete = try container.decode(Bool.self, forKey: "del")
      self.execute = try container.decode(Bool.self, forKey: "exec")
      self.read = try container.decode(Bool.self, forKey: "read")
      self.write = try container.decode(Bool.self, forKey: "write")
    }
  }
}

// MARK: - FileStation.DirectoryInfo

extension FileStation {
  public struct DirectoryInfo: Decodable, Hashable {
    let numberOfDirectories: Int
    let numberOfFiles: Int
    let totalSize: UInt64

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.numberOfDirectories = try container.decode(Int.self, forKey: "num_dir")
      self.numberOfFiles = try container.decode(Int.self, forKey: "num_file")
      self.totalSize = try container.decode(UInt64.self, forKey: "total_size")
    }
  }
}

// MARK: - FileStation.FileSortAttribute

extension FileStation {
  public enum FileSortAttribute: String, CustomStringConvertible {
    case name
    case size
    case user
    case group
    case modifiedTime = "mtime"
    case accessTime = "atime"
    case changedTime = "ctime"
    case createdTime = "crtime"
    case posix
    case fileExtension = "type"

    public var description: String { rawValue }
  }
}

// MARK: - FileStation.FileAdditionalInfo

extension FileStation {
  public enum FileAdditionalInfo: String {
    case absolutePath = "real_path"
    case size
    case owner
    case time
    case permission = "perm"
    case mountPointType = "mount_point_type"
    case type
  }
}

// MARK: - FileStation.FileType

extension FileStation {
  public enum FileTypeFilter: String {
    case fileOnly = "file"
    case directoryOnly = "dir"
  }
}

// MARK: - FileStation.NewDirectoryInfo

extension FileStation {
  public struct NewDirectoryInfo {
    let path: String
    let name: String
  }
}

// MARK: - FileStation.RenameFile

extension FileStation {
  public struct RenameInfo {
    let path: String
    let name: String
  }
}
