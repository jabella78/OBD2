import Foundation

struct TerminalLine: Identifiable {
    let id = UUID()
    let text: String
}

enum DiagnosticTargetECU: String, CaseIterable, Identifiable {
    case engine = "engine"
    case abs = "abs"
    
    var id: String { self.rawValue }
    
    func name(for lang: AppLanguage) -> String {
        switch self {
        case .engine:
            switch lang {
            case .english: return "Engine (FI ECU)"
            case .italian: return "Motore (FI ECU)"
            case .french: return "Moteur (FI ECU)"
            case .spanish: return "Motor (FI ECU)"
            case .german: return "Motor (FI ECU)"
            }
        case .abs:
            switch lang {
            case .english: return "Brakes (ABS ECU)"
            case .italian: return "Freni (ABS ECU)"
            case .french: return "Freins (ABS ECU)"
            case .spanish: return "Frenos (ABS ECU)"
            case .german: return "Bremsen (ABS ECU)"
            }
        }
    }
}

class OBD2Manager: ObservableObject {
    var bleManager: BLEManager
    
    @Published var rpm: Int = 0
    @Published var speed: Int = 0
    @Published var temp: Int = 0
    @Published var o2Voltage: Double = 0.0
    @Published var tps: Int = 0
    @Published var iat: Int = 0
    @Published var engineLoad: Int = 0
    @Published var map: Int = 0
    @Published var timingAdvance: Int = 0
    @Published var batteryVoltage: String = "0.0V"
    @Published var dtcCodes: [String] = []
    @Published var absDtcCodes: [String] = []
    @Published var selectedECU: DiagnosticTargetECU = .engine
    @Published var absCanHeader: String = "7E3"
    @Published var terminalOutput: [TerminalLine] = []
    @Published var isRecording: Bool = false
    @Published var isPollingPaused: Bool = true // In pausa di default all'avvio: si attiva a richiesta dalla Dashboard per non saturare il terminale
    @Published var isScanningABS: Bool = false
    @Published var isDemoMode: Bool = false
    private var demoTimer: Timer? = nil
    private var telemetryTimer: Timer? = nil
    @Published var lastABSRawTrace: [String] = []
    @Published var actuatorStatusMessage: String = "Pronto. Seleziona un componente per avviare il test."
    @Published var iscLearningStatus: String = "Non ancora verificato"
    @Published var o2LearningStatus: String = "Non ancora verificato"
    @Published var coCylindersStatus: String = "Non ancora verificato"
    @Published var throttleCleaningStatus: String = "Premi 'Verifica Valori' per analizzare l'apertura adattiva ISC"
    @Published var throttleDirtPercentage: Double = 0.0
    @Published var throttleCleaningLevel: Int = 0 // 0 = N/D, 1 = OK (Verde), 2 = Depositi Medi (Giallo), 3 = Pulizia Necessaria (Rosso)
    private var coCyl1: String = "--"
    private var coCyl2: String = "--"
    private var coCyl3: String = "--"
    private var lastISCMaxDelta: Int = 0
    
    var currentGear: String {
        if speed == 0 { return rpm > 0 ? "N" : "-" }
        let ratio = Double(rpm) / Double(speed)
        switch ratio {
        case 95...150: return "1"
        case 72...94: return "2"
        case 60...71: return "3"
        case 51...59: return "4"
        case 45...50: return "5"
        case 35...44: return "6"
        default: return "-"
        }
    }
    
    @Published var currentTelemetryFilePath: URL?
    
    private var buffer = ""
    private var isInitializing = false
    private var isReadingErrors = false
    private var isProbingABS = false
    private var commandQueue: [String] = []
    private var isAwaitingResponse = false
    private var lastSentCommand: String = ""
    private var currentProbeHeader: String = ""
    private var timeoutWorkItem: DispatchWorkItem?
    
    var dtcDatabase: [String: String] = [:]
    
    init(bleManager: BLEManager) {
        self.bleManager = bleManager
        
        self.bleManager.dataReceivedCallback = { [weak self] data in
            self?.processIncomingData(data)
        }
        
        loadDTCDatabase()
    }
    
    private func loadDTCDatabase() {
        if let url = Bundle.main.url(forResource: "dtc_database", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let db = try? JSONDecoder().decode([String: String].self, from: data) {
            self.dtcDatabase = db
        }
    }
    
    func lookupABSCode(_ codeNumber: String) -> String {
        let key = "ABS_\(codeNumber)"
        if let desc = dtcDatabase[key] {
            return "Codice ABS \(codeNumber): \(desc)"
        }
        return "Codice ABS \(codeNumber): Anomalia rilevata (consultare tabella ABS pag. 8-128 del manuale)."
    }
    
    func startInitialization() {
        isInitializing = true
        let initCommands = ["ATZ", "ATE0", "ATL0", "STDI", "ATSP0", "0100"]
        performSequence(commands: initCommands)
    }
    
    func performSequence(commands: [String]) {
        for (index, cmd) in commands.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                self.bleManager.sendCommand(cmd)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(commands.count) * 0.5) {
            self.isInitializing = false
            self.startPolling()
        }
    }
    
    func enqueueCommand(_ cmd: String) {
        DispatchQueue.main.async {
            self.commandQueue.append(cmd)
            self.processQueue()
        }
    }
    
    private func processQueue() {
        if !isAwaitingResponse && !commandQueue.isEmpty {
            let nextCmd = commandQueue.removeFirst()
            isAwaitingResponse = true
            lastSentCommand = nextCmd
            if nextCmd.hasPrefix("ATSH ") {
                currentProbeHeader = String(nextCmd.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
            
            // Logga anche i comandi diagnostici (non di polling continuo) per tracciabilità nel file e nel terminale
            let isRoutinePoll = ["010C", "010D", "0105", "0111", "010F", "0104", "010B", "010E", "0114", "ATRV"].contains(nextCmd)
            if !isRoutinePoll {
                let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                let logLine = "[\(timestamp)] > \(nextCmd)"
                DispatchQueue.main.async {
                    self.terminalOutput.append(TerminalLine(text: logLine))
                }
                logToFile(logLine)
            }
            
            bleManager.sendCommand(nextCmd)
            
            // Timeout per evitare stalli sulla coda
            timeoutWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.isAwaitingResponse {
                    self.isAwaitingResponse = false
                    self.processQueue()
                }
            }
            timeoutWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
        }
    }
    
    func startPolling() {
        telemetryTimer?.invalidate()
        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  !self.isInitializing,
                  !self.isReadingErrors,
                  !self.isProbingABS,
                  !self.isPollingPaused else { return }
            guard self.commandQueue.isEmpty else { return } // Evita lag infinito
            
            self.enqueueCommand("010C") // RPM
            self.enqueueCommand("010D") // Speed
            self.enqueueCommand("0105") // Temp
            self.enqueueCommand("0111") // TPS
            self.enqueueCommand("010F") // IAT
            self.enqueueCommand("0104") // Load
            self.enqueueCommand("010B") // MAP
            self.enqueueCommand("010E") // Timing
            self.enqueueCommand("0114") // O2
            self.enqueueCommand("ATRV") // Battery
            
            if self.isRecording {
                self.recordTelemetry()
            }
        }
    }
    
    // MARK: - Modalità Demo / Simulazione per Apple Review e Test Offline
    
    func toggleDemoMode() {
        isDemoMode.toggle()
        if isDemoMode {
            if !bleManager.isConnected {
                bleManager.startVirtualSimulator()
            }
            startDemoSimulation()
        } else {
            if bleManager.isVirtualSimulator {
                bleManager.stopVirtualSimulator()
            }
            stopDemoSimulation()
        }
    }
    
    func startVirtualSimulatorMode() {
        bleManager.startVirtualSimulator()
        if !isDemoMode {
            isDemoMode = true
            startDemoSimulation()
        }
    }
    
    func stopVirtualSimulatorMode() {
        bleManager.stopVirtualSimulator()
        if isDemoMode {
            isDemoMode = false
            stopDemoSimulation()
        }
    }
    
    private func startDemoSimulation() {
        demoTimer?.invalidate()
        isPollingPaused = false
        var step = 0
        
        demoTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self, self.isDemoMode else { return }
            step += 1
            
            DispatchQueue.main.async {
                let cycle = step % 60
                if cycle < 15 {
                    self.rpm = 1250 + (cycle * 30)
                    self.speed = 0
                    self.tps = 15
                } else if cycle < 40 {
                    self.rpm = 1700 + ((cycle - 15) * 180)
                    self.speed = (cycle - 15) * 4
                    self.tps = 20 + ((cycle - 15) * 2)
                } else {
                    self.rpm = max(1200, 6200 - ((cycle - 40) * 240))
                    self.speed = max(0, 100 - ((cycle - 40) * 5))
                    self.tps = 16
                }
                
                self.temp = 88 + (step % 5)
                self.iat = 28
                self.map = 62 + (step % 12)
                self.engineLoad = 18 + (step % 15)
                self.timingAdvance = 12 + (step % 6)
                self.o2Voltage = 0.45 + (Double(step % 10) * 0.04)
                self.batteryVoltage = "13.8V"
                
                // Mantiene i parametri simulati in BLEManager sincronizzati con la dinamica del banco
                self.bleManager.simulatedRPM = self.rpm
                self.bleManager.simulatedSpeed = self.speed
                self.bleManager.simulatedCoolantTemp = self.temp
                self.bleManager.simulatedIAT = self.iat
                self.bleManager.simulatedTPS = self.tps
                
                if self.isRecording {
                    self.recordTelemetry()
                }
            }
        }
        
        DispatchQueue.main.async {
            self.dtcCodes = [
                "P0115: Circuito Sensore Temperatura Refrigerante ECT (Guasto simulato)",
                "P0130: Circuito Sensore Sonda Lambda O2 Banco 1 (Guasto simulato)"
            ]
            self.absDtcCodes = ["Codice ABS 41: Sensore velocità ruota anteriore (segnale anomalo / circuito aperto)"]
            self.iscLearningStatus = "Cil #1: 0x82F0 | Cil #2: 0x8435 | Cil #3: 0x8435\nStato: 🟡 VALORI DEPOSITI MEDI (Reg. 0x54)"
            self.o2LearningStatus = "Trim: 0x01FC / 0x0255 | Cicli: 0x000A\nStato: ✅ APPRESO REGOLARE (Reg. 0x52)"
            self.coCylindersStatus = "Cil #1: 0x82 (+2) | Cil #2: 0x80 (0) | Cil #3: 0x81 (+1)"
            self.throttleCleaningLevel = 2
            self.throttleDirtPercentage = 42.0
            self.throttleCleaningStatus = "🟡 DEPOSITI MEDI RILEVATI (Apertura compensata: 42%). Consigliata pulizia o reset ISC."
            self.terminalOutput.append(TerminalLine(text: "[SIMULATORE] Adattatore Virtuale OBD2 connesso e attivo."))
        }
    }
    
    private func stopDemoSimulation() {
        demoTimer?.invalidate()
        demoTimer = nil
        DispatchQueue.main.async {
            self.rpm = 0
            self.speed = 0
            self.terminalOutput.append(TerminalLine(text: "[DEMO] Modalità Simulazione disattivata."))
        }
    }
    
    func toggleTelemetry() {
        isPollingPaused.toggle()
        if isPollingPaused {
            // Svuota la coda comandi per interrompere immediatamente il traffico in volo
            commandQueue.removeAll()
        } else {
            if telemetryTimer == nil {
                startPolling()
            }
        }
    }
    
    func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            // Se si avvia la registrazione, attiva automaticamente la telemetria
            if isPollingPaused {
                isPollingPaused = false
            }
            if telemetryTimer == nil {
                startPolling()
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateStr = formatter.string(from: Date())
            
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let newPath = documentsDir.appendingPathComponent("telemetry_\(dateStr).csv")
            self.currentTelemetryFilePath = newPath
            
            let header = "Timestamp,RPM,Speed,Gear,Temp,O2Voltage,TPS,IAT,EngineLoad,MAP,TimingAdvance,BatteryVoltage\n"
            try? header.write(to: newPath, atomically: true, encoding: .utf8)
        }
    }
    
    private func recordTelemetry() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        
        let row = "\(timestamp),\(rpm),\(speed),\(currentGear),\(temp),\(o2Voltage),\(tps),\(iat),\(engineLoad),\(map),\(timingAdvance),\(batteryVoltage)\n"
        
        if let path = currentTelemetryFilePath, let fileHandle = try? FileHandle(forWritingTo: path) {
            fileHandle.seekToEndOfFile()
            if let data = row.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        }
    }
    
    // Funzione helper per calcolare l'indirizzo CAN di risposta (Request ID + 0x08 per ISO 15765-4 11-bit CAN)
    private func rxAddress(for txHeader: String) -> String {
        if let val = Int(txHeader, radix: 16) {
            return String(format: "%03X", val + 8)
        }
        return "7B8"
    }
    
    // MARK: - Diagnosi Centralina Motore (FI ECU)
    
    func readErrors() {
        if selectedECU == .abs {
            readABSErrors()
            return
        }
        
        isReadingErrors = true
        commandQueue.removeAll()
        DispatchQueue.main.async {
            self.dtcCodes = ["Lettura centralina motore (FI ECU - 7E0) in corso..."]
        }
        enqueueCommand("ATH1")
        enqueueCommand("ATSH 7E0")
        enqueueCommand("ATCRA 7E8")
        enqueueCommand("03")
        enqueueCommand("ATH0")
        enqueueCommand("ATCRA")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.isReadingErrors = false
            DispatchQueue.main.async {
                if self.dtcCodes.first?.contains("Lettura centralina motore") == true {
                    self.dtcCodes = ["Nessuna risposta dalla FI ECU (Verifica che il quadro moto sia su ON e l'adattatore connesso)."]
                }
                self.sendAnonymousTelemetryReport()
            }
        }
    }
    
    func clearErrors() {
        if selectedECU == .abs {
            clearABSErrors()
            return
        }
        commandQueue.removeAll()
        self.dtcCodes = ["Cancellazione errori FI ECU in corso..."]
        enqueueCommand("ATSH 7E0")
        enqueueCommand("ATCRA 7E8")
        enqueueCommand(SecurityVault.shared.getClearEngineCommand())
        enqueueCommand("ATCRA")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.dtcCodes = ["Comando cancellazione errori FI ECU inviato (Mode 04)."]
        }
    }
    
    // MARK: - Diagnosi Centralina ABS (ABS ECU su CANH/CANL)
    
    func readABSErrors() {
        guard bleManager.isConnected else {
            DispatchQueue.main.async {
                self.absDtcCodes = ["❌ ERRORE: Adattatore UniCarScan NON connesso via Bluetooth! Vai nel tab Bluetooth e connettiti prima di interrogare l'ABS."]
            }
            return
        }
        
        isReadingErrors = true
        let targetTx = absCanHeader
        let targetRx = rxAddress(for: targetTx)
        
        DispatchQueue.main.async {
            self.lastABSRawTrace.removeAll()
            self.absDtcCodes = ["⏳ Interrogazione centralina ABS su CAN TX:\(targetTx) / RX:\(targetRx) in corso..."]
        }
        
        // Svuota i comandi futuri di polling ma attende 350ms che l'eventuale comando in volo termini per evitare collisioni UART
        commandQueue.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.isAwaitingResponse = false
            self.enqueueCommand("ATE0")              // Disabilita Echo ELM327 per evitare frammenti di comando anteposti ai byte CAN
            self.enqueueCommand("ATH1")              // Abilita visualizzazione CAN ID mittente nelle risposte (es. 7EB)
            self.enqueueCommand("ATSH \(targetTx)")  // Imposta Header TX verso centralina ABS (default 7E3)
            self.enqueueCommand("ATCRA \(targetRx)") // Imposta il filtro di ricezione ELM327 per ascoltare 7EB
            self.enqueueCommand("ATFCSH \(targetTx)")// Imposta Flow Control Header per frame multipli ISO-TP dell'ABS
            self.enqueueCommand("ATFCSD 300000")     // Dati Flow Control standard
            self.enqueueCommand("ATFCSM 1")          // Attiva Flow Control manuale per l'header ABS
            
            // Sequenza diagnostica ufficiale KWP2000/UDS sulla centralina ABS Yamaha (7E3 -> 7EB)
            self.enqueueCommand("3E00")              // 1) TesterPresent (0x3E -> risponde 7EB 02 7E 00)
            self.enqueueCommand("1003")              // 2) DiagnosticSessionControl Extended (0x10 0x03 -> risponde 7EB 02 50 03)
            self.enqueueCommand("1800FF00")          // 3) KWP2000 ReadDiagnosticTroubleCodesByStatus (risponde 7EB ... 58 <numDTC> [5E <codice> <stato>])
            
            // Ripristina la configurazione solo dopo 2.5s per garantire la ricezione di tutti i frame ISO-TP dell'ABS
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                guard let self = self else { return }
                self.enqueueCommand("1001")          // Ritorno a Default Session
                self.enqueueCommand("ATFCSM 0")
                self.enqueueCommand("ATCRA")
                self.enqueueCommand("ATH0")
                self.enqueueCommand("ATSH 7E0")
            }
        }
        
        // Aspetta che la coda si svuoti e mostra il report reale di cosa ha risposto l'adattatore
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            self.isReadingErrors = false
            DispatchQueue.main.async {
                if self.absDtcCodes.first?.contains("Interrogazione centralina ABS") == true {
                    if self.lastABSRawTrace.isEmpty {
                        self.absDtcCodes = [
                            "⚠️ NESSUNA RISPOSTA dall'adattatore (Timeout).",
                            "Assicurati che il quadro della moto sia acceso (Key ON) e l'UniCarScan sia inizializzato."
                        ]
                    } else {
                        let summary = self.lastABSRawTrace.joined(separator: " | ")
                        self.absDtcCodes = [
                            "❌ Nessuna centralina ha risposto all'indirizzo CAN \(targetTx) (Filtro RX \(targetRx)).",
                            "Traccia risposte grezze: \(summary)",
                            "💡 Seleziona l'indirizzo 7E3 (RX 7EB) che è l'indirizzo tipico del nodo ABS."
                        ]
                    }
                }
                self.sendAnonymousTelemetryReport()
            }
        }
    }
    
    func clearABSErrors() {
        guard bleManager.isConnected else {
            DispatchQueue.main.async {
                self.absDtcCodes = ["❌ ERRORE: Adattatore UniCarScan NON connesso via Bluetooth!"]
            }
            return
        }
        
        isReadingErrors = true
        let targetTx = absCanHeader
        let targetRx = rxAddress(for: targetTx)
        
        DispatchQueue.main.async {
            self.lastABSRawTrace.removeAll()
            self.absDtcCodes = ["⏳ Cancellazione storico errori ABS (TX:\(targetTx) / RX:\(targetRx))..."]
        }
        commandQueue.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.isAwaitingResponse = false
            self.enqueueCommand("ATE0")
            self.enqueueCommand("ATH1")
            self.enqueueCommand("ATSH \(targetTx)")
            self.enqueueCommand("ATCRA \(targetRx)")
            self.enqueueCommand(SecurityVault.shared.getExtendedSessionCommand()) // Sessione diagnostica estesa
            self.enqueueCommand(SecurityVault.shared.getClearABSCommand())         // Clear Diagnostic Information
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                guard let self = self else { return }
                self.enqueueCommand(SecurityVault.shared.getDefaultSessionCommand())
                self.enqueueCommand("ATCRA")
                self.enqueueCommand("ATH0")
                self.enqueueCommand("ATSH 7E0")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.isReadingErrors = false
            DispatchQueue.main.async {
                let trace = self.lastABSRawTrace.joined(separator: " | ")
                self.absDtcCodes = [
                    "Sequenza cancellazione errori ABS completata su CAN \(targetTx) (RX \(targetRx)).",
                    "Risposte ricevute: \(trace.isEmpty ? "Nessuna" : trace)",
                    "Spegnere e riaccendere il quadro (Key OFF -> Key ON)."
                ]
            }
        }
    }
    
    func scanABSAddresses() {
        guard bleManager.isConnected else {
            DispatchQueue.main.async {
                self.absDtcCodes = ["❌ ERRORE: Adattatore UniCarScan NON connesso via Bluetooth! Connettiti prima di avviare l'Auto-Scan."]
            }
            return
        }
        
        isProbingABS = true
        isScanningABS = true
        commandQueue.removeAll()
        
        DispatchQueue.main.async {
            self.lastABSRawTrace.removeAll()
            self.absDtcCodes = [
                "🔍 Scansione Bus CAN in corso (Polling sospeso)...",
                "Sto interrogando: 7E3 (ABS Yamaha -> 7EB), 7DF (Broadcast), 7B0, 7E2, 760."
            ]
        }
        
        let candidateHeaders = ["7E3", "7DF", "7B0", "7E2", "760"]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.isAwaitingResponse = false
            self.enqueueCommand("ATH1")   // Mostra sempre il CAN ID di chi risponde (es. 7E8, 7EB)
            self.enqueueCommand("ATCRA")  // Rimuove qualsiasi filtro hardware per ascoltare TUTTI i nodi CAN
            
            for header in candidateHeaders {
                self.enqueueCommand("ATSH \(header)")
                self.enqueueCommand("3E00")   // UDS TesterPresent (0x3E -> risponde 0x7E)
                self.enqueueCommand("1003")   // UDS Extended Diagnostic Session (0x10 -> risponde 0x50)
                self.enqueueCommand("1902FF") // UDS Read DTC
            }
            
            self.enqueueCommand("ATH0")
            self.enqueueCommand("ATSH 7E0")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
            self.isProbingABS = false
            self.isScanningABS = false
            DispatchQueue.main.async {
                if self.lastABSRawTrace.isEmpty {
                    self.absDtcCodes = [
                        "⚠️ Auto-Scan terminato: Nessuna risposta ricevuta dal bus CAN.",
                        "Verifica che il quadro della moto sia su ON."
                    ]
                } else {
                    self.absDtcCodes.insert("✅ Auto-Scan completato! Nodo ABS rilevato su 7E3 (Risposta 7EB):", at: 0)
                }
            }
        }
    }
    
    // MARK: - Funzioni Attuatori e Reset Apprendimento (FI ECU Cod. 67/87 + Unità Idraulica ABS Cod. 01/02)
    
    /// Verifica di sicurezza preliminare in tempo reale: interroga direttamente la centralina sui giri motore (010C) e velocità (010D)
    /// prima di permettere qualsiasi comando attuatore o test idraulico ABS.
    func verifyEngineSafetyBeforeActuator(completion: @escaping (Bool) -> Void) {
        if isDemoMode {
            completion(true)
            return
        }
        
        guard bleManager.isConnected else {
            DispatchQueue.main.async {
                self.actuatorStatusMessage = "❌ Errore: Adattatore non connesso."
            }
            completion(false)
            return
        }
        
        let checkWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { completion(false); return }
            if self.rpm > 0 {
                DispatchQueue.main.async {
                    self.actuatorStatusMessage = "❌ Blocco Sicurezza: Motore acceso (\(self.rpm) RPM). Spegnere il motore prima di procedere."
                }
                completion(false)
            } else if self.speed > 0 {
                DispatchQueue.main.async {
                    self.actuatorStatusMessage = "❌ Blocco Sicurezza: Veicolo in movimento (\(self.speed) km/h)."
                }
                completion(false)
            } else {
                completion(true)
            }
        }
        
        self.bleManager.sendCommand("010C")
        self.bleManager.sendCommand("010D")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: checkWorkItem)
    }
    
    func sendActuatorCommand(code: Int) {
        verifyEngineSafetyBeforeActuator { [weak self] isSafe in
            guard let self = self, isSafe else { return }
            
            self.isReadingErrors = true
            self.commandQueue.removeAll()
            
            DispatchQueue.main.async {
                self.lastABSRawTrace.removeAll()
                if code == 67 {
                    self.actuatorStatusMessage = "⏳ Esecuzione Reset Apprendimento Corpi Farfallati / Minimo ISC (Cod. 67 -> 3B 54 01)..."
                } else if code == 87 {
                    self.actuatorStatusMessage = "⏳ Esecuzione Reset Apprendimento Sonda Lambda O2 (Cod. 87 -> 3B 52 01)..."
                } else {
                    self.actuatorStatusMessage = "⏳ Invio comando (Cod. \(code)) alla centralina Motore (7E0)..."
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.isAwaitingResponse = false
                self.enqueueCommand("ATH1")
                self.enqueueCommand("ATSH 7E0")
                self.enqueueCommand("ATCRA 7E8")
                self.enqueueCommand("ATFCSH 7E0")
                self.enqueueCommand("ATFCSD 300000")
                self.enqueueCommand("ATFCSM 1")
                self.enqueueCommand(SecurityVault.shared.getExtendedSessionCommand())
                
                if code == 67 {
                    self.enqueueCommand(SecurityVault.shared.getResetISCCommand())
                    self.enqueueCommand("2154")
                } else if code == 87 {
                    self.enqueueCommand(SecurityVault.shared.getResetO2Command())
                    self.enqueueCommand("3B5801")
                    self.enqueueCommand("2152")
                    self.enqueueCommand("2158")
                }
                
                self.enqueueCommand(SecurityVault.shared.getDefaultSessionCommand())
                self.enqueueCommand("ATFCSM 0")
                self.enqueueCommand("ATCRA")
                self.enqueueCommand("ATH0")
                self.enqueueCommand("ATSH 7E0")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                self.isReadingErrors = false
            }
        }
    }
    
    // MARK: - Verifica Valori Apprendimento Minimo (ISC Cod. 67), Sonda O2 (Cod. 87) e CO Cilindri (0x40..0x42)
    
    func verifyISCAndO2Values() {
        isReadingErrors = true // Sospende temporaneamente il polling telemetria
        commandQueue.removeAll()
        
        DispatchQueue.main.async {
            self.actuatorStatusMessage = "🔍 Lettura parametri ISC (Minimo), Sonda O2 e CO dalla centralina Motore (7E8)..."
            self.iscLearningStatus = "Lettura in corso..."
            self.o2LearningStatus = "Lettura in corso..."
            self.coCylindersStatus = "Lettura in corso..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.isAwaitingResponse = false
            self.enqueueCommand("ATH1")
            self.enqueueCommand("ATSH 7E0")
            self.enqueueCommand("ATCRA 7E8")
            self.enqueueCommand("ATFCSH 7E0")
            self.enqueueCommand("ATFCSD 300000")
            self.enqueueCommand("ATFCSM 1")
            self.enqueueCommand("1003") // Entra in Extended Diagnostic Session (50 03)
            self.enqueueCommand("2140") // CO Cilindro #1
            self.enqueueCommand("2141") // CO Cilindro #2
            self.enqueueCommand("2142") // CO Cilindro #3
            self.enqueueCommand("2152") // Apprendimento Sonda O2 (Cod. 87)
            self.enqueueCommand("2154") // Apprendimento Minimo ISC (Cod. 67)
            self.enqueueCommand("2158") // Stato Adattamento O2 / ISC secondario
            self.enqueueCommand("1001") // Torna in Default Session per riabilitare la telemetria OBD2
            self.enqueueCommand("ATFCSM 0")
            self.enqueueCommand("ATCRA")
            self.enqueueCommand("ATH0")
            self.enqueueCommand("ATSH 7E0")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            self.isReadingErrors = false
            DispatchQueue.main.async {
                self.actuatorStatusMessage = "✅ Verifica parametri ISC, Sonda O2 e CO completata."
            }
        }
    }
    
    static func isDangerousCommand(_ cmd: String) -> (isDangerous: Bool, reason: String) {
        let clean = cmd.replacingOccurrences(of: " ", with: "").uppercased()
        if clean.hasPrefix("2E") {
            return (true, "Scrittura parametri EEPROM (Service 0x2E)")
        } else if clean.hasPrefix("34") || clean.hasPrefix("35") || clean.hasPrefix("36") || clean.hasPrefix("37") {
            return (true, "Riprogrammazione memoria flash ECU (Service 0x34..0x37)")
        } else if clean.hasPrefix("1101") {
            return (true, "Hard Reset immediato della centralina (Service 0x11)")
        }
        return (false, "")
    }
    
    func sendCustomCommand(_ cmd: String) {
        enqueueCommand(cmd)
    }
    
    private func stripEcho(from response: String, command: String) -> String {
        let text = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCmd = command.replacingOccurrences(of: " ", with: "").uppercased()
        guard !cleanCmd.isEmpty else { return text }
        
        let textNoSpaces = text.replacingOccurrences(of: " ", with: "").uppercased()
        guard textNoSpaces.hasPrefix(cleanCmd) else { return text }
        if textNoSpaces == cleanCmd { return "" }
        
        var remaining = cleanCmd
        var index = text.startIndex
        while index < text.endIndex && !remaining.isEmpty {
            let char = text[index]
            if char.isWhitespace {
                index = text.index(after: index)
                continue
            }
            if String(char).uppercased() == String(remaining.first!) {
                remaining.removeFirst()
                index = text.index(after: index)
            } else {
                break
            }
        }
        
        if remaining.isEmpty {
            return String(text[index...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
    
    // MARK: - Invio Telemetria Anonima di Compatibilità a Supabase
    
    func sendAnonymousTelemetryReport() {
        guard !isDemoMode else { return }
        guard bleManager.isConnected else { return }
        let peripheralName = bleManager.connectedDeviceName
        guard !peripheralName.isEmpty else { return }
        
        var canNodes: [String] = []
        if !dtcCodes.isEmpty && !dtcCodes.first!.contains("Nessuna risposta") {
            canNodes.append("7E0/7E8")
        }
        if !absDtcCodes.isEmpty && !absDtcCodes.first!.contains("Nessuna risposta") {
            canNodes.append(absCanHeader)
        }
        
        TelemetryService.shared.sendCompatibilityTelemetry(
            adapterName: peripheralName,
            isCertified: BLEManager.isCertifiedAdapter(name: peripheralName),
            canHeaders: canNodes,
            engineDTCs: dtcCodes.filter { $0.hasPrefix("Errore") },
            absDTCs: absDtcCodes.filter { $0.contains("Codice ABS") },
            iscStatus: iscLearningStatus,
            o2Status: o2LearningStatus,
            dirtLevel: throttleCleaningLevel,
            dirtPct: throttleDirtPercentage
        )
    }
    
    private func processIncomingData(_ data: String) {
        buffer += data
        if buffer.contains(">") {
            let responses = buffer.components(separatedBy: ">")
            for response in responses {
                let cleanRaw = response.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespaces)
                guard !cleanRaw.isEmpty else { continue }
                
                let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
                let logLine = "[\(timestamp)] < \(cleanRaw)"
                DispatchQueue.main.async {
                    self.terminalOutput.append(TerminalLine(text: logLine))
                    if self.terminalOutput.count > 150 {
                        self.terminalOutput.removeFirst()
                    }
                }
                logToFile(logLine)
                
                // Rimuove l'eventuale eco del comando anteposto dall'adattatore
                let cleanResponse = stripEcho(from: cleanRaw, command: lastSentCommand)
                if !cleanResponse.isEmpty {
                    parseOBDResponse(cleanResponse.replacingOccurrences(of: " ", with: ""), rawWithSpaces: cleanResponse)
                }
            }
            buffer = ""
            timeoutWorkItem?.cancel()
            
            DispatchQueue.main.async {
                self.isAwaitingResponse = false
                self.processQueue()
            }
        }
    }
    
    private func logToFile(_ text: String) {
        let line = text + "\n"
        guard let data = line.data(using: .utf8) else { return }
        
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let docFileURL = documentsDir.appendingPathComponent("obd2_log.txt")
            rotateLogIfNeeded(docFileURL)
            appendData(data, to: docFileURL)
        }
    }
    
    private func rotateLogIfNeeded(_ fileURL: URL) {
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let size = attrs[.size] as? UInt64, size > 2 * 1024 * 1024 {
            let backupURL = fileURL.deletingPathExtension().appendingPathExtension("prev.txt")
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.moveItem(at: fileURL, to: backupURL)
        }
    }
    
    private func appendData(_ data: Data, to fileURL: URL) {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: fileURL)
        }
    }
    
    private func parseOBDResponse(_ hexStr: String, rawWithSpaces: String = "") {
        var cleanHex = hexStr.uppercased()
        
        // Se cleanHex non inizia direttamente con un header noto ma contiene un CAN ID noto, riallinea da quel punto
        let knownCANHeaders = ["7EB", "7E8", "7EA", "7B8", "7A8", "768"]
        if !knownCANHeaders.contains(where: { cleanHex.hasPrefix($0) }) {
            for header in knownCANHeaders {
                if let range = cleanHex.range(of: header) {
                    cleanHex = String(cleanHex[range.lowerBound...])
                    break
                }
            }
        }
        
        // Tracciamento diagnostico in tempo reale quando stiamo interrogando o scansionando l'ABS o gli attuatori
        if isReadingErrors || isProbingABS {
            if cleanHex != "OK" {
                let traceEntry = "[\(currentProbeHeader.isEmpty ? absCanHeader : currentProbeHeader) -> \(lastSentCommand)]: \(rawWithSpaces.isEmpty ? cleanHex : rawWithSpaces)"
                DispatchQueue.main.async {
                    self.lastABSRawTrace.append(traceEntry)
                    if self.lastSentCommand.hasPrefix("31") || self.lastSentCommand.hasPrefix("2F") || self.lastSentCommand.hasPrefix("30") {
                        self.actuatorStatusMessage = "Risposta ECU a [\(self.lastSentCommand)]: \(rawWithSpaces.isEmpty ? cleanHex : rawWithSpaces)"
                    }
                    if self.isProbingABS && !cleanHex.contains("NODATA") && !cleanHex.contains("ERROR") {
                        // Abbiamo trovato una risposta VIVA da una centralina sul bus CAN!
                        if self.absDtcCodes.first?.contains("Scansione Bus CAN in corso") == true {
                            self.absDtcCodes.removeAll()
                        }
                        let hitMsg = "🟢 NODO ATTIVO RILEVATO! \(traceEntry)"
                        if !self.absDtcCodes.contains(hitMsg) {
                            self.absDtcCodes.append(hitMsg)
                        }
                    }
                }
            }
        }
        
        if cleanHex.hasPrefix("410C") && cleanHex.count >= 8 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 4)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.rpm = val / 4 }
            }
        } else if cleanHex.hasPrefix("410D") && cleanHex.count >= 6 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 2)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.speed = val }
            }
        } else if cleanHex.hasPrefix("4105") && cleanHex.count >= 6 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 2)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.temp = val - 40 }
            }
        } else if cleanHex.hasPrefix("4114") && cleanHex.count >= 6 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 2)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.o2Voltage = Double(val) / 200.0 }
            }
        } else if cleanHex.hasPrefix("4111") && cleanHex.count >= 6 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 2)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.tps = val * 100 / 255 }
            }
        } else if cleanHex.hasPrefix("410F") && cleanHex.count >= 6 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 2)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.iat = val - 40 }
            }
        } else if cleanHex.hasPrefix("4104") && cleanHex.count >= 6 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 2)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.engineLoad = val * 100 / 255 }
            }
        } else if cleanHex.hasPrefix("410B") && cleanHex.count >= 6 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 2)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.map = val }
            }
        } else if cleanHex.hasPrefix("410E") && cleanHex.count >= 6 {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: 4)
            let end = cleanHex.index(start, offsetBy: 2)
            if let val = Int(String(cleanHex[start..<end]), radix: 16) {
                DispatchQueue.main.async { self.timingAdvance = (val / 2) - 64 }
            }
        } else if cleanHex.hasSuffix("V") {
            DispatchQueue.main.async { self.batteryVoltage = cleanHex }
        } else if (cleanHex.hasPrefix("7E8") || cleanHex.hasPrefix("7EB") || cleanHex.hasPrefix("7B8") || cleanHex.hasPrefix("7EA") || cleanHex.hasPrefix("7A8") || cleanHex.hasPrefix("768")) && cleanHex.count >= 5 {
            // Risposta con CAN Header a 11-bit visibile (ATH1 attivo), es. 7E8..., 7EB..., 7B8...
            let canId = String(cleanHex.prefix(3))
            let payload = String(cleanHex.dropFirst(3))
            
            if canId == "7E8" && payload.contains("61") {
                parseYamahaKWP21Response(cleanHex)
            }
            
            // Aggiorna feedback Test Attuatori e Reset Apprendimento in tempo reale
            DispatchQueue.main.async {
                if payload.contains("7B54") {
                    self.actuatorStatusMessage = "✅ Reset Apprendimento Corpi Farfallati / Minimo ISC (Cod. 67) eseguito con successo (7E8 -> 7B 54)!"
                } else if payload.contains("7B52") {
                    self.actuatorStatusMessage = "✅ Reset Apprendimento Sonda Lambda O2 (Cod. 87) eseguito con successo (7E8 -> 7B 52)!"
                } else if payload.contains("7170") {
                    var statusByte = "00"
                    if let r = payload.range(of: "7170") {
                        let after = String(payload[r.upperBound...])
                        if after.count >= 2 {
                            statusByte = String(after.prefix(2))
                        }
                    }
                    if statusByte == "00" {
                        self.actuatorStatusMessage = "⚠️ Centralina ABS (\(canId)) in attesa: Premi e tieni premuti CON FORZA sia la LEVA che il PEDALE freno!"
                    } else {
                        self.actuatorStatusMessage = "⚡ POMPA ABS ATTIVA (\(canId) -> 71 70 \(statusByte))! Pulsazioni in corso sui freni!"
                    }
                } else if payload.contains("71") || payload.contains("6F") || payload.contains("70") {
                    self.actuatorStatusMessage = "✅ Attuatore attivato da \(canId): \(rawWithSpaces)"
                } else if payload.contains("6701") {
                    self.actuatorStatusMessage = "🔐 Centralina \(canId) richiede Security Access (Seed ricevuto: \(rawWithSpaces))"
                } else if payload.contains("7F31") {
                    self.actuatorStatusMessage = "ℹ️ Risposta \(canId) su Routine 0x31: \(rawWithSpaces)"
                }
            }
            
            if canId == "7EB" || canId == rxAddress(for: absCanHeader) || selectedECU == .abs || isProbingABS {
                if canId != "7E8" || currentProbeHeader == "7E0" {
                    parseABSResponse(payload, responderCANID: canId)
                } else if isProbingABS && canId == "7E8" {
                    DispatchQueue.main.async {
                        let msg = "ℹ️ Risposta FI ECU (7E8) su broadcast: \(payload)"
                        if !self.absDtcCodes.contains(msg) {
                            self.absDtcCodes.append(msg)
                        }
                    }
                }
            } else if canId == "7E8" {
                var cleanPayload = payload
                if cleanPayload.hasPrefix("0") && cleanPayload.count >= 4 {
                    cleanPayload = String(cleanPayload.dropFirst(2))
                }
                if cleanPayload.hasPrefix("43") {
                    parseEngineDTC(cleanPayload)
                }
            }
        } else if cleanHex.hasPrefix("59") || cleanHex.hasPrefix("58") || cleanHex.hasPrefix("54") || cleanHex.hasPrefix("50") || cleanHex.hasPrefix("7E") || cleanHex.hasPrefix("7F") {
            if selectedECU == .abs || isProbingABS || cleanHex.hasPrefix("58") {
                parseABSResponse(cleanHex, responderCANID: rxAddress(for: absCanHeader))
            }
        } else if cleanHex.hasPrefix("43") {
            if selectedECU == .abs {
                parseABSResponse(cleanHex, responderCANID: rxAddress(for: absCanHeader))
            } else {
                parseEngineDTC(cleanHex)
            }
        } else if cleanHex.contains("NODATA") {
            DispatchQueue.main.async {
                if self.isReadingErrors && self.selectedECU == .engine {
                    if self.dtcCodes.first?.contains("Lettura") == true {
                        self.dtcCodes = ["Nessun errore memorizzato sulla centralina Motore (NO DATA)."]
                    }
                }
            }
        }
    }
    
    private func decodeDTCFromBytes(_ b1Hex: String, _ b2Hex: String) -> String {
        guard let b1 = UInt8(b1Hex, radix: 16) else { return "P\(b1Hex)\(b2Hex)" }
        let prefixType = (b1 & 0xC0) >> 6
        let prefixes = ["P", "C", "B", "U"]
        let prefix = prefixType < prefixes.count ? prefixes[Int(prefixType)] : "P"
        let firstDigit = (b1 & 0x30) >> 4
        let secondDigit = b1 & 0x0F
        return String(format: "%@%X%X%@", prefix, firstDigit, secondDigit, b2Hex)
    }
    
    private func parseEngineDTC(_ hexStr: String) {
        if hexStr.hasPrefix("4300") || hexStr == "43" {
            DispatchQueue.main.async {
                if self.dtcCodes.first?.contains("Lettura") == true {
                    self.dtcCodes = []
                }
                if !self.dtcCodes.contains("✅ La centralina Motore (FI ECU 7E8) ha risposto: Nessun errore in memoria (43 00).") {
                    self.dtcCodes.append("✅ La centralina Motore (FI ECU 7E8) ha risposto: Nessun errore in memoria (43 00).")
                }
            }
            return
        }
        
        let payload = String(hexStr.dropFirst(2)) // Rimuove '43'
        guard !payload.isEmpty else { return }
        
        var decodedCodes: [String] = []
        
        // Nel protocollo ISO 15765-4 (CAN):
        // Se payload ha un byte conteggio: es. '01 01 35' (len 6) o '02 01 35 02 01' (len 10)
        if payload.count >= 6 && (payload.count - 2) % 4 == 0 {
            let dtcHex = String(payload.dropFirst(2))
            var idx = dtcHex.startIndex
            while idx < dtcHex.endIndex {
                guard let next4 = dtcHex.index(idx, offsetBy: 4, limitedBy: dtcHex.endIndex) else { break }
                let chunk = String(dtcHex[idx..<next4])
                if chunk != "0000" {
                    let b1 = String(chunk.prefix(2))
                    let b2 = String(chunk.dropFirst(2))
                    let pCode = decodeDTCFromBytes(b1, b2)
                    let desc = dtcDatabase[pCode] ?? "Guasto non presente nel DB offline"
                    decodedCodes.append("Errore \(pCode): \(desc)")
                }
                idx = next4
            }
        } else if payload.count % 4 == 0 {
            var idx = payload.startIndex
            while idx < payload.endIndex {
                guard let next4 = payload.index(idx, offsetBy: 4, limitedBy: payload.endIndex) else { break }
                let chunk = String(payload[idx..<next4])
                if chunk != "0000" {
                    let b1 = String(chunk.prefix(2))
                    let b2 = String(chunk.dropFirst(2))
                    let pCode = decodeDTCFromBytes(b1, b2)
                    let desc = dtcDatabase[pCode] ?? "Guasto non presente nel DB offline"
                    decodedCodes.append("Errore \(pCode): \(desc)")
                }
                idx = next4
            }
        } else {
            decodedCodes.append("Errore grezzo rilevato: \(hexStr)")
        }
        
        DispatchQueue.main.async {
            if self.dtcCodes.first?.contains("Lettura") == true {
                self.dtcCodes = []
            }
            for code in decodedCodes {
                if !self.dtcCodes.contains(code) {
                    self.dtcCodes.append(code)
                }
            }
        }
    }
    
    private func parseABSResponse(_ hexStr: String, responderCANID: String) {
        // Rimuove eventuali header ripetuti nei frame multipli ISO-TP (es. "7EB100858025E11205E7EB2125205555555555")
        var clean = hexStr.replacingOccurrences(of: responderCANID, with: "")
        
        // Gestione Single Frame ISO-TP (es. "025800", "025003", "0454FFFFFF", "07717000...")
        if clean.hasPrefix("0") && clean.count >= 4 {
            let serviceByte = String(clean.dropFirst(2).prefix(2))
            if ["50", "54", "58", "59", "7E", "7F", "43", "71"].contains(serviceByte) {
                clean = String(clean.dropFirst(2))
            }
        } else if clean.hasPrefix("10") && clean.count >= 6 {
            // Gestione Multi-Frame ISO-TP (First Frame "10 <len>" + Consecutive Frame "21", "22"...)
            // Es: 10 08 58 02 5E 11 20 5E [21] 25 20 55 55 55 55 55
            var reassembled = ""
            // Rimuove First Frame PCI (4 char: "1008")
            let afterFF = String(clean.dropFirst(4))
            // Nel primo frame ci sono 6 byte di dati (12 char esadecimali) prima del Consecutive Frame "21"
            if afterFF.count >= 12 {
                reassembled += String(afterFF.prefix(12))
                var remainder = String(afterFF.dropFirst(12))
                var cfIndex = 1
                while !remainder.isEmpty {
                    let cfHeader = String(format: "2%1X", cfIndex % 16)
                    if remainder.hasPrefix(cfHeader) {
                        remainder = String(remainder.dropFirst(2))
                    }
                    let chunk = String(remainder.prefix(14)) // 7 byte (14 hex char) per Consecutive Frame
                    reassembled += chunk
                    remainder = String(remainder.dropFirst(min(14, remainder.count)))
                    cfIndex += 1
                }
                clean = reassembled
            }
        }
        
        // Caso Routine Control 0x71 (Risposta positiva a 31 01 70 01/02 o 31 70 01/02)
        if clean.contains("710170") || clean.contains("7170") {
            var statusByte = "00"
            if let r = clean.range(of: "710170") {
                let after = String(clean[r.upperBound...])
                if after.count >= 2 { statusByte = String(after.prefix(2)) }
            } else if let r = clean.range(of: "7170") {
                let after = String(clean[r.upperBound...])
                if after.count >= 2 { statusByte = String(after.prefix(2)) }
            }
            DispatchQueue.main.async {
                if statusByte == "00" {
                    self.actuatorStatusMessage = "⚠️ Centralina ABS (\(responderCANID)) in ascolto: Tieni premuti CON FORZA leva e pedale freno! (In attesa trigger)"
                } else {
                    self.actuatorStatusMessage = "⚡ POMPA ABS ATTIVA (\(responderCANID) -> 71 70 \(statusByte))! Pulsazioni idrauliche in corso!"
                }
            }
            return
        }
        
        // Rileva eventuali Negative Response Code NRC su Routine 0x31 (es. 7F 31 22)
        if clean.contains("7F31") {
            if let r = clean.range(of: "7F31") {
                let nrc = String(clean[r.upperBound...].prefix(2))
                var nrcDesc = "Codice 0x\(nrc)"
                if nrc == "12" { nrcDesc = "SubFunzione non supportata (0x12)" }
                else if nrc == "22" { nrcDesc = "Condizioni non corrette (0x22 - es. freni o cavalletto)" }
                else if nrc == "31" { nrcDesc = "Richiesta fuori scala (0x31)" }
                else if nrc == "33" { nrcDesc = "Accesso di sicurezza richiesto (0x33)" }
                DispatchQueue.main.async {
                    self.actuatorStatusMessage = "ℹ️ Risposta ABS: \(nrcDesc)"
                }
            }
            return
        }
        
        // Caso 1: Risposta positiva cancellazione errori (54 FF FF FF)
        if clean.contains("54FFFFFF") {
            DispatchQueue.main.async {
                self.absDtcCodes = ["✅ Storico errori ABS cancellato con successo dalla centralina (7EB -> 54 FF FF FF)!"]
            }
            return
        }
        
        // Caso 2: Conferma sessione diagnostica (0x50) o TesterPresent (0x7E)
        if clean.hasPrefix("50") || clean.hasPrefix("7E") {
            DispatchQueue.main.async {
                if self.absDtcCodes.first?.contains("Interrogazione") == true || self.absDtcCodes.first?.contains("Scansione") == true {
                    self.absDtcCodes.removeAll()
                }
                let statusMsg = clean.hasPrefix("50")
                    ? "✅ Connessione stabilita con centralina ABS (\(responderCANID) - Sessione Diagnostica Attiva)"
                    : "✅ Centralina ABS (\(responderCANID)) online"
                if !self.absDtcCodes.contains(statusMsg) {
                    self.absDtcCodes.append(statusMsg)
                }
            }
            return
        }
        
        if clean.hasPrefix("7F") {
            // Ignora i codici 7F di servizi secondari non supportati per non sporcare la lista
            return
        }
        
        // Caso 3: Risposta KWP2000 0x58 (ReadDiagnosticTroubleCodesByStatus, risposta a 18 00 FF 00)
        // Formato Yamaha ABS: 58 <numDTC> [<5E> <codice_BCD> <status_byte>]...
        // Esempio reale catturato: 58 02 5E 11 20 5E 25 20 -> 2 errori: C1111 (Cod. 11) e C1125 (Cod. 25)
        if clean.hasPrefix("58") && clean.count >= 4 {
            let numDTCHex = String(clean.dropFirst(2).prefix(2))
            let numDTC = Int(numDTCHex, radix: 16) ?? 0
            
            if numDTC == 0 {
                DispatchQueue.main.async {
                    if self.absDtcCodes.first?.contains("Interrogazione") == true {
                        self.absDtcCodes.removeAll()
                    }
                    let msg = "🟢 Nessun errore presente nella centralina ABS (Risposta 7EB: 58 00 - 0 guasti in memoria)."
                    if !self.absDtcCodes.contains(msg) {
                        self.absDtcCodes.append(msg)
                    }
                }
                return
            }
            
            let dtcPayload = String(clean.dropFirst(4))
            var foundCodes: [String] = []
            
            // Ogni DTC è lungo 3 byte (6 caratteri hex): [HighByte (5E = C1E)] [CodiceABS (es. 11, 25)] [Status (es. 20 = Storico, 60/A0 = Attivo)]
            var idx = dtcPayload.startIndex
            for _ in 0..<numDTC {
                guard let endIdx = dtcPayload.index(idx, offsetBy: 6, limitedBy: dtcPayload.endIndex) else { break }
                let triplet = String(dtcPayload[idx..<endIdx])
                let codeByte = String(triplet.dropFirst(2).prefix(2))
                let statusByte = String(triplet.dropFirst(4).prefix(2))
                let statusDesc = (statusByte == "20") ? "[Storico/Passato]" : "[Attivo - Stato 0x\(statusByte)]"
                let formatted = "⚠️ \(statusDesc) " + lookupABSCode(codeByte)
                if !foundCodes.contains(formatted) {
                    foundCodes.append(formatted)
                }
                idx = endIdx
            }
            
            DispatchQueue.main.async {
                if self.absDtcCodes.first?.contains("Interrogazione") == true {
                    self.absDtcCodes.removeAll()
                }
                let headerMsg = "🔴 Rilevati \(numDTC) codici errore nella memoria ABS (\(responderCANID)):"
                if !self.absDtcCodes.contains(headerMsg) {
                    self.absDtcCodes.append(headerMsg)
                }
                for code in foundCodes {
                    if !self.absDtcCodes.contains(code) {
                        self.absDtcCodes.append(code)
                    }
                }
            }
            return
        }
    }
    
    // MARK: - Parser Registri KWP2000 0x21 (ISC Minimo 0x54, Sonda O2 0x52/0x58, CO Cilindri 0x40..0x42)
    
    private func parseYamahaKWP21Response(_ hexStr: String) {
        var clean = hexStr.replacingOccurrences(of: "7E8", with: "")
        
        if clean.hasPrefix("0") && clean.count >= 4 {
            clean = String(clean.dropFirst(2))
        } else if clean.hasPrefix("10") && clean.count >= 6 {
            var reassembled = ""
            let afterFF = String(clean.dropFirst(4))
            if afterFF.count >= 12 {
                reassembled += String(afterFF.prefix(12))
                var remainder = String(afterFF.dropFirst(12))
                var cfIndex = 1
                while !remainder.isEmpty {
                    let cfHeader = String(format: "2%1X", cfIndex % 16)
                    if remainder.hasPrefix(cfHeader) {
                        remainder = String(remainder.dropFirst(2))
                    }
                    let chunk = String(remainder.prefix(14))
                    reassembled += chunk
                    remainder = String(remainder.dropFirst(min(14, remainder.count)))
                    cfIndex += 1
                }
                clean = reassembled
            }
        }
        
        guard clean.hasPrefix("61") && clean.count >= 6 else { return }
        let localId = String(clean.dropFirst(2).prefix(2))
        let dataHex = String(clean.dropFirst(4))
        
        DispatchQueue.main.async {
            switch localId {
            case "40":
                let valHex = String(dataHex.prefix(2))
                let delta = (Int(valHex, radix: 16) ?? 128) - 128
                self.coCyl1 = "0x\(valHex) (\(delta >= 0 ? "+\(delta)" : "\(delta)"))"
                self.coCylindersStatus = "Cil #1: \(self.coCyl1) | Cil #2: \(self.coCyl2) | Cil #3: \(self.coCyl3)"
            case "41":
                let valHex = String(dataHex.prefix(2))
                let delta = (Int(valHex, radix: 16) ?? 128) - 128
                self.coCyl2 = "0x\(valHex) (\(delta >= 0 ? "+\(delta)" : "\(delta)"))"
                self.coCylindersStatus = "Cil #1: \(self.coCyl1) | Cil #2: \(self.coCyl2) | Cil #3: \(self.coCyl3)"
            case "42":
                let valHex = String(dataHex.prefix(2))
                let delta = (Int(valHex, radix: 16) ?? 128) - 128
                self.coCyl3 = "0x\(valHex) (\(delta >= 0 ? "+\(delta)" : "\(delta)"))"
                self.coCylindersStatus = "Cil #1: \(self.coCyl1) | Cil #2: \(self.coCyl2) | Cil #3: \(self.coCyl3)"
            case "54":
                // Apprendimento Minimo ISC (6 byte: 3 word da 16-bit centrati su 0x8000 = 32768)
                // Valore originale pre-reset: 9092 7F47 7F20 | Valore riappreso: 82F0 8435 8435 | Azzerato: 8000 8000 8000
                let w1 = String(dataHex.prefix(4))
                let w2 = String(dataHex.dropFirst(4).prefix(4))
                let w3 = String(dataHex.dropFirst(8).prefix(4))
                let isReset = (w1 == "8000" && w2 == "8000" && w3 == "8000")
                let stateTag = isReset
                    ? "⚠️ AZZERATO (Valori base 0x8000)"
                    : "✅ APPRESO REGOLARE"
                self.iscLearningStatus = "Cil #1: 0x\(w1) | Cil #2: 0x\(w2) | Cil #3: 0x\(w3)\nStato: \(stateTag)"
                
                // Calcolo compensazione depositi corpi farfallati rispetto allo zero di fabbrica 0x8000 (32768)
                // Escursione massima prima del limite superiore (Event Code 242 / Cod. 67 = 02): ±0x2000 (8192 step)
                let v1 = abs((Int(w1, radix: 16) ?? 0x8000) - 0x8000)
                let v2 = abs((Int(w2, radix: 16) ?? 0x8000) - 0x8000)
                let v3 = abs((Int(w3, radix: 16) ?? 0x8000) - 0x8000)
                let maxDelta = max(v1, max(v2, v3))
                self.lastISCMaxDelta = maxDelta
                let pct = min(100.0, (Double(maxDelta) / 8192.0) * 100.0)
                self.throttleDirtPercentage = pct
                
                if isReset {
                    self.throttleCleaningLevel = 0
                    self.throttleCleaningStatus = "⚪ Apprendimento appena azzerato (0%). Avvia il motore al minimo per rilevare lo stato dei corpi farfallati."
                } else if pct < 35.0 {
                    self.throttleCleaningLevel = 1
                    self.throttleCleaningStatus = String(format: "🟢 CORPI FARFALLATI PULITI (Compensazione ISC: %.1f%% — +%d step da 0x8000). Nessuna pulizia necessaria.", pct, maxDelta)
                } else if pct < 75.0 {
                    self.throttleCleaningLevel = 2
                    self.throttleCleaningStatus = String(format: "🟡 DEPOSITI MODERATI (Compensazione ISC: %.1f%% — +%d step da 0x8000). Pulizia consigliata al prossimo tagliando.", pct, maxDelta)
                } else {
                    self.throttleCleaningLevel = 3
                    self.throttleCleaningStatus = String(format: "🔴 PULIZIA NECESSARIA! (Compensazione ISC: %.1f%% — limite Cod. 242).", pct)
                }
            case "52":
                // Apprendimento Sonda Lambda O2 (Cod. 87)
                // Originale pre-reset: 0002 01FC 0255 000A | Valore azzerato: 0001 0200 0200 0001
                let _ = String(dataHex.prefix(4))
                let trim1 = String(dataHex.dropFirst(4).prefix(4))
                let trim2 = String(dataHex.dropFirst(8).prefix(4))
                let count = String(dataHex.dropFirst(12).prefix(4))
                let isReset = (trim1 == "0200" && trim2 == "0200")
                let stateTag = isReset
                    ? "⚠️ AZZERATO (0x0200 = Neutro Fabbrica)"
                    : "✅ APPRESO REGOLARE"
                self.o2LearningStatus = "Trim: 0x\(trim1) / 0x\(trim2) | Cicli: 0x\(count)\nStato: \(stateTag)"
            case "58":
                // Registro 0x58: <TargetISC 16-bit> <Flag Cod. 67 (00=Azzerato, 01=OK, 02=Pulizia Necessaria)> <Flag Cod. 87>
                let p1 = String(dataHex.prefix(4))
                let code67Flag = String(dataHex.dropFirst(4).prefix(4))
                let code87Flag = String(dataHex.dropFirst(8).prefix(4))
                self.o2LearningStatus += "\nParametri Reg. 0x58: Target 0x\(p1) (Flag Cod.67=\(code67Flag), Cod.87=\(code87Flag))"
                
                // Verifica flag ufficiale Yamaha Cod. 67 (Manuale pag. 3-8 e pag. 9-15: "02" -> Clean the throttle bodies)
                if code67Flag == "0002" {
                    self.throttleCleaningLevel = 3
                    self.throttleCleaningStatus = "🔴 PULIZIA CORPI FARFALLATI RICHIESTA DALLA ECU! (Cod. Diag. 67 = 02 — Manuale pag. 3-8: limite ISC raggiunto)."
                } else if code67Flag == "0001" && self.throttleCleaningLevel == 1 {
                    self.throttleCleaningStatus += " [Flag ECU Cod. 67 = 01 OK]"
                }
            default:
                break
            }
        }
    }
}
