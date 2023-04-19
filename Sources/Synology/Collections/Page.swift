//
//  Page.swift
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

// MARK: - Page

public struct Page<Element>: Collection, ExpressibleByArrayLiteral, CustomStringConvertible {
  let elements: [Element]
  let nextPage: () -> Page<Element>?

  public var startIndex: Int { elements.startIndex }

  public var endIndex: Int { count }

  public var count: Int {
    func _count(page: Self) -> Int {
      page.elements.count + (page.nextPage().map { _count(page: $0) } ?? 0)
    }
    return _count(page: self)
  }

  public var offset: Int {
    func _offset(page: Self) -> Int {
      (page.nextPage().map { _offset(page: $0) } ?? 0) + 1
    }
    return _offset(page: self) - 1
  }

  public var description: String { "\(map { $0 })" }

  public init(arrayLiteral elements: Element...) {
    self.elements = elements
    self.nextPage = { nil }
  }

  init(_ elements: [Element], nextPage: @escaping () -> Page<Element>? = { nil }) {
    self.elements = elements
    self.nextPage = nextPage
  }

  public func index(after i: Int) -> Int { i + 1 }

  public subscript(position: Int) -> Element {
    func _get(page: Self, index: Int) -> Element {
      if page.elements.count > index {
        return page.elements[index]
      } else if let nextPage = page.nextPage() {
        return _get(page: nextPage, index: index - page.elements.count)
      }
      return page.elements[index]
    }
    return _get(page: self, index: position)
  }

  public func makeIterator() -> Iterator {
    return Iterator(
      iterator: elements.makeIterator(),
      nextPage: nextPage
    )
  }

  public struct Iterator: IteratorProtocol {
    var iterator: IndexingIterator<[Element]>
    var nextPage: () -> Page<Element>?

    public mutating func next() -> Element? {
      if let nextelement = iterator.next() {
        return nextelement
      }
      if let nextPage = nextPage() {
        self.iterator = nextPage.elements.makeIterator()
        self.nextPage = nextPage.nextPage
        return self.iterator.next()
      }
      return nil
    }
  }
}

// MARK: - Page (Operator)

extension Page {
  public mutating func append(_ page: Page<Element>) {
    self = self + page
  }

  public func appending(_ page: Page<Element>) -> Page<Element> {
    return self + page
  }

  public static func + (lhs: Self, rhs: Self) -> Self {
    func _merge(page: Self) -> Self {
      if let nextPage = page.nextPage() {
        let mergedNextPage = _merge(page: nextPage)
        return Self(page.elements, nextPage: { mergedNextPage })
      }
      return Self(page.elements, nextPage: { rhs })
    }
    return _merge(page: lhs)
  }
}

// MARK: - Page (Hashable)

extension Page: Hashable, Equatable where Element: Hashable {
  public func hash(into hasher: inout Hasher) {
    func _hash(into hasher: inout Hasher, page: Page<Element>) {
      hasher.combine(page.elements)
      if let nextPage = page.nextPage() {
        _hash(into: &hasher, page: nextPage)
      }
    }
    _hash(into: &hasher, page: self)
  }

  public static func == (lhs: Page<Element>, rhs: Page<Element>) -> Bool {
    func _isEqual(lhs: Page<Element>, rhs: Page<Element>) -> Bool {
      guard lhs.elements == rhs.elements else {
        return false
      }
      guard let leftNextPage = lhs.nextPage(), let rightNextPage = rhs.nextPage() else {
        return false
      }
      return _isEqual(lhs: leftNextPage, rhs: rightNextPage)
    }
    return _isEqual(lhs: lhs, rhs: rhs)
  }
}
