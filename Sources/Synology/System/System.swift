//
//  System.swift
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

public enum System {
}

// MARK: - System.Connection

extension System {
  public struct Connection: Decodable {
    public let pid: Int
    public let from: String
    public let type: String
    public let who: String
    public let desc: String

    public init(pid: Int, from: String, type: String, who: String, desc: String) {
      self.pid = pid
      self.from = from
      self.type = type
      self.who = who
      self.desc = desc
    }

    enum CodingKeys: String, CodingKey {
      case pid
      case from
      case type
      case who
      case desc = "descr"
    }
  }
}

// MARK: - System.Process

extension System {
  public struct Process: Decodable {
    public let pid: Int
    public let command: String
    public let cpu: Int
    public let memory: UInt
    public let sharedMemory: UInt
    public let status: String
    public var isRunning: Bool { status == "R" }

    public init(pid: Int, command: String, cpu: Int, memory: UInt, sharedMemory: UInt, status: String) {
      self.pid = pid
      self.command = command
      self.cpu = cpu
      self.memory = memory
      self.sharedMemory = sharedMemory
      self.status = status
    }

    enum CodingKeys: String, CodingKey {
      case pid
      case command
      case cpu
      case memory = "mem"
      case sharedMemory = "mem_shared"
      case status
    }
  }
}

// MARK: - System.VolumeInfo

extension System {
  public struct VolumeInfo: Decodable, Hashable {
    public let identifier: String
    public let name: String
    public let type: String
    public let status: String
    public let usedSpace: Int64
    public let totalSpace: Int64
    public var freeSpace: Int64 { totalSpace - usedSpace }

    public init(identifier: String, name: String, type: String, status: String, usedSpace: Int64, totalSpace: Int64) {
      self.identifier = identifier
      self.name = name
      self.type = type
      self.status = status
      self.usedSpace = usedSpace
      self.totalSpace = totalSpace
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: StringCodingKey.self)
      self.identifier = try container.decode(String.self, forKey: "volume")
      self.name = try container.decode(String.self, forKey: "name").replacingOccurrences(of: "_", with: " ").capitalized
      self.type = try container.decode(String.self, forKey: "vol_desc")
      self.status = try container.decode(String.self, forKey: "status")
      self.usedSpace = Int64(try container.decode(String.self, forKey: "used_size")) ?? 0
      self.totalSpace = Int64(try container.decode(String.self, forKey: "total_size")) ?? 0
    }
  }
}
