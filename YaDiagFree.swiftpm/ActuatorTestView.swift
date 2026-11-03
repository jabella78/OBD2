import SwiftUI

struct Actuator {
    let code: Int
    let name: String
    let description: String
    let isDangerous: Bool
}

struct ActuatorTestView: View {
    @ObservedObject var obd2Manager: OBD2Manager
    @ObservedObject var lang = LocalizationManager.shared
    
    @State private var showingProUpgradeAlert = false
    @State private var selectedActuator: Actuator?
    
    var engineActuators: [Actuator] {
        switch lang.currentLanguage {
        case .english:
            return [
                Actuator(
                    code: 67,
                    name: "Throttle Bodies / ISC Idle Learning Reset",
                    description: "Manual p. 8-60 (Code 67 — KWP Command 3B 54 01): Clears adaptive values of the ISC stepper motor, returning register 0x54 to 80 00 | 80 00 | 80 00. To be performed after throttle body cleaning or synchronization.",
                    isDangerous: true
                ),
                Actuator(
                    code: 87,
                    name: "O2 Lambda Closed-Loop Trim Reset",
                    description: "Manual p. 8-61 (Code 87 — KWP Command 3B 52 01): Clears closed-loop fuel correction memory from O2 sensor, returning register 0x52 to neutral factory values (02 00 / 02 00). To be performed after intake/exhaust service or O2 replacement.",
                    isDangerous: true
                )
            ]
        case .french:
            return [
                Actuator(
                    code: 67,
                    name: "Reset Apprentissage Ralenti / Corps Papillon (ISC)",
                    description: "Manuel p. 8-60 (Code 67 — Commande KWP 3B 54 01) : Réinitialise les valeurs adaptatives du moteur pas-à-pas ISC vers 80 00 | 80 00 | 80 00. À effectuer après nettoyage ou synchronisation des corps papillon.",
                    isDangerous: true
                ),
                Actuator(
                    code: 87,
                    name: "Reset Apprentissage Sonde Lambda O2 (Trim A/F)",
                    description: "Manuel p. 8-61 (Code 87 — Commande KWP 3B 52 01) : Efface la mémoire de correction de richesse en boucle fermée et remet le registre 0x52 aux valeurs d'usine neutres (02 00 / 02 00).",
                    isDangerous: true
                )
            ]
        case .spanish:
            return [
                Actuator(
                    code: 67,
                    name: "Reinicio Aprendizaje Ralentí / Mariposas (ISC)",
                    description: "Manual pág. 8-60 (Cód. 67 — Comando KWP 3B 54 01): Borra los valores adaptativos del motor paso a paso ISC restableciendo el registro 0x54 a 80 00 | 80 00 | 80 00. Ejecutar tras limpieza o sincronización.",
                    isDangerous: true
                ),
                Actuator(
                    code: 87,
                    name: "Reinicio Aprendizaje Sonda Lambda O2 (Trim A/F)",
                    description: "Manual pág. 8-61 (Cód. 87 — Comando KWP 3B 52 01): Borra la memoria de corrección en lazo cerrado y restaura el registro 0x52 a valores neutros de fábrica (02 00 / 02 00).",
                    isDangerous: true
                )
            ]
        case .german:
            return [
                Actuator(
                    code: 67,
                    name: "Reset Drosselklappen- / ISC-Leerlaufadaption",
                    description: "Handbuch S. 8-60 (Code 67 — KWP-Befehl 3B 54 01): Löscht die Adaptionswerte des ISC-Schrittmotors auf 80 00 | 80 00 | 80 00. Nach Reinigung oder Drosselklappensynchronisation durchführen.",
                    isDangerous: true
                ),
                Actuator(
                    code: 87,
                    name: "Reset Lambdasonden-Gemischadaption (A/F Trim)",
                    description: "Handbuch S. 8-61 (Code 87 — KWP-Befehl 3B 52 01): Löscht den Closed-Loop Gemischkorrekturspeicher und setzt Register 0x52 auf neutrale Werkswerte (02 00 / 02 00) zurück.",
                    isDangerous: true
                )
            ]
        case .italian:
            return [
                Actuator(
                    code: 67,
                    name: "Reset Apprendimento Corpi Farfallati / Minimo (ISC)",
                    description: "Manuale pag. 8-60 (Cod. 67 — Comando KWP 3B 54 01): Cancella i valori adattivi del motorino passo-passo ISC dei corpi farfallati riportando il registro 0x54 a 80 00 | 80 00 | 80 00. Da eseguire dopo pulizia o allineamento corpi farfallati.",
                    isDangerous: true
                ),
                Actuator(
                    code: 87,
                    name: "Reset Apprendimento Sonda Lambda O2 (Trim A/F)",
                    description: "Manuale pag. 8-61 (Cod. 87 — Comando KWP 3B 52 01): Cancella la memoria di correzione carburazione closed-loop della sonda O2 riportando il registro 0x52 ai valori neutri di fabbrica (02 00 / 02 00). Da eseguire dopo manutenzione aspirazione/scarico o sonda O2.",
                    isDangerous: true
                )
            ]
        }
    }
    
    var isEngineRunning: Bool {
        if obd2Manager.isDemoMode {
            return false
        }
        return obd2Manager.rpm > 0 || obd2Manager.speed > 0
    }
    
    private var throttleStatusColor: Color {
        switch obd2Manager.throttleCleaningLevel {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .secondary
        }
    }
    
    var displayActuatorStatusMessage: String {
        let msg = obd2Manager.actuatorStatusMessage
        if msg == "Pronto." || msg == "Ready." || msg.isEmpty {
            return lang.t("act_status_ready")
        }
        return msg
    }
    
    var proUpgradeBtnTitle: String {
        switch lang.currentLanguage {
        case .english: return "Available in YaDiag Pro"
        case .italian: return "Disponibile in YaDiag Pro"
        case .french: return "Disponible dans YaDiag Pro"
        case .spanish: return "Disponible en YaDiag Pro"
        case .german: return "In YaDiag Pro verfügbar"
        }
    }
    
    var proUpgradeAlertTitle: String {
        switch lang.currentLanguage {
        case .english: return "YaDiag Pro Feature"
        case .italian: return "Funzionalità Esclusiva YaDiag Pro"
        case .french: return "Fonctionnalité YaDiag Pro"
        case .spanish: return "Función Exclusiva YaDiag Pro"
        case .german: return "YaDiag Pro Exklusivfunktion"
        }
    }
    
    var proUpgradeAlertBody: String {
        switch lang.currentLanguage {
        case .english:
            return "Engine adaptive parameter resets (ISC idle stepper motor and O2 lambda trims) are reserved for YaDiag Pro, available on the App Store."
        case .italian:
            return "I reset dei parametri adattivi motore (reset motorino minimo ISC e correttori lambda O2) sono riservati all'edizione YaDiag Pro disponibile su App Store."
        case .french:
            return "La réinitialisation des paramètres adaptatifs moteur (ISC ralenti et trims Lambda O2) est réservée à l'édition YaDiag Pro disponible sur l'App Store."
        case .spanish:
            return "El reinicio de parámetros adaptativos del motor (motor paso a paso ISC y trims lambda O2) está reservado para YaDiag Pro disponible en App Store."
        case .german:
            return "Das Zurücksetzen adaptiver Motorparameter (ISC-Leerlaufschrittmotor und O2-Lambdatrims) ist der YaDiag Pro-Edition vorbehalten."
        }
    }
    
    var appStoreBtnTitle: String {
        switch lang.currentLanguage {
        case .english: return "View on App Store"
        case .italian: return "Vedi su App Store"
        case .french: return "Voir sur l'App Store"
        case .spanish: return "Ver en App Store"
        case .german: return "Im App Store anzeigen"
        }
    }
    
    var closeBtnTitle: String {
        switch lang.currentLanguage {
        case .english: return "Close"
        case .italian: return "Chiudi"
        case .french: return "Fermer"
        case .spanish: return "Cerrar"
        case .german: return "Schließen"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(lang.t("act_title"))
                .font(.title2)
                .bold()
                .padding(.top, 10)
            
            ScrollView {
                VStack(spacing: 12) {
                    if isEngineRunning {
                        VStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.red)
                            Text(lang.t("act_danger_title"))
                                .font(.headline)
                                .bold()
                                .foregroundColor(.red)
                            Text(lang.t("act_danger_msg"))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text(lang.t("act_ready_engine"))
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        
                        Text(displayActuatorStatusMessage)
                            .font(.caption)
                            .bold()
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
            
                    engineParametersSection
            
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))], spacing: 16) {
                        ForEach(engineActuators, id: \.code) { actuator in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(actuator.name)
                                        .font(.headline)
                                        .foregroundColor(actuator.isDangerous ? .orange : .primary)
                                    Spacer()
                                    Text(lang.currentLanguage == .english ? "DIAG Code \(actuator.code)" : (lang.currentLanguage == .french ? "DIAG Code \(actuator.code)" : (lang.currentLanguage == .spanish ? "DIAG Cód. \(actuator.code)" : (lang.currentLanguage == .german ? "DIAG Code \(actuator.code)" : "DIAG Cod. \(actuator.code)"))))
                                        .font(.caption)
                                        .bold()
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(6)
                                }
                                
                                Text(actuator.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(minHeight: 55, alignment: .topLeading)
                                
                                Button(action: {
                                    showingProUpgradeAlert = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                        Text(proUpgradeBtnTitle)
                                            .font(.system(size: 13, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.blue.opacity(0.25), radius: 3, x: 0, y: 2)
                                }
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .alert(proUpgradeAlertTitle, isPresented: $showingProUpgradeAlert) {
            Button(appStoreBtnTitle) {
                if let url = URL(string: AppEdition.proAppStoreURL) {
                    #if os(iOS)
                    UIApplication.shared.open(url)
                    #elseif os(macOS)
                    NSWorkspace.shared.open(url)
                    #endif
                }
            }
            Button(closeBtnTitle, role: .cancel) {}
        } message: {
            Text(proUpgradeAlertBody)
        }
    }
    
    // Labels localizzate per i parametri motore
    var engineParamsTitle: String {
        switch lang.currentLanguage {
        case .english: return "Engine Parameters"
        case .italian: return "Parametri Motore"
        case .french: return "Paramètres Moteur"
        case .spanish: return "Parámetros del Motor"
        case .german: return "Motorparameter"
        }
    }
    
    var verifyValuesBtnText: String {
        switch lang.currentLanguage {
        case .english: return "Verify Values"
        case .italian: return "Verifica Valori"
        case .french: return "Vérifier Valeurs"
        case .spanish: return "Verificar Valores"
        case .german: return "Werte Prüfen"
        }
    }
    
    var iscParamTitle: String {
        switch lang.currentLanguage {
        case .english: return "ISC Idle Stepper Learning (Code 67 — Reg. 0x54):"
        case .italian: return "Apprendimento Minimo ISC (Cod. 67 — Reg. 0x54):"
        case .french: return "Apprentissage Ralenti ISC (Code 67 — Reg. 0x54) :"
        case .spanish: return "Aprendizaje Ralentí ISC (Cód. 67 — Reg. 0x54):"
        case .german: return "ISC-Leerlaufadaption (Code 67 — Reg. 0x54):"
        }
    }
    
    var throttleCleaningParamTitle: String {
        switch lang.currentLanguage {
        case .english: return "Throttle Body Cleaning Status:"
        case .italian: return "Stato Pulizia Corpi Farfallati:"
        case .french: return "État Propreté Corps Papillon :"
        case .spanish: return "Estado Limpieza Cuerpos de Mariposa:"
        case .german: return "Drosselklappen-Reinigungszustand:"
        }
    }
    
    var o2ParamTitle: String {
        switch lang.currentLanguage {
        case .english: return "O2 Lambda Sensor Learning (Code 87 — Reg. 0x52):"
        case .italian: return "Apprendimento Sonda Lambda O2 (Cod. 87 — Reg. 0x52):"
        case .french: return "Apprentissage Sonde Lambda O2 (Code 87 — Reg. 0x52) :"
        case .spanish: return "Aprendizaje Sonda Lambda O2 (Cód. 87 — Reg. 0x52):"
        case .german: return "O2-Lambdasondenadaption (Code 87 — Reg. 0x52):"
        }
    }
    
    var coParamTitle: String {
        switch lang.currentLanguage {
        case .english: return "Cylinder CO Adjustment (Reg. 0x40 – 0x42):"
        case .italian: return "Regolazione CO Cilindri (Reg. 0x40 – 0x42):"
        case .french: return "Réglage CO Cylindres (Reg. 0x40 – 0x42) : "
        case .spanish: return "Ajuste CO Cilindros (Reg. 0x40 – 0x42):"
        case .german: return "Zylinder-CO-Einstellung (Reg. 0x40 – 0x42):"
        }
    }
    
    @ViewBuilder
    private var engineParametersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(engineParamsTitle, systemImage: "waveform.path.ecg.rectangle.fill")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer()
                Button(action: {
                    obd2Manager.verifyISCAndO2Values()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11))
                        Text(verifyValuesBtnText)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                // 1. Minimo ISC (Cod. 67 - Reg. 0x54)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.cyan)
                        Text(iscParamTitle)
                            .font(.caption)
                            .bold()
                        Spacer()
                    }
                    Text(obd2Manager.iscLearningStatus)
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(obd2Manager.iscLearningStatus.contains("AZZERATO") || obd2Manager.iscLearningStatus.contains("RESET") ? .orange : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                // 2. Stato Pulizia Corpi Farfallati
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.cyan)
                        Text(throttleCleaningParamTitle)
                            .font(.caption)
                            .bold()
                        Spacer()
                    }
                    Text(obd2Manager.throttleCleaningStatus)
                        .font(.caption)
                        .bold()
                        .foregroundColor(throttleStatusColor)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if obd2Manager.throttleCleaningLevel > 0 {
                        ProgressView(value: obd2Manager.throttleDirtPercentage, total: 100.0)
                            .tint(throttleStatusColor)
                            .padding(.top, 2)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                // 3. Sonda Lambda O2 (Cod. 87 - Reg. 0x52)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text(o2ParamTitle)
                            .font(.caption)
                            .bold()
                        Spacer()
                    }
                    Text(obd2Manager.o2LearningStatus)
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(obd2Manager.o2LearningStatus.contains("AZZERATO") || obd2Manager.o2LearningStatus.contains("RESET") ? .orange : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                // 4. Regolazione CO Cilindri (0x40 - 0x42)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "gauge.with.needle.fill")
                            .foregroundColor(.cyan)
                        Text(coParamTitle)
                            .font(.caption)
                            .bold()
                        Spacer()
                    }
                    Text(obd2Manager.coCylindersStatus)
                        .font(.caption)
                        .monospaced()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cyan.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
