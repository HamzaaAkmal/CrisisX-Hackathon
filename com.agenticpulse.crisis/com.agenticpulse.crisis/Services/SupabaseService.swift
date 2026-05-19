import Foundation
import Combine

@MainActor
final class SupabaseService: ObservableObject {
    private let config: AppConfig
    private let keychain = KeychainStore()
    private let sessionAccount = "primary"
    private let urlSession: URLSession
    private(set) var session: SupabaseSession?

    init(config: AppConfig) {
        self.config = config
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        self.urlSession = URLSession(configuration: configuration)
    }

    var accessToken: String? {
        session?.accessToken
    }

    func restoreSession() {
        guard let data = try? keychain.load(account: sessionAccount),
              let stored = try? JSONDecoder.supabase.decode(SupabaseSession.self, from: data) else {
            return
        }
        session = stored
    }

    func refreshSessionIfNeeded(force: Bool = false) async throws {
        guard let current = session else { return }
        guard force || current.shouldRefresh else { return }
        guard let refreshToken = current.refreshToken, !refreshToken.isEmpty else {
            signOut()
            throw APIError.server(status: 401, message: "Saved session expired. Please sign in again.")
        }

        let data = try await request(
            path: "/auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: ["refresh_token": refreshToken],
            authenticated: false
        )
        let refreshed = try decodeSession(data)
        try persist(refreshed)
    }

    func signIn(email: String, password: String) async throws -> SupabaseSession {
        let data = try await request(
            path: "/auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: ["email": email, "password": password],
            authenticated: false
        )
        let session = try decodeSession(data)
        try persist(session)
        return session
    }

    func signUp(email: String, password: String, fullName: String) async throws -> SupabaseSession? {
        let data = try await request(
            path: "/auth/v1/signup",
            method: "POST",
            body: [
                "email": email,
                "password": password,
                "data": ["full_name": fullName],
            ],
            authenticated: false
        )

        guard let session = try? decodeSession(data) else {
            return nil
        }
        try persist(session)
        return session
    }

    func signOut() {
        session = nil
        keychain.delete(account: sessionAccount)
    }

    func persist(_ newSession: SupabaseSession) throws {
        let data = try JSONEncoder.supabase.encode(newSession)
        try keychain.save(data, account: sessionAccount)
        session = newSession
    }

    func fetch<T: Decodable>(
        table: String,
        queryItems: [URLQueryItem] = [],
        authenticated: Bool = true
    ) async throws -> [T] {
        var items = [URLQueryItem(name: "select", value: "*")]
        items.append(contentsOf: queryItems)
        let data = try await request(path: "/rest/v1/\(table)", method: "GET", queryItems: items, authenticated: authenticated)
        do {
            return try JSONDecoder.supabase.decode([T].self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    func insertReturning<T: Decodable>(table: String, values: [String: Any]) async throws -> T {
        let data = try await request(
            path: "/rest/v1/\(table)",
            method: "POST",
            queryItems: [URLQueryItem(name: "select", value: "*")],
            body: values,
            extraHeaders: ["Prefer": "return=representation"]
        )
        do {
            let rows = try JSONDecoder.supabase.decode([T].self, from: data)
            guard let first = rows.first else { throw APIError.invalidResponse }
            return first
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    func updateReturning<T: Decodable>(
        table: String,
        id: UUID,
        values: [String: Any]
    ) async throws -> T {
        let data = try await request(
            path: "/rest/v1/\(table)",
            method: "PATCH",
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(id.uuidString)"),
                URLQueryItem(name: "select", value: "*"),
            ],
            body: values,
            extraHeaders: ["Prefer": "return=representation"]
        )
        do {
            let rows = try JSONDecoder.supabase.decode([T].self, from: data)
            guard let first = rows.first else { throw APIError.invalidResponse }
            return first
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    func invokeFunction(_ name: String, body: [String: Any]) async throws -> [String: JSONValue] {
        let data = try await request(path: "/functions/v1/\(name)", method: "POST", body: body)
        do {
            return try JSONDecoder.supabase.decode([String: JSONValue].self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func decodeSession(_ data: Data) throws -> SupabaseSession {
        do {
            return try JSONDecoder.supabase.decode(SupabaseSession.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func request(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Any? = nil,
        authenticated: Bool = true,
        extraHeaders: [String: String] = [:],
        hasRetriedAfterRefresh: Bool = false
    ) async throws -> Data {
        guard config.isSupabaseConfigured else {
            throw APIError.missingConfiguration("SUPABASE_ANON_KEY")
        }

        let base = config.supabaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        var components = URLComponents(string: base + normalizedPath)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { throw APIError.invalidResponse }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        let timeoutInterval = Self.timeoutInterval(for: normalizedPath)
        urlRequest.timeoutInterval = timeoutInterval
        urlRequest.setValue(config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Bearer \(authenticated ? (session?.accessToken ?? config.supabaseAnonKey) : config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        extraHeaders.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200..<300).contains(http.statusCode) else {
                if authenticated, http.statusCode == 401, !hasRetriedAfterRefresh, !normalizedPath.hasPrefix("/auth/v1/") {
                    try await refreshSessionIfNeeded(force: true)
                    return try await request(
                        path: path,
                        method: method,
                        queryItems: queryItems,
                        body: body,
                        authenticated: authenticated,
                        extraHeaders: extraHeaders,
                        hasRetriedAfterRefresh: true
                    )
                }
                throw APIError.server(status: http.statusCode, message: Self.errorMessage(from: data))
            }
            return data
        } catch let error as APIError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw APIError.server(status: -1, message: "Request timed out after \(Int(timeoutInterval))s. The AI model may be under heavy load. Please try again in a moment.")
        } catch {
            throw APIError.server(status: -1, message: error.localizedDescription)
        }
    }

    private static func errorMessage(from data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return (object["msg"] as? String)
                ?? (object["message"] as? String)
                ?? (object["error_description"] as? String)
                ?? (object["error"] as? String)
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown error"
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }

    private static func timeoutInterval(for path: String) -> TimeInterval {
        if path.contains("/functions/v1/") { return 120 }
        if path.contains("/auth/v1/") { return 20 }
        return 8
    }
}
