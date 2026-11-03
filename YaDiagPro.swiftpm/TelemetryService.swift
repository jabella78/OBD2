import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Modello del payload di telemetria diagnostica anonima
public struct DiagnosticTelemetryReport: Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case appVersion = "app_version"
        case osVersion = "os_version"
        case deviceModel = "device_model"
        case adapterName = "adapter_name"
        case isAdapterCertified = "is_adapter_certified"
        case detectedCANHeaders = "detected_can_headers"
        case activeDTCs = "active_dtcs"
        case absDTCs = "abs_dtcs"
        case iscStatusSample = "isc_status_sample"
        case o2StatusSample = "o2_status_sample"
        case throttleDirtLevel = "throttle_dirt_level"
        case throttleDirtPct = "throttle_dirt_pct"
    }
}

public class TelemetryService {
    public static let shared = TelemetryService()
    
    public var cloudIngestURLString: String = "https://dtucjtuhgtcrkkjjfvcr.supabase.co/rest/v1/telemetry_reports"
    public var apiKey: String = "sb_publishable_BefsC-26ZRHndn105jFIKw_g4U-e7t0"
    
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
            return
        }
        
        guard let jsonData = try? JSONEncoder().encode(report) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { _, _, _ in
            // Fallisce silenziosamente in background
        }.resume()
    }
}
