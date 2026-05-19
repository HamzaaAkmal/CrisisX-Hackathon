import Foundation

struct AppConfig {
    let supabaseURL: URL
    let supabaseAnonKey: String
    let googleMapsAPIKey: String?

    nonisolated static let shared = AppConfig(
        supabaseURL: URL(string: resolvedValue(
            infoKey: "SupabaseURL",
            envKey: "SUPABASE_URL",
            fallback: "https://rkxhbbrcrfikbanjvuig.supabase.co"
        ))!,
        supabaseAnonKey: resolvedValue(infoKey: "SupabaseAnonKey", envKey: "SUPABASE_ANON_KEY"),
        googleMapsAPIKey: optionalResolvedValue(infoKey: "GoogleMapsAPIKey", envKey: "GOOGLE_MAPS_IOS_API_KEY")
    )

    var isSupabaseConfigured: Bool {
        !supabaseAnonKey.isEmpty
    }

    var isGoogleMapsConfigured: Bool {
        googleMapsAPIKey?.isEmpty == false
    }

    private static func resolvedValue(infoKey: String, envKey: String, fallback: String = "") -> String {
        optionalResolvedValue(infoKey: infoKey, envKey: envKey) ?? fallback
    }

    private static func optionalResolvedValue(infoKey: String, envKey: String) -> String? {
        let env = ProcessInfo.processInfo.environment[envKey]
        if let env, !isPlaceholder(env), !env.isEmpty {
            return env
        }

        let bundle = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String
        if let bundle, !isPlaceholder(bundle), !bundle.isEmpty {
            return bundle
        }

        return nil
    }

    private static func isPlaceholder(_ value: String) -> Bool {
        value.contains("$(") || value.contains("<") || value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
