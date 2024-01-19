//
//  FileStation+BackgroundTask.swift
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

// MARK: - FileStation (BackgroundTask)

extension FileStation {
  public func backgroundTasks(
    offset: Int? = nil,
    limit: Int? = nil,
    sortBy sortDescriptor: SortBy<TaskSortAttribute>? = nil,
    type: [TaskTypeFilter]? = nil
  ) async throws -> Page<TaskItem> {
    let api = DiskStationAPI<Page<TaskItem>>(
      name: "SYNO.FileStation.BackgroundTask",
      method: "list",
      preferredVersion: 3,
      parameters: [
        "offset": offset,
        "limit": limit,
        "sort_by": sortDescriptor?.attribute.rawValue,
        "sort_direction": sortDescriptor?.direction,
        "api_filter": type.map { "[\($0.map { #""\#($0.rawValue)""# }.joined(separator: ","))]" }
      ]
    )
    return try await dataTask(api).elements(path: "tasks")
  }

  public func stopBackgroundTasks(_ task: TaskItem) async throws {
    let api = DiskStationAPI<Void>(
      name: task.api,
      method: "stop",
      preferredVersion: task.version,
      parameters: [
        "taskid": task.id
      ]
    )
    return try await dataTask(api).result()
  }

  public func clearFinishedBackgroundTasks(_ tasks: [TaskItem]? = nil) async throws {
    return try await clearFinishedBackgroundTasks(tasks?.map(\.id))
  }

  public func clearFinishedBackgroundTasks(_ tasksIDs: [String]? = nil) async throws {
    let api = DiskStationAPI<Void>(
      name: "SYNO.FileStation.BackgroundTask",
      method: "clear_finished",
      preferredVersion: 3,
      parameters: [
        "taskid": tasksIDs.map { "[\($0.map { #""\#($0)""# }.joined(separator: ","))]" }
      ]
    )
    return try await dataTask(api).result()
  }
}

// MARK: - FileStation.TaskItem

extension FileStation {
  public struct TaskItem: Decodable, Hashable {
    let api: String
    let version: Int

    public let id: String
    public let type: TaskType
    public let createdDate: Date
    public let finished: Bool
    public let path: String
    public let progress: Progress

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.api = try container.decode(String.self, forKey: "api")
      self.version = try container.decode(Int.self, forKey: "version")
      self.id = try container.decode(String.self, forKey: "taskid")
      self.type = try TaskType(api: api, parameters: container.decode(JSON.self, forKey: "params"))
      self.createdDate = try Date(timeIntervalSince1970: container.decode(TimeInterval.self, forKey: "crtime"))
      self.finished = try container.decode(Bool.self, forKey: "finished")
      self.path = try container.decode(String.self, forKey: "path")
      self.progress = Progress(totalUnitCount: try container.decode(Int64.self, forKey: "total"))
      self.progress.completedUnitCount = try container.decodeIfPresent(Int64.self, forKey: "processed_size") ?? 0
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      hasher.combine(finished)
      hasher.combine(progress)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.id == rhs.id && lhs.finished == rhs.finished && lhs.progress == rhs.progress
    }
  }
}

// MARK: - FileStation.TaskType

extension FileStation {
  public enum TaskType {
    case copy
    case move
    case delete
    case extract
    case compress
    case unknown(api: String, parameters: [String: Any])

    init(api: String, parameters: JSON) {
      switch api {
      case "SYNO.FileStation.CopyMove":
        self = parameters["remove_src"].value(Bool.self) == true  ? .copy : .move
      case "SYNO.FileStation.Delete":
        self = .delete
      case "SYNO.FileStation.Extract":
        self = .extract
      case "SYNO.FileStation.Compress":
        self = .compress
      default:
        self = .unknown(api: api, parameters: parameters.value([String: Any].self) ?? [:])
      }
    }
  }
}

// MARK: - FileStation.TaskSortAttribute

extension FileStation {
  public enum TaskSortAttribute: String {
    case createdDate = "crtime"
    case finished
  }
}

// MARK: - FileStation.TaskTypeFilter

extension FileStation {
  public enum TaskTypeFilter: String, CaseIterable {
    case copyMove = "SYNO.FileStation.CopyMove"
    case delete = "SYNO.FileStation.Delete"
    case extract = "SYNO.FileStation.Extract"
    case compress = "SYNO.FileStation.Compress"
  }
}
