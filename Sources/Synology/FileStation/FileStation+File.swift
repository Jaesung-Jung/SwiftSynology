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
    sortBy sortDescriptor: SortBy<FileSortAttribute>? = nil,
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
        "sort_by": sortDescriptor?.attribute.rawValue,
        "sort_direction": sortDescriptor?.direction,
        "additional": additionalInfo.map { "[\($0.map { #""\#($0.rawValue)""# }.joined(separator: ","))]" },
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

  public func move(files: [File], destinationPath: String, overwrite: Bool, accurateProgress: Bool = false, searchTaskID: String? = nil) async throws -> BackgroundTask<Empty, FileProgress> {
    return try await move(
      filePaths: files.map(\.path),
      destinationPath: destinationPath,
      overwrite: overwrite,
      accurateProgress: accurateProgress,
      searchTaskID: searchTaskID
    )
  }

  public func move(filePaths: [String], destinationPath: String, overwrite: Bool, accurateProgress: Bool = false, searchTaskID: String? = nil) async throws -> BackgroundTask<Empty, FileProgress> {
    return try await BackgroundTask {
      let api = DiskStationAPI<TaskID>(
        name: "SYNO.FileStation.CopyMove",
        method: "start",
        preferredVersion: 3,
        parameters: [
          "path": "[\(filePaths.map { #""\#($0)""# }.joined(separator: ","))]",
          "dest_folder_path": destinationPath,
          "overwrite": "\(overwrite)",
          "remove_src": "true",
          "accurate_progress": "\(accurateProgress)",
          "search_taskid": searchTaskID
        ]
      )
      return try await dataTask(api).data()
    } status: { taskID in
      let api = DiskStationAPI<Empty>(
        name: "SYNO.FileStation.CopyMove",
        method: "status",
        preferredVersion: 3,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await backgroundDataTask(api).data()
    } stop: { taskID in
      let api = DiskStationAPI<Void>(
        name: "SYNO.FileStation.CopyMove",
        method: "stop",
        preferredVersion: 3,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await dataTask(api).result()
    }
  }

  public func copy(files: [File], destinationPath: String, overwrite: Bool, accurateProgress: Bool = false, searchTaskID: String? = nil) async throws -> BackgroundTask<Empty, FileProgress> {
    return try await copy(
      filePaths: files.map(\.path),
      destinationPath: destinationPath,
      overwrite: overwrite,
      accurateProgress: accurateProgress,
      searchTaskID: searchTaskID
    )
  }

  public func copy(filePaths: [String], destinationPath: String, overwrite: Bool, accurateProgress: Bool = false, searchTaskID: String? = nil) async throws -> BackgroundTask<Empty, FileProgress> {
    return try await BackgroundTask {
      let api = DiskStationAPI<TaskID>(
        name: "SYNO.FileStation.CopyMove",
        method: "start",
        preferredVersion: 3,
        parameters: [
          "path": "[\(filePaths.map { #""\#($0)""# }.joined(separator: ","))]",
          "dest_folder_path": destinationPath,
          "overwrite": "\(overwrite)",
          "remove_src": "false",
          "accurate_progress": "\(accurateProgress)",
          "search_taskid": searchTaskID
        ]
      )
      return try await dataTask(api).data()
    } status: { taskID in
      let api = DiskStationAPI<Empty>(
        name: "SYNO.FileStation.CopyMove",
        method: "status",
        preferredVersion: 3,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await backgroundDataTask(api).data()
    } stop: { taskID in
      let api = DiskStationAPI<Void>(
        name: "SYNO.FileStation.CopyMove",
        method: "stop",
        preferredVersion: 3,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await dataTask(api).result()
    }
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
    public let isValid: Bool
    public let fileExtension: String

    // Additional info
    public let absolutePath: String?
    public let mountPointType: String?
    public let size: UInt64?
    public let owner: Owner?
    public let dates: Dates?
    public let permission: Permission?
    public let type: String?

    public init(name: String, path: String, isDirectory: Bool, isValid: Bool, absolutePath: String?, mountPointType: String?, size: UInt64?, owner: Owner?, dates: Dates?, permission: Permission?, type: String?) {
      self.name = name
      self.path = path
      self.isDirectory = isDirectory
      self.isValid = isValid
      self.absolutePath = absolutePath
      self.mountPointType = mountPointType
      self.size = size
      self.owner = owner
      self.dates = dates
      self.permission = permission
      self.type = type
      self.fileExtension = isDirectory ? "" : name.lastIndex(of: ".").map { String(name[name.index(after: $0)...].lowercased()) } ?? ""
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      let name = try container.decode(String.self, forKey: "name")
      self.name = name
      self.path = try container.decode(String.self, forKey: "path")
      self.isDirectory = try container.decode(Bool.self, forKey: "isdir")
      self.isValid = try container.decodeIfPresent(String.self, forKey: "status_filter").map { $0.lowercased() == "valid" } ?? true
      self.fileExtension = isDirectory ? "" : name.lastIndex(of: ".").map { String(name[name.index(after: $0)...].lowercased()) } ?? ""

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

    public init(_ sharedFolder: SharedFolder) {
      self.name = sharedFolder.name
      self.path = sharedFolder.path
      self.isDirectory = sharedFolder.isDirectory
      self.isValid = true
      self.absolutePath = sharedFolder.absolutePath
      self.mountPointType = sharedFolder.mountPointType
      self.size = sharedFolder.usesSpace
      self.owner = sharedFolder.owner
      self.dates = sharedFolder.dates
      self.permission = sharedFolder.permission
      self.type = nil
      self.fileExtension = ""
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

    public init(gid: Int, group: String, uid: Int, user: String) {
      self.gid = gid
      self.group = group
      self.uid = uid
      self.user = user
    }
  }
}

// MARK: - FileStation.Permission

extension FileStation {
  public struct Permission: Decodable, Hashable {
    public let acl: ACL
    public let isACLMode: Bool
    public let posix: Int

    public init(acl: FileStation.ACL, isACLMode: Bool, posix: Int) {
      self.acl = acl
      self.isACLMode = isACLMode
      self.posix = posix
    }

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

    public init(append: Bool, delete: Bool, execute: Bool, read: Bool, write: Bool) {
      self.append = append
      self.delete = delete
      self.execute = execute
      self.read = read
      self.write = write
    }

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
    public let numberOfDirectories: Int
    public let numberOfFiles: Int
    public let totalSize: UInt64

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.numberOfDirectories = try container.decode(Int.self, forKey: "num_dir")
      self.numberOfFiles = try container.decode(Int.self, forKey: "num_file")
      self.totalSize = try container.decode(UInt64.self, forKey: "total_size")
    }
  }
}

// MARK: - FileStation.FileProgress

extension FileStation {
  public struct FileProgress: Decodable {
    public let progress: Double
    public let processedSize: UInt64
    public let totalSize: UInt64

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.progress = try container.decode(Double.self, forKey: "progress")
      self.processedSize = try container.decode(UInt64.self, forKey: "processed_size")
      self.totalSize = try container.decode(UInt64.self, forKey: "total")
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
    public let path: String
    public let name: String

    public init(path: String, name: String) {
      self.path = path
      self.name = name
    }
  }
}

// MARK: - FileStation.RenameFile

extension FileStation {
  public struct RenameInfo {
    public let path: String
    public let name: String

    public init(path: String, name: String) {
      self.path = path
      self.name = name
    }
  }
}
