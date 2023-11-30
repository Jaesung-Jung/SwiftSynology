//
//  BackgroundTask.swift
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

// MARK: - BackgroundTask

public actor BackgroundTask<Completed: Decodable, Processing: Decodable> {
  private var _taskID: TaskID?
  private var _taskState: TaskState

  let startBlock: () async throws -> TaskID
  let statusBlock: (TaskID) async throws -> Status
  let stopBlock: (TaskID) async throws -> Void

  init(
    start: @escaping () async throws -> TaskID,
    status: @escaping (TaskID) async throws -> Status,
    stop: @escaping (TaskID) async throws -> Void
  ) async throws {
    self._taskState = .suspended
    self.startBlock = start
    self.statusBlock = status
    self.stopBlock = stop
  }

  public func status(pollingInterval interval: Interval = .seconds(2)) async throws -> AsyncThrowingStream<Status, Error> {
    let taskID = try await getTaskID()
    return AsyncThrowingStream { continuation in
      Task {
        do {
          while _taskState != .completed && _taskState != .cancelled {
            let status = try await statusBlock(taskID)
            continuation.yield(status)
            if case .completed = status {
              _taskState = .completed
            } else {
              try? await Task.sleep(nanoseconds: interval.ns)
            }
          }
          continuation.finish()
        } catch {
          _taskState = .cancelled
          continuation.finish(throwing: error)
          try? await stopBlock(taskID)
        }
      }
    }
  }

  public func cancel() async throws {
    try await stopBlock(try await getTaskID())
    _taskState = .cancelled
  }

  func getTaskID() async throws -> TaskID {
    if let taskID = _taskID {
      return taskID
    }
    let taskID = try await startBlock()
    _taskID = taskID
    _taskState = .started
    return taskID
  }
}

// MARK: - BackgroundTask.TaskState

extension BackgroundTask {
  enum TaskState {
    case suspended
    case started
    case cancelled
    case completed
  }
}

// MARK: - BackgroundTask.Status

extension BackgroundTask {
  public enum Status: Decodable {
    case completed(Completed)
    case processing(Processing)

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      let finished = try container.decode(Bool.self, forKey: "finished")
      if finished {
        self = .completed(try Completed(from: decoder))
      } else {
        self = .processing(try Processing(from: decoder))
      }
    }
  }
}

// MARK: - BackgroundTask.Interval

extension BackgroundTask {
  public enum Interval {
    case seconds(UInt64)
    case milliseconds(UInt64)
    case microseconds(UInt64)
    case nanoseconds(UInt64)

    var ns: UInt64 {
      switch self {
      case .seconds(let s):
        return s * 1_000_000_000
      case .milliseconds(let ms):
        return ms * 1_000_000
      case .microseconds(let us):
        return us * 1_000
      case .nanoseconds(let ns):
        return ns
      }
    }
  }
}

// MARK: - TaskID

struct TaskID: Decodable {
  let id: String

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: StringCodingKey.self)
    // https://www.reddit.com/user/BeBooBailey/ (Synology API - No Such Task)
    self.id = #""\#(try container.decode(String.self, forKey: "taskid"))""#
  }
}
