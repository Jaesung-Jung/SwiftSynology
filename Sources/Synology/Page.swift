//
//  Page.swift
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

// MARK: - Page

public struct Page<Element: Decodable> {
  public let offset: Int
  public let totalCount: Int
  public let elements: [Element]

  public var isAtEnd: Bool { elements.count >= totalCount }

  public init<C: Collection>(offset: Int, totalCount: Int, elements: C) where C.Element == Element {
    self.offset = offset
    self.totalCount = totalCount
    self.elements = Array(elements)
  }
}

// MARK: - Page (Sequence)

extension Page: Sequence {
  public func makeIterator() -> some IteratorProtocol<Element> {
    return elements.makeIterator()
  }
}

// MARK: - Page (Collection)

extension Page: Collection {
  public var startIndex: Int { elements.startIndex }

  public var endIndex: Int { elements.endIndex }

  public var count: Int { elements.count }

  public func index(after i: Int) -> Int {
    return elements.index(after: i)
  }

  public subscript(position: Int) -> Element {
    return elements[position]
  }
}

// MARK: - Page (BidirectionalCollection)

extension Page: BidirectionalCollection {
  public var indices: Range<Int> {
    return elements.indices
  }

  public func index(before i: Int) -> Int {
    return elements.index(before: i)
  }
}
