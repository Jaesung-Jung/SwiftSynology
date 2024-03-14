//
//  DownloadStation+Task.swift
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

extension DownloadStation {
}

// MARK: - DownloadStation.Task

extension DownloadStation {
  public struct Task: Decodable {
    public let id: String
    public let title: String
    public let size: UInt64
    public let username: String
    public let type: TaskType
    public let status: TaskStatus

//    public let detail: TaskDetail?

    public let files: [File]
    public let trackers: [Tracker]
    public let peers: [Peer]

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.title = try container.decode(String.self, forKey: "title")
      self.size = try container.decode(UInt64.self, forKey: "size")
      self.username = try container.decode(String.self, forKey: "username")
      self.type = try TaskType(container.decode(String.self, forKey: "type"))
      self.status = TaskStatus(
        rawValue: try container.decode(String.self, forKey: "status"),
        extraContainer: try? container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "status_extra")
      )

      let additionalContainer = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: "additional")
      self.files = try additionalContainer.decodeIfPresent([File].self, forKey: "file") ?? []
      self.trackers = try additionalContainer.decodeIfPresent([Tracker].self, forKey: "tracker") ?? []
      self.peers = try additionalContainer.decodeIfPresent([Peer].self, forKey: "peer") ?? []
    }
  }
}

// MARK: - DownloadStation.TaskDetail

extension DownloadStation {
  public struct TaskDetail: Decodable {
    public let uri: String

    public let connectedLeechers: Int
    public let connectedPeers: Int
    public let connectedSeeders: Int

    public let totalPeers: Int
    public let totalPieces: Int

    public let createdDate: Date
    public let startedDate: Date?
    public let completedDate: Date?

    public let destinationPath: String

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.uri = try container.decode(String.self, forKey: "uri")
      self.connectedLeechers = try container.decode(Int.self, forKey: "connected_leechers")
      self.connectedPeers = try container.decode(Int.self, forKey: "connected_peers")
      self.connectedSeeders = try container.decode(Int.self, forKey: "connected_seeders")
      self.totalPeers = try container.decode(Int.self, forKey: "total_peers")
      self.totalPieces = try container.decode(Int.self, forKey: "total_pieces")
      self.createdDate = try Date(timeIntervalSince1970: container.decode(TimeInterval.self, forKey: "create_time"))
      self.startedDate = try container.decodeIfPresent(TimeInterval.self, forKey: "started_time").flatMap { $0 == 0 ? nil : Date(timeIntervalSince1970: $0) }
      self.completedDate = try container.decodeIfPresent(TimeInterval.self, forKey: "completed_time").flatMap { $0 == 0 ? nil : Date(timeIntervalSince1970: $0) }
      let destination = try container.decode(String.self, forKey: "destination")
      self.destinationPath = destination.hasPrefix("/") ? destination : "/\(destination)"
    }
  }
}

// MARK: - DownloadStation.TaskTransfer

extension DownloadStation {
  public struct TaskTransfer: Decodable {
    /// Downloaded pieces
    public let downloadedPieces: Int
    /// Downloaded size (bytes)
    public let downloadedSize: UInt64
    /// Uploaded size (bytes)
    public let uploadedSize: UInt64
    /// Download speed (byte/s)
    public let downloadSpeed: UInt64
    /// Upload speed (byte/s)
    public let uploadSpeed: UInt64

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.downloadedPieces = try container.decode(Int.self, forKey: "downloaded_pieces")
      self.downloadedSize = try container.decode(UInt64.self, forKey: "size_downloaded")
      self.uploadedSize = try container.decode(UInt64.self, forKey: "size_uploaded")
      self.downloadSpeed = try container.decode(UInt64.self, forKey: "speed_download")
      self.uploadSpeed = try container.decode(UInt64.self, forKey: "speed_upload")
    }
  }
}

// MARK: - DownloadStation.File

extension DownloadStation {
  public struct File: Decodable {
    public let index: Int
    public let name: String
    public let size: UInt64
    public let downloadedSize: UInt64
    public let isExcluded: Bool
    public let priority: Priority

    public enum Priority {
      case auto
      case low
      case normal
      case high

      init<S: StringProtocol>(_ string: S) {
        switch string {
        case "auto":
          self = .auto
        case "low":
          self = .low
        case "high":
          self = .high
        default:
          self = .normal
        }
      }
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.index = try container.decode(Int.self, forKey: "index")
      self.name = try container.decode(String.self, forKey: "filename")
      self.size = try container.decode(UInt64.self, forKey: "size")
      self.downloadedSize = try container.decode(UInt64.self, forKey: "size_downloaded")
      self.isExcluded = !(try container.decode(Bool.self, forKey: "wanted"))
      self.priority = try Priority(container.decode(String.self, forKey: "priority"))
    }
  }
}

// MARK: - DownloadStation.Tracker

extension DownloadStation {
  public struct Tracker: Decodable {
    public let url: URL
    public let peers: Int
    public let seeds: Int
    public let status: String
    public let updateTimer: Int

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.url = try container.decode(URL.self, forKey: "url")
      self.peers = try container.decode(Int.self, forKey: "peers")
      self.seeds = try container.decode(Int.self, forKey: "seeds")
      self.status = try container.decode(String.self, forKey: "status")
      self.updateTimer = try container.decode(Int.self, forKey: "update_timer")
    }
  }
}

// MARK: - DownloadStation.Peer

extension DownloadStation {
  public struct Peer: Decodable {
    public let address: String
    public let agent: String
    public let progress: Double
    public let downloadSpeed: UInt64
    public let uploadSpeed: UInt64

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.address = try container.decode(String.self, forKey: "address")
      self.agent = try container.decode(String.self, forKey: "agent")
      self.progress = try container.decode(Double.self, forKey: "progress")
      self.downloadSpeed = try container.decode(UInt64.self, forKey: "speed_download")
      self.uploadSpeed = try container.decode(UInt64.self, forKey: "speed_upload")
    }
  }
}

// MARK: - DownloadStation.TaskType

extension DownloadStation {
  public enum TaskType: Equatable {
    case bt
    case nzb
    case http
    case ftp
    case eMule
    case unknown(String)

    init<S: StringProtocol>(_ string: S) {
      switch string.lowercased() {
      case "bt":
        self = .bt
      case "nzb":
        self = .nzb
      case "http":
        self = .http
      case "ftp":
        self = .ftp
      case "emule":
        self = .eMule
      default:
        self = .unknown(String(string))
      }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.bt, .bt), (.nzb, .nzb), (.http, .http), (.ftp, .ftp), (.eMule, .eMule):
        return true
      case (.unknown(let rawValue1), .unknown(let rawValue2)):
        return rawValue1 == rawValue2
      default:
        return false
      }
    }
  }
}

// MARK: - DownloadStation.TaskStatus

extension DownloadStation {
  public enum TaskStatus {
    case waiting
    case downloading
    case paused
    case finishing
    case finished
    case hashChecking
    case seeding
    case filehostingWaiting
    case extracting(Double)
    case error(DownloadStationTaskError)
    case unknown(String)

    init<S: StringProtocol>(rawValue: S, extraContainer: KeyedDecodingContainer<StringCodingKey>?) {
      switch rawValue {
      case "waiting":
        self = .waiting
      case "downloading":
        self = .downloading
      case "paused":
        self = .paused
      case "finishing":
        self = .finishing
      case "finished":
        self = .finished
      case "hash_checking":
        self = .hashChecking
      case "seeding":
        self = .seeding
      case "filehosting_waiting":
        self = .filehostingWaiting
      case "extracting":
        let progress = try? extraContainer?.decodeIfPresent(Double.self, forKey: "unzip_progress")
        self = .extracting((progress ?? 0) / 100)
      case "error":
        if let errorDetail = try? extraContainer?.decodeIfPresent(String.self, forKey: "error_detail") {
          self = .error(.reason(errorDetail))
        } else {
          self = .error(.unknown)
        }
      default:
        self = .unknown(String(rawValue))
      }
    }
  }
}
