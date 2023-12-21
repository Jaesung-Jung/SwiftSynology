//
//  DSRequestable.swift
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
import Alamofire

// MARK: - DSRequestable

protocol DSRequestable {
  associatedtype Failure: DiskStationError

  var serverURL: URL { get }
  var session: Session { get }
  var apiInfo: APIInfo? { get }
  var sessionID: String? { get async }
}

// MARK: - DSRequestable (AuthenticationProviding)

extension DSRequestable where Self: AuthenticationProviding {
  var sessionID: String? {
    get async {
      await auth.sessionID
    }
  }
}

// MARK: - DSRequestable (RegionSupporting)

extension DSRequestable where Self: RegionSupporting {
  func dateFormatter<T: CustomDateFormatting>(_ type: T.Type) async -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = T.dateFormat
    if let timeZone = try? await region.timeZone() {
      formatter.timeZone = timeZone
    }
    return formatter
  }

  func dataTask<Output: Decodable & CustomDateFormatting>(_ api: DiskStationAPI<Output>) async throws -> DiskStationResponse<Output, Failure> {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(await dateFormatter(Output.self))
    return try await session.request(makeRequest(api: api)).serializingDecodable(decoder: decoder).value
  }

  func dataTask<Element: Decodable & CustomDateFormatting>(_ api: DiskStationAPI<Page<Element>>) async throws -> DiskStationPageResponse<Element, Failure> {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(await dateFormatter(Element.self))
    return try await session.request(makeRequest(api: api)).serializingDecodable(decoder: decoder).value
  }
}

// MARK: - DSRequestable (Default Implemtation)

extension DSRequestable {
  var apiInfo: APIInfo? { nil }

  func dataTask(_ api: DiskStationAPI<Void>) async throws -> DiskStationEmptyResponse<Failure> {
    return try await session.request(makeRequest(api: api)).serializingDecodable().value
  }

  func dataTask<Output: Decodable>(_ api: DiskStationAPI<Output>) async throws -> DiskStationResponse<Output, Failure> {
    return try await session.request(makeRequest(api: api)).serializingDecodable().value
  }

  func dataTask<Element: Decodable>(_ api: DiskStationAPI<Page<Element>>) async throws -> DiskStationPageResponse<Element, Failure> {
    return try await session.request(makeRequest(api: api)).serializingDecodable().value
  }

  func imageTask(_ api: DiskStationAPI<PlatformImage>) async throws -> PlatformImage? {
    let serializer = DiskStationDataResponseSerializer<DiskStationLazyDataResponse>()
    let serializedResponse = try await session.request(makeRequest(api: api)).serializingResponse(using: serializer).value
    return PlatformImage(data: try serializedResponse.data)
  }

  func backgroundDataTask<Completed: Decodable, Processing: Decodable>(_ api: DiskStationAPI<Completed>) async throws -> DiskStationResponse<BackgroundTask<Completed, Processing>.Status, Failure> {
    return try await session.request(makeRequest(api: api)).serializingDecodable().value
  }

  func uploadTask(_ api: DiskStationAPI<Void>, to path: String, fileName: String) async throws -> UploadTask<Void> {
    let request = try await uploadRequest(api)
    return UploadTask(
      serverURL: serverURL,
      path: path,
      name: fileName,
      request: request) {
        try await request.serializingDecodable(DiskStationEmptyResponse<Failure>.self).value.result()
      }
  }

  func uploadTask<Output: Decodable>(_ api: DiskStationAPI<Output>, to path: String, fileName: String, decode: ((DiskStationResponse<Output, Failure>) throws -> Output)? = nil) async throws -> UploadTask<Output> {
    let request = try await uploadRequest(api)
    return UploadTask(
      serverURL: serverURL,
      path: path,
      name: fileName,
      request: request) {
        let value = try await request.serializingDecodable(DiskStationResponse<Output, Failure>.self).value
        return try decode?(value) ?? value.data()
      }
  }

  func downloadTask(_ api: DiskStationAPI<URL>, at path: String, fileName: String) async throws -> DownloadTask<URL> {
    let request = try await downloadRequest(api)
    return DownloadTask(
      serverURL: serverURL,
      path: path,
      name: fileName,
      request: request) {
        try await request.serializingDownloadedFileURL().value
      }
  }

  func makeRequest<Result>(api: DiskStationAPI<Result>) async throws -> URLRequest {
    let info = try await apiInfo?.item(for: api.name)
    return try await makeRequest(api: api, info: info)
  }

  func makeRequest<Result>(api: DiskStationAPI<Result>, info: APIInfo.Item?) async throws -> URLRequest {
    let version = version(preferredVersion: api.preferredVersion, info: info)
    let path = info?.path ?? "entry.cgi"

    let url: URL
    if #available(iOS 16.0, macCatalyst 16.0, macOS 13.0, tvOS 13.0, watchOS 9.0, visionOS 1.0, *) {
      url = serverURL.appending(path: "webapi").appending(path: path)
    } else {
      url = serverURL.appendingPathComponent("webapi").appendingPathComponent(path)
    }

    let authorization: Parameters = ["_sid": await sessionID].compactMapValues { $0 }
    let apiInfo: Parameters = [
      "api": api.name,
      "method": api.method,
      "version": version
    ]
    let parameters: Parameters
    let parameterEncoding: ParameterEncoding
    if case .dictionary(let keyValueData, let encoding) = api.parameters {
      switch keyValueData {
      case .static(let dictionary):
        parameters = dictionary
          .compactMapValues { $0 }
          .merging(apiInfo) { $1 }
          .merging(authorization) { $1 }
      case .conditional(let closure):
        parameters = closure(version)
          .compactMapValues { $0 }
          .merging(apiInfo) { $1 }
          .merging(authorization) { $1 }
      }
      parameterEncoding = encoding
    } else {
      parameters = apiInfo.merging(authorization) { $1 }
      parameterEncoding = URLEncoding.default
    }

    return try parameterEncoding.encode(URLRequest(url: url, method: api.httpMethod), with: parameters)
  }

  func downloadRequest<Output>(_ api: DiskStationAPI<Output>) async throws -> DownloadRequest {
    return try await session.download(makeRequest(api: api))
  }

  func uploadRequest<Output>(_ api: DiskStationAPI<Output>) async throws -> UploadRequest {
    let info = try await apiInfo?.item(for: api.name)
    let version = version(preferredVersion: api.preferredVersion, info: info)

    let formItems: [DiskStationAPIParameters.FormData.Item]
    if case .formData(let parameters) = api.parameters {
      switch parameters {
      case .static(let items):
        formItems = items.compactMap { $0 }
      case .conditional(let closure):
        formItems = closure(version).compactMap { $0 }
      }
    } else {
      formItems = []
    }

    let formData = MultipartFormData()
    for item in formItems {
      switch item {
      case .text(let string, let name):
        if let data = string.data(using: .utf8) {
          formData.append(data, withName: name)
        }
      case .fileData(let data, let fileName, let name):
        formData.append(data, withName: name, fileName: fileName)
      case .fileURL(let fileURL, let name):
        formData.append(fileURL, withName: name)
      }
    }
    let url = try await makeRequest(api: api).url!
    return session.upload(
      multipartFormData: formData,
      to: url
    )
  }

  @inlinable func version(preferredVersion: Int, info: APIInfo.Item?) -> Int {
    return info.map { min(preferredVersion, $0.maxVersion) } ?? preferredVersion
  }
}
