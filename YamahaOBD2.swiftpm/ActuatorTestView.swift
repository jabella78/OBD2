import SwiftUI

struct Actuator {
    let code: Int
    let name: String
    let description: String
    let isDangerous: Bool
    let isABSTest: Bool
}

struct ActuatorTestView: View {
    @ObservedObject var obd2Manager: OBD2Manager
    @ObservedObject var lang = LocalizationManager.shared
    
    @State private var showingResetConfirmAlert = false
    @State private var showingABSInstructionAlert = false
    @State private var selectedActuator: Actuator?
    @State private var selectedCategory: Int = 0 // 0 = Motore (FI ECU), 1 = Pompa ABS (ABS ECU)
    
    let engineActuators = [
        Actuator(
            code: 67,
            name: "Reset Apprendimento Corpi Farfallati / Minimo (ISC)",
            description: "Manuale pag. 8-60 (Cod. 67 — Comando KWP 3B 54 01): Cancella i valori adattivi del motorino passo-passo ISC dei corpi farfallati riportando il registro 0x54 a 80 00 | 80 00 | 80 00. Da eseguire dopo pulizia o allineamento corpi farfallati.",
            isDangerous: true,
            isABSTest: false
        ),
        Actuator(
            code: 87,
            name: "Reset Apprendimento Sonda Lambda O2 (Trim A/F)",
            description: "Manuale pag. 8-61 (Cod. 87 — Comando KWP 3B 52 01): Cancella la memoria di correzione carburazione closed-loop della sonda O2 riportando il registro 0x52 ai valori neutri di fabbrica (02 00 / 02 00). Da eseguire dopo manutenzione aspirazione/scarico o sonda O2.",
            isDangerous: true,
            isABSTest: false
        )
    ]
    
    let absActuators = [
        Actuator(
            code: 1,
            name: "Conferma Forza di Reazione ABS (Pompa + Solenoidi)",
            description: "Manuale pag. 4-66 (Cod. 1): Genera la pulsazione dell'ABS in sequenza: Leva Freno Ant. -> Pedale Freno Post. -> Leva Freno Ant. Richiede Batteria > 12.8V e freni tirati.",
            isDangerous: false,
            isABSTest: true
        ),
        Actuator(
            code: 2,
            name: "Conferma Instradamento Tubi Freno (Unità Idraulica)",
            description: "Manuale pag. 4-65 (Cod. 2): Verifica il corretto collegamento dei tubi idraulici generando un impulso singolo: Leva Ant. -> Pedale Post. -> Leva Ant.",
            isDangerous: false,
            isABSTest: true
        )
    ]
    
    var isEngineRunning: Bool {
        if obd2Manager.isDemoMode {
            return false // In modalità simulazione consente il test completo delle procedure di reset e attuatori
        }
        return obd2Manager.rpm > 0 || obd2Manager.speed > 0
    }
    
    var currentActuators: [Actuator] {
        return selectedCategory == 0 ? engineActuators : absActuators
    }
    
    private var throttleStatusColor: Color {
        switch obd2Manager.throttleCleaningLevel {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .secondary
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(lang.t("act_title"))
                .font(.title2)
                .bold()
                .padding(.top, 10)
            
            Picker(lang.t("act_category"), selection: $selectedCategory) {
                Text(lang.t("act_cat_engine")).tag(0)
                Text(lang.t("act_cat_abs")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
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
                            Text(selectedCategory == 0
                                 ? lang.t("act_ready_engine")
                                 : lang.t("act_ready_abs"))
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        
                        Text(obd2Manager.actuatorStatusMessage)
                            .font(.caption)
                            .bold()
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
            
            if selectedCategory == 0 {
                engineParametersSection
            }
            
            if selectedCategory == 1 {
                if obd2Manager.isABSTestRunning {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "drop.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.t("act_abs_running_title"))
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.orange)
                                Text(lang.t("act_abs_running_desc"))
                                    .font(.caption)
                                    .bold()
                            }
                            Spacer()
                            Text("\(obd2Manager.absTestCountdown)s")
                                .font(.system(size: 30, weight: .heavy, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        
                        ProgressView(value: Double(obd2Manager.absTestCountdown), total: 12.0)
                            .tint(.orange)
                        
                        Button(action: {
                            obd2Manager.stopABSHydraulicTest()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "stop.fill")
                                Text(lang.t("act_abs_stop_btn"))
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.18))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Procedura Ufficiale Yamaha (Pag. 4-65 / 4-67):")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.orange)
                        Text("1. Posizionare la moto sul cavalletto centrale con batteria carica (> 12.8 V).\n2. Quadro su ON (motore spento) e ruote completamente ferme.\n3. PREMI E TIENI PREMUTI la leva del freno anteriore e il pedale posteriore, poi premi 'Avvia'.\n4. Mantieni la pressione per tutti i 12 secondi: sentirai la pulsazione idraulica nella sequenza: Leva Ant. → Pedale Post. → Leva Ant.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))], spacing: 16) {
                        ForEach(currentActuators, id: \.code) { actuator in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(actuator.name)
                                        .font(.headline)
                                        .foregroundColor(actuator.isDangerous ? .orange : .primary)
                                    Spacer()
                                    Text(actuator.isABSTest ? "ABS Cod. 0\(actuator.code)" : "DIAG Cod. \(actuator.code)")
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
                                    if !StoreManager.shared.isProUnlocked {
                                        obd2Manager.actuatorStatusMessage = "🔒 Funzione Pro: sblocca la versione completa nella scheda Setup per eseguire questo comando."
                                        return
                                    }
                                    selectedActuator = actuator
                                    if actuator.isABSTest {
                                        showingABSInstructionAlert = true
                                    } else {
                                        showingResetConfirmAlert = true
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        if !StoreManager.shared.isProUnlocked {
                                            Image(systemName: "lock.fill")
                                            Text("Sblocca con YaDiag Pro")
                                                .font(.system(size: 14, weight: .bold))
                                        } else {
                                            Image(systemName: actuator.isABSTest ? "drop.fill" : "arrow.counterclockwise")
                                            Text(actuator.isABSTest ? (obd2Manager.isABSTestRunning ? "Test in corso (\(obd2Manager.absTestCountdown)s)..." : "Avvia Test Pompa ABS") : "Esegui Reset Adattivo (Cod. \(actuator.code))")
                                                .font(.system(size: 14, weight: .bold))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(!StoreManager.shared.isProUnlocked ? Color.blue : (isEngineRunning || (actuator.isABSTest && obd2Manager.isABSTestRunning) ? Color.gray : (actuator.isABSTest ? Color.orange : Color.red.opacity(0.85))))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(color: (!StoreManager.shared.isProUnlocked ? Color.blue : (actuator.isABSTest ? Color.orange : Color.red)).opacity(0.25), radius: 3, x: 0, y: 2)
                                }
                                .disabled(StoreManager.shared.isProUnlocked && (isEngineRunning || (actuator.isABSTest && obd2Manager.isABSTestRunning)))
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
        .alert("Conferma Reset Parametri Adattivi", isPresented: $showingResetConfirmAlert) {
            Button("Conferma ed Esegui Reset", role: .destructive) {
                if let actuator = selectedActuator {
                    obd2Manager.sendActuatorCommand(code: actuator.code, isABSTest: false)
                }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            if selectedActuator?.code == 67 {
                Text("Stai per azzerare i valori di apprendimento dei corpi farfallati / valvola minimo ISC (Cod. 67 — Registro 0x54).\n\n⚠️ IMPORTANTE: Dopo il reset dovrai spegnere il quadro per 5 secondi, riaccenderlo e lasciar girare il motore al minimo (senza toccare l'acceleratore) per alcuni minuti fino a stabilizzazione del minimo.")
            } else {
                Text("Stai per azzerare i valori di auto-apprendimento carburazione della Sonda Lambda O2 (Cod. 87 — Registro 0x52).\n\n⚠️ IMPORTANTE: La centralina riapprenderà automaticamente i nuovi correttori A/F durante i successivi cicli di funzionamento a motore caldo.")
            }
        }
        .alert(lang.t("act_abs_alert_title"), isPresented: $showingABSInstructionAlert) {
            Button(lang.t("act_abs_alert_confirm")) {
                if let actuator = selectedActuator {
                    obd2Manager.sendActuatorCommand(code: actuator.code, isABSTest: true)
                }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text(lang.t("act_abs_alert_body"))
        }
    }
    
    @ViewBuilder
    private var engineParametersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Parametri & Apprendimenti Motore", systemImage: "waveform.path.ecg.rectangle.fill")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.cyan)
                Spacer()
                Button(action: {
                    obd2Manager.verifyISCAndO2Values()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Verifica Valori")
                            .bold()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
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
                        Text("Apprendimento Minimo ISC (Cod. 67 — Reg. 0x54):")
                            .font(.caption)
                            .bold()
                        Spacer()
                    }
                    Text(obd2Manager.iscLearningStatus)
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(obd2Manager.iscLearningStatus.contains("AZZERATO") ? .orange : .primary)
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
                        Text("Stato Pulizia Corpi Farfallati:")
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
                        Text("Apprendimento Sonda Lambda O2 (Cod. 87 — Reg. 0x52):")
                            .font(.caption)
                            .bold()
                        Spacer()
                    }
                    Text(obd2Manager.o2LearningStatus)
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(obd2Manager.o2LearningStatus.contains("AZZERATO") ? .orange : .primary)
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
                        Text("Regolazione CO Cilindri (Reg. 0x40 – 0x42):")
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
