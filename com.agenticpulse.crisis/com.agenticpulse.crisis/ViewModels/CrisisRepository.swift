import Foundation
import Combine

@MainActor
final class CrisisRepository: ObservableObject {
    @Published var signals: [Signal] = []
    @Published var normalizedSignals: [NormalizedSignal] = []
    @Published var incidents: [Incident] = []
    @Published var evidence: [IncidentEvidence] = []
    @Published var agentRuns: [AgentRun] = []
    @Published var agentLogs: [AgentLog] = []
    @Published var toolCalls: [ToolCallRecord] = []
    @Published var actions: [ResponseAction] = []
    @Published var simulationRuns: [SimulationRun] = []
    @Published var simulationMetrics: [SimulationMetric] = []
    @Published var alerts: [MockAlert] = []
    @Published var tickets: [EmergencyTicket] = []
    @Published var resources: [ResourceItem] = []
    @Published var blockedSegments: [BlockedSegment] = []
    @Published var routeOptions: [RouteOption] = []
    @Published var systemStatus: [SystemStatus] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var hasLoadedOnce = false
    @Published var isRunningAgent = false
    @Published var lastError: String?

    private let api: SupabaseService
    private let realtime: SupabaseRealtimeService
    private var reloadTask: Task<Void, Never>?
    private var isReloadInFlight = false

    init(api: SupabaseService, realtime: SupabaseRealtimeService) {
        self.api = api
        self.realtime = realtime
    }

    func start() async {
        await loadAll()
        realtime.connect(tables: realtimeTables, accessToken: api.accessToken) { [weak self] _ in
            self?.scheduleReload()
        }
    }

    func reset() {
        reloadTask?.cancel()
        signals = []
        normalizedSignals = []
        incidents = []
        evidence = []
        agentRuns = []
        agentLogs = []
        toolCalls = []
        actions = []
        simulationRuns = []
        simulationMetrics = []
        alerts = []
        tickets = []
        resources = []
        blockedSegments = []
        routeOptions = []
        systemStatus = []
        isLoading = false
        isRefreshing = false
        hasLoadedOnce = false
        isReloadInFlight = false
        lastError = nil
    }

    func loadAll() async {
        guard !isReloadInFlight else { return }
        isReloadInFlight = true
        let isInitialLoad = !hasLoadedOnce
        if isInitialLoad {
            isLoading = true
        } else {
            isRefreshing = true
        }
        defer {
            isReloadInFlight = false
            isLoading = false
            isRefreshing = false
            hasLoadedOnce = true
        }

        var refreshErrors: [String] = []

        func refresh<T: Decodable>(
            _ label: String,
            operation: () async throws -> [T],
            assign: ([T]) -> Void
        ) async {
            do {
                assign(try await operation())
            } catch {
                refreshErrors.append("\(label): \(error.localizedDescription)")
            }
        }

        await refresh("signals", operation: {
            try await api.fetch(table: "signals", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "80"),
            ])
        }, assign: { (items: [Signal]) in signals = items })

        await refresh("incidents", operation: {
            try await api.fetch(table: "incidents", queryItems: [
                URLQueryItem(name: "order", value: "updated_at.desc"),
                URLQueryItem(name: "limit", value: "80"),
            ])
        }, assign: { (items: [Incident]) in incidents = items })

        await refresh("response actions", operation: {
            try await api.fetch(table: "response_actions", queryItems: [
                URLQueryItem(name: "order", value: "updated_at.desc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
        }, assign: { (items: [ResponseAction]) in actions = items })

        await refresh("agent runs", operation: {
            try await api.fetch(table: "agent_runs", queryItems: [
                URLQueryItem(name: "order", value: "started_at.desc"),
                URLQueryItem(name: "limit", value: "60"),
            ])
        }, assign: { (items: [AgentRun]) in agentRuns = items })

        await refresh("agent logs", operation: {
            try await api.fetch(table: "agent_logs", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "180"),
            ])
        }, assign: { (items: [AgentLog]) in agentLogs = items })

        await refresh("tool calls", operation: {
            try await api.fetch(table: "tool_calls", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "180"),
            ])
        }, assign: { (items: [ToolCallRecord]) in toolCalls = items })

        await refresh("system status", operation: {
            try await api.fetch(table: "system_status", queryItems: [
                URLQueryItem(name: "order", value: "updated_at.desc"),
            ])
        }, assign: { (items: [SystemStatus]) in systemStatus = items })

        await refresh("normalized signals", operation: {
            try await api.fetch(table: "normalized_signals", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "80"),
            ])
        }, assign: { (items: [NormalizedSignal]) in normalizedSignals = items })

        await refresh("evidence", operation: {
            try await api.fetch(table: "incident_evidence", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
        }, assign: { (items: [IncidentEvidence]) in evidence = items })

        await refresh("route options", operation: {
            try await api.fetch(table: "route_options", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
        }, assign: { (items: [RouteOption]) in routeOptions = items })

        await refresh("blocked segments", operation: {
            try await api.fetch(table: "blocked_segments", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
        }, assign: { (items: [BlockedSegment]) in blockedSegments = items })

        await refresh("simulation runs", operation: {
            try await api.fetch(table: "simulation_runs", queryItems: [
                URLQueryItem(name: "order", value: "started_at.desc"),
                URLQueryItem(name: "limit", value: "80"),
            ])
        }, assign: { (items: [SimulationRun]) in simulationRuns = items })

        await refresh("simulation metrics", operation: {
            try await api.fetch(table: "simulation_metrics", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
        }, assign: { (items: [SimulationMetric]) in simulationMetrics = items })

        await refresh("mock alerts", operation: {
            try await api.fetch(table: "mock_alerts", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
        }, assign: { (items: [MockAlert]) in alerts = items })

        await refresh("emergency tickets", operation: {
            try await api.fetch(table: "emergency_tickets", queryItems: [
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
        }, assign: { (items: [EmergencyTicket]) in tickets = items })

        await refresh("resources", operation: {
            try await api.fetch(table: "resources", queryItems: [
                URLQueryItem(name: "order", value: "updated_at.desc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
        }, assign: { (items: [ResourceItem]) in resources = items })

        if refreshErrors.isEmpty {
            lastError = nil
        } else {
            lastError = "Some data could not refresh: \(refreshErrors.prefix(2).joined(separator: "; "))"
        }
    }

    func createReportSignal(text: String, locationText: String, category: String, urgency: Int) async throws -> Signal {
        guard let userId = api.session?.user.id else {
            lastError = "Sign in before submitting reports."
            throw APIError.server(status: 401, message: "Sign in before submitting reports.")
        }

        lastError = nil
        let signal: Signal = try await api.insertReturning(table: "signals", values: [
            "submitted_by": userId.uuidString,
            "source_type": "user_report",
            "report_text": text,
            "category": category,
            "urgency": urgency,
            "location_text": locationText,
            "raw_payload": [
                "client": "CrisisAI iOS",
                "submitted_at": ISO8601DateFormatter.standard.string(from: Date()),
            ],
        ])
        await loadAll()
        return signal
    }

    @discardableResult
    func processSignal(_ signalId: UUID, retryCount: Int = 0) async throws -> [String: JSONValue] {
        isRunningAgent = true
        lastError = nil
        defer { isRunningAgent = false }

        do {
            let output = try await api.invokeFunction("ciro-agent", body: [
                "action": "start_processing",
                "signal_id": signalId.uuidString,
            ])
            await loadPipelineState(for: signalId, acceptedRunId: output["run_id"]?.uuidValue)
            return output
        } catch let error as APIError {
            // If timeout and haven't retried yet, try once more
            if case .server(let status, let message) = error, status == -1, message.contains("timed out"), retryCount < 1 {
                lastError = "Agent orchestrator timed out, retrying..."
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                return try await processSignal(signalId, retryCount: retryCount + 1)
            }
            throw error
        }
    }

    func ensureProcessingStarted(for signalId: UUID, acceptedRunId: UUID? = nil, force: Bool = false) async {
        guard force || run(for: signalId)?.status != "running" else {
            await loadPipelineState(for: signalId, acceptedRunId: acceptedRunId)
            return
        }

        do {
            let output = try await api.invokeFunction("ciro-agent", body: [
                "action": "start_processing",
                "signal_id": signalId.uuidString,
            ])
            await loadPipelineState(for: signalId, acceptedRunId: output["run_id"]?.uuidValue ?? acceptedRunId)
        } catch {
            lastError = "Could not start orchestrator: \(error.localizedDescription)"
        }
    }

    func loadPipelineState(for signalId: UUID, acceptedRunId: UUID? = nil) async {
        do {
            let matchingSignals: [Signal] = try await api.fetch(table: "signals", queryItems: [
                URLQueryItem(name: "id", value: "eq.\(signalId.uuidString)"),
                URLQueryItem(name: "limit", value: "1"),
            ])
            merge(matchingSignals, into: &signals)

            let matchingNormalized: [NormalizedSignal] = try await api.fetch(table: "normalized_signals", queryItems: [
                URLQueryItem(name: "signal_id", value: "eq.\(signalId.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "3"),
            ])
            merge(matchingNormalized, into: &normalizedSignals)

            let matchingRuns: [AgentRun] = try await api.fetch(table: "agent_runs", queryItems: [
                URLQueryItem(name: "trigger_type", value: "eq.signal"),
                URLQueryItem(name: "trigger_id", value: "eq.\(signalId.uuidString)"),
                URLQueryItem(name: "order", value: "started_at.desc"),
                URLQueryItem(name: "limit", value: "3"),
            ])
            merge(matchingRuns, into: &agentRuns)

            if let acceptedRunId {
                let directRuns: [AgentRun] = try await api.fetch(table: "agent_runs", queryItems: [
                    URLQueryItem(name: "id", value: "eq.\(acceptedRunId.uuidString)"),
                    URLQueryItem(name: "limit", value: "1"),
                ])
                merge(directRuns, into: &agentRuns)
            }

            guard let run = matchingRuns.first ?? run(for: signalId) ?? acceptedRunId.flatMap({ id in agentRuns.first { $0.id == id } }) else {
                lastError = nil
                return
            }

            let matchingLogs: [AgentLog] = try await api.fetch(table: "agent_logs", queryItems: [
                URLQueryItem(name: "agent_run_id", value: "eq.\(run.id.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
            merge(matchingLogs, into: &agentLogs)

            let matchingTools: [ToolCallRecord] = try await api.fetch(table: "tool_calls", queryItems: [
                URLQueryItem(name: "agent_run_id", value: "eq.\(run.id.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "120"),
            ])
            merge(matchingTools, into: &toolCalls)

            if let incidentId = run.outputPayload["incident_id"]?.uuidValue {
                let matchingIncidents: [Incident] = try await api.fetch(table: "incidents", queryItems: [
                    URLQueryItem(name: "id", value: "eq.\(incidentId.uuidString)"),
                    URLQueryItem(name: "limit", value: "1"),
                ])
                merge(matchingIncidents, into: &incidents)
            }
            lastError = nil
        } catch {
            lastError = "Pipeline heartbeat could not refresh: \(error.localizedDescription)"
        }
    }

    func submitReport(text: String, locationText: String, category: String, urgency: Int) async {
        do {
            let signal = try await createReportSignal(text: text, locationText: locationText, category: category, urgency: urgency)
            try await processSignal(signal.id)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func runSimulation(for incident: Incident) async {
        isRunningAgent = true
        lastError = nil
        defer { isRunningAgent = false }

        do {
            _ = try await api.invokeFunction("ciro-agent", body: [
                "action": "run_simulation",
                "incident_id": incident.id.uuidString,
                "scenario": "manual_safe_response_execution",
            ])
            await loadAll()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func generateBackendSignal(location: String, category: String, urgency: Int) async {
        isRunningAgent = true
        lastError = nil
        defer { isRunningAgent = false }

        do {
            _ = try await api.invokeFunction("ciro-agent", body: [
                "action": "generate_api_signal",
                "location_text": location,
                "category": category,
                "urgency": urgency,
                "region_bias": "PK",
            ])
            await loadAll()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateAction(_ action: ResponseAction, status: String) async {
        do {
            let updated: ResponseAction = try await api.updateReturning(table: "response_actions", id: action.id, values: ["status": status])
            if let index = actions.firstIndex(where: { $0.id == updated.id }) {
                actions[index] = updated
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func evidence(for incident: Incident) -> [IncidentEvidence] {
        evidence.filter { $0.incidentId == incident.id }
    }

    func actions(for incident: Incident) -> [ResponseAction] {
        actions.filter { $0.incidentId == incident.id }.sorted { $0.priority > $1.priority }
    }

    func logs(for run: AgentRun) -> [AgentLog] {
        agentLogs.filter { $0.agentRunId == run.id }.sorted { $0.createdAt < $1.createdAt }
    }

    func toolCalls(for run: AgentRun) -> [ToolCallRecord] {
        toolCalls.filter { $0.agentRunId == run.id }.sorted { $0.createdAt < $1.createdAt }
    }

    func run(for signalId: UUID) -> AgentRun? {
        agentRuns.first { $0.triggerId == signalId && $0.triggerType == "signal" }
    }

    var hasActiveAgentRuns: Bool {
        isRunningAgent || agentRuns.contains { $0.status == "queued" || $0.status == "running" }
    }

    func isRunActive(for signalId: UUID?) -> Bool {
        guard let signalId else { return false }
        return agentRuns.contains {
            $0.triggerId == signalId &&
            $0.triggerType == "signal" &&
            ($0.status == "queued" || $0.status == "running")
        }
    }

    func signal(id: UUID) -> Signal? {
        signals.first { $0.id == id }
    }

    func normalizedSignal(for signalId: UUID) -> NormalizedSignal? {
        normalizedSignals.first { $0.signalId == signalId }
    }

    func incident(id: UUID?) -> Incident? {
        guard let id else { return nil }
        return incidents.first { $0.id == id }
    }

    func incident(for run: AgentRun?) -> Incident? {
        guard let run else { return nil }
        return incident(id: run.outputPayload["incident_id"]?.uuidValue)
    }

    func logs(for incident: Incident) -> [AgentLog] {
        let runIds = Set(agentRuns.filter { $0.outputPayload["incident_id"]?.stringValue == incident.id.uuidString || $0.triggerId == incident.id }.map(\.id))
        return agentLogs.filter { runIds.contains($0.agentRunId) }.sorted { $0.createdAt < $1.createdAt }
    }

    func simulations(for incident: Incident) -> [SimulationRun] {
        simulationRuns.filter { $0.incidentId == incident.id }.sorted { $0.startedAt > $1.startedAt }
    }

    func metrics(for incident: Incident) -> [SimulationMetric] {
        simulationMetrics.filter { $0.incidentId == incident.id }
    }

    func alerts(for incident: Incident) -> [MockAlert] {
        alerts.filter { $0.incidentId == incident.id }
    }

    func tickets(for incident: Incident) -> [EmergencyTicket] {
        tickets.filter { $0.incidentId == incident.id }
    }

    func routes(for incident: Incident) -> [RouteOption] {
        routeOptions.filter { $0.incidentId == incident.id }
    }

    func blockedSegments(for incident: Incident) -> [BlockedSegment] {
        blockedSegments.filter { $0.incidentId == incident.id }
    }
    
    var isAgentOrchestratorHealthy: Bool {
        guard let orchestratorStatus = systemStatus.first(where: { $0.statusKey == "agent_orchestrator" }) else {
            return true // Assume healthy if no status yet
        }
        return orchestratorStatus.status == "healthy"
    }
    
    var agentOrchestratorMessage: String? {
        systemStatus.first(where: { $0.statusKey == "agent_orchestrator" })?.message
    }

    private func merge<T: Identifiable>(_ incoming: [T], into current: inout [T]) where T.ID == UUID {
        for item in incoming {
            if let index = current.firstIndex(where: { $0.id == item.id }) {
                current[index] = item
            } else {
                current.append(item)
            }
        }
    }

    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            await self?.loadAll()
        }
    }

    private var realtimeTables: [String] {
        [
            "signals",
            "normalized_signals",
            "incidents",
            "incident_evidence",
            "agent_runs",
            "agent_logs",
            "tool_calls",
            "response_actions",
            "simulation_runs",
            "simulation_metrics",
            "mock_alerts",
            "emergency_tickets",
            "resources",
            "blocked_segments",
            "route_options",
            "system_status",
        ]
    }
}
