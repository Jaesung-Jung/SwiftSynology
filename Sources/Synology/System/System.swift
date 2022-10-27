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
    let pid: Int
    let from: String
    let type: String
    let who: String
    let desc: String

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
    let pid: Int
    let command: String
    let cpu: Int
    let memory: UInt
    let sharedMemory: UInt
    let status: String
    var isRunning: Bool { status == "R" }

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
