//
//  APIClient.swift
//  UpShiftMobile
//
//  Lightweight REST client that attaches a Clerk Bearer token.
//

import Foundation
import Clerk

enum APIClientError: Error, LocalizedError {
  case invalidURL
  case invalidResponse
  case http(status: Int, body: String?)
  case notAuthenticated

  var errorDescription: String? {
    switch self {
    case .invalidURL: return "Invalid URL"
    case .invalidResponse: return "Invalid response from server"
    case .http(let status, let body):
      return "HTTP \(status): \(body ?? "")"
    case .notAuthenticated: return "Not authenticated"
    }
  }
}

final class APIClient {
  static let shared = APIClient()

  // Matches the host used by Network.swift (Apollo client).
  private let baseURL = URL(string: "https://upshiftbackend.vercel.app")!

  private lazy var decoder: JSONDecoder = {
    let d = JSONDecoder()
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let isoNoFraction = ISO8601DateFormatter()
    isoNoFraction.formatOptions = [.withInternetDateTime]
    d.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let str = try container.decode(String.self)
      if let date = iso.date(from: str) ?? isoNoFraction.date(from: str) {
        return date
      }
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid date: \(str)"
      )
    }
    return d
  }()

  func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
    guard let url = URL(string: path, relativeTo: baseURL) else {
      throw APIClientError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "Accept")

    if let session = await Clerk.shared.session,
       let tokenResource = try await session.getToken() {
      request.addValue("Bearer \(tokenResource.jwt)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw APIClientError.invalidResponse
    }
    guard (200..<300).contains(http.statusCode) else {
      throw APIClientError.http(
        status: http.statusCode,
        body: String(data: data, encoding: .utf8)
      )
    }
    return try decoder.decode(T.self, from: data)
  }
}
