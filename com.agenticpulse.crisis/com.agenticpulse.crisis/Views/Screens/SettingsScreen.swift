import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var app: AppModel
    @State private var apiLocation = ""
    @State private var apiCategory = "weather"
    @State private var apiUrgency = 3.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(
                    title: "Settings",
                    subtitle: "Configuration, health, backend-generated signals, and account controls.",
                    icon: "gearshape.fill"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Configuration")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    ConfigRow(title: "Supabase URL", value: AppConfig.shared.supabaseURL.absoluteString, ok: true)
                    ConfigRow(title: "Supabase anon key", value: AppConfig.shared.isSupabaseConfigured ? "Configured" : "Missing", ok: AppConfig.shared.isSupabaseConfigured)
                    ConfigRow(title: "Google Maps iOS key", value: AppConfig.shared.isGoogleMapsConfigured ? "Configured" : "Missing", ok: AppConfig.shared.isGoogleMapsConfigured)
                    ConfigRow(title: "Realtime", value: app.realtime.isConnected ? "Connected" : "Connecting", ok: app.realtime.isConnected)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("System Status")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                        Spacer()
                        if app.repository.systemStatus.contains(where: { $0.status == "degraded" }) {
                            Button {
                                Task { await app.repository.loadAll() }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    if app.repository.isLoading && !app.repository.hasLoadedOnce {
                        SettingsStatusSkeleton()
                    } else if app.repository.systemStatus.isEmpty {
                        EmptyState(icon: "heart.text.square", title: "No status yet", message: "Run the migration and an agent flow to populate system status.")
                    } else {
                        ForEach(app.repository.systemStatus) { status in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(status.statusKey.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.ink)
                                        Text(status.message ?? "No message")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                    Spacer()
                                    StatusPill(status: status.status)
                                }
                                
                                if status.status == "degraded" && status.statusKey == "agent_orchestrator" {
                                    Text("The primary AI model may be under high load. New submissions can still run and will retry through the Kimi fallback model.")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.warning)
                                        .padding(.top, 4)
                                }
                            }
                            .ciroCard()
                        }
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Backend API Signal")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("Creates test signals only through the backend function using geocoding, weather, and Exa context.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)

                    TextField("Location for generated signal", text: $apiLocation)
                        .textFieldStyle(.roundedBorder)
                    Picker("Category", selection: $apiCategory) {
                        Text("Weather").tag("weather")
                        Text("Traffic").tag("traffic")
                        Text("Infrastructure").tag("infrastructure")
                        Text("Environment").tag("environment")
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Urgency")
                        Slider(value: $apiUrgency, in: 1...5, step: 1)
                            .tint(AppTheme.blue)
                        Text("\(Int(apiUrgency))")
                            .font(.headline)
                            .foregroundStyle(AppTheme.blue)
                    }

                    Button {
                        Task {
                            await app.repository.generateBackendSignal(location: apiLocation, category: apiCategory, urgency: Int(apiUrgency))
                        }
                    } label: {
                        Label("Generate Through Backend", systemImage: "server.rack")
                    }
                    .buttonStyle(PrimaryButtonStyle(isDisabled: apiLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || app.repository.hasActiveAgentRuns))
                    .disabled(apiLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || app.repository.hasActiveAgentRuns)
                }
                .padding(.horizontal)

                Button(role: .destructive) {
                    app.signOut()
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(AppTheme.surface)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await app.repository.loadAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

private struct SettingsStatusSkeleton: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.line)
                            .frame(width: 150, height: 17)
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.line)
                            .frame(width: 84, height: 28)
                    }
                    RoundedRectangle(cornerRadius: 5)
                        .fill(AppTheme.line)
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(AppTheme.line)
                        .frame(width: 220, height: 12)
                }
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
                .ciroCard()
                .shimmeringSkeleton()
            }
        }
    }
}

private struct ConfigRow: View {
    let title: String
    let value: String
    let ok: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: ok ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(ok ? AppTheme.success : AppTheme.warning)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.ink)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .ciroCard()
    }
}
