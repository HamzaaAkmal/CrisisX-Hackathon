import SwiftUI

enum AppTheme {
    static let blue = Color(red: 0.05, green: 0.36, blue: 0.92)
    static let sky = Color(red: 0.14, green: 0.62, blue: 1.0)
    static let ink = Color(red: 0.06, green: 0.10, blue: 0.18)
    static let muted = Color(red: 0.38, green: 0.45, blue: 0.56)
    static let surface = Color(red: 0.96, green: 0.98, blue: 1.0)
    static let line = Color(red: 0.84, green: 0.89, blue: 0.96)
    static let success = Color(red: 0.04, green: 0.58, blue: 0.32)
    static let warning = Color(red: 0.95, green: 0.58, blue: 0.12)
    static let danger = Color(red: 0.88, green: 0.18, blue: 0.22)
    static let cardRadius: CGFloat = 25

    static func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 5: return danger
        case 4: return Color(red: 0.95, green: 0.34, blue: 0.18)
        case 3: return warning
        case 2: return sky
        default: return success
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDisabled ? AppTheme.muted : AppTheme.blue)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.line, lineWidth: 1)
            )
    }
}

extension View {
    func ciroCard() -> some View {
        modifier(CardBackground())
    }
}
