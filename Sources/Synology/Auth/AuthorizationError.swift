//
//  AuthorizationError.swift
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

public class AuthorizationError: SynologyError {
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

  public static let noSuchAccountOrIncorrectPassword = AuthorizationError(code: 400)
  public static let disabledAccount = AuthorizationError(code: 401)
  public static let permissionDenied = AuthorizationError(code: 402)
  public static let requiredTwoFactorAuthenticationCode = AuthorizationError(code: 403)
  public static let incorrectTwoFactorAuthenticationCode = AuthorizationError(code: 404)
  public static let enforceTwoFactorAuthenticationCode = AuthorizationError(code: 406)
  public static let blockedIPSource = AuthorizationError(code: 407)
  public static let expiredPasswordCanNotChanged = AuthorizationError(code: 408)
  public static let expiredPassword = AuthorizationError(code: 409)
  public static let passwordMustBeChanged = AuthorizationError(code: 410)
}
