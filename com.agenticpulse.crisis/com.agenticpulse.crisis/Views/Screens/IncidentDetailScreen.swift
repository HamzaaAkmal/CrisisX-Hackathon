import SwiftUI

struct IncidentDetailScreen: View {
    @EnvironmentObject private var app: AppModel
    let incidentId: UUID

    private var incident: Incident? {
        app.repository.incidents.first { $0.id == incidentId }
    }

    var body: some View {
        Group {
            if app.repository.isLoading && !app.repository.hasLoadedOnce {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SkeletonCardList(rows: 1, includeHeader: false)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            SkeletonStatTile()
                            SkeletonStatTile()
                            SkeletonStatTile()
                            SkeletonStatTile()
                        }
                        .padding(.horizontal)
                        SkeletonCardList(rows: 3)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .background(AppTheme.surface)
            } else if let incident {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(incident)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            StatTile(title: "Confidence", value: "\(Int(incident.confidence * 100))%", icon: "checkmark.seal.fill")
                            StatTile(title: "Actions", value: "\(app.repository.actions(for: incident).count)", icon: "checklist")
                            StatTile(title: "Evidence", value: "\(app.repository.evidence(for: incident).count)", icon: "doc.text.magnifyingglass")
                            StatTile(title: "Simulations", value: "\(app.repository.simulations(for: incident).count)", icon: "play.rectangle.fill")
                        }
                        .padding(.horizontal)

                        VStack(spacing: 10) {
                            NavigationLink {
                                ResponsePlanScreen(incidentId: incident.id)
                            } label: {
                                Label("Response Plan", systemImage: "list.bullet.clipboard.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            HStack(spacing: 10) {
                                NavigationLink {
                                    AgentTraceScreen(incidentId: incident.id)
                                } label: {
                                    Label("Trace", systemImage: "point.3.connected.trianglepath.dotted")
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.line))
                                }

                                NavigationLink {
                                    SimulationOutcomeScreen(incidentId: incident.id)
                                } label: {
                                    Label("Simulation", systemImage: "chart.line.uptrend.xyaxis")
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.line))
                                }
                            }

                            Button {
                                Task { await app.repository.runSimulation(for: incident) }
                            } label: {
                                Label("Run Safe Mock Simulation", systemImage: "play.fill")
                            }
                            .buttonStyle(PrimaryButtonStyle(isDisabled: app.repository.hasActiveAgentRuns))
                            .disabled(app.repository.hasActiveAgentRuns)
                        }
                        .padding(.horizontal)

                        evidenceSection(incident)
                    }
                    .padding(.bottom, 24)
                }
                .background(AppTheme.surface)
            } else {
                EmptyState(icon: "questionmark.folder", title: "Incident unavailable", message: "The incident may have been resolved or removed.")
                    .background(AppTheme.surface)
            }
        }
        .navigationTitle("Incident")
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

    private func header(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SeverityBadge(severity: incident.severity)
                StatusPill(status: incident.status)
                Spacer()
                Text(incident.updatedAt.compactTime)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            Text(incident.title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(incident.description ?? "Incident created from clustered live signals and evidence.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            if let lat = incident.centroidLat, let lng = incident.centroidLng {
                Label(String(format: "%.4f, %.4f", lat, lng), systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private func evidenceSection(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Evidence")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal)

            let items = app.repository.evidence(for: incident)
            if items.isEmpty {
                EmptyState(icon: "doc.text.magnifyingglass", title: "Evidence pending", message: "Weather, route, and Exa corroboration will appear as the Evidence Agent writes it.")
                    .padding(.horizontal)
            } else {
                ForEach(items) { item in
                    EvidenceRow(item: item)
                        .padding(.horizontal)
                }
            }
        }
    }
}

private struct SkeletonStatTile: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.line)
                .frame(width: 28, height: 28)
            RoundedRectangle(cornerRadius: 5)
                .fill(AppTheme.line)
                .frame(width: 64, height: 20)
            RoundedRectangle(cornerRadius: 5)
                .fill(AppTheme.line)
                .frame(width: 86, height: 12)
        }
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .ciroCard()
        .shimmeringSkeleton()
    }
}

private struct EvidenceRow: View {
    let item: IncidentEvidence

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(item.evidenceType.capitalized, systemImage: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.blue)
                Spacer()
                Text("\(Int(item.confidence * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            Text(item.title ?? item.sourceName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
            if let url = item.url, let link = URL(string: url) {
                Link(url, destination: link)
                    .font(.caption)
                    .foregroundStyle(AppTheme.blue)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .ciroCard()
    }

    private var icon: String {
        switch item.evidenceType {
        case "weather": return "cloud.sun.rain.fill"
        case "route": return "point.topleft.down.curvedto.point.bottomright.up.fill"
        case "news", "web": return "newspaper.fill"
        default: return "doc.text.fill"
        }
    }
}
