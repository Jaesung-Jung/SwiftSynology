//
//  PageTests.swift
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
import Testing
@testable import Synology

@Suite
struct PageTests {
  let items = repeatElement((), count: 20).map { Int.random(in: 0...1000) }

  @Test(arguments: [20, 100])
  func testPageCreation(totalCount: Int) {
    let page = Page(offset: 1, totalCount: totalCount, elements: items)
    #expect(page.offset == 1)
    #expect(page.totalCount == totalCount)
    #expect(page.count == items.count)
  }

  @Test
  func testPageSequence() {
    let page = Page(offset: 1, totalCount: 100, elements: items)
    #expect(page.map { $0 } == items)
  }

  @Test
  func testPageCollection() {
    let page = Page(offset: 1, totalCount: 100, elements: items)
    #expect(page.startIndex == items.startIndex)
    #expect(page.endIndex == items.endIndex)

    let index = Int.random(in: 0..<items.count)
    #expect(page[index] == items[index])
  }

  @Test
  func testPageBidirectionalCollection() {
    let page = Page(offset: 1, totalCount: 100, elements: items)
    #expect(page.indices == items.indices)
  }
}
