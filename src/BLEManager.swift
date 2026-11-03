import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isBluetoothOn = false
    @Published var isConnected = false
    @Published var isVirtualSimulator = false
    @Published var discoveredPeripherals = [CBPeripheral]()
    @Published var receivedData = ""
    @Published var showOnlyCertifiedAdapters: Bool = true {
        didSet {
            UserDefaults.standard.set(showOnlyCertifiedAdapters, forKey: "showOnlyCertifiedAdapters")
            if centralManager != nil && centralManager.state == .poweredOn {
                scan()
            }
        }
    }
    
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var txCharacteristic: CBCharacteristic?
    var rxCharacteristic: CBCharacteristic?
    
    var dataReceivedCallback: ((String) -> Void)?
    
    // Parametri Simulatore OBD2 Virtuale (Banco Prova Senza Adattatore)
    var simulatedRPM: Int = 1350
    var simulatedSpeed: Int = 0
    var simulatedCoolantTemp: Int = 88
    var simulatedIAT: Int = 28
    var simulatedTPS: Int = 16
    var simulatedEngineDTCs: [String] = ["P0115", "P0130"]
    var simulatedABSDTCs: [String] = ["41"]
    var simulatedISCLearned: Bool = true
    var simulatedO2Learned: Bool = true
    private var virtualATH: Bool = false
    private var virtualATSH: String = "7E0"
    
    var connectedDeviceName: String {
        if isVirtualSimulator {
            switch LocalizationManager.shared.currentLanguage {
            case .italian: return "Adattatore Virtuale UniCarScan (Simulatore)"
            case .french: return "Adaptateur Virtuel UniCarScan (Simulateur)"
            case .spanish: return "Adaptador Virtual UniCarScan (Simulador)"
            case .german: return "Virtueller UniCarScan-Adapter (Simulator)"
            case .english: return "Virtual UniCarScan Adapter (Simulator)"
            }
        }
        return connectedPeripheral?.name ?? LocalizationManager.shared.t("ble_device_default")
    }

    static let certifiedKeywords = [
        "unicarscan", "ucsi",
        "vlinker", "vgate",
        "obdlink",
        "veepeak", "obdcheck",
        "carista"
    ]
    
    static func isCertifiedAdapter(name: String) -> Bool {
        let lower = name.lowercased()
        return certifiedKeywords.contains { lower.contains($0) }
    }
    
    static func isGenericOBDAdapter(name: String) -> Bool {
        let lower = name.lowercased()
        let genericKeywords = ["obd", "elm", "vlink", "viecar", "konnwei", "bafx", "diag"]
        return genericKeywords.contains { lower.contains($0) }
    }

    override init() {
        super.init()
        if UserDefaults.standard.object(forKey: "showOnlyCertifiedAdapters") != nil {
            self.showOnlyCertifiedAdapters = UserDefaults.standard.bool(forKey: "showOnlyCertifiedAdapters")
        }
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scan() {
        guard centralManager.state == .poweredOn else { return }
        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func connect(peripheral: CBPeripheral) {
        if isVirtualSimulator {
            stopVirtualSimulator()
        }
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func startVirtualSimulator() {
        isVirtualSimulator = true
        isConnected = true
        simulatedEngineDTCs = ["P0115", "P0130"]
        simulatedABSDTCs = ["41"]
        simulatedISCLearned = true
        simulatedO2Learned = true
        if centralManager != nil {
            centralManager.stopScan()
        }
        discoveredPeripherals.removeAll()
    }
    
    func stopVirtualSimulator() {
        isVirtualSimulator = false
        isConnected = false
        virtualATH = false
        virtualATSH = "7E0"
    }
    
    func disconnect() {
        if isVirtualSimulator {
            stopVirtualSimulator()
            return
        }
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func sendCommand(_ command: String) {
        if isVirtualSimulator {
            handleVirtualSimulatorCommand(command)
            return
        }
        guard centralManager.state == .poweredOn, isConnected, let peripheral = connectedPeripheral, let tx = txCharacteristic else { return }
        let fullCommand = command.hasSuffix("\r") ? command : command + "\r"
        if let data = fullCommand.data(using: .utf8) {
            let type: CBCharacteristicWriteType = tx.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
            peripheral.writeValue(data, for: tx, type: type)
        }
    }
    
    private func handleVirtualSimulatorCommand(_ rawCommand: String) {
        let clean = rawCommand.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "").uppercased()
        
        // Simula la latenza fisica UART / CAN Bus (35ms)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.035) { [weak self] in
            guard let self = self, self.isVirtualSimulator else { return }
            
            var response = ""
            
            if clean == "ATZ" {
                response = "ELM327 v1.5 (Simulated)\r\r>"
            } else if clean == "ATE0" || clean == "ATE1" {
                response = "OK\r\r>"
            } else if clean == "ATL0" || clean == "ATL1" {
                response = "OK\r\r>"
            } else if clean == "ATH1" {
                self.virtualATH = true
                response = "OK\r\r>"
            } else if clean == "ATH0" {
                self.virtualATH = false
                response = "OK\r\r>"
            } else if clean.hasPrefix("ATSH") {
                let header = String(clean.dropFirst(4))
                self.virtualATSH = header.isEmpty ? "7E0" : header
                response = "OK\r\r>"
            } else if clean.hasPrefix("ATCRA") || clean.hasPrefix("ATFCS") || clean.hasPrefix("ATSP") || clean.hasPrefix("ATST") || clean.hasPrefix("ATAT") || clean.hasPrefix("ATAL") || clean.hasPrefix("ATIB") || clean.hasPrefix("ATMA") {
                response = "OK\r\r>"
            } else if clean == "STDI" {
                response = "UniCarScan BT 2.4 (Simulated)\r\r>"
            } else if clean == "ATRV" {
                response = "13.8V\r\r>"
            } else if clean.hasPrefix("AT") {
                response = "OK\r\r>"
            }
            // OBD2 Mode 01 - Telemetria Live PIDs
            else if clean == "0100" {
                response = self.virtualATH ? "7E8 06 41 00 BE 3F B8 13\r\r>" : "41 00 BE 3F B8 13\r\r>"
            } else if clean == "0120" {
                response = self.virtualATH ? "7E8 06 41 20 80 00 00 00\r\r>" : "41 20 80 00 00 00\r\r>"
            } else if clean == "010C" { // RPM
                let val = max(0, self.simulatedRPM * 4)
                let hex = String(format: "%04X", val)
                let b1 = String(hex.prefix(2))
                let b2 = String(hex.suffix(2))
                response = self.virtualATH ? "7E8 04 41 0C \(b1) \(b2)\r\r>" : "41 0C \(b1) \(b2)\r\r>"
            } else if clean == "010D" { // Velocità km/h
                let hex = String(format: "%02X", max(0, self.simulatedSpeed))
                response = self.virtualATH ? "7E8 03 41 0D \(hex)\r\r>" : "41 0D \(hex)\r\r>"
            } else if clean == "0105" { // Temperatura Liquido Refrigerante
                let hex = String(format: "%02X", min(255, max(0, self.simulatedCoolantTemp + 40)))
                response = self.virtualATH ? "7E8 03 41 05 \(hex)\r\r>" : "41 05 \(hex)\r\r>"
            } else if clean == "010F" { // Temperatura Aria Aspirata (IAT)
                let hex = String(format: "%02X", min(255, max(0, self.simulatedIAT + 40)))
                response = self.virtualATH ? "7E8 03 41 0F \(hex)\r\r>" : "41 0F \(hex)\r\r>"
            } else if clean == "0111" { // Posizione Farfalla (TPS)
                let tpsByte = min(255, max(0, Int(Double(self.simulatedTPS) * 255.0 / 100.0)))
                let hex = String(format: "%02X", tpsByte)
                response = self.virtualATH ? "7E8 03 41 11 \(hex)\r\r>" : "41 11 \(hex)\r\r>"
            } else if clean == "010B" { // Pressione Aspirazione MAP (kPa)
                response = self.virtualATH ? "7E8 03 41 0B 3E\r\r>" : "41 0B 3E\r\r>"
            } else if clean == "0104" { // Carico Motore Calcolato
                response = self.virtualATH ? "7E8 03 41 04 35\r\r>" : "41 04 35\r\r>"
            } else if clean == "010E" { // Anticipo Accensione
                response = self.virtualATH ? "7E8 03 41 0E 58\r\r>" : "41 0E 58\r\r>"
            } else if clean == "0114" { // Tensione Sonda Lambda O2
                response = self.virtualATH ? "7E8 04 41 14 80 80\r\r>" : "41 14 80 80\r\r>"
            } else if clean == "0142" { // Tensione Modulo Controllo Batteria
                response = self.virtualATH ? "7E8 04 41 42 35 E8\r\r>" : "41 42 35 E8\r\r>"
            }
            // Diagnostica Errori Motore Mode 03 / Mode 04
            else if clean == "03" {
                if self.simulatedEngineDTCs.isEmpty {
                    response = self.virtualATH ? "7E8 02 43 00\r\r>" : "43 00\r\r>"
                } else {
                    // Restituisce codici simulati: P0115 (0115) e P0130 (0130)
                    response = self.virtualATH ? "7E8 06 43 02 01 15 01 30\r\r>" : "43 02 01 15 01 30\r\r>"
                }
            } else if clean == "04" {
                self.simulatedEngineDTCs.removeAll()
                response = self.virtualATH ? "7E8 01 44\r\r>" : "44\r\r>"
            } else if clean == "07" {
                response = self.virtualATH ? "7E8 02 47 00\r\r>" : "47 00\r\r>"
            }
            // Diagnostica ABS (UDS / KWP su 7E3 / 7EB)
            else if clean == "3E00" || clean == "3E" {
                response = self.virtualATH ? "7EB 02 7E 00\r\r>" : "7E 00\r\r>"
            } else if clean == "1003" {
                let sender = (self.virtualATSH == "7E3" || self.virtualATSH == "7EB") ? "7EB" : "7E8"
                response = self.virtualATH ? "\(sender) 02 50 03\r\r>" : "50 03\r\r>"
            } else if clean == "1001" {
                let sender = (self.virtualATSH == "7E3" || self.virtualATSH == "7EB") ? "7EB" : "7E8"
                response = self.virtualATH ? "\(sender) 02 50 01\r\r>" : "50 01\r\r>"
            } else if clean.hasPrefix("1800FF00") || clean.hasPrefix("1902FF") {
                if self.simulatedABSDTCs.isEmpty {
                    response = self.virtualATH ? "7EB 03 59 02 00\r\r>" : "59 02 00\r\r>"
                } else {
                    // Codice ABS 41 (Sensore velocità ruota anteriore anomalo)
                    response = self.virtualATH ? "7EB 06 59 02 00 41 28 08\r\r>" : "59 02 00 41 28 08\r\r>"
                }
            } else if clean == "14FFFFFF" {
                self.simulatedABSDTCs.removeAll()
                response = self.virtualATH ? "7EB 04 54 FF FF FF\r\r>" : "54 FF FF FF\r\r>"
            }
            // Attuatori & Registri Apprendimento (7E0 / 7E8)
            else if clean == "2154" { // Lettura registro 0x54 (Minimo ISC)
                if self.simulatedISCLearned {
                    response = self.virtualATH ? "7E8 07 61 54 82 F0 84 35\r\r>" : "61 54 82 F0 84 35\r\r>"
                } else {
                    response = self.virtualATH ? "7E8 07 61 54 80 00 80 00\r\r>" : "61 54 80 00 80 00\r\r>"
                }
            } else if clean == "3B5401" { // Reset registro 0x54 (Minimo ISC)
                self.simulatedISCLearned = false
                response = self.virtualATH ? "7E8 03 7B 54 01\r\r>" : "7B 54 01\r\r>"
            } else if clean == "2152" { // Lettura registro 0x52 (Sonda Lambda O2)
                if self.simulatedO2Learned {
                    response = self.virtualATH ? "7E8 05 61 52 01 FC 02 55\r\r>" : "61 52 01 FC 02 55\r\r>"
                } else {
                    response = self.virtualATH ? "7E8 05 61 52 02 00 02 00\r\r>" : "61 52 02 00 02 00\r\r>"
                }
            } else if clean == "3B5201" { // Reset registro 0x52 (Sonda Lambda O2)
                self.simulatedO2Learned = false
                response = self.virtualATH ? "7E8 03 7B 52 01\r\r>" : "7B 52 01\r\r>"
            } else if clean == "2140" { // CO Cilindro 1
                response = self.virtualATH ? "7E8 03 61 40 82\r\r>" : "61 40 82\r\r>"
            } else if clean == "2141" { // CO Cilindro 2
                response = self.virtualATH ? "7E8 03 61 41 80\r\r>" : "61 41 80\r\r>"
            } else if clean == "2142" { // CO Cilindro 3
                response = self.virtualATH ? "7E8 03 61 42 81\r\r>" : "61 42 81\r\r>"
            } else if clean == "2158" {
                response = self.virtualATH ? "7E8 04 61 58 00 00\r\r>" : "61 58 00 00\r\r>"
            } else if clean.hasPrefix("3170") { // Routine Test Idraulico Pompa ABS
                response = self.virtualATH ? "7EB 04 71 70 01 00\r\r>" : "71 70 01 00\r\r>"
            } else {
                response = "NO DATA\r\r>"
            }
            
            DispatchQueue.main.async {
                self.receivedData += response
                self.dataReceivedCallback?(response)
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothOn = central.state == .poweredOn
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, !name.isEmpty else { return }
        
        let isCertified = BLEManager.isCertifiedAdapter(name: name)
        let isGeneric = BLEManager.isGenericOBDAdapter(name: name)
        
        if showOnlyCertifiedAdapters {
            // Filtro predefinito: mostra solo adattatori ad alte prestazioni verificati (UniCarScan, vLinker, OBDLink, Veepeak, Carista)
            guard isCertified else { return }
        } else {
            // Modalità estesa: mostra certificati e qualsiasi scanner diagnostico OBDII generico
            guard isCertified || isGeneric else { return }
        }
        
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        txCharacteristic = nil
        rxCharacteristic = nil
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            if char.properties.contains(.notify) || char.properties.contains(.indicate) {
                rxCharacteristic = char
                peripheral.setNotifyValue(true, for: char)
            }
            if char.properties.contains(.write) || char.properties.contains(.writeWithoutResponse) {
                txCharacteristic = char
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedData += string
                self.dataReceivedCallback?(string)
            }
        }
    }
}
