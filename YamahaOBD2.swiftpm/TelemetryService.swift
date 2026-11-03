import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Modello del payload di telemetria diagnostica anonima
public struct DiagnosticTelemetryReport: Codable {
    public let timestamp: String
    public let appVersion: String
    public let osVersion: String
    public let deviceModel: String
    public let adapterName: String
    public let isAdapterCertified: Bool
    public let detectedCANHeaders: [String]
    public let activeDTCs: [String]
    public let absDTCs: [String]
    public let iscStatusSample: String
    public let o2StatusSample: String
    public let throttleDirtLevel: Int
    public let throttleDirtPct: Double
}

public class TelemetryService {
    public static let shared = TelemetryService()
    
    // Inserire qui l'endpoint Supabase o Cloudflare Worker / Firebase
    // Se lasciato vuoto o non configurato, il report viene generato ed archiviato localmente senza errori
    public var cloudIngestURLString: String = "https://YOUR_PROJECT_ID.supabase.co/rest/v1/telemetry_reports"
    public var apiKey: String = "YOUR_ANON_PUBLIC_KEY"
    
    private init() {}
    
    public func sendCompatibilityTelemetry(
        adapterName: String,
        isCertified: Bool,
        canHeaders: [String],
        engineDTCs: [String],
        absDTCs: [String],
        iscStatus: String,
        o2Status: String,
        dirtLevel: Int,
        dirtPct: Double
    ) {
        // Disabilitato in modalità Demo per non sporcare i dati di telemetria reali
        guard !adapterName.isEmpty && adapterName != "Simulated ELM327" else { return }
        
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        
        let appVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        #if os(iOS)
        let osVer = "iOS " + UIDevice.current.systemVersion
        let model = UIDevice.current.model
        #else
        let osVer = "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
        let model = "Mac"
        #endif
        
        let report = DiagnosticTelemetryReport(
            timestamp: now,
            appVersion: "\(appVer) (\(build))",
            osVersion: osVer,
            deviceModel: model,
            adapterName: adapterName,
            isAdapterCertified: isCertified,
            detectedCANHeaders: canHeaders,
            activeDTCs: engineDTCs,
            absDTCs: absDTCs,
            iscStatusSample: iscStatus,
            o2StatusSample: o2Status,
            throttleDirtLevel: dirtLevel,
            throttleDirtPct: dirtPct
        )
        
        guard let url = URL(string: cloudIngestURLString), !cloudIngestURLString.contains("YOUR_PROJECT_ID") else {
            // Se il backend non è ancora configurato con un URL reale, non inviare richieste a vuoto
            return
        }
        
        guard let jsonData = try? JSONEncoder().encode(report) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            // Fallisce silenziosamente in background senza disturbare l'utente
        }.resume()
    }
}
