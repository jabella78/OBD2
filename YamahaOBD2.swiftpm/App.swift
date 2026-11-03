import SwiftUI

@main
struct YaDiagApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localizationManager)
        }
    }
}
