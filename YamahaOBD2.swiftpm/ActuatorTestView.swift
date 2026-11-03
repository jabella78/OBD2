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
    @State private var selectedActuator: Actuator?
    
    let engineActuators = [
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
    
    var isEngineRunning: Bool {
        if obd2Manager.isDemoMode {
            return false // In modalità simulazione consente il test completo delle procedure di reset e attuatori
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
                        
                        Text(obd2Manager.actuatorStatusMessage)
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
                                    Text("DIAG Cod. \(actuator.code)")
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
                                        Text("Reset Adattivo (Cod. \(actuator.code))")
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
        .alert("Conferma Reset Parametri Adattivi", isPresented: $showingResetConfirmAlert) {
            Button("Conferma ed Esegui Reset", role: .destructive) {
                if let actuator = selectedActuator {
                    obd2Manager.sendActuatorCommand(code: actuator.code)
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
    }
    
    @ViewBuilder
    private var engineParametersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Parametri Motore", systemImage: "waveform.path.ecg.rectangle.fill")
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
                        Text("Verifica Valori")
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
