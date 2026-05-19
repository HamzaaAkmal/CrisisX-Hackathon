import Foundation
import Combine

@MainActor
final class SupabaseRealtimeService: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var lastEventTable: String?

    private let config: AppConfig
    private var task: URLSessionWebSocketTask?
    private var ref = 0
    private var heartbeatTask: Task<Void, Never>?
    private var onTableEvent: ((String) -> Void)?

    init(config: AppConfig) {
        self.config = config
    }

    func connect(tables: [String], accessToken: String?, onTableEvent: @escaping (String) -> Void) {
        disconnect()
        guard config.isSupabaseConfigured else { return }

        self.onTableEvent = onTableEvent

        var components = URLComponents(url: config.supabaseURL, resolvingAgainstBaseURL: false)
        components?.scheme = "wss"
        components?.path = "/realtime/v1/websocket"
        components?.queryItems = [
            URLQueryItem(name: "apikey", value: config.supabaseAnonKey),
            URLQueryItem(name: "vsn", value: "1.0.0"),
        ]
        guard let url = components?.url else { return }

        var request = URLRequest(url: url)
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let webSocket = URLSession.shared.webSocketTask(with: request)
        task = webSocket
        webSocket.resume()
        isConnected = true
        receiveLoop()

        tables.forEach { table in
            join(table: table, accessToken: accessToken)
        }

        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 25_000_000_000)
                self?.heartbeat()
            }
        }
    }

    func disconnect() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isConnected = false
    }

    private func join(table: String, accessToken: String?) {
        let payload: [String: Any] = [
            "config": [
                "broadcast": ["self": false],
                "presence": ["key": ""],
                "postgres_changes": [[
                    "event": "*",
                    "schema": "public",
                    "table": table,
                ]],
            ],
            "access_token": accessToken ?? config.supabaseAnonKey,
        ]
        send(topic: "realtime:public:\(table)", event: "phx_join", payload: payload)
    }

    private func heartbeat() {
        send(topic: "phoenix", event: "heartbeat", payload: [:])
    }

    private func send(topic: String, event: String, payload: [String: Any]) {
        guard let task else { return }
        ref += 1
        let message: [String: Any] = [
            "topic": topic,
            "event": event,
            "payload": payload,
            "ref": "\(ref)",
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let text = String(data: data, encoding: .utf8) else { return }
        task.send(.string(text)) { _ in }
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let message):
                    self.handle(message)
                    self.receiveLoop()
                case .failure:
                    self.isConnected = false
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let text: String?
        switch message {
        case .string(let value):
            text = value
        case .data(let data):
            text = String(data: data, encoding: .utf8)
        @unknown default:
            text = nil
        }
        guard let text,
              let data = text.data(using: .utf8),
              let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let topic = envelope["topic"] as? String ?? ""
        let event = envelope["event"] as? String ?? ""
        guard topic.hasPrefix("realtime:public:"), event != "phx_reply" else { return }

        let table = topic.replacingOccurrences(of: "realtime:public:", with: "")
        lastEventTable = table
        onTableEvent?(table)
    }
}
