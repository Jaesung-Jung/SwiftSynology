//
//  TransferTask.swift
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

// MARK: - TransferTask

public protocol TransferTask {
  associatedtype Output

  var serverURL: URL { get }
  var path: String { get }
  var name: String { get }
  var taskType: TransferTaskType { get }

  func execute() async throws -> Output
  func cancel() async
  func pause() async
  func resume() async
}

// MARK: - UploadTask

public struct UploadTask<Output>: TransferTask {
  let request: UploadRequest
  let executeBlock: () async throws -> Output

  public let serverURL: URL
  public let path: String
  public let name: String
  public let taskType: TransferTaskType

  init(serverURL: URL, path: String, name: String, request: UploadRequest, executeBlock: @escaping () async throws -> Output) {
    self.request = request
    self.executeBlock = executeBlock
    self.serverURL = serverURL
    self.path = path
    self.name = name
    self.taskType = .upload
  }

  public func execute() async throws -> Output {
    return try await executeBlock()
  }

  public func cancel() {
    request.cancel()
  }

  public func pause() {
    request.suspend()
  }

  public func resume() {
    request.resume()
  }

  public func progress() -> AsyncStream<Progress> {
    let stream = request.uploadProgress()
    return AsyncStream { continuation in
      Task {
        for await progress in stream {
          continuation.yield(progress)
        }
        continuation.finish()
      }
    }
  }
}

// MARK: - DownloadTask

public struct DownloadTask<Output>: TransferTask {
  let request: DownloadRequest
  let executeBlock: () async throws -> Output

  public let serverURL: URL
  public let path: String
  public let name: String
  public let taskType: TransferTaskType

  init(serverURL: URL, path: String, name: String, request: DownloadRequest, executeBlock: @escaping () async throws -> Output) {
    self.request = request
    self.executeBlock = executeBlock
    self.serverURL = serverURL
    self.path = path
    self.name = name
    self.taskType = .download
  }

  public func execute() async throws -> Output {
    return try await executeBlock()
  }

  public func cancel() {
    request.cancel()
  }

  public func pause() {
    request.suspend()
  }

  public func resume() {
    request.resume()
  }

  public func progress() -> AsyncStream<Progress> {
    let stream = request.downloadProgress()
    return AsyncStream { continuation in
      Task {
        for await progress in stream {
          continuation.yield(progress)
        }
        continuation.finish()
      }
    }
  }
}

// MARK: - TransferTaskType

public enum TransferTaskType {
  case upload
  case download
  case polling
}

// MARK: - TransferTaskState

public enum TransferTaskState {
  case running
  case suspended
  case canceled
}
