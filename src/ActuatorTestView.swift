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
    
    @State private var showingResetConfirmAlert = false
    @State private var showingServiceGuide = false
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
    
    var bannerServiceTitle: String {
        switch lang.currentLanguage {
        case .english: return "Reset Service / Maintenance Warning?"
        case .italian: return "Reset Spia Tagliando / Manutenzione?"
        case .french: return "Reset Voyant Vidange / Entretien ?"
        case .spanish: return "¿Reinicio Testigo Servicio / Aceite?"
        case .german: return "Service- / Wartungsanzeige zurücksetzen?"
        }
    }
    
    var bannerServiceDesc: String {
        switch lang.currentLanguage {
        case .english: return "On Yamaha motorcycles, service reset is performed directly on the dashboard."
        case .italian: return "Su moto Yamaha il reset è gestito direttamente dalla strumentazione."
        case .french: return "Sur les motos Yamaha, la réinitialisation se fait directement au compteur."
        case .spanish: return "En motos Yamaha el reinicio se realiza directamente desde el cuadro."
        case .german: return "Bei Yamaha-Motorrädern erfolgt der Service-Reset direkt am Cockpit."
        }
    }
    
    var bannerServiceBtn: String {
        switch lang.currentLanguage {
        case .english: return "Service Guide"
        case .italian: return "Guida Reset"
        case .french: return "Guide Reset"
        case .spanish: return "Guía Reset"
        case .german: return "Reset-Anleitung"
        }
    }
    
    var alertConfirmTitle: String {
        switch lang.currentLanguage {
        case .english: return "Confirm Adaptive Parameter Reset"
        case .italian: return "Conferma Reset Parametri Adattivi"
        case .french: return "Confirmer la Réinitialisation Adaptative"
        case .spanish: return "Confirmar Reinicio de Parámetros Adaptativos"
        case .german: return "Adaptiven Parameter-Reset Bestätigen"
        }
    }
    
    var alertConfirmBtn: String {
        switch lang.currentLanguage {
        case .english: return "Confirm and Execute Reset"
        case .italian: return "Conferma ed Esegui Reset"
        case .french: return "Confirmer et Réinitialiser"
        case .spanish: return "Confirmar y Ejecutar Reinicio"
        case .german: return "Bestätigen und Ausführen"
        }
    }
    
    var alertCancelBtn: String {
        switch lang.currentLanguage {
        case .english: return "Cancel"
        case .italian: return "Annulla"
        case .french: return "Annuler"
        case .spanish: return "Cancelar"
        case .german: return "Abbrechen"
        }
    }
    
    func alertMessageText(for code: Int) -> String {
        if code == 67 {
            switch lang.currentLanguage {
            case .english:
                return "You are about to reset throttle bodies / ISC idle stepper learning values (Code 67 — Register 0x54).\n\n⚠️ IMPORTANT: After reset, switch off ignition for 5 seconds, turn back ON and let engine idle (without touching the throttle) for several minutes until idle stabilizes."
            case .french:
                return "Vous allez réinitialiser les valeurs d'apprentissage du ralenti ISC (Code 67 — Registre 0x54).\n\n⚠️ IMPORTANT : Coupez le contact pendant 5 secondes, remettez-le et laissez tourner le moteur au ralenti sans toucher à la poignée de gaz pendant quelques minutes."
            case .spanish:
                return "Vas a reiniciar los valores de aprendizaje de ralentí ISC (Cód. 67 — Registro 0x54).\n\n⚠️ IMPORTANTE: Tras el reinicio, apaga el contacto 5 segundos, vuelve a encenderlo y deja el motor al ralentí sin acelerar durante unos minutos."
            case .german:
                return "Sie setzen die Drosselklappen- / ISC-Leerlaufadaptionswerte zurück (Code 67 — Register 0x54).\n\n⚠️ WICHTIG: Nach dem Reset die Zündung für 5 Sekunden ausschalten, wieder einschalten und den Motor einige Minuten im Leerlauf laufen lassen (ohne Gas zu geben)."
            case .italian:
                return "Stai per azzerare i valori di apprendimento dei corpi farfallati / valvola minimo ISC (Cod. 67 — Registro 0x54).\n\n⚠️ IMPORTANTE: Dopo il reset dovrai spegnere il quadro per 5 secondi, riaccenderlo e lasciar girare il motore al minimo (senza toccare l'acceleratore) per alcuni minuti fino a stabilizzazione del minimo."
            }
        } else {
            switch lang.currentLanguage {
            case .english:
                return "You are about to reset O2 sensor closed-loop air/fuel learning values (Code 87 — Register 0x52).\n\n⚠️ IMPORTANT: The ECU will automatically learn new fuel trims during subsequent warm riding cycles."
            case .french:
                return "Vous allez réinitialiser les valeurs d'auto-apprentissage de la sonde Lambda O2 (Code 87 — Registre 0x52).\n\n⚠️ IMPORTANT : Le calculateur réapprendra automatiquement les nouveaux correcteurs lors des prochains cycles de roulage à chaud."
            case .spanish:
                return "Vas a reiniciar los valores de autoaprendizaje de la sonda Lambda O2 (Cód. 87 — Registro 0x52).\n\n⚠️ IMPORTANTE: La centralita aprenderá automáticamente las nuevas correcciones en los siguientes ciclos con motor caliente."
            case .german:
                return "Sie setzen die O2-Lambdasonden Gemisch-Adaptionswerte zurück (Code 87 — Register 0x52).\n\n⚠️ WICHTIG: Das Steuergerät lernt die neuen Gemischtrims bei den folgenden Fahrzyklen bei warmem Motor automatisch an."
            case .italian:
                return "Stai per azzerare i valori di auto-apprendimento carburazione della Sonda Lambda O2 (Cod. 87 — Registro 0x52).\n\n⚠️ IMPORTANTE: La centralina riapprenderà automaticamente i nuovi correttori A/F durante i successivi cicli di funzionamento a motore caldo."
            }
        }
    }
    
    func adaptiveResetButtonTitle(for code: Int) -> String {
        switch lang.currentLanguage {
        case .english: return "Adaptive Reset (Code \(code))"
        case .italian: return "Reset Adattivo (Cod. \(code))"
        case .french: return "Reset Adaptatif (Code \(code))"
        case .spanish: return "Reinicio Adaptativo (Cód. \(code))"
        case .german: return "Adaptiver Reset (Code \(code))"
        }
    }
    
    var displayActuatorStatusMessage: String {
        let msg = obd2Manager.actuatorStatusMessage
        if msg == "Pronto." || msg == "Ready." || msg.isEmpty {
            return lang.t("act_status_ready")
        }
        return msg
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
            
                    // Card Informativa & Accesso Rapido Guida Reset Service
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundColor(.orange)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bannerServiceTitle)
                                    .font(.subheadline)
                                    .bold()
                                Text(bannerServiceDesc)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                showingServiceGuide = true
                            }) {
                                HStack(spacing: 4) {
                                    Text(bannerServiceBtn)
                                        .font(.system(size: 12, weight: .bold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(10)
                    .padding(.horizontal)
            
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
                                    selectedActuator = actuator
                                    showingResetConfirmAlert = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text(adaptiveResetButtonTitle(for: actuator.code))
                                            .font(.system(size: 13, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isEngineRunning ? Color.gray : Color.red.opacity(0.85))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.red.opacity(0.25), radius: 3, x: 0, y: 2)
                                }
                                .disabled(isEngineRunning)
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
        .alert(alertConfirmTitle, isPresented: $showingResetConfirmAlert) {
            Button(alertConfirmBtn, role: .destructive) {
                if let actuator = selectedActuator {
                    obd2Manager.sendActuatorCommand(code: actuator.code)
                }
            }
            Button(alertCancelBtn, role: .cancel) {}
        } message: {
            if let act = selectedActuator {
                Text(alertMessageText(for: act.code))
            }
        }
        .sheet(isPresented: $showingServiceGuide) {
            ServiceResetGuideView()
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
