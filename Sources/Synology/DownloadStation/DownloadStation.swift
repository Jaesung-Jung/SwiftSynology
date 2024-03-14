//
//  DownloadStation.swift
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

import Foundation
import Alamofire

public struct DownloadStation: DSRequestable, DSPollable, AuthenticationProviding {
  typealias Failure = DownloadStationError

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

  public func info() async throws -> Info {
    let api = DiskStationAPI<Info>(
      name: "SYNO.DownloadStation.Info",
      method: "GetInfo",
      preferredVersion: 1
    )
    return try await dataTask(api).data()
  }

  public func config() async throws -> Config {
    let api = DiskStationAPI<Config>(
      name: "SYNO.DownloadStation.Info",
      method: "GetConfig",
      preferredVersion: 2
    )
    return try await dataTask(api).data()
  }

  public func setConfig(_ config: Config) async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.DownloadStation.Info",
      method: "SetServerConfig",
      preferredVersion: 1,
      parameters: [
        Config.CodingKeys.bitTorrentMaxDownload.rawValue: config.bitTorrentMaxDownload,
        Config.CodingKeys.bitTorrentMaxUpload.rawValue: config.bitTorrentMaxUpload,
        Config.CodingKeys.emuleMaxDownload.rawValue: config.emuleMaxDownload,
        Config.CodingKeys.emuleMaxUpload.rawValue: config.emuleMaxUpload,
        Config.CodingKeys.nzbMaxDownload.rawValue: config.nzbMaxDownload,
        Config.CodingKeys.ftpMaxDownload.rawValue: config.ftpMaxDownload,
        Config.CodingKeys.httpMaxDownload.rawValue: config.httpMaxDownload,
        Config.CodingKeys.defaultDestination.rawValue: config.defaultDestination,
        Config.CodingKeys.emuleDefaultDestination.rawValue: config.emuleDefaultDestination,
        Config.CodingKeys.isEmuleServiceEnabled.rawValue: config.isEmuleServiceEnabled,
        Config.CodingKeys.isUnzipServiceEnabled.rawValue: config.isUnzipServiceEnabled
      ]
    )
    return try await dataTask(api).result()
  }

  public func scheduleConfig() async throws -> ScheduleConfig {
    let api = DiskStationAPI<ScheduleConfig>(
      name: "SYNO.DownloadStation.Schedule",
      method: "GetConfig",
      preferredVersion: 1
    )
    return try await dataTask(api).data()
  }

  public func setScheduleConfig(_ config: ScheduleConfig) async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.DownloadStation.Schedule",
      method: "SetConfig",
      preferredVersion: 1,
      parameters: [
        ScheduleConfig.CodingKeys.isEnabled.rawValue: config.isEnabled,
        ScheduleConfig.CodingKeys.isEmulEnabled.rawValue: config.isEmulEnabled
      ]
    )
    return try await dataTask(api).result()
  }
}

// MARK: - DownloadStation.Info

extension DownloadStation {
  public struct Info: Decodable {
    public let isManager: Bool
    public let version: Int
    public let versionString: String

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.isManager = try container.decode(Bool.self, forKey: "is_manager")
      self.version = try container.decode(Int.self, forKey: "version")
      self.versionString = try container.decode(String.self, forKey: "version_string")
    }
  }
}

// MARK: - DownloadStation.Config

extension DownloadStation {
  public struct Config: Decodable {
    /// Max Bit Torrent download speed in KB/s ('0' means unlimited)
    public let bitTorrentMaxDownload: Int
    /// Max Bit Torrent upload speed in KB/s ('0' means unlimited)
    public let bitTorrentMaxUpload: Int
    /// Max eMule download speed in KB/s ('0' means unlimited)
    public let emuleMaxDownload: Int
    /// Max eMule upload speed in KB/s ('0' means unlimited)
    public let emuleMaxUpload: Int
    /// Max NZB download speed in KB/s ('0' means unlimited)
    public let nzbMaxDownload: Int
    /// Max FTP download speed in KB/s ('0' means unlimited)
    public let ftpMaxDownload: Int
    /// Max HTTP download speed in KB/s ('0' means unlimited)
    public let httpMaxDownload: Int
    /// Default download destination
    public let defaultDestination: String?
    /// Default download destination for Emule
    public let emuleDefaultDestination: String?
    /// If eMule service is enabled
    public let isEmuleServiceEnabled: Bool
    /// If Auto unzip service is enabled for users except admin or administrators group
    public let isUnzipServiceEnabled: Bool

    public enum CodingKeys: String, CodingKey {
      case bitTorrentMaxDownload = "bt_max_download"
      case bitTorrentMaxUpload = "bt_max_upload"
      case emuleMaxDownload = "emule_max_download"
      case emuleMaxUpload = "emule_max_upload"
      case nzbMaxDownload = "nzb_max_download"
      case ftpMaxDownload = "ftp_max_download"
      case httpMaxDownload = "http_max_download"
      case defaultDestination = "default_destination"
      case emuleDefaultDestination = "emule_default_destination"
      case isEmuleServiceEnabled = "emule_enabled"
      case isUnzipServiceEnabled = "unzip_service_enabled"
    }
  }
}

// MARK: - DownloadStation.ScheduleConfig

extension DownloadStation {
  public struct ScheduleConfig: Decodable {
    /// If download schedule is enabled
    public let isEnabled: Bool
    /// If eMule download schedule is enabled
    public let isEmulEnabled: Bool

    public enum CodingKeys: String, CodingKey {
      case isEnabled = "enabled"
      case isEmulEnabled = "emule_enabled"
    }
  }
}
