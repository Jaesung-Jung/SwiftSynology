//
//  JSONTests.swift
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
struct JSONTests {
  let jsonString = """
  {
    "command": "get_server_info",
    "server": {
      "ddns": "js.dsm.com",
      "ds_state": "CONNECTED",
      "gateway": "192.168.0.1",
      "interface": [
        {
          "ip": "192.168.0.250",
          "ipv6": [
            {
              "address": "ff80::200:11ff:fe55:dc33",
              "scope": "link"
            }
          ],
          "mask": "255.255.255.0",
          "name": "eth0"
        }
      ]
    },
    "service": {
      "port": 5000,
      "ext_port": 63724,
      "pingpong": "DISCONNECTED",
      "pingpong_desc": []
    },
    "smartdns": {
      "host": "js.quickconnect.com",
      "external": "syn4.js.quickconnect.com",
      "externalv6": "syn6.js.quickconnect.com",
      "lan": ["192-168-0-250.js.quickconnect.com"],
      "lanv6": ["syn6.js.quickconnect.com"],
      "hole_punch": "127-0-0-1.js.quickconnect.com"
    },
    "version": 1
  }
  """

  let json: JSON

  init() throws {
    let data = try #require(jsonString.data(using: .utf8))
    self.json = try JSONDecoder().decode(JSON.self, from: data)
  }

  @Test
  func testSubscript() throws {
    #expect(json["command"].value() == "get_server_info")
    #expect(json["server"]["interface"][0]["ip"].value() == "192.168.0.250")
    #expect(json["service"]["port"].value() == 5000)
  }

  @Test
  func testDynamicMemberLookup() {
    #expect(json.command.value() == "get_server_info")
    #expect(json.version.value() == 1)
    #expect(json.smartdns.host.value() == "js.quickconnect.com")
    #expect(json.server.interface[0].ipv6[0].address.value() == "ff80::200:11ff:fe55:dc33")
  }

  @Test
  func testNonExsistentValue() {
    #expect(json["comman"].value(String.self) == nil)
    #expect(json.unknown.value(String.self) == nil)
  }

  @Test
  func testInvalidType() {
    #expect(json.command.value(String.self) != nil)
    #expect(json.command.value(Int.self) == nil)
  }
}
