//
//  AuthError.swift
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

// MARK: - AuthError

public class AuthError: DiskStationError {
  public override var errorDescription: String? {
    switch code {
    case 400:
      return "No such account or incorrect password"
    case 401:
      return "Disabled account"
    case 402:
      return "Permission denied"
    case 403:
      return "Required 2-factor authentication code"
    case 404:
      return "Incorrect 2-factor authentication code"
    case 406:
      return "Enforce to authenticate with 2-factor authentication code"
    case 407:
      return "Blocked IP source"
    case 408:
      return "Expired password cannot change"
    case 409:
      return "Expired password"
    case 410:
      return "Password must be changed"
    default:
      return super.errorDescription
    }
  }
}

// MARK: - AuthError (Static)

extension AuthError {
  /// No such account or incorrect password
  public static let noSuchAccountOrIncorrectPassword = AuthError(code: 400)

  /// Disabled account
  public static let disabledAccount = AuthError(code: 401)

  /// Permission denied
  public static let permissionDenied = AuthError(code: 402)

  /// Required 2-factor authentication code
  public static let requiredTwoFactorAuthenticationCode = AuthError(code: 403)

  /// Incorrect 2-factor authentication code
  public static let incorrectTwoFactorAuthenticationCode = AuthError(code: 404)

  /// Enforce to authenticate with 2-factor authentication code
  public static let enforceTwoFactorAuthenticationCode = AuthError(code: 406)

  /// Blocked IP source
  public static let blockedIPSource = AuthError(code: 407)

  /// Expired password cannot change
  public static let expiredPasswordCannotChanged = AuthError(code: 408)

  /// Expired password
  public static let expiredPassword = AuthError(code: 409)

  /// Password must be changed
  public static let passwordMustBeChanged = AuthError(code: 410)
}
