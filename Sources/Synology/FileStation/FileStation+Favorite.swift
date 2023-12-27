//
//  FileStation+Favorite.swift
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

// MARK: - FileStation (Favorite)

extension FileStation {
  public func favoriteFiles(
    offset: Int? = nil,
    limit: Int? = nil,
    additionalInfo: Set<FileAdditionalInfo>? = nil,
    status: FavoriteFileFilter? = nil
  ) async throws -> Page<File> {
    let api = DiskStationAPI<Page<File>>(
      name: "SYNO.FileStation.Favorite",
      method: "list",
      preferredVersion: 2,
      parameters: [
        "offset": offset,
        "limit": limit,
        "additional": additionalInfo.map { "[\($0.map { #""\#($0.rawValue)""# }.joined(separator: ","))]" },
        "status_filter": status?.rawValue
      ]
    )
    return try await dataTask(api).elements(path: "favorites")
  }

  public func addFavoriteFile(for path: String, name: String, at index: Int? = nil) async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Favorite",
      method: "add",
      preferredVersion: 2,
      parameters: [
        "path": path,
        "name": name,
        "index": index
      ]
    )
    try await dataTask(api).result()
  }

  public func editFavoriteFile(for path: String, name: String) async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Favorite",
      method: "edit",
      preferredVersion: 2,
      parameters: [
        "path": path,
        "name": name
      ]
    )
    try await dataTask(api).result()
  }

  public func deleteFavoriteFile(of path: String) async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Favorite",
      method: "delete",
      preferredVersion: 2,
      parameters: [
        "path": path
      ]
    )
    return try await dataTask(api).result()
  }

  public func clearInvalidFavorites() async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Favorite",
      method: "clear_broken",
      preferredVersion: 2
    )
    return try await dataTask(api).result()
  }
}

// MARK: - FileStation.FavoriteFileFilter

extension FileStation {
  public enum FavoriteFileFilter: String {
    case validOnly = "valid"
    case brokenOnly = "broken"
  }
}
