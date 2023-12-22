//
//  FileStation.swift
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

// MARK: - FileStation

public struct FileStation: DSRequestable, DSTranferable, DSPollable, AuthenticationProviding, RegionSupporting {
  typealias Failure = FileStationError

  let serverURL: URL
  let session: Session
  let apiInfo: APIInfo?
  let auth: AuthStore
  let region: Region

  init(serverURL: URL, session: Session, apiInfo: APIInfo, auth: AuthStore, region: Region) {
    self.serverURL = serverURL
    self.session = session
    self.apiInfo = apiInfo
    self.auth = auth
    self.region = region
  }

  public func info() async throws -> Info {
    let api = DiskStationAPI<Info>(
      name: "SYNO.FileStation.Info",
      method: "get",
      preferredVersion: 2
    )
    return try await dataTask(api).data()
  }

  public func md5(filePath: String) async throws -> BackgroundTask<MD5, Empty> {
    return try await BackgroundTask {
      let api = DiskStationAPI<TaskID>(
        name: "SYNO.FileStation.MD5",
        method: "start",
        preferredVersion: 2,
        parameters: [
          "file_path": filePath
        ]
      )
      return try await dataTask(api).data()
    } status: { taskID in
      let api = DiskStationAPI<MD5>(
        name: "SYNO.FileStation.MD5",
        method: "status",
        preferredVersion: 2,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await backgroundDataTask(api).data()
    } stop: { taskID in
      let api = DiskStationAPI<Void>(
        name: "SYNO.FileStation.MD5",
        method: "stop",
        preferredVersion: 2,
        parameters: [
          "taskid": taskID.id
        ]
      )
      try await dataTask(api).result()
    }
  }

  public func upload(to path: String, fileURL: URL, create shouldCreate: Bool = false, overwrite: Bool = false, dates: Dates? = nil) async throws -> UploadTask<Void> {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Upload",
      method: "upload",
      preferredVersion: 3,
      parameters: .formData { version in
        [
          .text(path, name: "path"),
          .text("\(shouldCreate)", name: "create_parents"),
          .text(version > 2 ? overwrite ? "overwrite" : "skip" : "\(overwrite)", name: "overwrite"),
          dates.map { .text("\(Int($0.created.timeIntervalSince1970 * 1000))", name: "crtime") },
          dates.map { .text("\(Int($0.modified.timeIntervalSince1970 * 1000))", name: "mtime") },
          dates.map { .text("\(Int($0.accessed.timeIntervalSince1970 * 1000))", name: "atime") },
          .fileURL(fileURL, name: "file")
        ]
      }
    )
    return try await uploadTask(api, to: path, fileName: fileURL.lastPathComponent)
  }

  public func upload(to path: String, data: Data, fileName: String, create shouldCreate: Bool = false, overwrite: Bool = false, dates: Dates? = nil) async throws -> UploadTask<Void> {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Upload",
      method: "upload",
      preferredVersion: 3,
      parameters: .formData { version in
        [
          .text(path, name: "path"),
          .text("\(shouldCreate)", name: "create_parents"),
          .text(version > 2 ? overwrite ? "overwrite" : "skip" : "\(overwrite)", name: "overwrite"),
          dates.map { .text("\(Int($0.created.timeIntervalSince1970 * 1000))", name: "crtime") },
          dates.map { .text("\(Int($0.modified.timeIntervalSince1970 * 1000))", name: "mtime") },
          dates.map { .text("\(Int($0.accessed.timeIntervalSince1970 * 1000))", name: "atime") },
          .fileData(data, fileName: fileName, name: "file")
        ]
      }
    )
    return try await uploadTask(api, to: path, fileName: fileName)
  }

  public func download(_ file: File) async throws -> DownloadTask<URL> {
    return try await download(at: file.path)
  }

  public func download(at filePath: String) async throws -> DownloadTask<URL> {
    let api = DiskStationAPI<URL>(
      name: "SYNO.FileStation.Download",
      method: "download",
      preferredVersion: 2,
      parameters: [
        "path": filePath,
        "mode": "download"
      ]
    )
    let path: String
    let name: String
    if let index = filePath.lastIndex(of: "/") {
      path = String(filePath[..<index])
      name = String(filePath[filePath.index(after: index)...])
    } else {
      path = ""
      name = filePath
    }
    return try await downloadTask(api, at: path, fileName: name)
  }
}

// MARK: - FileStation.Info

extension FileStation {
  public struct Info: Decodable {
    public let hostname: String
    public let isManager: Bool
    public let supportFileRequest: Bool
    public let supportFileSharing: Bool
    public let supportVirtualProtocols: [String]
    public let systemCodepage: String

    public init(hostname: String, isManager: Bool, supportFileRequest: Bool, supportFileSharing: Bool, supportVirtualProtocols: [String], systemCodepage: String) {
      self.hostname = hostname
      self.isManager = isManager
      self.supportFileRequest = supportFileRequest
      self.supportFileSharing = supportFileSharing
      self.supportVirtualProtocols = supportVirtualProtocols
      self.systemCodepage = systemCodepage
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.hostname = try container.decode(String.self, forKey: "hostname")
      self.isManager = try container.decode(Bool.self, forKey: "is_manager")
      self.supportFileRequest = try container.decode(Bool.self, forKey: "support_file_request")
      self.supportFileSharing = try container.decode(Bool.self, forKey: "support_file_sharing")
      self.supportVirtualProtocols = try container.decode([String].self, forKey: "support_virtual_protocol")
      self.systemCodepage = try container.decode(String.self, forKey: "system_codepage")
    }
  }
}

// MARK: - FileStation.Dates

extension FileStation {
  public struct Dates: Decodable, Hashable {
    public let created: Date
    public let modified: Date
    public let changed: Date
    public let accessed: Date

    public init(created: Date, modified: Date, changed: Date, accessed: Date) {
      self.created = created
      self.modified = modified
      self.changed = changed
      self.accessed = accessed
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.accessed = Date(timeIntervalSince1970: try container.decode(TimeInterval.self, forKey: "atime"))
      self.created = Date(timeIntervalSince1970: try container.decode(TimeInterval.self, forKey: "crtime"))
      self.changed = Date(timeIntervalSince1970: try container.decode(TimeInterval.self, forKey: "ctime"))
      self.modified = Date(timeIntervalSince1970: try container.decode(TimeInterval.self, forKey: "mtime"))
    }
  }
}

// MARK: - FileStation.MD5

extension FileStation {
  public struct MD5: Decodable {
    public let value: String

    public init(value: String) {
      self.value = value
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.value = try container.decode(String.self, forKey: "md5")
    }
  }
}
