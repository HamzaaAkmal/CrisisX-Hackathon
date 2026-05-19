import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var app: AppModel
    @State private var bootstrapped = false

    var body: some View {
        Group {
            if app.session == nil {
                AuthView()
            } else {
                MainShellView()
            }
        }
        .task {
            guard !bootstrapped else { return }
            bootstrapped = true
            app.bootstrap()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppModel())
}
