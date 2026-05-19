import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var app: AppModel
    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(AppTheme.blue)
                        Text("CrisisAI")
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.ink)
                        Text("powered by AgenticPulse")
                            .font(.headline)
                            .foregroundStyle(AppTheme.blue)
                        Text("Real-time crisis intelligence, agent traceability, and safe simulated response orchestration.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Picker("Mode", selection: $mode) {
                        Text("Login").tag(AuthMode.signIn)
                        Text("Signup").tag(AuthMode.signUp)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 12) {
                        if mode == .signUp {
                            TextField("Full name", text: $fullName)
                                .textContentType(.name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .textFieldStyle(.roundedBorder)
                        }

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)

                        SecureField("Password", text: $password)
                            .textContentType(mode == .signIn ? .password : .newPassword)
                            .textFieldStyle(.roundedBorder)
                    }

                    if !AppConfig.shared.isSupabaseConfigured {
                        Label("Set SUPABASE_ANON_KEY before signing in.", systemImage: "key.slash")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppTheme.warning)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.warning.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    if let notice = app.authNotice {
                        Label(notice, systemImage: "envelope.badge")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.blue)
                    }

                    if let error = app.authError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.danger)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if app.isAuthenticating {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(mode == .signIn ? "Login" : "Create account")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(isDisabled: !canSubmit))
                    .disabled(!canSubmit || app.isAuthenticating)
                }
                .padding(22)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(AppTheme.surface)
            }
        }
    }

    private var canSubmit: Bool {
        AppConfig.shared.isSupabaseConfigured &&
        email.contains("@") &&
        password.count >= 6 &&
        (mode == .signIn || !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func submit() async {
        switch mode {
        case .signIn:
            await app.signIn(email: email, password: password)
        case .signUp:
            await app.signUp(email: email, password: password, fullName: fullName)
        }
    }
}

private enum AuthMode {
    case signIn
    case signUp
}
