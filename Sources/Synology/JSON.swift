//
//  JSON.swift
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

@dynamicMemberLookup
struct JSON {
  let element: Element

  init(_ element: JSON.Element) {
    self.element = element
  }

  subscript(dynamicMember dynamicMemeber: String) -> JSON {
    guard case .dictionary(let dictionary) = element, let item = dictionary[dynamicMemeber] else {
      return JSON(.null)
    }
    return item
  }

  subscript(key: String) -> JSON {
    guard case .dictionary(let dictionary) = element, let item = dictionary[key] else {
      return JSON(.null)
    }
    return item
  }

  subscript(index: Int) -> JSON {
    guard case .array(let array) = element, array.indices.contains(index) else {
      return JSON(.null)
    }
    return array[index]
  }

  func value(_ type: Bool.Type = Bool.self) -> Bool? {
    guard case .bool(let bool) = element else {
      return nil
    }
    return bool
  }

  func value(_ type: Int.Type = Int.self) -> Int? {
    guard case .integer(let int) = element else {
      return nil
    }
    return int
  }

  func value(_ type: Double.Type = Double.self) -> Double? {
    guard case .double(let double) = element else {
      return nil
    }
    return double
  }

  func value(_ type: String.Type = String.self) -> String? {
    guard case .string(let string) = element else {
      return nil
    }
    return string
  }

  func value(_ type: [Any].Type = [Any].self) -> [Any]? {
    guard case .array(let array) = element else {
      return nil
    }
    return array.map(\.element.rawValue)
  }

  func value(_ type: [String: Any].Type = [String: Any].self) -> [String: Any]? {
    guard case .dictionary(let dictionary) = element else {
      return nil
    }
    return dictionary.mapValues(\.element.rawValue)
  }

  func decode<Value: Decodable>(_ type: Array<Value>.Type) -> [Value]? {
    guard case .array(let array) = element else {
      return nil
    }
    guard let data = try? JSONEncoder().encode(array) else {
      return nil
    }
    return try? JSONDecoder().decode([Value].self, from: data)
  }

  func decode<Value: Decodable>(_ type: Value.Type) -> Value? {
    guard case .dictionary(let dictionary) = element else {
      return nil
    }
    guard let data = try? JSONEncoder().encode(dictionary) else {
      return nil
    }
    return try? JSONDecoder().decode(Value.self, from: data)
  }
}

extension JSON: Codable {
  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let value = try? container.decode(Bool.self) {
      self.element = .bool(value)
    } else if let value = try? container.decode(Int.self) {
      self.element = .integer(value)
    } else if let value = try? container.decode(Double.self) {
      self.element = .double(value)
    } else if let value = try? container.decode(String.self) {
      self.element = .string(value)
    } else if let value = try? container.decode([JSON].self) {
      self.element = .array(value)
    } else if let value = try? container.decode([String: JSON].self) {
      self.element = .dictionary(value)
    } else {
      self.element = .null
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch element {
    case .bool(let bool):
      try container.encode(bool)
    case .integer(let int):
      try container.encode(int)
    case .double(let double):
      try container.encode(double)
    case .string(let string):
      try container.encode(string)
    case .array(let array):
      try container.encode(array)
    case .dictionary(let dictionary):
      try container.encode(dictionary)
    case .null:
      try container.encodeNil()
    }
  }
}

extension JSON {
  enum Element {
    case bool(Bool)
    case integer(Int)
    case double(Double)
    case string(String)
    case array([JSON])
    case dictionary([String: JSON])
    case null

    var rawValue: Any {
      switch self {
      case .bool(let bool):
        return bool
      case .integer(let int):
        return int
      case .double(let double):
        return double
      case .string(let string):
        return string
      case .array(let array):
        return array.map(\.element.rawValue)
      case .dictionary(let dictionary):
        return dictionary.mapValues(\.element.rawValue)
      case .null:
        return NSNull()
      }
    }
  }
}
