import Foundation

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var email: String
    var fullName: String?
    var role: String
    var organization: String?
    var status: String
    var location: [String: JSONValue]
    var preferences: [String: JSONValue]
    var createdAt: Date
    var updatedAt: Date
}

struct Signal: Codable, Identifiable, Hashable {
    let id: UUID
    var submittedBy: UUID?
    var sourceType: String
    var reportText: String
    var languageHint: String?
    var category: String?
    var urgency: Int
    var locationText: String?
    var latitude: Double?
    var longitude: Double?
    var status: String
    var confidence: Double
    var rawPayload: [String: JSONValue]
    var normalizedSignalId: UUID?
    var createdAt: Date
    var updatedAt: Date
}

struct NormalizedSignal: Codable, Identifiable, Hashable {
    let id: UUID
    var signalId: UUID
    var normalizedText: String
    var translatedText: String?
    var locationText: String?
    var latitude: Double?
    var longitude: Double?
    var category: String?
    var severityHint: Int?
    var entities: [String: JSONValue]
    var status: String
    var model: String?
    var confidence: Double
    var createdAt: Date
    var updatedAt: Date
}

struct Incident: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var description: String?
    var category: String
    var status: String
    var severity: Int
    var confidence: Double
    var centroidLat: Double?
    var centroidLng: Double?
    var radiusMeters: Int
    var startedAt: Date
    var lastSignalAt: Date
    var summary: [String: JSONValue]
    var evidenceSummary: [String: JSONValue]
    var assignedOwner: UUID?
    var createdAt: Date
    var updatedAt: Date
}

struct IncidentEvidence: Codable, Identifiable, Hashable {
    let id: UUID
    var incidentId: UUID
    var signalId: UUID?
    var evidenceType: String
    var sourceName: String
    var title: String?
    var url: String?
    var observedAt: Date
    var location: [String: JSONValue]
    var confidence: Double
    var payload: [String: JSONValue]
    var createdAt: Date
}

struct AgentRun: Codable, Identifiable, Hashable {
    let id: UUID
    var triggerType: String
    var triggerId: UUID?
    var status: String
    var startedAt: Date
    var endedAt: Date?
    var inputPayload: [String: JSONValue]
    var outputPayload: [String: JSONValue]
    var error: String?
    var createdBy: UUID?
}

struct AgentLog: Codable, Identifiable, Hashable {
    let id: UUID
    var agentRunId: UUID
    var agentName: String
    var step: String
    var status: String
    var message: String?
    var inputPayload: [String: JSONValue]
    var outputPayload: [String: JSONValue]
    var confidence: Double?
    var error: String?
    var startedAt: Date
    var completedAt: Date?
    var createdAt: Date
}

struct ToolCallRecord: Codable, Identifiable, Hashable {
    let id: UUID
    var agentRunId: UUID
    var agentLogId: UUID?
    var toolName: String
    var status: String
    var arguments: [String: JSONValue]
    var result: [String: JSONValue]
    var error: String?
    var latencyMs: Int?
    var createdAt: Date
}

struct ResponseAction: Codable, Identifiable, Hashable {
    let id: UUID
    var incidentId: UUID
    var actionType: String
    var title: String
    var description: String?
    var priority: Int
    var status: String
    var assignedTo: String?
    var dueAt: Date?
    var payload: [String: JSONValue]
    var createdBy: UUID?
    var createdAt: Date
    var updatedAt: Date
}

struct SimulationRun: Codable, Identifiable, Hashable {
    let id: UUID
    var incidentId: UUID
    var agentRunId: UUID?
    var status: String
    var scenario: String
    var startedAt: Date
    var completedAt: Date?
    var inputPayload: [String: JSONValue]
    var outputPayload: [String: JSONValue]
    var createdBy: UUID?
}

struct SimulationMetric: Codable, Identifiable, Hashable {
    let id: UUID
    var simulationRunId: UUID
    var incidentId: UUID
    var metricName: String
    var beforeValue: Double?
    var afterValue: Double?
    var unit: String?
    var delta: Double?
    var payload: [String: JSONValue]
    var createdAt: Date
}

struct MockAlert: Codable, Identifiable, Hashable {
    let id: UUID
    var incidentId: UUID
    var simulationRunId: UUID?
    var audience: String
    var channel: String
    var title: String
    var body: String
    var status: String
    var sentAt: Date?
    var payload: [String: JSONValue]
    var createdAt: Date
}

struct EmergencyTicket: Codable, Identifiable, Hashable {
    let id: UUID
    var incidentId: UUID
    var simulationRunId: UUID?
    var externalRef: String
    var ticketType: String
    var priority: Int
    var status: String
    var summary: String
    var details: String?
    var payload: [String: JSONValue]
    var createdAt: Date
    var updatedAt: Date
}

struct ResourceItem: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var resourceType: String
    var status: String
    var homeLat: Double?
    var homeLng: Double?
    var currentLat: Double?
    var currentLng: Double?
    var capacity: Int
    var assignedIncidentId: UUID?
    var metadata: [String: JSONValue]
    var createdAt: Date
    var updatedAt: Date
}

struct BlockedSegment: Codable, Identifiable, Hashable {
    let id: UUID
    var incidentId: UUID
    var simulationRunId: UUID?
    var status: String
    var startLat: Double
    var startLng: Double
    var endLat: Double
    var endLng: Double
    var reason: String
    var severity: Int
    var payload: [String: JSONValue]
    var createdAt: Date
    var updatedAt: Date
}

struct RouteOption: Codable, Identifiable, Hashable {
    let id: UUID
    var incidentId: UUID
    var simulationRunId: UUID?
    var origin: [String: JSONValue]
    var destination: [String: JSONValue]
    var provider: String
    var status: String
    var etaSeconds: Int?
    var distanceMeters: Int?
    var polyline: String?
    var payload: [String: JSONValue]
    var createdAt: Date
    var updatedAt: Date
}

struct SystemStatus: Codable, Identifiable, Hashable {
    var statusKey: String
    var status: String
    var message: String?
    var payload: [String: JSONValue]
    var updatedAt: Date

    var id: String { statusKey }
}

struct SupabaseUser: Codable, Hashable {
    var id: UUID
    var email: String?
}

struct SupabaseSession: Codable, Hashable {
    var accessToken: String
    var refreshToken: String?
    var expiresIn: Int?
    var tokenType: String?
    var user: SupabaseUser
}
