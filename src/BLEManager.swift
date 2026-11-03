import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isBluetoothOn = false
    @Published var isConnected = false
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
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func sendCommand(_ command: String) {
        guard centralManager.state == .poweredOn, isConnected, let peripheral = connectedPeripheral, let tx = txCharacteristic else { return }
        let fullCommand = command.hasSuffix("\r") ? command : command + "\r"
        if let data = fullCommand.data(using: .utf8) {
            let type: CBCharacteristicWriteType = tx.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
            peripheral.writeValue(data, for: tx, type: type)
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
