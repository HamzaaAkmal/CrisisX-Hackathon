import SwiftUI

struct SignalInboxScreen: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(
                    title: "Signal Inbox",
                    subtitle: "Realtime stream of user reports, backend API signals, normalization, and clustering status.",
                    icon: "tray.full.fill"
                )

                if app.repository.isLoading && !app.repository.hasLoadedOnce {
                    SkeletonCardList(rows: 2)
                    SkeletonCardList(rows: 4)
                } else if !app.repository.incidents.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Detected Incidents")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                            .padding(.horizontal)
                        ForEach(app.repository.incidents) { incident in
                            NavigationLink {
                                IncidentDetailScreen(incidentId: incident.id)
                            } label: {
                                IncidentListRow(incident: incident)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }

                if !app.repository.isLoading || app.repository.hasLoadedOnce {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Signals")
                            .font(.headline)
                            .foregroundStyle(AppTheme.ink)
                            .padding(.horizontal)

                        if app.repository.signals.isEmpty {
                            EmptyState(
                                icon: "tray",
                                title: "No signals yet",
                                message: "Reports and backend-generated API signals will appear here instantly."
                            )
                            .padding(.horizontal)
                        } else {
                            ForEach(app.repository.signals) { signal in
                                SignalRow(signal: signal, normalized: normalized(for: signal))
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(AppTheme.surface)
        .navigationTitle("Inbox")
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

    private func normalized(for signal: Signal) -> NormalizedSignal? {
        app.repository.normalizedSignals.first { $0.signalId == signal.id }
    }
}

private struct IncidentListRow: View {
    let incident: Incident

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SeverityBadge(severity: incident.severity)
            VStack(alignment: .leading, spacing: 6) {
                Text(incident.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                Text(incident.category.capitalized)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                HStack {
                    StatusPill(status: incident.status)
                    Text("\(Int(incident.confidence * 100))% confidence")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.blue)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
        .ciroCard()
    }
}

private struct SignalRow: View {
    let signal: Signal
    let normalized: NormalizedSignal?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(signal.sourceType.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: signal.sourceType == "user_report" ? "person.crop.circle" : "server.rack")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.blue)
                Spacer()
                StatusPill(status: signal.status)
            }

            Text(signal.reportText)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(3)

            if let normalized {
                Divider()
                Text(normalized.normalizedText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(3)
            }

            HStack {
                if let location = signal.locationText {
                    Label(location, systemImage: "mappin.and.ellipse")
                }
                Spacer()
                Text(signal.createdAt.shortRelative)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .ciroCard()
    }
}
