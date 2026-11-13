package com.jabella78.yadiag.core

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothSocket
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.InputStream
import java.io.OutputStream
import java.nio.charset.StandardCharsets
import java.util.UUID

data class DiscoveredOBDDevice(
    val address: String,
    val name: String,
    val device: BluetoothDevice?,
    val isClassicSpp: Boolean = false,
    val rssi: Int = -60
) {
    val isClassicSPP: Boolean
        get() = isClassicSpp
}

/**
 * Gestore Bluetooth Dual-Mode (BLE GATT + Bluetooth Classic RFCOMM SPP) e Simulatore Virtuale OBD2 per Android.
 * Replica fedelmente il comportamento di BLEManager.swift su iOS aggiungendo il supporto nativo
 * per adattatori Bluetooth Classic (UniCarScan UCSI-2000/2100, OBDLink MX) diffusi su Android.
 */
@SuppressLint("MissingPermission")
class BLEManager(private val context: Context) {

    var isBluetoothOn by mutableStateOf(false)
        private set

    var isConnected by mutableStateOf(false)
        private set

    var isVirtualSimulator by mutableStateOf(false)
        private set

    var isScanning by mutableStateOf(false)
        private set

    val isSimulationMode: Boolean
        get() = isVirtualSimulator

    val connectedPeripheralName: String?
        get() = if (isConnected) connectedDeviceName else null

    val statusMessage: String
        get() = when {
            isVirtualSimulator -> connectedDeviceName
            isConnected -> connectedDeviceName
            isBluetoothOn -> "Bluetooth Ready (BLE + Classic SPP)"
            else -> "Bluetooth Off"
        }

    val onlyCertifiedAdapters: Boolean
        get() = showOnlyCertifiedAdapters

    fun updateCertifiedFilter(enabled: Boolean) = updateShowOnlyCertifiedAdapters(enabled)

    val discoveredPeripherals: List<DiscoveredOBDDevice>
        get() = discoveredDevices

    fun startScanning() = scan()
    fun stopScanning() = stopScan()

    fun toggleSimulationMode() {
        if (isVirtualSimulator) {
            stopVirtualSimulator()
        } else {
            startVirtualSimulator()
        }
    }

    val discoveredDevices = mutableStateListOf<DiscoveredOBDDevice>()

    var receivedData by mutableStateOf("")
        private set

    private val prefs = context.applicationContext.getSharedPreferences("yadiag_prefs", Context.MODE_PRIVATE)

    var showOnlyCertifiedAdapters by mutableStateOf(
        prefs.getBoolean("showOnlyCertifiedAdapters", true)
    )
        private set

    fun updateShowOnlyCertifiedAdapters(onlyCertified: Boolean) {
        showOnlyCertifiedAdapters = onlyCertified
        prefs.edit().putBoolean("showOnlyCertifiedAdapters", onlyCertified).apply()
        if (isBluetoothOn && !isConnected) {
            scan()
        }
    }

    var dataReceivedCallback: ((String) -> Unit)? = null

    // Parametri Simulatore OBD2 Virtuale (Banco Prova Senza Adattatore)
    var simulatedRPM: Int = 1350
    var simulatedSpeed: Int = 0
    var simulatedCoolantTemp: Int = 88
    var simulatedIAT: Int = 28
    var simulatedTPS: Int = 16
    val simulatedEngineDTCs = mutableListOf("P0115", "P0130")
    val simulatedABSDTCs = mutableListOf("41")
    var simulatedISCLearned: Boolean = true
    var simulatedO2Learned: Boolean = true
    private var virtualATH: Boolean = false
    private var virtualATSH: String = "7E0"

    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioScope = CoroutineScope(Dispatchers.IO)

    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter

    private var activeGatt: BluetoothGatt? = null
    private var txCharacteristic: BluetoothGattCharacteristic? = null
    private var rxCharacteristic: BluetoothGattCharacteristic? = null

    private var classicSocket: BluetoothSocket? = null
    private var classicOutStream: OutputStream? = null
    private var classicReadJob: Job? = null

    private var connectedDeviceRecord: DiscoveredOBDDevice? = null

    val connectedDeviceName: String
        get() {
            if (isVirtualSimulator) {
                return when (LocalizationManager.currentLanguage) {
                    AppLanguage.ITALIAN -> "Adattatore Virtuale UniCarScan (Simulatore)"
                    AppLanguage.FRENCH -> "Adaptateur Virtuel UniCarScan (Simulateur)"
                    AppLanguage.SPANISH -> "Adaptador Virtual UniCarScan (Simulador)"
                    AppLanguage.GERMAN -> "Virtueller UniCarScan-Adapter (Simulator)"
                    AppLanguage.ENGLISH -> "Virtual UniCarScan Adapter (Simulator)"
                }
            }
            return connectedDeviceRecord?.name ?: LocalizationManager.t("ble_device_default")
        }

    init {
        refreshBluetoothState()
    }

    fun refreshBluetoothState() {
        isBluetoothOn = bluetoothAdapter?.isEnabled == true
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            val dev = result?.device ?: return
            val name = dev.name ?: result.scanRecord?.deviceName ?: return
            if (name.isBlank()) return

            addDiscoveredCandidate(
                DiscoveredOBDDevice(
                    address = dev.address,
                    name = name,
                    device = dev,
                    isClassicSpp = false
                )
            )
        }
    }

    private fun addDiscoveredCandidate(candidate: DiscoveredOBDDevice) {
        val isCertified = isCertifiedAdapter(candidate.name)
        val isGeneric = isGenericOBDAdapter(candidate.name)

        if (showOnlyCertifiedAdapters) {
            if (!isCertified) return
        } else {
            if (!isCertified && !isGeneric) return
        }

        mainHandler.post {
            if (discoveredDevices.none { it.address == candidate.address }) {
                discoveredDevices.add(candidate)
            }
        }
    }

    fun scan() {
        refreshBluetoothState()
        if (!isBluetoothOn) return
        discoveredDevices.clear()
        isScanning = true

        // 1) Includi eventuali adattatori già associati via Bluetooth Classic (SPP) o Dual-Mode
        try {
            bluetoothAdapter?.bondedDevices?.forEach { bonded ->
                val bName = bonded.name ?: ""
                if (bName.isNotBlank()) {
                    val isBleCapable = bonded.type == BluetoothDevice.DEVICE_TYPE_LE ||
                            bonded.type == BluetoothDevice.DEVICE_TYPE_DUAL
                    addDiscoveredCandidate(
                        DiscoveredOBDDevice(
                            address = bonded.address,
                            name = bName,
                            device = bonded,
                            isClassicSpp = !isBleCapable
                        )
                    )
                }
            }
        } catch (_: SecurityException) {
        }

        // 2) Avvia scansione attiva BLE a bassa latenza
        try {
            val scanner = bluetoothAdapter?.bluetoothLeScanner ?: return
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()
            scanner.stopScan(scanCallback)
            scanner.startScan(null, settings, scanCallback)
        } catch (_: SecurityException) {
        }
    }

    fun stopScan() {
        isScanning = false
        try {
            bluetoothAdapter?.bluetoothLeScanner?.stopScan(scanCallback)
        } catch (_: Exception) {
        }
    }

    fun connect(target: DiscoveredOBDDevice) {
        if (isVirtualSimulator) {
            stopVirtualSimulator()
        }
        stopScan()
        val hwDevice = target.device ?: return
        connectedDeviceRecord = target

        if (target.isClassicSpp) {
            connectClassicSpp(hwDevice)
        } else {
            try {
                activeGatt?.close()
                activeGatt = hwDevice.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            } catch (_: SecurityException) {
            }
        }
    }

    private fun connectClassicSpp(device: BluetoothDevice) {
        classicReadJob?.cancel()
        classicReadJob = ioScope.launch {
            try {
                val sppUuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                val socket = device.createRfcommSocketToServiceRecord(sppUuid)
                socket.connect()
                classicSocket = socket
                classicOutStream = socket.outputStream
                mainHandler.post {
                    isConnected = true
                }

                val input: InputStream = socket.inputStream
                val buf = ByteArray(1024)
                while (isActive && socket.isConnected) {
                    val readCount = input.read(buf)
                    if (readCount > 0) {
                        val str = String(buf, 0, readCount, StandardCharsets.UTF_8)
                        mainHandler.post {
                            receivedData += str
                            dataReceivedCallback?.invoke(str)
                        }
                    } else if (readCount < 0) {
                        break
                    }
                }
            } catch (_: Exception) {
                // Se il socket RFCOMM fallisce su un adattatore Dual-Mode, tenta fallback su GATT BLE
                mainHandler.post {
                    try {
                        activeGatt = device.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
                    } catch (_: Exception) {
                        isConnected = false
                    }
                }
            }
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                mainHandler.post {
                    isConnected = true
                }
                // Richiede MTU estesa a 512 byte per evitare il troncamento dei frame multipli ISO-TP dell'ABS
                try {
                    gatt.requestMtu(512)
                } catch (_: Exception) {
                    gatt.discoverServices()
                }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                mainHandler.post {
                    isConnected = false
                    connectedDeviceRecord = null
                    txCharacteristic = null
                    rxCharacteristic = null
                }
                gatt.close()
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            gatt.discoverServices()
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) return
            val cccdUuid = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

            for (service in gatt.services) {
                for (char in service.characteristics) {
                    val props = char.properties
                    val canNotify = (props and BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0 ||
                            (props and BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0
                    val canWrite = (props and BluetoothGattCharacteristic.PROPERTY_WRITE) != 0 ||
                            (props and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0

                    if (canNotify && rxCharacteristic == null) {
                        rxCharacteristic = char
                        gatt.setCharacteristicNotification(char, true)
                        val descriptor = char.getDescriptor(cccdUuid)
                        if (descriptor != null) {
                            descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                            gatt.writeDescriptor(descriptor)
                        }
                    }
                    if (canWrite && txCharacteristic == null) {
                        txCharacteristic = char
                    }
                }
            }
        }

        @Deprecated("Deprecated in Java")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            val bytes = characteristic.value ?: return
            val text = String(bytes, StandardCharsets.UTF_8)
            mainHandler.post {
                receivedData += text
                dataReceivedCallback?.invoke(text)
            }
        }
    }

    fun startVirtualSimulator() {
        isVirtualSimulator = true
        isConnected = true
        simulatedEngineDTCs.clear()
        simulatedEngineDTCs.addAll(listOf("P0115", "P0130"))
        simulatedABSDTCs.clear()
        simulatedABSDTCs.add("41")
        simulatedISCLearned = true
        simulatedO2Learned = true
        stopScan()
        discoveredDevices.clear()
    }

    fun stopVirtualSimulator() {
        isVirtualSimulator = false
        isConnected = false
        virtualATH = false
        virtualATSH = "7E0"
    }

    fun disconnect() {
        if (isVirtualSimulator) {
            stopVirtualSimulator()
            return
        }
        classicReadJob?.cancel()
        try {
            classicSocket?.close()
        } catch (_: Exception) {
        }
        classicSocket = null
        classicOutStream = null

        try {
            activeGatt?.disconnect()
            activeGatt?.close()
        } catch (_: Exception) {
        }
        activeGatt = null
        txCharacteristic = null
        rxCharacteristic = null
        connectedDeviceRecord = null
        isConnected = false
    }

    fun sendCommand(command: String) {
        if (isVirtualSimulator) {
            handleVirtualSimulatorCommand(command)
            return
        }
        if (!isConnected) return
        val fullCommand = if (command.endsWith("\r")) command else "$command\r"
        val bytes = fullCommand.toByteArray(StandardCharsets.UTF_8)

        // 1) Se connesso in modalità RFCOMM Classic SPP
        val out = classicOutStream
        if (out != null) {
            ioScope.launch {
                try {
                    out.write(bytes)
                    out.flush()
                } catch (_: Exception) {
                }
            }
            return
        }

        // 2) Se connesso in modalità BLE GATT
        val gatt = activeGatt ?: return
        val tx = txCharacteristic ?: return
        try {
            tx.writeType = if ((tx.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0) {
                BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
            } else {
                BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            }
            tx.value = bytes
            gatt.writeCharacteristic(tx)
        } catch (_: Exception) {
        }
    }

    private fun handleVirtualSimulatorCommand(rawCommand: String) {
        val clean = rawCommand.trim().replace(" ", "").uppercase()

        // Simula la latenza fisica UART / CAN Bus (35ms)
        ioScope.launch {
            delay(35)
            if (!isVirtualSimulator) return@launch

            val response: String = when {
                clean == "ATZ" -> "ELM327 v1.5 (Simulated)\r\r>"
                clean == "ATE0" || clean == "ATE1" -> "OK\r\r>"
                clean == "ATL0" || clean == "ATL1" -> "OK\r\r>"
                clean == "ATH1" -> {
                    virtualATH = true
                    "OK\r\r>"
                }
                clean == "ATH0" -> {
                    virtualATH = false
                    "OK\r\r>"
                }
                clean.startsWith("ATSH") -> {
                    val header = clean.drop(4)
                    virtualATSH = header.ifEmpty { "7E0" }
                    "OK\r\r>"
                }
                clean.startsWith("ATCRA") || clean.startsWith("ATFCS") || clean.startsWith("ATSP") ||
                        clean.startsWith("ATST") || clean.startsWith("ATAT") || clean.startsWith("ATAL") ||
                        clean.startsWith("ATIB") || clean.startsWith("ATMA") -> "OK\r\r>"
                clean == "STDI" -> "UniCarScan BT 2.4 (Simulated)\r\r>"
                clean == "ATRV" -> "13.8V\r\r>"
                clean.startsWith("AT") -> "OK\r\r>"

                // OBD2 Mode 01 - Telemetria Live PIDs
                clean == "0100" -> if (virtualATH) "7E8 06 41 00 BE 3F B8 13\r\r>" else "41 00 BE 3F B8 13\r\r>"
                clean == "0120" -> if (virtualATH) "7E8 06 41 20 80 00 00 00\r\r>" else "41 20 80 00 00 00\r\r>"
                clean == "010C" -> { // RPM
                    val v = maxOf(0, simulatedRPM * 4)
                    val hex = String.format("%04X", v)
                    val b1 = hex.take(2)
                    val b2 = hex.takeLast(2)
                    if (virtualATH) "7E8 04 41 0C $b1 $b2\r\r>" else "41 0C $b1 $b2\r\r>"
                }
                clean == "010D" -> { // Velocità km/h
                    val hex = String.format("%02X", maxOf(0, simulatedSpeed))
                    if (virtualATH) "7E8 03 41 0D $hex\r\r>" else "41 0D $hex\r\r>"
                }
                clean == "0105" -> { // Temperatura Liquido Refrigerante
                    val hex = String.format("%02X", minOf(255, maxOf(0, simulatedCoolantTemp + 40)))
                    if (virtualATH) "7E8 03 41 05 $hex\r\r>" else "41 05 $hex\r\r>"
                }
                clean == "010F" -> { // Temperatura Aria Aspirata (IAT)
                    val hex = String.format("%02X", minOf(255, maxOf(0, simulatedIAT + 40)))
                    if (virtualATH) "7E8 03 41 0F $hex\r\r>" else "41 0F $hex\r\r>"
                }
                clean == "0111" -> { // Posizione Farfalla (TPS)
                    val tpsByte = minOf(255, maxOf(0, (simulatedTPS.toDouble() * 255.0 / 100.0).toInt()))
                    val hex = String.format("%02X", tpsByte)
                    if (virtualATH) "7E8 03 41 11 $hex\r\r>" else "41 11 $hex\r\r>"
                }
                clean == "010B" -> if (virtualATH) "7E8 03 41 0B 3E\r\r>" else "41 0B 3E\r\r>"
                clean == "0104" -> if (virtualATH) "7E8 03 41 04 35\r\r>" else "41 04 35\r\r>"
                clean == "010E" -> if (virtualATH) "7E8 03 41 0E 58\r\r>" else "41 0E 58\r\r>"
                clean == "0114" -> if (virtualATH) "7E8 04 41 14 80 80\r\r>" else "41 14 80 80\r\r>"
                clean == "0142" -> if (virtualATH) "7E8 04 41 42 35 E8\r\r>" else "41 42 35 E8\r\r>"

                // Diagnostica Errori Motore Mode 03 / Mode 04
                clean == "03" -> {
                    if (simulatedEngineDTCs.isEmpty()) {
                        if (virtualATH) "7E8 02 43 00\r\r>" else "43 00\r\r>"
                    } else {
                        if (virtualATH) "7E8 06 43 02 01 15 01 30\r\r>" else "43 02 01 15 01 30\r\r>"
                    }
                }
                clean == "04" -> {
                    simulatedEngineDTCs.clear()
                    if (virtualATH) "7E8 01 44\r\r>" else "44\r\r>"
                }
                clean == "07" -> if (virtualATH) "7E8 02 47 00\r\r>" else "47 00\r\r>"

                // Diagnostica ABS (UDS / KWP su 7E3 / 7EB)
                clean == "3E00" || clean == "3E" -> if (virtualATH) "7EB 02 7E 00\r\r>" else "7E 00\r\r>"
                clean == "1003" -> {
                    val sender = if (virtualATSH == "7E3" || virtualATSH == "7EB") "7EB" else "7E8"
                    if (virtualATH) "$sender 02 50 03\r\r>" else "50 03\r\r>"
                }
                clean == "1001" -> {
                    val sender = if (virtualATSH == "7E3" || virtualATSH == "7EB") "7EB" else "7E8"
                    if (virtualATH) "$sender 02 50 01\r\r>" else "50 01\r\r>"
                }
                clean.startsWith("1800FF00") || clean.startsWith("1902FF") -> {
                    if (simulatedABSDTCs.isEmpty()) {
                        if (virtualATH) "7EB 03 58 00\r\r>" else "58 00\r\r>"
                    } else {
                        // Risposta KWP2000 0x58 con Codice ABS 41 (Sensore velocità ruota anteriore)
                        if (virtualATH) "7EB 06 58 01 5E 41 20\r\r>" else "58 01 5E 41 20\r\r>"
                    }
                }
                clean == "14FFFFFF" -> {
                    simulatedABSDTCs.clear()
                    if (virtualATH) "7EB 04 54 FF FF FF\r\r>" else "54 FF FF FF\r\r>"
                }

                // Attuatori & Registri Apprendimento (7E0 / 7E8)
                clean == "2154" -> {
                    if (simulatedISCLearned) {
                        if (virtualATH) "7E8 07 61 54 82 F0 84 35 84 35\r\r>" else "61 54 82 F0 84 35 84 35\r\r>"
                    } else {
                        if (virtualATH) "7E8 07 61 54 80 00 80 00 80 00\r\r>" else "61 54 80 00 80 00 80 00\r\r>"
                    }
                }
                clean == "3B5401" -> {
                    simulatedISCLearned = false
                    if (virtualATH) "7E8 03 7B 54 01\r\r>" else "7B 54 01\r\r>"
                }
                clean == "2152" -> {
                    if (simulatedO2Learned) {
                        if (virtualATH) "7E8 05 61 52 00 02 01 FC 02 55 00 0A\r\r>" else "61 52 00 02 01 FC 02 55 00 0A\r\r>"
                    } else {
                        if (virtualATH) "7E8 05 61 52 00 01 02 00 02 00 00 01\r\r>" else "61 52 00 01 02 00 02 00 00 01\r\r>"
                    }
                }
                clean == "3B5201" || clean == "3B5801" -> {
                    simulatedO2Learned = false
                    if (virtualATH) "7E8 03 7B 52 01\r\r>" else "7B 52 01\r\r>"
                }
                clean == "2140" -> if (virtualATH) "7E8 03 61 40 82\r\r>" else "61 40 82\r\r>"
                clean == "2141" -> if (virtualATH) "7E8 03 61 41 80\r\r>" else "61 41 80\r\r>"
                clean == "2142" -> if (virtualATH) "7E8 03 61 42 81\r\r>" else "61 42 81\r\r>"
                clean == "2158" -> if (virtualATH) "7E8 07 61 58 05 46 00 01 00 01\r\r>" else "61 58 05 46 00 01 00 01\r\r>"
                clean.startsWith("3170") -> if (virtualATH) "7EB 04 71 70 01 00\r\r>" else "71 70 01 00\r\r>"
                else -> "NO DATA\r\r>"
            }

            mainHandler.post {
                receivedData += response
                dataReceivedCallback?.invoke(response)
            }
        }
    }

    companion object {
        val certifiedKeywords = listOf(
            "unicarscan", "ucsi",
            "vlinker", "vgate",
            "obdlink",
            "veepeak", "obdcheck",
            "carista"
        )

        private val genericKeywords = listOf(
            "obd", "elm", "vlink", "viecar", "konnwei", "bafx", "diag"
        )

        fun isCertifiedAdapter(name: String): Boolean {
            val lower = name.lowercase()
            return certifiedKeywords.any { lower.contains(it) }
        }

        fun isGenericOBDAdapter(name: String): Boolean {
            val lower = name.lowercase()
            return genericKeywords.any { lower.contains(it) }
        }
    }
}
