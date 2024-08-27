//
//  CodePage.swift
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

public enum CodePage: String {
  case englishUS = "enu"
  case chineseTraditional = "cht"
  case chineseSimplified = "chs"
  case korean = "krn"
  case german = "ger"
  case french = "fre"
  case italian = "ita"
  case spanish = "spn"
  case japanese = "jpn"
  case danish = "dan"
  case norwegian = "nor"
  case swedish = "sve"
  case dutch = "nld"
  case russian = "rus"
  case polish = "plk"
  case portugueseBrazil = "ptb"
  case portuguesePortugal = "ptg"
  case hungarian = "hun"
  case turkish = "trk"
  case czech = "csy"

  init(languageCode: String) {
    switch languageCode {
    case "zh_Hant":
      self = .chineseTraditional
    case "zh_Hans":
      self = .chineseSimplified
    case "ko":
      self = .korean
    case "de":
      self = .german
    case "fr":
      self = .french
    case "it":
      self = .italian
    case "es":
      self = .spanish
    case "ja":
      self = .japanese
    case "da":
      self = .danish
    case "no":
      self = .norwegian
    case "sv":
      self = .swedish
    case "nl":
      self = .dutch
    case "ru":
      self = .russian
    case "pl":
      self = .polish
    case "":
      self = .portugueseBrazil
    case "pt":
      self = .portuguesePortugal
    case "hu":
      self = .hungarian
    case "tr":
      self = .turkish
    case "cs":
      self = .czech
    default:
      self = .englishUS
    }
  }
}
