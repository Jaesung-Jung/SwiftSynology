//
//  FileStation+Compress.swift
//
//  Copyright © 2024 Jaesung Jung. All rights reserved.
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

// MARK: - FileStation (Compress)

extension FileStation {
  public func compress(
    files: [File],
    destinationFilePath: String,
    level: CompressLevel? = nil,
    mode: CompressMode? = nil,
    format: CompressFormat = .zip,
    password: String? = nil
  ) async throws -> BackgroundTask<Empty, FileTaskProgress> {
    return try await compress(
      filePaths: files.map(\.path),
      destinationFilePath: destinationFilePath,
      level: level,
      mode: mode,
      format: format,
      password: password
    )
  }

  public func compress(
    filePaths: [String],
    destinationFilePath: String,
    level: CompressLevel? = nil,
    mode: CompressMode? = nil,
    format: CompressFormat = .zip,
    password: String? = nil
  ) async throws -> BackgroundTask<Empty, FileTaskProgress> {
    return try await BackgroundTask {
      let api = DiskStationAPI<TaskID>(
        name: "SYNO.FileStation.Compress",
        method: "start",
        preferredVersion: 3,
        parameters: [
          "path": "[\(filePaths.map { #""\#($0)""# }.joined(separator: ","))]",
          "dest_file_path": destinationFilePath,
          "level": level?.rawValue,
          "mode": mode?.rawValue,
          "format": format.rawValue,
          "password": password
        ]
      )
      return try await dataTask(api).data()
    } status: { taskID in
      let api = DiskStationAPI<Empty>(
        name: "SYNO.FileStation.Compress",
        method: "status",
        preferredVersion: 3,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await backgroundDataTask(api).data()
    } stop: { taskID in
      let api = DiskStationAPI<Void>(
        name: "SYNO.FileStation.Compress",
        method: "stop",
        preferredVersion: 3,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await dataTask(api).result()
    }
  }
}

// MARK: - FileStation (Extract)

extension FileStation {
  public func extract(
    file: FileStation.File,
    destinationFolderPath: String,
    overwrite: Bool,
    createSubfolder: Bool = true,
    keepDirectory: Bool = true,
    codePage: CodePage? = nil,
    password: String? = nil,
    itemID: Int? = nil
  ) async throws -> BackgroundTask<Empty, FileTaskProgress> {
    return try await extract(
      filePath: file.path,
      destinationFolderPath: destinationFolderPath,
      overwrite: overwrite,
      createSubfolder: createSubfolder,
      keepDirectory: keepDirectory,
      codePage: codePage,
      password: password,
      itemID: itemID
    )
  }

  public func extract(
    filePath: String,
    destinationFolderPath: String,
    overwrite: Bool,
    createSubfolder: Bool = true,
    keepDirectory: Bool = true,
    codePage: CodePage? = nil,
    password: String? = nil,
    itemID: Int? = nil
  ) async throws -> BackgroundTask<Empty, FileTaskProgress> {
    return try await BackgroundTask {
      let api = DiskStationAPI<TaskID>(
        name: "SYNO.FileStation.Extract",
        method: "start",
        preferredVersion: 3,
        parameters: [
          "path": filePath,
          "dest_folder_path": destinationFolderPath,
          "overwrite": "\(overwrite)",
          "create_subfolder": "\(createSubfolder)",
          "keep_dir": "\(keepDirectory)",
          "codepage": codePage?.rawValue,
          "password": password,
          "item_id": itemID
        ]
      )
      return try await dataTask(api).data()
    } status: { taskID in
      let api = DiskStationAPI<Empty>(
        name: "SYNO.FileStation.Extract",
        method: "status",
        preferredVersion: 3,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await backgroundDataTask(api).data()
    } stop: { taskID in
      let api = DiskStationAPI<Void>(
        name: "SYNO.FileStation.Extract",
        method: "stop",
        preferredVersion: 3,
        parameters: [
          "taskid": taskID.id
        ]
      )
      return try await dataTask(api).result()
    }
  }
}

// MARK: - FileStation.CompressLevel

extension FileStation {
  public enum CompressLevel: String {
    /// moderate compression and normal compression speed.
    case moderate
    /// pack files with no compress.
    case store
    /// fastest compression speed but less compression.
    case fastest
    /// slowest compression speed but optimal compression.
    case best
  }
}

// MARK: - FileStation.CompressMode

extension FileStation {
  public enum CompressMode: String {
    /// pdate existing items and add new files. If an archive does not exist, a new one is created.
    case add
    /// Update existing items if newer on the file system and add new files. If the archive does not exist create a new archive.
    case update
    /// Update existing items of an archive if newer on the file system. Does not add new files to the archive.
    case refreshen
    /// Update older files in the archive and add files that are not already in the archive.
    case synchronize
  }
}

// MARK: - FileStation.CompressFormat

extension FileStation {
  public enum CompressFormat: String {
    /// ZIP
    case zip
    /// 7z
    case sevenz = "7z"
  }
}
