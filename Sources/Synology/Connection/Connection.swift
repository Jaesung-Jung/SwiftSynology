//
//  Connection.swift
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

// MARK: - Connection

public struct Connection {
  static let connectionsKey = "connections"

  public var items: [Item] {
    return getItems()
  }

  public init() {
  }

  @discardableResult
  public func append(_ item: Item) -> [Item]? {
    var items = getItems()
    guard !items.contains(where: { $0.serverURL == item.serverURL }) else {
      return nil
    }
    items.append(item)
    setItems(items)
    return items
  }

  @discardableResult
  public func update(_ item: Item, at index: Int) -> [Item]? {
    var items = getItems()
    guard items.indices.contains(index) else {
      return nil
    }
    items[index] = item
    setItems(items)
    return items
  }

  public func remove(_ item: Item) -> [Item]? {
    var items = getItems()
    guard let index = items.firstIndex(of: item) else {
      return nil
    }
    items.remove(at: index)
    setItems(items)
    return items
  }

  public func remove(at index: Int) -> [Item]? {
    var items = getItems()
    guard items.indices.contains(index) else {
      return nil
    }
    items.remove(at: index)
    setItems(items)
    return items
  }
}

// MARK: - Connection (Internal)

extension Connection {
  func defaults() -> UserDefaults? {
    return UserDefaults(suiteName: "synology.connection")
  }

  func getItems() -> [Item] {
    let items = defaults()
      .flatMap { $0.data(forKey: Connection.connectionsKey) }
      .flatMap { try? JSONDecoder().decode([Item].self, from: $0) }
    return items ?? []
  }

  func setItems(_ items: [Item]) {
    guard let defaults = defaults() else {
      return
    }
    guard let data = try? JSONEncoder().encode(items) else {
      return
    }
    defaults.set(data, forKey: Connection.connectionsKey)
  }
}

// MARK: - Connection.Item

extension Connection {
  public struct Item: Codable, Hashable {
    public let alias: String
    public let serverURL: URL
  }
}
