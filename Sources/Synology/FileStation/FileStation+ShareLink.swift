//
//  FileStation+ShareLink.swift
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

// MARK: - FileStation (ShareLink)

extension FileStation {
  public func shareLinks(
    offset: Int? = nil,
    limit: Int? = nil,
    sortBy sortDescriptor: SortBy<ShareLinkSortAttribute>? = nil,
    forceClean: Bool? = nil
  ) async throws -> Page<ShareLink> {
    let api = DiskStationAPI<Page<ShareLink>>(
      name: "SYNO.FileStation.Sharing",
      method: "list",
      preferredVersion: 3,
      parameters: [
        "offset": offset,
        "limit": limit,
        "sort_by": sortDescriptor?.attribute.rawValue,
        "sort_direction": sortDescriptor?.direction,
        "force_clean": forceClean
      ]
    )
    return try await dataTask(api).elements(path: "links")
  }

  public func shareLinkInfo(_ link: ShareLink) async throws -> ShareLink {
    return try await shareLinkInfo(id: link.id)
  }

  public func shareLinkInfo(id: String) async throws -> ShareLink {
    let api = DiskStationAPI<ShareLink>(
      name: "SYNO.FileStation.Sharing",
      method: "getinfo",
      preferredVersion: 3,
      parameters: [
        "id": id
      ]
    )
    return try await dataTask(api).data()
  }

  public func createShareLink(file: File, password: String? = nil, availableDate: Date? = nil, expiredDate: Date? = nil) async throws -> ShareLink {
    return try await createShareLink(path: file.path, password: password, availableDate: availableDate, expiredDate: expiredDate)
  }

  public func createShareLink(path: String, password: String? = nil, availableDate: Date? = nil, expiredDate: Date? = nil) async throws -> ShareLink {
    guard let link = try await createShareLink(paths: [path], password: password, availableDate: availableDate, expiredDate: expiredDate).first else {
      throw Failure.invalidResponse
    }
    return link
  }

  public func createShareLink(files: [File], password: String? = nil, availableDate: Date? = nil, expiredDate: Date? = nil) async throws -> [ShareLink] {
    return try await createShareLink(paths: files.map(\.path), password: password, availableDate: availableDate, expiredDate: expiredDate)
  }

  public func createShareLink(paths: [String], password: String? = nil, availableDate: Date? = nil, expiredDate: Date? = nil) async throws -> [ShareLink] {
    let dateFormatter = await dateFormatter(ShareLink.self)
    let api = DiskStationAPI<[ShareLink]>(
      name: "SYNO.FileStation.Sharing",
      method: "create",
      preferredVersion: 3,
      parameters: [
        "path": "[\(paths.map { #""\#($0)""# }.joined(separator: ","))]",
        "password": password,
        "date_available": availableDate.map { #""\#(dateFormatter.string(from: $0))""# },
        "sort_direction": expiredDate.map { #""\#(dateFormatter.string(from: $0))""# }
      ]
    )
    return try await dataTask(api).data(path: "links")
  }

  public func editShareLink(_ shareLink: ShareLink, password: String? = nil, availableDate: Date? = nil, expiredDate: Date? = nil) async throws {
    return try await editShareLink(id: shareLink.id, password: password, availableDate: availableDate, expiredDate: expiredDate)
  }

  public func editShareLink(id: String, password: String? = nil, availableDate: Date? = nil, expiredDate: Date? = nil) async throws {
    let dateFormatter = await dateFormatter(ShareLink.self)
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Sharing",
      method: "edit",
      preferredVersion: 3,
      parameters: [
        "id": id,
        "password": password,
        "date_available": availableDate.map { #""\#(dateFormatter.string(from: $0))""# },
        "sort_direction": expiredDate.map { #""\#(dateFormatter.string(from: $0))""# }
      ]
    )
    return try await dataTask(api).result()
  }

  public func deleteShareLink(_ shareLink: ShareLink) async throws {
    return try await deleteShareLink(id: shareLink.id)
  }

  public func deleteShareLink(id: String) async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Sharing",
      method: "delete",
      preferredVersion: 3,
      parameters: [
        "id": id
      ]
    )
    return try await dataTask(api).result()
  }

  public func clearInvalidShareLinks() async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.Sharing",
      method: "clear_invalid",
      preferredVersion: 3
    )
    return try await dataTask(api).result()
  }
}

// MARK: - FileStation.ShareLink

extension FileStation {
  public struct ShareLink: Decodable, Hashable, CustomDateFormatting {
    static let dateFormat: String = "yyyy-MM-dd HH:mm:ss"

    /// A unique ID of a sharing link.
    public let id: String
    /// A URL of a sharing link.
    public let url: URL
    /// Base64-encoded image of QR code describing the URL of the sharing link.
    public let qrcode: String
    /// A filename of sharing link.
    public let name: String
    /// A path of sharing file.
    public let path: String
    /// If this sharing file is a directory or not.
    public let isDirectory: Bool
    /// The accessibility status of the sharing link.
    public let status: Status
    /// If this sharing link has a password or not.
    public let hasPassword: Bool
    /// User name of file owner.
    public let owner: String
    /// The available date of the sharing link in the format yyyy-MM-dd HH:mm:ss.
    public let availableDate: Date
    /// The expiration date of the sharing link in the format yyyy-MM-dd HH:mm:ss.
    public let expiredDate: Date
    // An image of QR code describing the URL of the sharing link.
    public var quecodeImage: PlatformImage? {
      qrcode.firstIndex(of: ",")
        .map { qrcode[qrcode.index(after: $0)...] }
        .flatMap { Data(base64Encoded: String($0)) }
        .flatMap { PlatformImage(data: $0) }
    }

    public init(id: String, url: URL, qrcode: String, name: String, path: String, isDirectory: Bool, status: Status, hasPassword: Bool, owner: String, availableDate: Date, expiredDate: Date) {
      self.id = id
      self.url = url
      self.qrcode = qrcode
      self.name = name
      self.path = path
      self.isDirectory = isDirectory
      self.status = status
      self.hasPassword = hasPassword
      self.owner = owner
      self.availableDate = availableDate
      self.expiredDate = expiredDate
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.url = try container.decode(URL.self, forKey: "url")
      self.qrcode = try container.decode(String.self, forKey: "qrcode")
      self.name = try container.decode(String.self, forKey: "name")
      self.path = try container.decode(String.self, forKey: "path")
      self.isDirectory = try container.decode(Bool.self, forKey: "isFolder")
      self.status = try container.decode(Status.self, forKey: "status")
      self.hasPassword = try container.decode(Bool.self, forKey: "has_password")
      self.owner = try container.decode(String.self, forKey: "link_owner")
      self.availableDate = try container.decode(Date.self, forKey: "date_available")
      self.expiredDate = try container.decode(Date.self, forKey: "date_expired")
    }

    /// The accessibility status of the sharing link.
    public enum Status: String, Decodable {
      /// The sharing link is active.
      case available = "valid"
      /// The sharing link is not active because the available date has not arrived yet.
      case unavailable = "invalid"
      /// The sharing link is not active because the available date has not arrived yet.
      case inactive = "inactive"
      /// The sharing link expired.
      case expired
      /// The sharing link broke due to a change in the file path or access permission.
      case broken
    }
  }
}

// MARK: - FileStation.ShareLinkSortAttribute

extension FileStation {
  public enum ShareLinkSortAttribute: String, CustomStringConvertible {
    case id
    case name
    case isFolder
    case path
    case expiredDate = "date_expired"
    case availableDate = "date_available"
    case status
    case url
    case owner = "link_owner"

    public var description: String { rawValue }
  }
}
