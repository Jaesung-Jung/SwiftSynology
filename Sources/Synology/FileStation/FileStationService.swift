//
//  FileStationService.swift
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

public struct FileStationService: SynologyAPIClient {
  typealias Error = SynologyError

  let serverURL: URL
  let apiInfoProvider: APIInfoProvider
  let authentication: Authentication?

  public func info() async throws -> FileStation.Info {
    let api = SynologyAPI<FileStation.Info>(
      name: "SYNO.FileStation.Info",
      method: "get"
    )
    return try await request(api).data()
  }

  public func sharedFolders(offset: Int = 0, limit: Int? = nil, sort: FileStation.SortDescriptor? = nil) async throws -> Page<FileStation.SharedFolder> {
    let api = SynologyAPI<[FileStation.SharedFolder]>(
      name: "SYNO.FileStation.List",
      method: "list_share",
      parameters: [
        "offset": offset,
        "limit": limit,
        "additional": "\(["volume_status", "time", "perm"])",
        "sort_by": sort.map(\.by.rawValue),
        "sort_direction": sort.map(\.order.rawValue)
      ]
    )
    return Page(try await request(api).data(path: "shares"))
  }

  public func files(at path: String, pattern: String? = nil, offset: Int = 0, limit: Int? = nil, sort: FileStation.SortDescriptor? = nil) async throws -> Page<FileStation.File> {
    let api = SynologyAPI<[FileStation.File]>(
      name: "SYNO.FileStation.List",
      method: "list",
      parameters: [
        "folder_path": path,
        "pattern": pattern,
        "offset": offset,
        "limit": limit,
        "additional": "\(["size", "time", "perm"])",
        "sort_by": sort.map(\.by.rawValue),
        "sort_direction": sort.map(\.order.rawValue)
      ]
    )
    return Page(try await request(api).data(path: "files"))
  }
}
