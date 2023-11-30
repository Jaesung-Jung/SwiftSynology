//
//  DiskStationError.swift
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

import Foundation

// MARK: - DiskStationError

public class DiskStationError: LocalizedError, CustomStringConvertible, Hashable, Decodable {
  public let code: Int

  required init(code: Int) {
    self.code = code
  }

  public init(error: DiskStationError) {
    self.code = error.code
  }

  public var description: String {
    return errorDescription ?? String(describing: Self.self)
  }

  public var errorDescription: String? {
    switch code {
    case -1:
      return "Invalid Response"
    case 101:
      return "No parameter of API, method or version"
    case 102:
      return "The requested API does not exist"
    case 103:
      return "The requested method does not exist"
    case 104:
      return "The requested version does not support the functionality"
    case 105:
      return "The logged in session does not have permission"
    case 106:
      return "Session timeout"
    case 107:
      return "Session interrupted by duplicate login"
    case 114:
      return "Lost parameters for this API"
    case 115:
      return "Not allowed to upload a file"
    case 119:
      return "SID not found"
    default:
      return "Unknown error (\(code))"
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(code)
  }

  public static func == (lhs: DiskStationError, rhs: DiskStationError) -> Bool {
    return lhs.code == rhs.code
  }
}

// MARK: - DiskStationError (Static)

extension DiskStationError {
  /// Invalid Response
  public static var invalidResponse: Self { Self(code: -1) }

  /// No parameter of API, method or version
  public static var missingMethodOrVersionParameter: Self { Self(code: 101) }

  /// The requested API does not exist
  public static var missingAPIParameter: Self { Self(code: 102) }

  /// The requested method does not exist
  public static var missingMethodParameter: Self { Self(code: 103) }

  /// The requested version does not support the functionality
  public static var doesNotSupportVersion: Self { Self(code: 104) }

  /// The logged in session does not have permission
  public static var doesNotHavePermission: Self { Self(code: 105) }

  /// Session timeout
  public static var sessionTimeout: Self { Self(code: 106) }

  /// Session interrupted by duplicate login
  public static var sessionInterruptedByDuplicateLogin: Self { Self(code: 107) }

  /// Lost parameters for this API
  public static var doesNotExistParameters: Self { Self(code: 114) }

  /// Not allowed to upload a file
  public static var notAllowedToUploadFile: Self { Self(code: 115) }

  /// SID not found
  public static var sidNotFound: Self { Self(code: 119) }
}
