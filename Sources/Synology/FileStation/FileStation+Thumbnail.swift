//
//  FileStation+Thumbnail.swift
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

// MARK: - FileStation (Thumbnail)

extension FileStation {
  public func thumbnail(for path: String, size: ThumbnailSize? = nil, orientation: ThumbnailOrientation? = nil) async throws -> PlatformImage? {
    let api = DiskStationAPI<PlatformImage>(
      name: "SYNO.FileStation.Thumb",
      method: "get",
      preferredVersion: 2,
      parameters: [
        "path": path,
        "size": size?.rawValue,
        "rotate": orientation?.rawValue
      ]
    )
    return try await imageTask(api)
  }
}

// MARK: - FileStation.ThumbnailSize

extension FileStation {
  public enum ThumbnailSize: String {
    case small
    case medium
    case large
    case original
  }
}

// MARK: - FileStation.ThumbnailOrientation

extension FileStation {
  public enum ThumbnailOrientation: Int {
    case up = 0
    case left = 1
    case down = 2
    case right = 3
  }
}
