import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

struct ContentView: View {
    @StateObject var bleManager = BLEManager()
    @StateObject var obd2Manager: OBD2Manager
    @StateObject var aiManager = AIManager()
    @ObservedObject var lang = LocalizationManager.shared
    
    var currentDeploymentBuild: String {
        if let path = Bundle.main.path(forResource: "deployment_id", ofType: "txt"),
           let text = try? String(contentsOfFile: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            return text
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (Build \(build))"
    }
    
    @AppStorage("lastAcceptedDeploymentBuild") private var lastAcceptedDeploymentBuild: String = ""
    @State private var showingManualDisclaimer: Bool = false
    
    var isDisclaimerRequired: Bool {
        return lastAcceptedDeploymentBuild != currentDeploymentBuild
    }
    
    init() {
        let ble = BLEManager()
        _bleManager = StateObject(wrappedValue: ble)
        _obd2Manager = StateObject(wrappedValue: OBD2Manager(bleManager: ble))
    }
    
    @AppStorage("selected_tab") private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView(obd2Manager: obd2Manager)
                    .tabItem { 
                        Image(systemName: "gauge")
                        Text(lang.t("tab_dash"))
                    }
                    .tag(0)
                
                DiagnosticsView(obd2Manager: obd2Manager, aiManager: aiManager)
                    .tabItem { 
                        Image(systemName: "wrench.and.screwdriver")
                        Text(lang.t("tab_dtc")) 
                    }
                    .tag(1)
                    
                TerminalView(obd2Manager: obd2Manager)
                    .tabItem { 
                        Image(systemName: "terminal")
                        Text(lang.t("tab_term")) 
                    }
                    .tag(2)
                
                ConnectionView(bleManager: bleManager, obd2Manager: obd2Manager)
                    .tabItem { 
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text(lang.t("tab_ble")) 
                    }
                    .tag(3)
                    
                ActuatorTestView(obd2Manager: obd2Manager)
                    .tabItem {
                        Image(systemName: "bolt.fill")
                        Text(lang.t("tab_actuators"))
                    }
                    .tag(4)
                    
                SettingsView(aiManager: aiManager)
                    .tabItem { 
                        Image(systemName: "gear")
                        Text(lang.t("tab_setup")) 
                    }
                    .tag(5)
                
                InfoView(onShowDisclaimer: {
                    showingManualDisclaimer = true
                })
                    .tabItem {
                        Image(systemName: "info.circle.fill")
                        Text(lang.t("tab_info"))
                    }
                    .tag(6)
            }
            .padding()
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 650)
            #else
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            #endif
            .disabled(isDisclaimerRequired || showingManualDisclaimer)
            
            // Overlay Bloccante Disclaimer Legale
            if isDisclaimerRequired || showingManualDisclaimer {
                Color.black.opacity(0.88)
                    .ignoresSafeArea()
                
                DisclaimerView(
                    appVersion: currentDeploymentBuild,
                    isReopeningTerms: showingManualDisclaimer && !isDisclaimerRequired,
                    onAccept: {
                        lastAcceptedDeploymentBuild = currentDeploymentBuild
                        showingManualDisclaimer = false
                    },
                    onDismiss: {
                        showingManualDisclaimer = false
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isDisclaimerRequired)
        .animation(.easeInOut(duration: 0.25), value: showingManualDisclaimer)
        .preferredColorScheme(.dark)
    }
}

struct AnalogTachometerView: View {
    var rpm: Int
    let maxRpm: Double = 13000
    
    var body: some View {
        ZStack {
            // Sfondo nero e ghiera
            Circle()
                .fill(Color.black)
                .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 3))
                .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 0)
            
            // Tacche e Numeri
            ForEach(0..<14) { i in
                let angle = Angle.degrees(Double(i) * (260.0 / 13.0) - 130.0)
                let isRedZone = i >= 10
                
                // Tacca
                VStack {
                    Rectangle()
                        .fill(isRedZone ? Color.red : Color.white)
                        .frame(width: i % 2 == 0 ? 4 : 2, height: i % 2 == 0 ? 15 : 8)
                    Spacer()
                }
                .frame(height: 230)
                .rotationEffect(angle)
                
                // Numero
                if i % 2 == 0 {
                    VStack {
                        Text("\(i)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isRedZone ? .red : .white)
                            .rotationEffect(-angle) // Raddrizza il testo
                        Spacer()
                    }
                    .frame(height: 180)
                    .rotationEffect(angle)
                }
            }
            
            // Lancetta (Ago)
            let currentAngle = Angle.degrees((min(Double(rpm), maxRpm) / maxRpm) * 260.0 - 130.0)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 6, height: 110)
                    .cornerRadius(3)
                Color.clear
                    .frame(width: 6, height: 110)
            }
            .rotationEffect(currentAngle)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rpm)
            
            // Perno centrale
            Circle()
                .fill(Color.black)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
            
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
            
            // Display Digitale in basso
            VStack {
                Spacer()
                Text("\(rpm)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("RPM")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 25)
        }
        .frame(width: 250, height: 250)
    }
}

struct O2SensorBarView: View {
    var voltage: Double
    
    var body: some View {
        VStack {
            Text(String(format: "%.2f V", voltage))
                .font(.system(size: 30, weight: .bold, design: .monospaced))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.red, .green, .blue]), startPoint: .leading, endPoint: .trailing))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 4, height: 30)
                        .offset(x: max(0, min(geometry.size.width - 4, CGFloat(voltage / 1.2) * geometry.size.width)))
                }
            }
            .frame(height: 30)
            
            HStack {
                Text("Magra").font(.caption).foregroundColor(.red)
                Spacer()
                Text("Stechio").font(.caption).foregroundColor(.green)
                Spacer()
                Text("Grassa").font(.caption).foregroundColor(.blue)
            }
        }
    }
}

struct CircularGaugeView: View {
    var value: Double
    var max: Double
    var title: String
    var unit: String
    var color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(Swift.max(value, 0)/max, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(String(format: "%.1f", value).replacingOccurrences(of: ".0", with: ""))
                    .font(.system(size: 20, weight: .bold))
            }
            .frame(width: 80, height: 80)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

struct DashboardView: View {
    @ObservedObject var obd2Manager: OBD2Manager
    @ObservedObject var lang = LocalizationManager.shared
    @State private var showingCSVShareSheet: Bool = false
    
    var recordCsvBtnText: String {
        if obd2Manager.isRecording {
            switch lang.currentLanguage {
            case .english: return "Stop CSV"
            case .italian: return "Stop CSV"
            case .french: return "Arrêter CSV"
            case .spanish: return "Detener CSV"
            case .german: return "CSV Stoppen"
            }
        } else {
            switch lang.currentLanguage {
            case .english: return "Record CSV"
            case .italian: return "Registra CSV"
            case .french: return "Enregistrer CSV"
            case .spanish: return "Grabar CSV"
            case .german: return "CSV Aufnehmen"
            }
        }
    }
    
    var exportCsvBtnText: String {
        switch lang.currentLanguage {
        case .english: return "Export CSV"
        case .italian: return "Esporta CSV"
        case .french: return "Exporter CSV"
        case .spanish: return "Exportar CSV"
        case .german: return "CSV Exportieren"
        }
    }
    
    var logoImage: PlatformImage? {
        if let path = Bundle.main.path(forResource: "yadiag_logo", ofType: "png") {
            return PlatformImage(contentsOfFile: path)
        }
        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Centrale YaDiag
                HStack {
                    Spacer()
                    HStack(spacing: 14) {
                        if let img = logoImage {
                            #if os(macOS)
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 58, height: 58)
                                .cornerRadius(14)
                                .shadow(color: .cyan.opacity(0.3), radius: 6, x: 0, y: 3)
                            #else
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .cornerRadius(12)
                                .shadow(color: .cyan.opacity(0.3), radius: 6, x: 0, y: 3)
                            #endif
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(AppEdition.appName)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [.cyan, .blue, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            Text(lang.t("dash_subtitle"))
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.cyan.opacity(0.85))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Control Center: Card Moderna Compatta per Telemetria, Rec e Demo
                VStack(spacing: 12) {
                    // Riga 1: I due comandi primari
                    HStack(spacing: 10) {
                        // 1. Tasto Telemetria Live (Play/Pausa)
                        Button(action: {
                            obd2Manager.toggleTelemetry()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: obd2Manager.isPollingPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text(obd2Manager.isPollingPaused ? lang.t("dash_live_resume") : lang.t("dash_live_pause"))
                                    .font(.system(size: 14, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                obd2Manager.isPollingPaused
                                    ? LinearGradient(colors: [Color.green.opacity(0.85), Color.green], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [Color.orange.opacity(0.85), Color.orange], startPoint: .top, endPoint: .bottom)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: (obd2Manager.isPollingPaused ? Color.green : Color.orange).opacity(0.3), radius: 3, x: 0, y: 2)
                        }
                        
                        // 2. Tasto Registrazione CSV Telemetria
                        Button(action: {
                            obd2Manager.toggleRecording()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: obd2Manager.isRecording ? "stop.fill" : "circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(obd2Manager.isRecording ? .white : .red)
                                Text(recordCsvBtnText)
                                    .font(.system(size: 14, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                obd2Manager.isRecording
                                    ? Color.red
                                    : Color.secondary.opacity(0.18)
                            )
                            .foregroundColor(obd2Manager.isRecording ? .white : .primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(obd2Manager.isRecording ? Color.red : Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // 3. Tasto Esporta CSV (visibile se è presente una sessione registrata)
                        if let path = obd2Manager.currentTelemetryFilePath, !obd2Manager.isRecording {
                            Button(action: {
                                #if os(iOS)
                                showingCSVShareSheet = true
                                #elseif os(macOS)
                                NSWorkspace.shared.open(path)
                                #endif
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 13, weight: .bold))
                                    Text(exportCsvBtnText)
                                        .font(.system(size: 13, weight: .bold))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 12)
                                .background(Color.cyan.opacity(0.18))
                                .foregroundColor(.cyan)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                    
                    // Riga 2: Card dedicata al Simulatore Banco Prova (Demo) con Switch Toggle
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: obd2Manager.isDemoMode ? "play.laptopcomputer" : "laptopcomputer")
                                .font(.system(size: 16))
                                .foregroundColor(obd2Manager.isDemoMode ? .purple : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.t("ble_bench_mode_title"))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(obd2Manager.isDemoMode ? .purple : .primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                Text(obd2Manager.isDemoMode ? lang.t("ble_bench_mode_active") : lang.t("ble_bench_mode_idle"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { obd2Manager.isDemoMode },
                            set: { _ in obd2Manager.toggleDemoMode() }
                        ))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(obd2Manager.isDemoMode ? Color.purple.opacity(0.12) : Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(obd2Manager.isDemoMode ? Color.purple.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(10)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(14)
                .padding(.horizontal, 16)
                
                // Primary Dashboard
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 50) {
                        AnalogTachometerView(rpm: obd2Manager.rpm)
                        
                        VStack {
                            Text("\(obd2Manager.speed)")
                                .font(.system(size: 80, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            Text("km/h")
                                .font(.title2)
                                .foregroundColor(.gray)
                                
                            HStack {
                                Text("\(lang.t("gear_label")):")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text(obd2Manager.currentGear)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 10)
                        }
                        .frame(width: 200, height: 200)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.5), lineWidth: 2))
                    }
                    
                    VStack(spacing: 20) {
                        AnalogTachometerView(rpm: obd2Manager.rpm)
                        
                        VStack {
                            Text("\(obd2Manager.speed)")
                                .font(.system(size: 80, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            Text("km/h")
                                .font(.title2)
                                .foregroundColor(.gray)
                                
                            HStack {
                                Text("\(lang.t("gear_label")):")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text(obd2Manager.currentGear)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 10)
                        }
                        .frame(width: 200, height: 200)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.5), lineWidth: 2))
                    }
                }
                
                // O2 Sensor
                VStack {
                    Text(lang.t("lambda_afr"))
                        .font(.headline)
                        .foregroundColor(.gray)
                    O2SensorBarView(voltage: obd2Manager.o2Voltage)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                .padding(.horizontal, 40)
                
                // Secondary Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    CircularGaugeView(value: Double(obd2Manager.temp), max: 120, title: "Temp", unit: "°C", color: obd2Manager.temp < 71 ? .blue : (obd2Manager.temp < 105 ? .green : (obd2Manager.temp < 116 ? .orange : .red)))
                    CircularGaugeView(value: Double(obd2Manager.tps), max: 100, title: "TPS", unit: "%", color: .blue)
                    CircularGaugeView(value: Double(obd2Manager.engineLoad), max: 100, title: "Load", unit: "%", color: .purple)
                    
                    let airLabel = lang.currentLanguage == .english || lang.currentLanguage == .french ? "Air" : (lang.currentLanguage == .german ? "Luft" : (lang.currentLanguage == .spanish ? "Aire" : "Aria"))
                    CircularGaugeView(value: Double(obd2Manager.iat), max: 60, title: airLabel, unit: "°C", color: .cyan)
                    CircularGaugeView(value: Double(obd2Manager.map), max: 110, title: "MAP", unit: "kPa", color: .yellow)
                    
                    let battLabel = lang.currentLanguage == .german || lang.currentLanguage == .french ? "Batterie" : (lang.currentLanguage == .english ? "Battery" : (lang.currentLanguage == .spanish ? "Batería" : "Batteria"))
                    let battDouble = Double(obd2Manager.batteryVoltage.replacingOccurrences(of: "V", with: "")) ?? 0.0
                    CircularGaugeView(value: battDouble, max: 16.0, title: battLabel, unit: "V", color: battDouble < 12.0 ? .red : .green)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showingCSVShareSheet) {
            if let path = obd2Manager.currentTelemetryFilePath {
                ActivityView(activityItems: [path])
            }
        }
        #endif
    }
}

struct DiagnosticsView: View {
    @ObservedObject var obd2Manager: OBD2Manager
    @ObservedObject var aiManager: AIManager
    @ObservedObject var lang = LocalizationManager.shared
    @State private var showingAIConsentAlert: Bool = false
    @State private var pendingAIAction: (() -> Void)? = nil
    @State private var manualABSCodeInput: String = ""
    @State private var showingServiceGuide: Bool = false
    @State private var generatedPDFURL: URL? = nil
    @State private var showingShareSheet: Bool = false
    @State private var showingPDFExportSuccess: Bool = false
    
    let absHeaders = ["7E3", "7B0", "7E2", "760"]
    
    var pdfBtnLabel: String {
        switch lang.currentLanguage {
        case .english: return "PDF Report"
        case .italian: return "Certificato PDF"
        case .french: return "Certificat PDF"
        case .spanish: return "Certificado PDF"
        case .german: return "PDF-Bericht"
        }
    }
    
    var serviceGuideBtnLabel: String {
        switch lang.currentLanguage {
        case .english: return "Service Guide"
        case .italian: return "Guida Tagliando"
        case .french: return "Guide Entretien"
        case .spanish: return "Guía Mantenimiento"
        case .german: return "Service-Anleitung"
        }
    }
    
    var pdfExportAlertTitle: String {
        switch lang.currentLanguage {
        case .english: return "PDF Certificate Generated"
        case .italian: return "Certificato PDF Generato"
        case .french: return "Certificat PDF Généré"
        case .spanish: return "Certificado PDF Generado"
        case .german: return "PDF-Zertifikat Erstellt"
        }
    }
    
    var pdfExportAlertDesc: String {
        switch lang.currentLanguage {
        case .english: return "The diagnostic inspection certificate PDF has been generated and opened in Preview."
        case .italian: return "Il certificato diagnostico in formato PDF è stato generato e aperto in Anteprima per la visualizzazione o la stampa."
        case .french: return "Le certificat d'inspection de diagnostic en format PDF a été généré et ouvert dans Aperçu."
        case .spanish: return "El certificado de peritaje y diagnóstico en formato PDF ha sido generado y abierto en Vista Previa."
        case .german: return "Das Inspektions- und Diagnosezertifikat als PDF wurde generiert und in der Vorschau geöffnet."
        }
    }
    
    var aiConsentTitle: String {
        switch lang.currentLanguage {
        case .english: return "Data Sharing with External AI Service"
        case .italian: return "Condivisione Dati con Servizio AI Esterno"
        case .french: return "Partage de Données avec Service d'IA Externe"
        case .spanish: return "Compartir Datos con Servicio de IA Externo"
        case .german: return "Datenweitergabe an externen KI-Dienst"
        }
    }
    
    var aiConsentConfirm: String {
        switch lang.currentLanguage {
        case .english: return "Consent and Send"
        case .italian: return "Acconsenti e Invia"
        case .french: return "Accepter et Envoyer"
        case .spanish: return "Aceptar y Enviar"
        case .german: return "Zustimmen und Senden"
        }
    }
    
    var aiConsentCancel: String {
        switch lang.currentLanguage {
        case .english: return "Cancel"
        case .italian: return "Annulla"
        case .french: return "Annuler"
        case .spanish: return "Cancelar"
        case .german: return "Abbrechen"
        }
    }
    
    var aiConsentBody: String {
        switch lang.currentLanguage {
        case .english: return "Technical diagnostic data (fault codes or session telemetry) will be transmitted to the \(aiManager.selectedProvider.rawValue) cloud endpoint to generate an expert mechanical assessment.\n\nNo personal data, vehicle registration or license plate details are collected or transmitted."
        case .italian: return "I dati tecnici diagnostici (codici guasto o telemetria della sessione) verranno trasmessi all'endpoint cloud di \(aiManager.selectedProvider.rawValue) per generare la valutazione meccanica specialistica.\n\nNessun dato personale o di identificazione veicolo/targa viene trasmesso."
        case .french: return "Les données techniques de diagnostic et les codes défaut seront transmis à l'endpoint de \(aiManager.selectedProvider.rawValue) pour analyse experte.\n\nAucune donnée personnelle ou d'immatriculation n'est transmise."
        case .spanish: return "Los datos técnicos de diagnóstico y códigos de avería se enviarán al servicio de \(aiManager.selectedProvider.rawValue) para generar el peritaje mecánico.\n\nNo se recoge ni comparte ningún dato personal ni matrícula."
        case .german: return "Diagnosetechnische Daten (Fehlercodes oder Telemetrie) werden an den Cloud-Endpunkt von \(aiManager.selectedProvider.rawValue) übermittelt, um eine mechanische Bewertung zu erstellen.\n\nEs werden keinerlei personenbezogene Daten oder Kennzeichen erfasst."
        }
    }
    
    var activeCodesList: [String] {
        return obd2Manager.selectedECU == .engine ? obd2Manager.dtcCodes : obd2Manager.absDtcCodes
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(lang.t("dtc_title"))
                    .font(.title3)
                    .bold()
                    .padding(.top, 8)
                
                Picker("ECU", selection: $obd2Manager.selectedECU) {
                    ForEach(DiagnosticTargetECU.allCases) { ecu in
                        Text(ecu.name(for: lang.currentLanguage)).tag(ecu)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if obd2Manager.selectedECU == .abs {
                    VStack(spacing: 10) {
                        // Riga 1: Selettore pulito dell'indirizzo CAN
                        HStack {
                            let canLabel = lang.currentLanguage == .english ? "ABS CAN Address:" : (lang.currentLanguage == .french ? "Adresse CAN ABS :" : (lang.currentLanguage == .spanish ? "Dirección CAN ABS:" : (lang.currentLanguage == .german ? "ABS CAN-Adresse:" : "Indirizzo CAN ABS:")))
                            Text(canLabel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("CAN ID", selection: $obd2Manager.absCanHeader) {
                                ForEach(absHeaders, id: \.self) { header in
                                    Text(header).tag(header)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 220)
                        }
                        
                        // Riga 2: Ricerca codice manuale + Scansione automatica CAN
                        HStack(spacing: 8) {
                            let searchPlaceholder = lang.currentLanguage == .english ? "ABS Code (11-64)" : (lang.currentLanguage == .french ? "Code ABS (11-64)" : (lang.currentLanguage == .spanish ? "Cód. ABS (11-64)" : (lang.currentLanguage == .german ? "ABS-Code (11-64)" : "Cod. ABS (11-64)")))
                            TextField(searchPlaceholder, text: $manualABSCodeInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.subheadline)
                            
                            Button(action: {
                                let trimmed = manualABSCodeInput.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                let desc = obd2Manager.lookupABSCode(trimmed)
                                if !obd2Manager.absDtcCodes.contains(desc) {
                                    obd2Manager.absDtcCodes.insert(desc, at: 0)
                                }
                                manualABSCodeInput = ""
                            }) {
                                Text(lang.currentLanguage == .english ? "Search" : (lang.currentLanguage == .french ? "Chercher" : (lang.currentLanguage == .spanish ? "Buscar" : (lang.currentLanguage == .german ? "Suchen" : "Cerca"))))
                                    .font(.system(size: 12, weight: .bold))
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { obd2Manager.scanABSAddresses() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 12))
                                    Text("Auto-Scan")
                                        .font(.system(size: 12, weight: .bold))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.18))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Card Azioni Diagnostiche DTC & AI con Design Squadrato Moderno
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    // 1. Scansiona Errori
                    Button(action: { obd2Manager.readErrors() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13, weight: .bold))
                            Text(lang.t("scan_dtc_btn"))
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            obd2Manager.selectedECU == .engine
                                ? LinearGradient(colors: [Color.blue.opacity(0.85), Color.blue], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.orange.opacity(0.85), Color.orange], startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: (obd2Manager.selectedECU == .engine ? Color.blue : Color.orange).opacity(0.25), radius: 3, x: 0, y: 2)
                    }
                    
                    // 2. Cancella Errori
                    Button(action: { obd2Manager.clearErrors() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 13))
                            Text(lang.t("clear_dtc_btn"))
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.4), lineWidth: 1))
                    }
                    
                    // 3. Valuta con AI
                    Button(action: {
                        pendingAIAction = {
                            aiManager.evaluateFaultCodes(activeCodesList)
                        }
                        showingAIConsentAlert = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                            Text(lang.t("ai_eval_btn"))
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            LinearGradient(colors: [Color.purple.opacity(0.9), Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color.purple.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    
                    // 4. Analisi Corsa Telemetria
                    Button(action: {
                        if let path = obd2Manager.currentTelemetryFilePath, let data = try? String(contentsOf: path, encoding: .utf8) {
                            pendingAIAction = {
                                aiManager.evaluateTelemetry(csvData: data)
                            }
                            showingAIConsentAlert = true
                        } else {
                            aiManager.evaluationResult = lang.currentLanguage == .english ? "No telemetry data found. Start recording in Dashboard." : (lang.currentLanguage == .french ? "Aucune donnée de télémétrie. Démarrez l'enregistrement." : (lang.currentLanguage == .spanish ? "Sin datos de telemetría. Inicia la grabación en el Tablero." : (lang.currentLanguage == .german ? "Keine Telemetriedaten gefunden. Aufnahme im Cockpit starten." : "Nessun dato di telemetria trovato. Avvia la registrazione nel Cruscotto.")))
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 13, weight: .bold))
                            let telemTitle = lang.currentLanguage == .english ? "Telemetry (AI)" : (lang.currentLanguage == .french ? "Télémétrie (IA)" : (lang.currentLanguage == .spanish ? "Telemetría (IA)" : (lang.currentLanguage == .german ? "Telemetrie (KI)" : "Analisi Corsa (AI)")))
                            Text(telemTitle)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.secondary.opacity(0.18))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal)
                
                // 5. Tasti Esporta Certificato Diagnostico PDF e Guida Reset Tagliando
                HStack(spacing: 10) {
                    Button(action: {
                        if let pdfURL = DiagnosticReportService.shared.generatePDF(obd2Manager: obd2Manager) {
                            generatedPDFURL = pdfURL
                            #if os(iOS)
                            showingShareSheet = true
                            #elseif os(macOS)
                            NSWorkspace.shared.open(pdfURL)
                            showingPDFExportSuccess = true
                            #endif
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.cyan)
                            Text(pdfBtnLabel)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(Color.cyan.opacity(0.16))
                        .foregroundColor(.cyan)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                    }
                    
                    Button(action: {
                        showingServiceGuide = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.orange)
                            Text(serviceGuideBtnLabel)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(Color.orange.opacity(0.16))
                        .foregroundColor(.orange)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                    }
                }
                .padding(.horizontal)
                
                // Box Codici Errore Rilevati
                VStack(alignment: .leading, spacing: 6) {
                    let errHeader = obd2Manager.selectedECU == .engine
                        ? (lang.currentLanguage == .english ? "Engine Fault Codes (FI ECU):" : (lang.currentLanguage == .french ? "Codes Défaut Moteur (FI ECU) :" : (lang.currentLanguage == .spanish ? "Códigos Avería Motor (FI ECU):" : (lang.currentLanguage == .german ? "Motor-Fehlercodes (FI ECU):" : "Codici Errore Motore (FI ECU):"))))
                        : (lang.currentLanguage == .english ? "ABS Fault Codes (ABS ECU):" : (lang.currentLanguage == .french ? "Codes Défaut Freins (ABS ECU) :" : (lang.currentLanguage == .spanish ? "Códigos Avería Frenos (ABS ECU):" : (lang.currentLanguage == .german ? "ABS-Fehlercodes (ABS ECU):" : "Codici Errore Freni (ABS ECU):"))))
                    Text(errHeader)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    if activeCodesList.isEmpty {
                        Text(lang.t("no_dtc_message"))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.secondary.opacity(0.08))
                            .cornerRadius(10)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(activeCodesList, id: \.self) { code in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(obd2Manager.selectedECU == .engine ? .blue : .orange)
                                        .padding(.top, 2)
                                    Text(code)
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(10)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Box Risultato Analisi AI
                if aiManager.isEvaluating || !aiManager.evaluationResult.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            let aiResultLabel = lang.currentLanguage == .english ? "AI Diagnostic Assessment:" : (lang.currentLanguage == .french ? "Résultat Analyse IA :" : (lang.currentLanguage == .spanish ? "Resultado Análisis IA:" : (lang.currentLanguage == .german ? "KI-Analyseergebnis:" : "Risultato Analisi AI:")))
                            Text(aiResultLabel)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                            if aiManager.isEvaluating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        Text(aiManager.evaluationResult)
                            .font(.subheadline)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .alert(aiConsentTitle, isPresented: $showingAIConsentAlert) {
            Button(aiConsentConfirm, role: .none) {
                pendingAIAction?()
                pendingAIAction = nil
            }
            Button(aiConsentCancel, role: .cancel) {
                pendingAIAction = nil
            }
        } message: {
            Text(aiConsentBody)
        }
        .sheet(isPresented: $showingServiceGuide) {
            ServiceResetGuideView()
        }
        #if os(iOS)
        .sheet(isPresented: $showingShareSheet) {
            if let url = generatedPDFURL {
                ActivityView(activityItems: [url])
            }
        }
        #endif
        .alert(pdfExportAlertTitle, isPresented: $showingPDFExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pdfExportAlertDesc)
        }
    }
}

struct ConnectionView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var obd2Manager: OBD2Manager
    @ObservedObject var lang = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text(lang.t("ble_title"))
                .font(.title2)
                .bold()
                .padding(.top, 10)
            
            // Toggle Filtro Adattatori Certificati
            Toggle(isOn: $bleManager.showOnlyCertifiedAdapters) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.t("ble_ext_mode"))
                        .font(.subheadline)
                        .bold()
                    Text(bleManager.showOnlyCertifiedAdapters
                         ? "UniCarScan, vLinker, OBDLink, Veepeak, Carista"
                         : lang.t("ble_ext_desc"))
                        .font(.caption2)
                        .foregroundColor(bleManager.showOnlyCertifiedAdapters ? .cyan : .orange)
                }
            }
            .padding(10)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            HStack {
                Circle()
                    .fill(bleManager.isBluetoothOn ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                let btStatus = bleManager.isBluetoothOn
                    ? (lang.currentLanguage == .english ? "Active" : (lang.currentLanguage == .german ? "Aktiv" : (lang.currentLanguage == .spanish ? "Activo" : (lang.currentLanguage == .french ? "Actif" : "Attivo"))))
                    : (lang.currentLanguage == .english ? "Off" : (lang.currentLanguage == .german ? "Aus" : (lang.currentLanguage == .spanish ? "Apagado" : (lang.currentLanguage == .french ? "Éteint" : "Spento"))))
                Text("Bluetooth: **\(btStatus)**")
                    .font(.subheadline)
            }
            
            if bleManager.isConnected {
                VStack(spacing: 12) {
                    if bleManager.isVirtualSimulator {
                        HStack {
                            Image(systemName: "laptopcomputer.and.arrow.down")
                                .foregroundColor(.purple)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.t("ble_sim_active_banner"))
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(.purple)
                                Text(bleManager.connectedDeviceName)
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.primary)
                                Text(lang.t("ble_simulated_protocol"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.12))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal)
                    } else {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.green)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.t("ble_connected_to"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(bleManager.connectedDeviceName)
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        obd2Manager.startInitialization()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.badge.checkmark.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("CAN Bus 500k Init")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(colors: [Color.blue.opacity(0.9), Color.blue], startPoint: .top, endPoint: .bottom)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        if bleManager.isVirtualSimulator {
                            obd2Manager.stopVirtualSimulatorMode()
                        } else {
                            bleManager.disconnect()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text(bleManager.isVirtualSimulator ? lang.t("ble_simulator_disconnect") : lang.t("ble_disconnect"))
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            } else {
                // Card Modalità Simulatore Senza Adattatore
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.laptopcomputer")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.t("ble_simulator_card_title"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.purple)
                            Text(lang.t("ble_simulator_card_desc"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        obd2Manager.startVirtualSimulatorMode()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                            Text(lang.t("ble_simulator_connect"))
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(colors: [Color.purple.opacity(0.9), Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color.purple.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                }
                .padding(12)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
                .padding(.bottom, 6)
                
                Button(action: {
                    bleManager.scan()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .bold))
                        Text(lang.t("ble_scan_btn"))
                            .font(.system(size: 15, weight: .bold))
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        bleManager.isBluetoothOn
                            ? LinearGradient(colors: [Color.blue.opacity(0.9), Color.blue], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.gray, Color.gray], startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: bleManager.isBluetoothOn ? Color.blue.opacity(0.3) : Color.clear, radius: 3, x: 0, y: 2)
                }
                .disabled(!bleManager.isBluetoothOn)
                .padding(.horizontal)
                
                if bleManager.discoveredPeripherals.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(lang.t("ble_no_devices"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lang.t("ble_insert_hint"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                } else {
                    List(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
                        let name = peripheral.name ?? lang.t("ble_device_default")
                        let isCert = BLEManager.isCertifiedAdapter(name: name)
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(name)
                                    .font(.headline)
                                HStack(spacing: 4) {
                                    Image(systemName: isCert ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                                    Text(isCert ? lang.t("ble_certified_badge") : lang.t("ble_generic_badge"))
                                }
                                .font(.caption2)
                                .foregroundColor(isCert ? .green : .orange)
                            }
                            Spacer()
                            Button(action: {
                                bleManager.connect(peripheral: peripheral)
                            }) {
                                Text(lang.t("ble_connect"))
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}

struct TerminalView: View {
    @ObservedObject var obd2Manager: OBD2Manager
    @ObservedObject var lang = LocalizationManager.shared
    @State private var commandInput: String = ""
    @State private var showingDangerousCommandAlert: Bool = false
    @State private var dangerousCommandWarning: String = ""
    @State private var pendingCommand: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(lang.t("term_title"))
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { obd2Manager.toggleTelemetry() }) {
                        HStack(spacing: 5) {
                            Image(systemName: obd2Manager.isPollingPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(obd2Manager.isPollingPaused ? "Live" : (lang.currentLanguage == .italian ? "Pausa" : "Pause"))
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(obd2Manager.isPollingPaused ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(color: (obd2Manager.isPollingPaused ? Color.green : Color.orange).opacity(0.3), radius: 3, x: 0, y: 1)
                    }
                    
                    Button(action: { obd2Manager.terminalOutput.removeAll() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text(lang.t("term_clear"))
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.secondary.opacity(0.18))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Text(lang.t("term_desc"))
                .foregroundColor(.secondary)
                .font(.caption)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(obd2Manager.terminalOutput) { line in
                        Text(line.text)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(line.text.contains(">") ? .cyan : (line.text.contains("NO DATA") || line.text.contains("ERROR") ? .orange : .green))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color.black.opacity(0.85))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .padding(.horizontal)
            
            HStack {
                TextField("ATSH 7B0, 1003, 1902FF, ATMA...", text: $commandInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !commandInput.isEmpty {
                        let check = OBD2Manager.isDangerousCommand(commandInput)
                        if check.isDangerous {
                            pendingCommand = commandInput
                            dangerousCommandWarning = check.reason
                            showingDangerousCommandAlert = true
                        } else {
                            obd2Manager.sendCustomCommand(commandInput)
                            commandInput = ""
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 13))
                        Text(lang.t("term_send"))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .alert(
            lang.currentLanguage == .english ? "Critical Diagnostic Command" : (lang.currentLanguage == .french ? "Commande Diagnostique Critique" : (lang.currentLanguage == .spanish ? "Comando Diagnóstico Crítico" : (lang.currentLanguage == .german ? "Kritischer Diagnosebefehl" : "Comando Diagnostico Critico"))),
            isPresented: $showingDangerousCommandAlert
        ) {
            Button(
                lang.currentLanguage == .english ? "Send Anyway (Expert Mode)" : (lang.currentLanguage == .french ? "Envoyer quand même (Mode Expert)" : (lang.currentLanguage == .spanish ? "Enviar de todos modos (Modo Experto)" : (lang.currentLanguage == .german ? "Trotzdem senden (Expertenmodus)" : "Invia Comunque (Modalità Esperto)"))),
                role: .destructive
            ) {
                obd2Manager.sendCustomCommand(pendingCommand)
                commandInput = ""
                pendingCommand = ""
            }
            Button(
                lang.currentLanguage == .english ? "Cancel" : (lang.currentLanguage == .french ? "Annuler" : (lang.currentLanguage == .spanish ? "Cancelar" : (lang.currentLanguage == .german ? "Abbrechen" : "Annulla"))),
                role: .cancel
            ) {
                pendingCommand = ""
            }
        } message: {
            Text("\(lang.t("term_danger_alert"))\n\n(\(dangerousCommandWarning))")
        }
    }
}

struct SettingsView: View {
    @ObservedObject var aiManager: AIManager
    @ObservedObject var lang = LocalizationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                #if !os(macOS)
                // Sezione Licenza YaDiag Pro (Edizione Completa Acquistata su App Store)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        Text(lang.currentLanguage == .english ? "YaDiag Pro Edition: ACTIVE" : (lang.currentLanguage == .french ? "Édition YaDiag Pro : ACTIVE" : (lang.currentLanguage == .spanish ? "Edición YaDiag Pro: ACTIVA" : (lang.currentLanguage == .german ? "YaDiag Pro Edition: AKTIV" : "Edizione YaDiag Pro: ATTIVA"))))
                            .font(.headline)
                            .bold()
                        Spacer()
                        Text("Lifetime")
                            .font(.caption2)
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.yellow.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                    
                    Text(lang.t("setup_pro_features_active"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color.yellow.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                #endif
                
                // Sezione 0: Selezione Lingua dell'Applicazione (Menu a Tendina)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "globe")
                            .font(.system(size: 26))
                            .foregroundColor(.cyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.t("setup_lang_section"))
                                .font(.title3)
                                .bold()
                            Text(lang.t("setup_lang_desc"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("\(lang.t("setup_lang_section")):")
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker(lang.t("setup_lang_section"), selection: $lang.currentLanguage) {
                            ForEach(AppLanguage.allCases) { item in
                                Text("\(item.flag)  \(item.displayName)").tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.cyan.opacity(0.15))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(0.5), lineWidth: 1))
                    }
                    .padding(.top, 4)
                }
                .padding(14)
                .background(Color.cyan.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                
                Divider()
                
                HStack(spacing: 12) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang.t("setup_ai_section"))
                            .font(.title3)
                            .bold()
                        Text(lang.t("setup_ai_desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 1) Selezione Provider
                VStack(alignment: .leading, spacing: 8) {
                    Text(lang.t("setup_provider_label"))
                        .font(.headline)
                    
                    Picker("Provider", selection: $aiManager.selectedProvider) {
                        ForEach(AIProvider.allCases) { prov in
                            Text(prov.rawValue).tag(prov)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 2) Selezione Modello LLM
                VStack(alignment: .leading, spacing: 8) {
                    Text(lang.t("setup_model_label"))
                        .font(.headline)
                    
                    if aiManager.selectedProvider == .custom {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(lang.t("setup_custom_model_name"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField(lang.t("setup_custom_model_placeholder"), text: $aiManager.selectedModel)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text(lang.t("setup_custom_endpoint_label"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("http://localhost:11434/v1", text: $aiManager.customEndpoint)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    } else {
                        Picker(lang.t("setup_selected_model_picker"), selection: $aiManager.selectedModel) {
                            ForEach(aiManager.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        
                        HStack {
                            Text(aiManager.localizedFetchStatus(for: lang.currentLanguage))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(action: {
                                aiManager.fetchLiveModels()
                            }) {
                                HStack(spacing: 4) {
                                    if aiManager.isFetchingModels {
                                        ProgressView().scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text(lang.t("setup_sync_btn"))
                                        .bold()
                                }
                                .font(.caption2)
                                .foregroundColor(.purple)
                            }
                            .disabled(aiManager.isFetchingModels)
                        }
                    }
                }
                
                // 3) Chiave API
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(lang.t("setup_apikey_label")) \(aiManager.selectedProvider.rawValue):")
                        .font(.headline)
                    
                    SecureField("API Key (\(aiManager.selectedProvider.placeholderKey))", text: $aiManager.apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(lang.t("setup_apikey_security"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(10)
                
                // Riepilogo Provider & Caratteristiche
                VStack(alignment: .leading, spacing: 8) {
                    Text(lang.t("setup_providers_guide"))
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("• **Google Gemini:** `gemini-4-flash`, `gemini-4-pro`, `gemini-3.8-flash`, `gemini-3.8-pro`, `gemini-3.0-flash`, `gemini-2.5-flash`.")
                        Text("• **OpenAI:** `gpt-5-preview`, `gpt-5-mini`, `gpt-4.5-preview`, `o3`, `o3-mini`, `o1`.")
                        Text("• **Anthropic Claude:** `claude-4-sonnet`, `claude-4-opus`, `claude-3-7-sonnet`, `claude-3-5-sonnet`.")
                        Text("• **DeepSeek:** `deepseek-v3`, `deepseek-r1`, `deepseek-chat`, `deepseek-reasoner`.")
                        Text("• **Groq:** `llama-4-scout-preview`, `llama-3.3-70b-versatile`, `deepseek-r1-distill-llama-70b`.")
                        Text("• **Personalizzato:** Localhost / Ollama / LM Studio (OpenAI Compatible).")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct ModelCategory: Identifiable {
    let id = UUID()
    let engineFamily: String
    let subtitle: String
    let models: [String]
    let years: String
    let badgeColor: Color
}

struct InfoView: View {
    var onShowDisclaimer: (() -> Void)? = nil
    @ObservedObject var lang = LocalizationManager.shared
    @State private var showingServiceGuide: Bool = false
    
    var categories: [ModelCategory] {
        switch lang.currentLanguage {
        case .italian:
            return [
                ModelCategory(
                    engineFamily: "CP3 — Tre Cilindri Crossplane (847cc / 890cc)",
                    subtitle: "Iniezione YCC-T Ride-by-Wire, ABS Advics 2 Canali",
                    models: [
                        "Tracer 900 / Tracer 900 GT",
                        "MT-09 / MT-09 SP",
                        "Tracer 9 / Tracer 9 GT / GT+",
                        "XSR900 / XSR900 GP / Abarth",
                        "NIKEN / NIKEN GT"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .cyan
                ),
                ModelCategory(
                    engineFamily: "CP2 — Bicilindrico Parallelo (689cc)",
                    subtitle: "Telemetria Completa, DTC Motore e Diagnostica ABS",
                    models: [
                        "MT-07 / MT-07 Moto Cage",
                        "Tracer 700 / Tracer 7 / GT",
                        "Ténéré 700 / Rally / World Raid / Explore",
                        "XSR700 / XTribute",
                        "YZF-R7"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .blue
                ),
                ModelCategory(
                    engineFamily: "CP4 — Quattro Cilindri Crossplane (998cc)",
                    subtitle: "Piattaforma Superbike & Hypernaked YCC-T",
                    models: [
                        "MT-10 / MT-10 SP / Tourer",
                        "YZF-R1 / YZF-R1M"
                    ],
                    years: "2015 – 2026+",
                    badgeColor: .purple
                ),
                ModelCategory(
                    engineFamily: "Sport & Maxi Scooter (Euro 4 / Euro 5)",
                    subtitle: "Diagnostica Standard KWP2000 & UDS CAN-bus",
                    models: [
                        "YZF-R3 / MT-03 (321cc)",
                        "TMAX 530 / TMAX 560 (2017+)",
                        "XMAX 125 / 300 / 400 (2017+)"
                    ],
                    years: "2016 – 2026+",
                    badgeColor: .orange
                )
            ]
        case .english:
            return [
                ModelCategory(
                    engineFamily: "CP3 — Three-Cylinder Crossplane (847cc / 890cc)",
                    subtitle: "YCC-T Ride-by-Wire Injection, Advics 2-Channel ABS",
                    models: [
                        "Tracer 900 / Tracer 900 GT",
                        "MT-09 / MT-09 SP",
                        "Tracer 9 / Tracer 9 GT / GT+",
                        "XSR900 / XSR900 GP / Abarth",
                        "NIKEN / NIKEN GT"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .cyan
                ),
                ModelCategory(
                    engineFamily: "CP2 — Parallel-Twin (689cc)",
                    subtitle: "Full Telemetry, Engine DTC and ABS Diagnostics",
                    models: [
                        "MT-07 / MT-07 Moto Cage",
                        "Tracer 700 / Tracer 7 / GT",
                        "Ténéré 700 / Rally / World Raid / Explore",
                        "XSR700 / XTribute",
                        "YZF-R7"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .blue
                ),
                ModelCategory(
                    engineFamily: "CP4 — Four-Cylinder Crossplane (998cc)",
                    subtitle: "Superbike & Hypernaked YCC-T Platform",
                    models: [
                        "MT-10 / MT-10 SP / Tourer",
                        "YZF-R1 / YZF-R1M"
                    ],
                    years: "2015 – 2026+",
                    badgeColor: .purple
                ),
                ModelCategory(
                    engineFamily: "Sport & Maxi Scooters (Euro 4 / Euro 5)",
                    subtitle: "Standard KWP2000 & UDS CAN-bus Diagnostics",
                    models: [
                        "YZF-R3 / MT-03 (321cc)",
                        "TMAX 530 / TMAX 560 (2017+)",
                        "XMAX 125 / 300 / 400 (2017+)"
                    ],
                    years: "2016 – 2026+",
                    badgeColor: .orange
                )
            ]
        case .french:
            return [
                ModelCategory(
                    engineFamily: "CP3 — Trois Cylindres Crossplane (847cc / 890cc)",
                    subtitle: "Injection Ride-by-Wire YCC-T, ABS Advics 2 Canaux",
                    models: [
                        "Tracer 900 / Tracer 900 GT",
                        "MT-09 / MT-09 SP",
                        "Tracer 9 / Tracer 9 GT / GT+",
                        "XSR900 / XSR900 GP / Abarth",
                        "NIKEN / NIKEN GT"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .cyan
                ),
                ModelCategory(
                    engineFamily: "CP2 — Bicylindre Parallèle (689cc)",
                    subtitle: "Télémétrie Complète, DTC Moteur et Diagnostic ABS",
                    models: [
                        "MT-07 / MT-07 Moto Cage",
                        "Tracer 700 / Tracer 7 / GT",
                        "Ténéré 700 / Rally / World Raid / Explore",
                        "XSR700 / XTribute",
                        "YZF-R7"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .blue
                ),
                ModelCategory(
                    engineFamily: "CP4 — Quatre Cylindres Crossplane (998cc)",
                    subtitle: "Plateforme Superbike & Hypernaked YCC-T",
                    models: [
                        "MT-10 / MT-10 SP / Tourer",
                        "YZF-R1 / YZF-R1M"
                    ],
                    years: "2015 – 2026+",
                    badgeColor: .purple
                ),
                ModelCategory(
                    engineFamily: "Sport & Maxi Scooters (Euro 4 / Euro 5)",
                    subtitle: "Diagnostic Standard KWP2000 & UDS CAN-bus",
                    models: [
                        "YZF-R3 / MT-03 (321cc)",
                        "TMAX 530 / TMAX 560 (2017+)",
                        "XMAX 125 / 300 / 400 (2017+)"
                    ],
                    years: "2016 – 2026+",
                    badgeColor: .orange
                )
            ]
        case .spanish:
            return [
                ModelCategory(
                    engineFamily: "CP3 — Tres Cilindros Crossplane (847cc / 890cc)",
                    subtitle: "Inyección YCC-T Ride-by-Wire, ABS Advics 2 Canales",
                    models: [
                        "Tracer 900 / Tracer 900 GT",
                        "MT-09 / MT-09 SP",
                        "Tracer 9 / Tracer 9 GT / GT+",
                        "XSR900 / XSR900 GP / Abarth",
                        "NIKEN / NIKEN GT"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .cyan
                ),
                ModelCategory(
                    engineFamily: "CP2 — Bicilíndrico Paralelo (689cc)",
                    subtitle: "Telemetría Completa, DTC Motor y Diagnóstico ABS",
                    models: [
                        "MT-07 / MT-07 Moto Cage",
                        "Tracer 700 / Tracer 7 / GT",
                        "Ténéré 700 / Rally / World Raid / Explore",
                        "XSR700 / XTribute",
                        "YZF-R7"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .blue
                ),
                ModelCategory(
                    engineFamily: "CP4 — Cuatro Cilindros Crossplane (998cc)",
                    subtitle: "Plataforma Superbike e Hipernaked YCC-T",
                    models: [
                        "MT-10 / MT-10 SP / Tourer",
                        "YZF-R1 / YZF-R1M"
                    ],
                    years: "2015 – 2026+",
                    badgeColor: .purple
                ),
                ModelCategory(
                    engineFamily: "Sport y Maxi Scooters (Euro 4 / Euro 5)",
                    subtitle: "Diagnóstico Estándar KWP2000 y UDS CAN-bus",
                    models: [
                        "YZF-R3 / MT-03 (321cc)",
                        "TMAX 530 / TMAX 560 (2017+)",
                        "XMAX 125 / 300 / 400 (2017+)"
                    ],
                    years: "2016 – 2026+",
                    badgeColor: .orange
                )
            ]
        case .german:
            return [
                ModelCategory(
                    engineFamily: "CP3 — Dreizylinder Crossplane (847cc / 890cc)",
                    subtitle: "YCC-T Ride-by-Wire Einspritzung, Advics 2-Kanal ABS",
                    models: [
                        "Tracer 900 / Tracer 900 GT",
                        "MT-09 / MT-09 SP",
                        "Tracer 9 / Tracer 9 GT / GT+",
                        "XSR900 / XSR900 GP / Abarth",
                        "NIKEN / NIKEN GT"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .cyan
                ),
                ModelCategory(
                    engineFamily: "CP2 — Zweizylinder-Reihenmotor (689cc)",
                    subtitle: "Vollständige Telemetrie, Motor-DTC und ABS-Diagnose",
                    models: [
                        "MT-07 / MT-07 Moto Cage",
                        "Tracer 700 / Tracer 7 / GT",
                        "Ténéré 700 / Rally / World Raid / Explore",
                        "XSR700 / XTribute",
                        "YZF-R7"
                    ],
                    years: "2014 – 2026+",
                    badgeColor: .blue
                ),
                ModelCategory(
                    engineFamily: "CP4 — Vierzylinder Crossplane (998cc)",
                    subtitle: "Superbike & Hypernaked YCC-T Plattform",
                    models: [
                        "MT-10 / MT-10 SP / Tourer",
                        "YZF-R1 / YZF-R1M"
                    ],
                    years: "2015 – 2026+",
                    badgeColor: .purple
                ),
                ModelCategory(
                    engineFamily: "Sport & Maxi-Roller (Euro 4 / Euro 5)",
                    subtitle: "Standard KWP2000 & UDS CAN-Bus Diagnose",
                    models: [
                        "YZF-R3 / MT-03 (321cc)",
                        "TMAX 530 / TMAX 560 (2017+)",
                        "XMAX 125 / 300 / 400 (2017+)"
                    ],
                    years: "2016 – 2026+",
                    badgeColor: .orange
                )
            ]
        }
    }
    
    var infoTitle: String {
        switch lang.currentLanguage {
        case .english: return "Information & Compatibility"
        case .italian: return "Informazioni & Compatibilità"
        case .french: return "Informations & Compatibilité"
        case .spanish: return "Información y Compatibilidad"
        case .german: return "Informationen & Kompatibilität"
        }
    }
    
    var infoSubtitle: String {
        return "\(AppEdition.appName) — Version 1.0.2 (Build 2026)"
    }
    
    var canOverviewTitle: String {
        switch lang.currentLanguage {
        case .english: return "CAN-bus Protocol Architecture"
        case .italian: return "Compatibilità Protocolli CAN-bus"
        case .french: return "Architecture Protocoles CAN-bus"
        case .spanish: return "Arquitectura Protocolos CAN-bus"
        case .german: return "CAN-Bus Protokollarchitektur"
        }
    }
    
    var canOverviewDesc: String {
        switch lang.currentLanguage {
        case .english:
            return "YaDiag communicates via standard **KWP2000 over CAN-bus (500 kbps, 11-bit standard ID)** and **UDS (ISO 14229)** protocol. All Euro 4 (4-pin white diagnostic connector) and Euro 5 (standard 16-pin OBD2 connector) Japanese motorcycles and scooters share the same ECU network architecture for the Engine ECU (**FI ECU 7E0/7E8**) and ABS unit (**Advics 7E3/7EB**)."
        case .italian:
            return "YaDiag comunica tramite standard **KWP2000 su CAN-bus (500 kbps, 11-bit)** e protocollo **UDS (ISO 14229)**. Tutte le motociclette e scooter dotati di omologazione **Euro 4 (connettore diagnostico 4-pin bianco)** ed **Euro 5 (connettore OBD2 standard a 16-pin)** condividono la stessa architettura per la centralina motore (**FI ECU 7E0/7E8**) e centralina ABS (**Advics 7E3/7EB**)."
        case .french:
            return "YaDiag communique via le standard **KWP2000 sur CAN-bus (500 kbps, ID 11 bits)** et le protocole **UDS (ISO 14229)**. Toutes les motos et scooters homologués **Euro 4 (prise blanche 4 broches)** et **Euro 5 (prise OBD2 standard 16 broches)** partagent la même architecture calculateur moteur (**FI ECU 7E0/7E8**) et ABS (**Advics 7E3/7EB**)."
        case .spanish:
            return "YaDiag se comunica mediante el estándar **KWP2000 sobre CAN-bus (500 kbps, 11 bits)** y protocolo **UDS (ISO 14229)**. Todas las motocicletas y scooters con homologación **Euro 4 (conector 4 pines blanco)** y **Euro 5 (conector OBD2 estándar 16 pines)** comparten la misma arquitectura de centralita motor (**FI ECU 7E0/7E8**) y ABS (**Advics 7E3/7EB**)."
        case .german:
            return "YaDiag kommuniziert über **KWP2000 auf CAN-Bus (500 kbps, 11-Bit)** und das **UDS (ISO 14229)** Protokoll. Alle nach **Euro 4 (weißer 4-Pin-Stecker)** und **Euro 5 (16-Pin OBD2-Buchse)** homologierten Modelle teilen die gleiche Architektur für das Motorsteuergerät (**FI ECU 7E0/7E8**) und das ABS-Modul (**Advics 7E3/7EB**)."
        }
    }
    
    var modelsSectionTitle: String {
        switch lang.currentLanguage {
        case .english: return "Supported Engine Families & Models"
        case .italian: return "Modelli e Piattaforme Motore Supportate"
        case .french: return "Familles Moteur et Modèles Supportés"
        case .spanish: return "Familias de Motor y Modelos Compatibles"
        case .german: return "Unterstützte Motorfamilien & Modelle"
        }
    }
    
    var featuresSectionTitle: String {
        switch lang.currentLanguage {
        case .english: return "Included Diagnostic Capabilities"
        case .italian: return "Funzionalità Diagnostiche Incluse"
        case .french: return "Fonctionnalités Diagnostic Incluses"
        case .spanish: return "Funciones de Diagnóstico Incluidas"
        case .german: return "Enthaltene Diagnosefunktionen"
        }
    }
    
    var featuresList: [(String, String)] {
        switch lang.currentLanguage {
        case .english:
            return [
                ("gauge.with.needle", "Live Telemetry: Engine RPM, Speed, Calculated Gear, TPS Throttle, Coolant Temp, Battery Voltage, O2 Lambda, IAT, MAP."),
                ("engine.combustion", "Engine DTC Diagnostics: Read and clear fault codes (DTC P-codes) with technical explanations."),
                ("shield.lefthalf.filled", "Advics ABS Advanced Diagnostics: KWP fault memory read (18 00 FF 00) with offline database of 23 active and historical codes."),
                ("doc.text.fill", "PDF Diagnostic Report: Export and share official diagnostic certificate & maintenance inspection report."),
                ("wrench.and.screwdriver.fill", "Service Reset Guide: Official dashboard button procedures to reset Oil Trip, Annual Service and V-Belt."),
                ("fanblades", "Throttle Body Wear & Cleaning: Monitor ISC stepper motor micro-step compensation (Register 0x54) and Code 67 status."),
                ("arrow.counterclockwise", "Adaptive Resets: Throttle bodies / ISC idle stepper reset (Code 67) and O2 lambda closed-loop trim reset (Code 87)."),
                ("terminal", "Raw Serial Terminal: Low-level OBD2/CAN command line to manually send ELM327 and KWP2000 frames.")
            ]
        case .italian:
            return [
                ("gauge.with.needle", "Telemetria live: RPM, Velocità, Marcia calcolata, TPS, Temperatura liquido, Batteria, Tensione Lambda O2, IAT, MAP."),
                ("engine.combustion", "Diagnosi Guasti Motore: Lettura e cancellazione codici DTC (DTC P-codes) con spiegazione contestuale."),
                ("shield.lefthalf.filled", "Diagnosi Avanzata ABS Advics: Lettura memoria guasti KWP (18 00 FF 00) con database offline di 23 codici storici e attivi."),
                ("doc.text.fill", "Certificato PDF & Perizia: Esportazione e condivisione report diagnostico con timbro data e stato di salute componenti."),
                ("wrench.and.screwdriver.fill", "Guida Reset Tagliando: Procedure ufficiali manuali da cruscotto per azzeramento spia tagliando, Oil Trip e V-Belt."),
                ("fanblades", "Stato Usura & Pulizia Corpi Farfallati: Monitoraggio compensazione micro-step ISC (Registro 0x54) e flag Cod. 67."),
                ("arrow.counterclockwise", "Reset Adattivi: Reset corpi farfallati/minimo ISC (Cod. 67) e reset autoadattamento sonda lambda O2 (Cod. 87)."),
                ("terminal", "Terminale Seriale Raw: Interfaccia a riga di comando OBD2/CAN per invio manuale di comandi ELM327/KWP2000.")
            ]
        case .french:
            return [
                ("gauge.with.needle", "Télémétrie en direct : RPM, Vitesse, Rapport engagé, TPS, Température liquide, Batterie, Sonde Lambda O2, IAT, MAP."),
                ("engine.combustion", "Diagnostic Moteur : Lecture et effacement des codes défaut (DTC) avec explications contextuelles."),
                ("shield.lefthalf.filled", "Diagnostic Avancé ABS Advics : Lecture mémoire défauts KWP (18 00 FF 00) avec base de données hors ligne de 23 codes."),
                ("doc.text.fill", "Rapport de Diagnostic PDF : Exportation et partage du certificat d'inspection et de maintenance officiel."),
                ("wrench.and.screwdriver.fill", "Guide Reset Entretien : Procédures manuelles au compteur pour réinitialiser Oil Trip, vidange et V-Belt."),
                ("fanblades", "Usure et Nettoyage Corps Papillon : Surveillance adaptation moteur pas-à-pas ISC (Registre 0x54) et Code 67."),
                ("arrow.counterclockwise", "Réinitialisations Adaptatives : Reset ralenti ISC (Code 67) et reset trims sonde Lambda O2 (Code 87)."),
                ("terminal", "Terminal Série Raw : Ligne de commande OBD2/CAN pour envoi manuel de trames ELM327/KWP2000.")
            ]
        case .spanish:
            return [
                ("gauge.with.needle", "Telemetría en vivo: RPM, Velocidad, Marcha engranada, TPS, Temperatura refrigerante, Batería, Sonda Lambda O2, IAT, MAP."),
                ("engine.combustion", "Diagnóstico de Motor: Lectura y borrado de averías (DTC) con explicaciones técnicas detalladas."),
                ("shield.lefthalf.filled", "Diagnóstico Avanzado ABS Advics: Lectura memoria KWP (18 00 FF 00) con base offline de 23 códigos."),
                ("doc.text.fill", "Certificado de Diagnóstico PDF: Exportación y compartición de informe técnico y peritaje oficial."),
                ("wrench.and.screwdriver.fill", "Guía Reset Mantenimiento: Pasos oficiales desde el cuadro de instrumentos para reiniciar Oil Trip y correa V-Belt."),
                ("fanblades", "Estado y Limpieza Cuerpos de Mariposa: Monitorización de adaptación motor paso a paso ISC (Registro 0x54) y Código 67."),
                ("arrow.counterclockwise", "Reinicios Adaptativos: Reset de ralentí ISC (Código 67) y reset de trims de sonda Lambda O2 (Código 87)."),
                ("terminal", "Terminal Serie Raw: Consola de comandos OBD2/CAN para envío manual de tramas ELM327/KWP2000.")
            ]
        case .german:
            return [
                ("gauge.with.needle", "Live-Telemetrie: Drehzahl, Geschwindigkeit, Gangberechnung, TPS, Kühlmitteltemp., Batteriespannung, Lambdasonde, IAT, MAP."),
                ("engine.combustion", "Motor-Fehlerdiagnose: Auslesen und Löschen von DTC-Fehlercodes mit technischen Erläuterungen."),
                ("shield.lefthalf.filled", "Erweiterte Advics ABS-Diagnose: KWP-Fehlerspeicher (18 00 FF 00) mit Offline-Datenbank für 23 Codes."),
                ("doc.text.fill", "PDF-Diagnosebericht: Export und Weitergabe des offiziellen Inspektions- und Wartungszertifikats."),
                ("wrench.and.screwdriver.fill", "Service-Reset-Anleitung: Manuelle Cockpit-Abläufe zum Zurücksetzen von Oil Trip, Wartung und V-Belt."),
                ("fanblades", "Drosselklappen-Verschleiß & Reinigung: Überwachung der ISC-Schrittmotor-Kompensation (Register 0x54) und Code 67."),
                ("arrow.counterclockwise", "Adaptive Resets: Reset Drosselklappen/Leerlauf ISC (Code 67) und Reset der Lambdasonden-Trims (Code 87)."),
                ("terminal", "Raw Serielles Terminal: OBD2/CAN-Befehlszeile zum manuellen Senden von ELM327- und KWP2000-Befehlen.")
            ]
        }
    }
    
    var hardwareSectionTitle: String {
        switch lang.currentLanguage {
        case .english: return "Supported & Certified OBD2 Adapters"
        case .italian: return "Adattatori OBD2 Supportati e Certificati"
        case .french: return "Adaptateurs OBD2 Supportés et Certifiés"
        case .spanish: return "Adaptadores OBD2 Compatibles y Certificados"
        case .german: return "Unterstützte & Zertifizierte OBD2-Adapter"
        }
    }
    
    var hardwareDesc: String {
        switch lang.currentLanguage {
        case .english:
            return "YaDiag utilizes advanced UDS/KWP2000 command sequences and ISO-TP CAN flow control (multi-frame). To ensure complete ECU safety and maximum refresh rates, the app includes an adapter compatibility filter."
        case .italian:
            return "YaDiag utilizza sequenze avanzate di comandi UDS/KWP2000 e controllo di flusso CAN ISO-TP (frame lunghi). Per garantire la totale sicurezza della centralina e la massima velocità di aggiornamento, l'app include un selettore di compatibilità."
        case .french:
            return "YaDiag utilise des séquences avancées UDS/KWP2000 et le contrôle de flux CAN ISO-TP (trames multiples). Pour assurer la sécurité du calculateur et un rafraîchissement maximal, l'application intègre un filtre de compatibilité."
        case .spanish:
            return "YaDiag utiliza secuencias avanzadas de comandos UDS/KWP2000 y control de flujo CAN ISO-TP (tramas largas). Para garantizar la total seguridad de la centralita y máxima velocidad, la app incluye un filtro de adaptadores."
        case .german:
            return "YaDiag verwendet fortschrittliche UDS/KWP2000-Befehlssequenzen und ISO-TP CAN-Flusskontrolle. Für höchste Steuergerätesicherheit und maximale Abtastraten verfügt die App über einen Kompatibilitätsfilter."
        }
    }
    
    var certifiedAdaptersTitle: String {
        switch lang.currentLanguage {
        case .english: return "Certified & Recommended Adapters (STN / High-Speed Chipsets):"
        case .italian: return "Adattatori Certificati e Raccomandati (Chipset STN / High-Speed):"
        case .french: return "Adaptateurs Certifiés et Recommandés (Chipsets STN / Haute Vitesse) :"
        case .spanish: return "Adaptadores Certificados y Recomendados (Chipsets STN / Alta Velocidad):"
        case .german: return "Zertifizierte & Empfohlene Adapter (STN / High-Speed Chipsätze):"
        }
    }
    
    var extendedModeWarning: String {
        switch lang.currentLanguage {
        case .english:
            return "⚠️ **Extended Compatibility Mode (Other ELM327 BLE):**\nWhen enabled in the Bluetooth tab, any generic BLE scanner can connect. Cheap clones ($5-10) are discouraged due to small memory buffers that fail on multi-frame ABS diagnostics or 35-byte payloads."
        case .italian:
            return "⚠️ **Modalità Compatibilità Estesa (Altri ELM327 BLE):**\nAttivando l'opzione nella scheda Bluetooth, è possibile collegare qualsiasi altro adattatore diagnostico BLE generico. Si sconsigliano cloni cinesi ultra-economici (5-10€) a causa di buffer di memoria limitati che non supportano la diagnostica profonda ABS o i frame a 35 byte."
        case .french:
            return "⚠️ **Mode Compatibilité Étendue (Autres ELM327 BLE) :**\nActivé dans l'onglet Bluetooth, tout scanner BLE générique peut se connecter. Les clones ultra-économiques (5-10€) sont déconseillés en raison de mémoires tampons insuffisantes pour le diagnostic ABS multi-trames."
        case .spanish:
            return "⚠️ **Modo Compatibilidad Extendida (Otros ELM327 BLE):**\nAl activarlo en la pestaña Bluetooth, se puede conectar cualquier otro escáner BLE genérico. Se desaconsejan clones chinos muy económicos (5-10€) por búferes de memoria insuficientes para diagnósticos ABS largos."
        case .german:
            return "⚠️ **Erweiterter Kompatibilitätsmodus (Andere ELM327 BLE):**\nBei Aktivierung im Bluetooth-Tab kann jeder generische BLE-Scanner verbunden werden. Günstige Klone (5-10€) werden wegen unzureichender Puffergröße für die ABS-Multiframe-Diagnose nicht empfohlen."
        }
    }
    
    var cableTitle: String {
        switch lang.currentLanguage {
        case .english:
            return "• **Motorcycle Diagnostic Cable:**\n  - **Euro 4 Models (2016–2020):** 4-pin white motorcycle adapter cable to 16-pin OBD2 female.\n  - **Euro 5 Models (2021+):** Standard 16-pin OBD2 connector already present under the seat."
        case .italian:
            return "• **Cavo Adattatore per Moto:**\n  - **Modelli Euro 4 (2016–2020):** Cavo adattatore Yamaha da connettore 4-pin bianco a presa standard OBD2 femmina 16-pin.\n  - **Modelli Euro 5 (2021+):** Presa standard OBD2 a 16-pin già presente di serie sotto la sella."
        case .french:
            return "• **Câble Adaptateur Moto :**\n  - **Modèles Euro 4 (2016–2020) :** Câble adaptateur prise blanche 4 broches vers prise femelle OBD2 16 broches.\n  - **Modèles Euro 5 (2021+) :** Prise OBD2 standard 16 broches présente de série sous la selle."
        case .spanish:
            return "• **Cable Adaptador para Moto:**\n  - **Modelos Euro 4 (2016–2020):** Cable adaptador de conector 4 pines blanco a toma hembra OBD2 16 pines.\n  - **Modelos Euro 5 (2021+):** Toma OBD2 estándar de 16 pines ya integrada de serie bajo el asiento."
        case .german:
            return "• **Motorrad-Diagnosekabel:**\n  - **Euro 4 Modelle (2016–2020):** Adapterkabel von weißem 4-Pin-Stecker auf 16-Pin OBD2-Buchse.\n  - **Euro 5 Modelle (2021+):** Standard 16-Pin OBD2-Buchse serienmäßig unter der Sitzbank vorhanden."
        }
    }
    
    var disclaimerSectionTitle: String {
        switch lang.currentLanguage {
        case .english: return "Legal Notice & Trademarks (Disclaimer)"
        case .italian: return "Note Legali e Marchi Registrati (Disclaimer)"
        case .french: return "Mentions Légales & Marques Déposées"
        case .spanish: return "Aviso Legal y Marcas Registradas"
        case .german: return "Rechtliche Hinweise & Marken (Disclaimer)"
        }
    }
    
    var transparencyTitle: String {
        switch lang.currentLanguage {
        case .english: return "Transparency & Compatibility Notice"
        case .italian: return "Nota di Trasparenza & Compatibilità"
        case .french: return "Note de Transparence & Compatibilité"
        case .spanish: return "Nota de Transparencia y Compatibilidad"
        case .german: return "Transparenz- & Kompatibilitätshinweis"
        }
    }
    
    var transparencyBody: String {
        switch lang.currentLanguage {
        case .english:
            return "YaDiag Pro is an independent diagnostic software. Standard DTC fault diagnostics (Mode 03/04 for Engine and KWP 0x18 for ABS) and live telemetry operate on standard CAN-bus architecture. Advanced adaptive resets (ISC Code 67 and O2 sensor Code 87) are certified on the CP3 Euro 4 platform; on other models, access to specific internal Denso registers depends on the installed ECU firmware release. Service reminder resets (oil / wrench indicators) are performed directly on the motorcycle meter cluster via the official dashboard procedures documented in the guide."
        case .italian:
            return "YaDiag Pro è un software diagnostico indipendente. Le funzionalità diagnostiche DTC (Mode 03/04 per Motore ed errore KWP 0x18 per ABS) e telemetria operano su standard CAN-bus. I reset adattivi (ISC Cod. 67 e Sonda Lambda Cod. 87) sono certificati sulla piattaforma CP3 Euro 4; per gli altri modelli l'accesso a specifici registri interni dipende dal firmware centralina Denso installato. Le procedure di azzeramento spia tagliando (chiave/olio) sono manuali da cruscotto e consultabili nella guida dedicata."
        case .french:
            return "YaDiag Pro est un logiciel de diagnostic indépendant. Le diagnostic standard DTC et la télémétrie fonctionnent selon les normes CAN-bus. Les réinitialisations adaptatives (ISC Code 67 et sonde Lambda Code 87) sont certifiées sur plateforme CP3 Euro 4. La réinitialisation des rappels d'entretien (voyant vidange/clé) s'effectue manuellement au tableau de bord selon les procédures documentées."
        case .spanish:
            return "YaDiag Pro es una herramienta de diagnóstico independiente. La diagnosis DTC y la telemetría operan sobre estándares CAN-bus. Los reinicios adaptativos (ISC Cód. 67 y Lambda Cód. 87) están certificados en la plataforma CP3 Euro 4. El reinicio de la luz de mantenimiento (aceite / llave) se realiza manualmente desde el cuadro de instrumentos mediante los pasos indicados en la guía."
        case .german:
            return "YaDiag Pro ist eine unabhängige Diagnosesoftware. Die DTC-Diagnose und Telemetrie arbeiten nach CAN-Bus-Standards. Adaptive Resets (ISC Code 67 und Lambdasonde Code 87) sind auf der CP3 Euro 4 Plattform zertifiziert. Das Zurücksetzen der Wartungsanzeige erfolgt manuell über das Cockpit gemäß Anleitung."
        }
    }
    
    var serviceGuideQuickBtnTitle: String {
        switch lang.currentLanguage {
        case .english: return "Official Service Reset Guide (Dashboard)"
        case .italian: return "Guida Ufficiale Reset Tagliando (da cruscotto)"
        case .french: return "Guide Officiel Reset Entretien (Compteur)"
        case .spanish: return "Guía Oficial Reinicio Servicio (Tablero)"
        case .german: return "Offizielle Service-Reset-Anleitung (Cockpit)"
        }
    }
    
    var serviceGuideQuickBtnSubtitle: String {
        switch lang.currentLanguage {
        case .english: return "Step-by-step manual procedures to reset Oil Trip, wrench icon and V-Belt"
        case .italian: return "Procedure manuali per azzerare Oil Trip, spia chiave e V-Belt per tutti i modelli"
        case .french: return "Procédures manuelles pour réinitialiser Oil Trip, voyant clé et V-Belt"
        case .spanish: return "Procedimientos manuales para reiniciar Oil Trip, testigo de llave y V-Belt"
        case .german: return "Manuelle Tastenfolgen zum Zurücksetzen von Oil Trip, Schraubenschlüssel und V-Belt"
        }
    }
    
    var disclaimerSectionDesc: String {
        switch lang.currentLanguage {
        case .english:
            return "YaDiag is an independent diagnostic software developed for enthusiast and professional technical use. The application is not affiliated, endorsed, sponsored, or associated in any way with Yamaha Motor Co., Ltd. or its subsidiaries. All trademarks, model names, and commercial references belong to their respective owners and are used purely for hardware and software compatibility identification."
        case .italian:
            return "YaDiag è un'applicazione diagnostica indipendente sviluppata ad uso amatoriale e professionale. L'applicazione non è affiliata, approvata, sponsorizzata o associata in alcun modo a Yamaha Motor Co., Ltd. né alle sue filiali. Tutti i marchi, i nomi dei modelli, i loghi e i riferimenti commerciali citati appartengono ai rispettivi proprietari e sono utilizzati esclusivamente a fini identificativi e descrittivi della compatibilità hardware e software."
        case .french:
            return "YaDiag est une application de diagnostic indépendante développée à des fins techniques et professionnelles. L'application n'est pas affiliée, approuvée, parrainée ou associée de quelque manière que ce soit à Yamaha Motor Co., Ltd. ou à ses filiales. Toutes les marques et dénominations citées appartiennent à leurs propriétaires respectifs et sont utilisées uniquement à des fins d'identification."
        case .spanish:
            return "YaDiag es una aplicación de diagnóstico independiente desarrollada para uso técnico y profesional. La aplicación no está afiliada, aprobada, patrocinada ni asociada en modo alguno con Yamaha Motor Co., Ltd. ni con sus filiales. Todas las marcas registradas y nombres comerciales pertenecen a sus respectivos propietarios y se utilizan únicamente con fines de identificación."
        case .german:
            return "YaDiag ist eine unabhängige Diagnosesoftware für den technischen und professionellen Einsatz. Die Anwendung steht in keinerlei Verbindung zu Yamaha Motor Co., Ltd. oder deren Tochtergesellschaften und wird von diesen weder unterstützt noch empfohlen. Alle genannten Marken und Modellbezeichnungen dienen ausschließlich der Kompatibilitätsbeschreibung."
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Info
                HStack(spacing: 14) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(infoTitle)
                            .font(.title2)
                            .bold()
                        Text(infoSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 10)
                
                // Card Panoramica
                VStack(alignment: .leading, spacing: 8) {
                    Text(canOverviewTitle)
                        .font(.headline)
                        .foregroundColor(.cyan)
                    Text(canOverviewDesc)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color.cyan.opacity(0.08))
                .cornerRadius(12)
                
                // Sezione Modelli Supportati & Compatibilità Graduata
                Text(modelsSectionTitle)
                    .font(.title3)
                    .bold()
                
                // Card Trasparenza & Disclaimer Compatibilità Funzioni Avanzate
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                            .foregroundColor(.orange)
                        Text(transparencyTitle)
                            .font(.caption)
                            .bold()
                            .foregroundColor(.orange)
                    }
                    Text(transparencyBody)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                
                // Bottone Accesso Rapido Guida Reset Tagliando da Cruscotto
                Button(action: {
                    showingServiceGuide = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(serviceGuideQuickBtnTitle)
                                .font(.system(size: 13, weight: .bold))
                            Text(serviceGuideQuickBtnSubtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                }
                
                VStack(spacing: 14) {
                    ForEach(categories) { cat in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(cat.engineFamily)
                                    .font(.headline)
                                    .foregroundColor(cat.badgeColor)
                                Spacer()
                                Text(cat.years)
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(cat.badgeColor.opacity(0.15))
                                    .foregroundColor(cat.badgeColor)
                                    .cornerRadius(6)
                            }
                            
                            Text(cat.subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            ForEach(cat.models, id: \.self) { model in
                                HStack {
                                    let isCertified = model.contains("Tracer 900") || (model.contains("MT-09") && !model.contains("Tracer 9"))
                                    let isKwpEuro4 = !model.contains("Tracer 9") && (cat.badgeColor == .blue || cat.badgeColor == .purple || cat.badgeColor == .cyan)
                                    
                                    Image(systemName: isCertified ? "checkmark.seal.fill" : (isKwpEuro4 ? "checkmark.circle.fill" : "circle.fill"))
                                        .foregroundColor(isCertified ? .green : (isKwpEuro4 ? .cyan : .blue))
                                        .font(.caption)
                                    Text(model)
                                        .font(.caption)
                                        .bold()
                                    Spacer()
                                    
                                    let certifiedBadge = lang.currentLanguage == .english ? "🟢 Certified 100%" : (lang.currentLanguage == .french ? "🟢 Certifié 100%" : (lang.currentLanguage == .spanish ? "🟢 Certificado 100%" : (lang.currentLanguage == .german ? "🟢 100% Zertifiziert" : "🟢 Certificato 100%")))
                                    let kwpBadge = lang.currentLanguage == .english ? "🟡 KWP Compatible" : (lang.currentLanguage == .french ? "🟡 Compatible KWP" : (lang.currentLanguage == .spanish ? "🟡 Compatible KWP" : (lang.currentLanguage == .german ? "🟡 KWP-kompatibel" : "🟡 Compatibile KWP")))
                                    let obd2Badge = lang.currentLanguage == .english ? "🔵 Standard OBD2" : (lang.currentLanguage == .french ? "🔵 Standard OBD2" : (lang.currentLanguage == .spanish ? "🔵 Estándar OBD2" : (lang.currentLanguage == .german ? "🔵 Standard-OBD2" : "🔵 Standard OBD2")))
                                    
                                    Text(isCertified ? certifiedBadge : (isKwpEuro4 ? kwpBadge : obd2Badge))
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(isCertified ? .green : (isKwpEuro4 ? .cyan : .blue))
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                // Sezione Funzionalità Diagnostiche
                VStack(alignment: .leading, spacing: 8) {
                    Text(featuresSectionTitle)
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(featuresList, id: \.1) { item in
                            Label(item.1, systemImage: item.0)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                // Sezione Requisiti Hardware
                VStack(alignment: .leading, spacing: 10) {
                    Text(hardwareSectionTitle)
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    Text(hardwareDesc)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text(certifiedAdaptersTitle)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                            Text("**UniCarScan serie UCSI:** UCSI-2000, UCSI-2100, UCSI-3000 (BLE)").font(.caption)
                        }
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                            Text("**vLinker serie (Vgate):** vLinker MC+, vLinker BM+, vLinker FS/FD+ (BLE)").font(.caption)
                        }
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                            Text("**OBDLink:** OBDLink MX+ (MFi Apple), OBDLink CX (BLE)").font(.caption)
                        }
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                            Text("**Veepeak:** OBDCheck BLE+").font(.caption)
                        }
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                            Text("**Carista:** Carista OBD Adapter (BLE)").font(.caption)
                        }
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(8)
                    
                    Text(extendedModeWarning)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text(cableTitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                // Disclaimer Legale & Bottone Rilettura Termini
                VStack(alignment: .leading, spacing: 10) {
                    Text(disclaimerSectionTitle)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                    Text(disclaimerSectionDesc)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    if let onShow = onShowDisclaimer {
                        Button(action: onShow) {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text(lang.t("info_read_terms"))
                                    .bold()
                            }
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.cyan.opacity(0.15))
                            .foregroundColor(.cyan)
                            .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(14)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(12)
            }
            .padding()
        }
        .sheet(isPresented: $showingServiceGuide) {
            ServiceResetGuideView()
        }
    }
}

struct DisclaimerView: View {
    let appVersion: String
    let isReopeningTerms: Bool
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    @ObservedObject var lang = LocalizationManager.shared
    @State private var hasCheckedBox: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.t("disclaimer_title"))
                                    .font(.title3)
                                    .bold()
                                Text("\(lang.t("disclaimer_version")) \(appVersion)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.cyan)
                            }
                            Spacer()
                            
                            // Selettore Rapido Lingua
                            Menu {
                                ForEach(AppLanguage.allCases) { item in
                                    Button(action: {
                                        lang.currentLanguage = item
                                    }) {
                                        HStack {
                                            Text("\(item.flag)  \(item.displayName)")
                                            if lang.currentLanguage == item {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(lang.currentLanguage.flag)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 8)
                        
                        Divider()
                        
                        Group {
                            ForEach(lang.disclaimerArticles, id: \.title) { article in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(article.title)
                                        .font(.headline)
                                        .foregroundColor(.cyan)
                                    Text(article.text)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.bottom, 6)
                            }
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Zona Conferma ed Accettazione
                VStack(spacing: 12) {
                    if isReopeningTerms {
                        Button(action: onDismiss) {
                            Text("\(lang.t("disclaimer_close")) (v\(appVersion))")
                                .font(.headline)
                                .bold()
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            hasCheckedBox.toggle()
                        }) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: hasCheckedBox ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(hasCheckedBox ? .green : .secondary)
                                Text(lang.t("disclaimer_checkbox"))
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onAccept) {
                            Text(lang.t("disclaimer_accept"))
                                .font(.headline)
                                .bold()
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(hasCheckedBox ? Color.green : Color.gray.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(!hasCheckedBox)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.08))
            }
            .navigationTitle(lang.t("disclaimer_nav_title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 650)
        #endif
    }
}
