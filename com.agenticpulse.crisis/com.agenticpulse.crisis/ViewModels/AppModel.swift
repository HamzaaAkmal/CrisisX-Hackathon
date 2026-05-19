import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var session: SupabaseSession?
    @Published var authError: String?
    @Published var authNotice: String?
    @Published var isAuthenticating = false

    let supabase: SupabaseService
    let realtime: SupabaseRealtimeService
    let repository: CrisisRepository

    init() {
        let config = AppConfig.shared
        let supabase = SupabaseService(config: config)
        let realtime = SupabaseRealtimeService(config: config)
        self.supabase = supabase
        self.realtime = realtime
        self.repository = CrisisRepository(api: supabase, realtime: realtime)
    }

    func bootstrap() {
        supabase.restoreSession()
        session = supabase.session
        if session != nil {
            Task {
                await repository.start()
            }
        }
    }

    func signIn(email: String, password: String) async {
        isAuthenticating = true
        authError = nil
        authNotice = nil
        defer { isAuthenticating = false }

        do {
            session = try await supabase.signIn(email: email, password: password)
            await repository.start()
        } catch {
            authError = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, fullName: String) async {
        isAuthenticating = true
        authError = nil
        authNotice = nil
        defer { isAuthenticating = false }

        do {
            if let newSession = try await supabase.signUp(email: email, password: password, fullName: fullName) {
                session = newSession
                await repository.start()
            } else {
                authNotice = "Account created. Check your email if confirmation is enabled, then sign in."
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    func signOut() {
        realtime.disconnect()
        repository.reset()
        supabase.signOut()
        session = nil
    }
}
