package com.jabella78.yadiag.core

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.nio.charset.StandardCharsets
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.Timer
import java.util.UUID
import kotlin.concurrent.scheduleAtFixedRate
import kotlin.math.abs

data class TerminalLine(
    val id: String = UUID.randomUUID().toString(),
    val text: String
)

enum class DiagnosticTargetECU(val rawValue: String) {
    ENGINE("engine"),
    ABS("abs");

    fun name(forLang: AppLanguage): String = when (this) {
        ENGINE -> when (forLang) {
            AppLanguage.ENGLISH -> "Engine (FI ECU)"
            AppLanguage.ITALIAN -> "Motore (FI ECU)"
            AppLanguage.FRENCH -> "Moteur (FI ECU)"
            AppLanguage.SPANISH -> "Motor (FI ECU)"
            AppLanguage.GERMAN -> "Motor (FI ECU)"
        }
        ABS -> when (forLang) {
            AppLanguage.ENGLISH -> "Brakes (ABS ECU)"
            AppLanguage.ITALIAN -> "Freni (ABS ECU)"
            AppLanguage.FRENCH -> "Freins (ABS ECU)"
            AppLanguage.SPANISH -> "Frenos (ABS ECU)"
            AppLanguage.GERMAN -> "Bremsen (ABS ECU)"
        }
    }
}

data class DTCLocalizedEntry(
    val en: String,
    val it: String,
    val fr: String? = null,
    val es: String? = null,
    val de: String? = null
) {
    fun localized(): String = when (LocalizationManager.currentLanguage) {
        AppLanguage.ITALIAN -> it
        AppLanguage.FRENCH -> fr ?: en
        AppLanguage.SPANISH -> es ?: en
        AppLanguage.GERMAN -> de ?: en
        AppLanguage.ENGLISH -> en
    }
}

class OBD2Manager(
    private val context: Context,
    val bleManager: BLEManager
) {
    var rpm by mutableIntStateOf(0)
        private set
    var speed by mutableIntStateOf(0)
        private set
    var temp by mutableIntStateOf(0)
        private set
    var o2Voltage by mutableDoubleStateOf(0.0)
        private set
    var tps by mutableIntStateOf(0)
        private set
    var iat by mutableIntStateOf(0)
        private set
    var engineLoad by mutableIntStateOf(0)
        private set
    var map by mutableIntStateOf(0)
        private set
    var timingAdvance by mutableIntStateOf(0)
        private set
    var batteryVoltage by mutableStateOf("0.0V")
        private set

    val dtcCodes = mutableStateListOf<String>()
    val absDtcCodes = mutableStateListOf<String>()

    var selectedECU by mutableStateOf(DiagnosticTargetECU.ENGINE)
    var absCanHeader by mutableStateOf("7E3")

    val terminalOutput = mutableStateListOf<TerminalLine>()
    var isRecording by mutableStateOf(false)
        private set
    var isPollingPaused by mutableStateOf(true) // In pausa di default all'avvio
        private set
    var isScanningABS by mutableStateOf(false)
        private set
    var isDemoMode by mutableStateOf(false)
        private set

    val lastABSRawTrace = mutableStateListOf<String>()
    var actuatorStatusMessage by mutableStateOf("Ready.")
        private set
    var throttleDirtPercentage by mutableDoubleStateOf(0.0)
        private set
    var throttleCleaningLevel by mutableIntStateOf(0) // 0=N/D, 1=OK, 2=Medi, 3=Pulizia Necessaria
        private set
    var lastISCMaxDelta by mutableIntStateOf(0)
        private set
    var iscW1 by mutableStateOf("--")
        private set
    var iscW2 by mutableStateOf("--")
        private set
    var iscW3 by mutableStateOf("--")
        private set
    var isISCLearningReset by mutableStateOf(false)
        private set
    var o2Trim1 by mutableStateOf("--")
        private set
    var o2Trim2 by mutableStateOf("--")
        private set
    var o2Cycles by mutableStateOf("--")
        private set
    var isO2Reset by mutableStateOf(false)
        private set
    var coCyl1 by mutableStateOf("--")
        private set
    var coCyl2 by mutableStateOf("--")
        private set
    var coCyl3 by mutableStateOf("--")
        private set
    var isReadingEngineParams by mutableStateOf(false)
        private set
    var iscTarget by mutableStateOf("")
        private set
    var ecuCode67Flag by mutableStateOf("")
        private set
    var ecuCode87Flag by mutableStateOf("")
        private set

    var currentTelemetryFile: File? by mutableStateOf(null)
        private set

    var recordedRowsCount by mutableIntStateOf(0)
        private set

    var isTerminalPaused by mutableStateOf(false)
        private set

    var lastVerificationTimestamp: Date? by mutableStateOf(null)
        private set

    val ecuStatus: String
        get() = when {
            bleManager.isVirtualSimulator -> "Simulated CAN ECU Active"
            bleManager.isConnected -> "ISO 15765-4 CAN / KWP2000 Ready"
            else -> "Disconnected"
        }

    val isStreaming: Boolean
        get() = !isPollingPaused

    fun toggleLiveStream() = toggleTelemetry()

    val isRecordingCSV: Boolean
        get() = isRecording

    fun getCSVFile(): File {
        return currentTelemetryFile ?: File(context.filesDir, "telemetry.csv")
    }

    val calculatedGear: String
        get() = currentGear

    val o2SensorVoltage: Double
        get() = o2Voltage

    val estimatedAFR: Double
        get() = if (o2Voltage <= 0.0) 14.7 else (17.2 - (o2Voltage * 5.0)).coerceIn(11.0, 18.5)

    val coolantTemp: Int
        get() = temp

    val throttlePos: Double
        get() = tps.toDouble()

    val intakeTemp: Int
        get() = iat

    val intakePressure: Int
        get() = map

    val batteryVoltageDouble: Double
        get() = batteryVoltage.replace("V", "", ignoreCase = true).trim().toDoubleOrNull() ?: 0.0

    val activeDTCs: List<String>
        get() = dtcCodes.filter {
            !it.startsWith("✅") && !it.startsWith("🟢") && !it.contains("Lettura") && !it.contains("Reading") && !it.contains("Nessun") && !it.contains("No fault")
        }.map { line ->
            val regex = Regex("([PCBU][0-9A-F]{4})")
            regex.find(line)?.value ?: line
        }

    val absDTCs: List<String>
        get() = absDtcCodes.filter {
            it.contains("ABS") && !it.startsWith("✅") && !it.startsWith("🟢") && !it.startsWith("⏳") && !it.startsWith("🔍")
        }

    val dtcDescriptions: Map<String, String>
        get() {
            val mapOut = mutableMapOf<String, String>()
            for ((k, v) in dtcDatabase) {
                mapOut[k] = v.localized()
            }
            for (line in dtcCodes) {
                val regex = Regex("([PCBU][0-9A-F]{4})\\s*:\\s*(.*)")
                val m = regex.find(line)
                if (m != null) {
                    mapOut[m.groupValues[1]] = m.groupValues[2]
                }
            }
            for (line in absDtcCodes) {
                mapOut[line] = line
            }
            return mapOut
        }

    val absTargetHeader: String
        get() = absCanHeader

    fun updateAbsHeader(addr: String) {
        absCanHeader = addr
    }

    fun autoScanABSAddresses() = scanABSAddresses()

    fun lookupManualABSCode(input: String) {
        val res = lookupABSCode(input)
        if (!absDtcCodes.contains(res)) {
            absDtcCodes.add(0, res)
        }
    }

    fun scanDTCs() {
        selectedECU = DiagnosticTargetECU.ENGINE
        readErrors()
    }

    fun scanABSDTCs() {
        selectedECU = DiagnosticTargetECU.ABS
        readABSErrors()
    }

    fun clearDTCs() {
        selectedECU = DiagnosticTargetECU.ENGINE
        clearErrors()
    }

    fun clearABSDTCs() {
        selectedECU = DiagnosticTargetECU.ABS
        clearABSErrors()
    }

    val iscLearningValue: Double?
        get() = if (iscW1 == "--") null else throttleDirtPercentage

    val o2CompensationValue: Double?
        get() {
            if (o2Trim1 == "--") return null
            val v = o2Trim1.toIntOrNull(16) ?: return 100.0
            return (v.toDouble() / 512.0) * 100.0
        }

    val coAdjustmentValues: Map<Int, Int>
        get() {
            if (coCyl1 == "--") return emptyMap()
            fun parseDelta(s: String): Int {
                val hexPart = s.substringAfter("0x").substringBefore(" ").trim()
                val v = hexPart.toIntOrNull(16) ?: 128
                return v - 128
            }
            return mapOf(
                1 to parseDelta(coCyl1),
                2 to parseDelta(coCyl2),
                3 to parseDelta(coCyl3)
            )
        }

    val actuatorStatus: String
        get() = if (actuatorStatusMessage == "Ready.") "" else actuatorStatusMessage

    fun resetISCLearning() = sendActuatorCommand(67)

    fun resetO2FuelTrim() = sendActuatorCommand(87)

    fun initializeAdapter() {
        if (bleManager.isVirtualSimulator) {
            startVirtualSimulatorMode()
        } else {
            startInitialization()
        }
    }

    val terminalLogs: List<String>
        get() = terminalOutput.map { it.text }

    fun toggleTerminalPause() {
        isTerminalPaused = !isTerminalPaused
    }

    fun clearTerminalLogs() {
        terminalOutput.clear()
    }

    private var isExecutingISCReset = false
    private var preResetISCSnapshot: Triple<String, String, String>? = null
    private var isExecutingO2Reset = false
    private var preResetO2Snapshot: Pair<String, String>? = null

    private var demoTimer: Timer? = null
    private var telemetryTimer: Timer? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var buffer = ""
    private var isInitializing = false
    private var isReadingErrors = false
    private var isProbingABS = false
    private val commandQueue = ArrayDeque<String>()
    private var isAwaitingResponse = false
    private var lastSentCommand = ""
    private var currentProbeHeader = ""
    private var timeoutRunnable: Runnable? = null

    private val dtcDatabase = mutableMapOf<String, DTCLocalizedEntry>()

    init {
        bleManager.dataReceivedCallback = { data ->
            processIncomingData(data)
        }
        loadDTCDatabase()
        val prefs = context.getSharedPreferences("yadiag_prefs", Context.MODE_PRIVATE)
        if (prefs.getBoolean("auto_start_demo_mode", false)) {
            mainHandler.postDelayed({ startVirtualSimulatorMode() }, 300)
        }
    }

    fun localizedMsg(
        en: String,
        it: String,
        fr: String? = null,
        es: String? = null,
        de: String? = null
    ): String = when (LocalizationManager.currentLanguage) {
        AppLanguage.ITALIAN -> it
        AppLanguage.FRENCH -> fr ?: en
        AppLanguage.SPANISH -> es ?: en
        AppLanguage.GERMAN -> de ?: en
        AppLanguage.ENGLISH -> en
    }

    fun localizedThrottleCleaningStatus(forLang: AppLanguage? = null): String {
        val l = forLang ?: LocalizationManager.currentLanguage
        if (ecuCode67Flag == "0002") {
            return when (l) {
                AppLanguage.ITALIAN -> "🔴 PULIZIA CORPI FARFALLATI RICHIESTA DALLA ECU! (Cod. Diag. 67 = 02 — Limite ISC raggiunto)."
                AppLanguage.ENGLISH -> "🔴 THROTTLE BODY CLEANING REQUESTED BY ECU! (Diag Code 67 = 02 — ISC limit reached)."
                AppLanguage.FRENCH -> "🔴 NETTOYAGE CORPS PAPILLONS REQUIS PAR L'ECU ! (Code Diag. 67 = 02 — Limite ISC atteinte)."
                AppLanguage.SPANISH -> "🔴 ¡LIMPIEZA DE CUERPOS DE MARIPOSA REQUERIDA POR LA ECU! (Cód. Diag. 67 = 02 — Límite ISC alcanzado)."
                AppLanguage.GERMAN -> "🔴 DROSSELKLAPPENREINIGUNG VON DER ECU ANGEFORDERT! (Diag-Code 67 = 02 — ISC-Grenzwert erreicht)."
            }
        }

        return when (throttleCleaningLevel) {
            1 -> {
                var baseStr = when (l) {
                    AppLanguage.ITALIAN -> String.format(Locale.US, "🟢 CORPI FARFALLATI PULITI (Compensazione ISC: %.1f%%). Nessuna pulizia necessaria.", throttleDirtPercentage)
                    AppLanguage.ENGLISH -> String.format(Locale.US, "🟢 THROTTLE BODIES CLEAN (ISC Trim: %.1f%%). No cleaning required.", throttleDirtPercentage)
                    AppLanguage.FRENCH -> String.format(Locale.US, "🟢 CORPS PAPILLONS PROPRES (Trim ISC : %.1f%%). Aucun nettoyage requis.", throttleDirtPercentage)
                    AppLanguage.SPANISH -> String.format(Locale.US, "🟢 CUERPOS DE MARIPOSA LIMPIOS (Compensación ISC: %.1f%%). Limpieza no requerida.", throttleDirtPercentage)
                    AppLanguage.GERMAN -> String.format(Locale.US, "🟢 DROSSELKLAPPEN SAUBER (ISC-Kompensation: %.1f%%). Keine Reinigung erforderlich.", throttleDirtPercentage)
                }
                if (ecuCode67Flag == "0001") {
                    baseStr += when (l) {
                        AppLanguage.ITALIAN -> " [Flag ECU Cod. 67 = 01 OK]"
                        AppLanguage.ENGLISH -> " [ECU Flag Code 67 = 01 OK]"
                        AppLanguage.FRENCH -> " [Flag ECU Code 67 = 01 OK]"
                        AppLanguage.SPANISH -> " [Flag ECU Cód. 67 = 01 OK]"
                        AppLanguage.GERMAN -> " [ECU-Flag Code 67 = 01 OK]"
                    }
                }
                baseStr
            }
            2 -> when (l) {
                AppLanguage.ITALIAN -> String.format(Locale.US, "🟡 DEPOSITI MODERATI RILEVATI (Apertura compensata: %.1f%%). Consigliata pulizia o reset ISC.", throttleDirtPercentage)
                AppLanguage.ENGLISH -> String.format(Locale.US, "🟡 MODERATE DEPOSITS DETECTED (Compensated opening: %.1f%%). Cleaning or ISC reset advised.", throttleDirtPercentage)
                AppLanguage.FRENCH -> String.format(Locale.US, "🟡 DÉPÔTS MODÉRÉS DÉTECTÉS (Ouverture compensée : %.1f%%). Nettoyage ou reset ISC conseillé.", throttleDirtPercentage)
                AppLanguage.SPANISH -> String.format(Locale.US, "🟡 DEPÓSITOS MODERADOS DETECTADOS (Apertura compensada: %.1f%%). Se recomienda limpieza o reset ISC.", throttleDirtPercentage)
                AppLanguage.GERMAN -> String.format(Locale.US, "🟡 MITTLERE ABLAGERUNGEN ERKANNT (Kompensierte Öffnung: %.1f%%). Reinigung oder ISC-Reset empfohlen.", throttleDirtPercentage)
            }
            3 -> when (l) {
                AppLanguage.ITALIAN -> String.format(Locale.US, "🔴 PULIZIA CORPI FARFALLATI NECESSARIA! (Compensazione: %.1f%% — limite Cod. 242).", throttleDirtPercentage)
                AppLanguage.ENGLISH -> String.format(Locale.US, "🔴 THROTTLE BODY CLEANING REQUIRED! (ISC Trim: %.1f%% — Event 242 limit).", throttleDirtPercentage)
                AppLanguage.FRENCH -> String.format(Locale.US, "🔴 NETTOYAGE CORPS PAPILLONS REQUIS ! (Trim ISC : %.1f%% — limite atteinte).", throttleDirtPercentage)
                AppLanguage.SPANISH -> String.format(Locale.US, "🔴 ¡LIMPIEZA DE CUERPOS DE MARIPOSA REQUERIDA! (Compensación: %.1f%% — límite excedido).", throttleDirtPercentage)
                AppLanguage.GERMAN -> String.format(Locale.US, "🔴 DROSSELKLAPPENREINIGUNG ERFORDERLICH! (ISC-Trim: %.1f%% — Grenzwert erreicht).", throttleDirtPercentage)
            }
            else -> when (l) {
                AppLanguage.ITALIAN -> "⚪ Apprendimento azzerato o non disponibile. Avvia il motore per rilevare lo stato."
                AppLanguage.ENGLISH -> "⚪ Learning reset or unavailable. Start engine at idle to detect condition."
                AppLanguage.FRENCH -> "⚪ Apprentissage réinitialisé ou indisponible. Démarrez le moteur pour détecter l'état."
                AppLanguage.SPANISH -> "⚪ Aprendizaje restablecido o no disponible. Arranque el motor para detectar el estado."
                AppLanguage.GERMAN -> "⚪ Adaption zurückgesetzt oder nicht verfügbar. Motor starten, um Zustand zu ermitteln."
            }
        }
    }

    val throttleCleaningStatus: String
        get() = localizedThrottleCleaningStatus()

    fun localizedISCLearningStatus(forLang: AppLanguage? = null): String {
        val l = forLang ?: LocalizationManager.currentLanguage
        if (isReadingEngineParams && iscW1 == "--") {
            return when (l) {
                AppLanguage.ITALIAN -> "Lettura in corso..."
                AppLanguage.ENGLISH -> "Reading in progress..."
                AppLanguage.FRENCH -> "Lecture en cours..."
                AppLanguage.SPANISH -> "Lectura en curso..."
                AppLanguage.GERMAN -> "Lesevorgang läuft..."
            }
        }
        if (iscW1 == "--") return "--"
        val cyl = if (l == AppLanguage.GERMAN) "Zyl" else "Cil"
        val stLabel = when (l) {
            AppLanguage.ENGLISH -> "State:"
            AppLanguage.FRENCH -> "État :"
            AppLanguage.SPANISH -> "Estado:"
            AppLanguage.GERMAN -> "Status:"
            AppLanguage.ITALIAN -> "Stato:"
        }

        val stateDesc = if (isISCLearningReset) {
            when (l) {
                AppLanguage.ITALIAN -> "⚠️ AZZERATO (Valori base 0x8000)"
                AppLanguage.ENGLISH -> "⚠️ RESET (Base values 0x8000)"
                AppLanguage.FRENCH -> "⚠️ RÉINITIALISÉ (Valeurs base 0x8000)"
                AppLanguage.SPANISH -> "⚠️ RESTABLECIDO (Valores base 0x8000)"
                AppLanguage.GERMAN -> "⚠️ ZURÜCKGESETZT (Basiswerte 0x8000)"
            }
        } else {
            when (throttleCleaningLevel) {
                1 -> when (l) {
                    AppLanguage.ITALIAN -> "✅ VALORI REGOLARI / PULITI (Reg. 0x54)"
                    AppLanguage.ENGLISH -> "✅ COMPLIANT / CLEAN VALUES (Reg. 0x54)"
                    AppLanguage.FRENCH -> "✅ VALEURS CONFORMES / PROPRES (Rég. 0x54)"
                    AppLanguage.SPANISH -> "✅ VALORES REGULARES / LIMPIOS (Reg. 0x54)"
                    AppLanguage.GERMAN -> "✅ KONFORME / SAUBERE WERTE (Reg. 0x54)"
                }
                2 -> when (l) {
                    AppLanguage.ITALIAN -> "🟡 VALORI DEPOSITI MEDI (Reg. 0x54)"
                    AppLanguage.ENGLISH -> "🟡 MODERATE DEPOSIT VALUES (Reg. 0x54)"
                    AppLanguage.FRENCH -> "🟡 VALEURS DÉPÔTS MODÉRÉS (Rég. 0x54)"
                    AppLanguage.SPANISH -> "🟡 VALORES DEPÓSITOS MEDIOS (Reg. 0x54)"
                    AppLanguage.GERMAN -> "🟡 MITTLERE ABLAGERUNGSWERTE (Reg. 0x54)"
                }
                3 -> when (l) {
                    AppLanguage.ITALIAN -> "🔴 LIMITE ISC SUPERATO (Reg. 0x54)"
                    AppLanguage.ENGLISH -> "🔴 ISC LIMIT EXCEEDED (Reg. 0x54)"
                    AppLanguage.FRENCH -> "🔴 LIMITE ISC DÉPASSÉE (Rég. 0x54)"
                    AppLanguage.SPANISH -> "🔴 LÍMITE ISC EXCEDIDO (Reg. 0x54)"
                    AppLanguage.GERMAN -> "🔴 ISC-GRENZWERT ÜBERSCHRITTEN (Reg. 0x54)"
                }
                else -> "--"
            }
        }
        return "$cyl #1: 0x$iscW1 | $cyl #2: 0x$iscW2 | $cyl #3: 0x$iscW3\n$stLabel $stateDesc"
    }

    val iscLearningStatus: String
        get() = localizedISCLearningStatus()

    fun localizedO2LearningStatus(forLang: AppLanguage? = null): String {
        val l = forLang ?: LocalizationManager.currentLanguage
        if (isReadingEngineParams && o2Trim1 == "--") {
            return when (l) {
                AppLanguage.ITALIAN -> "Lettura in corso..."
                AppLanguage.ENGLISH -> "Reading in progress..."
                AppLanguage.FRENCH -> "Lecture en cours..."
                AppLanguage.SPANISH -> "Lectura en curso..."
                AppLanguage.GERMAN -> "Lesevorgang läuft..."
            }
        }
        if (o2Trim1 == "--") return "--"
        val stLabel = when (l) {
            AppLanguage.ENGLISH -> "State:"
            AppLanguage.FRENCH -> "État :"
            AppLanguage.SPANISH -> "Estado:"
            AppLanguage.GERMAN -> "Status:"
            AppLanguage.ITALIAN -> "Stato:"
        }
        val cycLabel = when (l) {
            AppLanguage.ENGLISH -> "Cycles:"
            AppLanguage.FRENCH -> "Cycles :"
            AppLanguage.SPANISH -> "Ciclos:"
            AppLanguage.GERMAN -> "Zyklen:"
            AppLanguage.ITALIAN -> "Cicli:"
        }

        val stateDesc = if (isO2Reset) {
            when (l) {
                AppLanguage.ITALIAN -> "⚠️ AZZERATO (0x0200 = Neutro Fabbrica)"
                AppLanguage.ENGLISH -> "⚠️ RESET (0x0200 = Factory Neutral)"
                AppLanguage.FRENCH -> "⚠️ RÉINITIALISÉ (0x0200 = Neutre usine)"
                AppLanguage.SPANISH -> "⚠️ RESTABLECIDO (0x0200 = Neutro fábrica)"
                AppLanguage.GERMAN -> "⚠️ ZURÜCKGESETZT (0x0200 = Werkseinstellung)"
            }
        } else {
            when (l) {
                AppLanguage.ITALIAN -> "✅ APPRESO REGOLARE (Reg. 0x52)"
                AppLanguage.ENGLISH -> "✅ ADAPTED NORMAL (Reg. 0x52)"
                AppLanguage.FRENCH -> "✅ APPRIS NORMAL (Rég. 0x52)"
                AppLanguage.SPANISH -> "✅ APRENDIDO NORMAL (Reg. 0x52)"
                AppLanguage.GERMAN -> "✅ NORMAL ADAPTIERT (Reg. 0x52)"
            }
        }
        var res = "Trim: 0x$o2Trim1 / 0x$o2Trim2 | $cycLabel 0x$o2Cycles\n$stLabel $stateDesc"
        if (iscTarget.isNotEmpty()) {
            res += "\nParametri Reg. 0x58: Target 0x$iscTarget (Flag Cod.67=$ecuCode67Flag, Cod.87=$ecuCode87Flag)"
        }
        return res
    }

    val o2LearningStatus: String
        get() = localizedO2LearningStatus()

    fun localizedCOCylindersStatus(forLang: AppLanguage? = null): String {
        val l = forLang ?: LocalizationManager.currentLanguage
        if (isReadingEngineParams && coCyl1 == "--") {
            return when (l) {
                AppLanguage.ITALIAN -> "Lettura in corso..."
                AppLanguage.ENGLISH -> "Reading in progress..."
                AppLanguage.FRENCH -> "Lecture en cours..."
                AppLanguage.SPANISH -> "Lectura en curso..."
                AppLanguage.GERMAN -> "Lesevorgang läuft..."
            }
        }
        if (coCyl1 == "--") return "--"
        val cyl = if (l == AppLanguage.GERMAN) "Zyl" else "Cil"
        return "$cyl #1: $coCyl1 | $cyl #2: $coCyl2 | $cyl #3: $coCyl3"
    }

    val coCylindersStatus: String
        get() = localizedCOCylindersStatus()

    val currentGear: String
        get() {
            if (speed == 0) return if (rpm > 0) "N" else "-"
            val ratio = rpm.toDouble() / speed.toDouble()
            return when {
                ratio in 95.0..150.0 -> "1"
                ratio in 72.0..94.99 -> "2"
                ratio in 60.0..71.99 -> "3"
                ratio in 51.0..59.99 -> "4"
                ratio in 45.0..50.99 -> "5"
                ratio in 35.0..44.99 -> "6"
                else -> "-"
            }
        }

    private fun loadDTCDatabase() {
        try {
            val jsonStr = context.assets.open("dtc_database.json").bufferedReader(StandardCharsets.UTF_8).use { it.readText() }
            val root = JSONObject(jsonStr)
            val keys = root.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val value = root.get(key)
                if (value is JSONObject) {
                    dtcDatabase[key] = DTCLocalizedEntry(
                        en = value.optString("en", ""),
                        it = value.optString("it", ""),
                        fr = value.optString("fr", "").takeIf { it.isNotEmpty() },
                        es = value.optString("es", "").takeIf { it.isNotEmpty() },
                        de = value.optString("de", "").takeIf { it.isNotEmpty() }
                    )
                } else if (value is String) {
                    dtcDatabase[key] = DTCLocalizedEntry(en = value, it = value, fr = value, es = value, de = value)
                }
            }
        } catch (_: Exception) {
        }
    }

    fun getDTCDescription(forCode: String): String? = dtcDatabase[forCode]?.localized()

    fun lookupABSCode(codeNumber: String): String {
        val cleanNum = codeNumber.trim().uppercase()
        val key = "ABS_$cleanNum"
        val absLabel = localizedMsg(en = "ABS Code", it = "Codice ABS", fr = "Code ABS", es = "Código ABS", de = "ABS-Code")
        val desc = getDTCDescription(key)
        if (desc != null) {
            return "$absLabel $cleanNum: $desc"
        }
        val fallback = localizedMsg(
            en = "Fault detected (refer to ABS chart page 8-128 of service manual).",
            it = "Anomalia rilevata (consultare tabella ABS pag. 8-128 del manuale).",
            fr = "Anomalie détectée (consultez le tableau ABS page 8-128 du manuel d'atelier).",
            es = "Anomalía detectada (consulte la tabla ABS pág. 8-128 del manual de taller).",
            de = "Störung erkannt (siehe ABS-Tabelle Seite 8-128 des Werkstatthandbuchs)."
        )
        return "$absLabel $cleanNum: $fallback"
    }

    fun startInitialization() {
        isInitializing = true
        val initCommands = listOf("ATZ", "ATE0", "ATL0", "STDI", "ATSP0", "0100")
        performSequence(initCommands)
    }

    private fun performSequence(commands: List<String>) {
        commands.forEachIndexed { index, cmd ->
            mainHandler.postDelayed({
                bleManager.sendCommand(cmd)
            }, (index * 500).toLong())
        }
        mainHandler.postDelayed({
            isInitializing = false
            startPolling()
        }, (commands.size * 500).toLong())
    }

    fun enqueueCommand(cmd: String) {
        mainHandler.post {
            commandQueue.addLast(cmd)
            processQueue()
        }
    }

    private fun processQueue() {
        if (!isAwaitingResponse && commandQueue.isNotEmpty()) {
            val nextCmd = commandQueue.removeFirst()
            isAwaitingResponse = true
            lastSentCommand = nextCmd
            if (nextCmd.startsWith("ATSH ")) {
                currentProbeHeader = nextCmd.drop(5).trim()
            }

            val isRoutinePoll = nextCmd in listOf("010C", "010D", "0105", "0111", "010F", "0104", "010B", "010E", "0114", "ATRV")
            if (!isRoutinePoll) {
                val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                val logLine = "[$timestamp] > $nextCmd"
                terminalOutput.add(TerminalLine(text = logLine))
                logToFile(logLine)
            }

            bleManager.sendCommand(nextCmd)

            timeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            val r = Runnable {
                if (isAwaitingResponse) {
                    isAwaitingResponse = false
                    processQueue()
                }
            }
            timeoutRunnable = r
            mainHandler.postDelayed(r, 2000)
        }
    }

    fun startPolling() {
        telemetryTimer?.cancel()
        val t = Timer()
        t.scheduleAtFixedRate(0L, 100L) {
            mainHandler.post {
                if (isInitializing || isReadingErrors || isProbingABS || isPollingPaused) return@post
                if (commandQueue.isNotEmpty()) return@post

                enqueueCommand("010C") // RPM
                enqueueCommand("010D") // Speed
                enqueueCommand("0105") // Temp
                enqueueCommand("0111") // TPS
                enqueueCommand("010F") // IAT
                enqueueCommand("0104") // Load
                enqueueCommand("010B") // MAP
                enqueueCommand("010E") // Timing
                enqueueCommand("0114") // O2
                enqueueCommand("ATRV") // Battery

                if (isRecording) {
                    recordTelemetry()
                }
            }
        }
        telemetryTimer = t
    }

    // MARK: - Modalità Demo / Simulazione per Banco Prova Offline

    fun toggleDemoMode() {
        isDemoMode = !isDemoMode
        if (isDemoMode) {
            if (!bleManager.isConnected) {
                bleManager.startVirtualSimulator()
            }
            startDemoSimulation()
        } else {
            if (bleManager.isVirtualSimulator) {
                bleManager.stopVirtualSimulator()
            }
            stopDemoSimulation()
        }
    }

    fun startVirtualSimulatorMode() {
        bleManager.startVirtualSimulator()
        if (!isDemoMode) {
            isDemoMode = true
            startDemoSimulation()
        }
    }

    fun stopVirtualSimulatorMode() {
        bleManager.stopVirtualSimulator()
        if (isDemoMode) {
            isDemoMode = false
            stopDemoSimulation()
        }
    }

    private fun startDemoSimulation() {
        demoTimer?.cancel()
        isPollingPaused = false
        var step = 0

        val t = Timer()
        t.scheduleAtFixedRate(0L, 250L) {
            if (!isDemoMode) return@scheduleAtFixedRate
            step += 1
            mainHandler.post {
                val cycle = step % 60
                when {
                    cycle < 15 -> {
                        rpm = 1250 + (cycle * 30)
                        speed = 0
                        tps = 15
                    }
                    cycle < 40 -> {
                        rpm = 1700 + ((cycle - 15) * 180)
                        speed = (cycle - 15) * 4
                        tps = 20 + ((cycle - 15) * 2)
                    }
                    else -> {
                        rpm = maxOf(1200, 6200 - ((cycle - 40) * 240))
                        speed = maxOf(0, 100 - ((cycle - 40) * 5))
                        tps = 16
                    }
                }

                temp = 88 + (step % 5)
                iat = 28
                map = 62 + (step % 12)
                engineLoad = 18 + (step % 15)
                timingAdvance = 12 + (step % 6)
                o2Voltage = 0.45 + ((step % 10) * 0.04)
                batteryVoltage = "13.8V"

                bleManager.simulatedRPM = rpm
                bleManager.simulatedSpeed = speed
                bleManager.simulatedCoolantTemp = temp
                bleManager.simulatedIAT = iat
                bleManager.simulatedTPS = tps

                if (isRecording) {
                    recordTelemetry()
                }
            }
        }
        demoTimer = t

        mainHandler.post {
            val dtc1Desc = localizedMsg(
                en = "ECT Coolant Temperature Sensor Circuit (Simulated fault)",
                it = "Circuito Sensore Temperatura Refrigerante ECT (Guasto simulato)",
                fr = "Circuit Capteur Température Liquide Refroidissement ECT (Défaut simulé)",
                es = "Circuito Sensor Temperatura Refrigerante ECT (Fallo simulado)",
                de = "Kühlmitteltemperatursensor-Stromkreis ECT (Simulierter Fehler)"
            )
            val dtc2Desc = localizedMsg(
                en = "O2 Lambda Sensor Circuit Bank 1 Sensor 1 (Simulated fault)",
                it = "Circuito Sensore Sonda Lambda O2 Banco 1 (Guasto simulato)",
                fr = "Circuit Sonde Lambda O2 Banc 1 (Défaut simulé)",
                es = "Circuito Sensor Sonda Lambda O2 Banco 1 (Fallo simulado)",
                de = "O2-Sensorkreis Bank 1 Sensor 1 (Simulierter Fehler)"
            )
            dtcCodes.clear()
            dtcCodes.add("P0115: $dtc1Desc")
            dtcCodes.add("P0130: $dtc2Desc")

            val absDesc = localizedMsg(
                en = "ABS Code 41: Front wheel speed sensor (anomalous signal / open circuit)",
                it = "Codice ABS 41: Sensore velocità ruota anteriore (segnale anomalo / circuito aperto)",
                fr = "Code ABS 41: Capteur de vitesse roue avant (signal anormal / circuit ouvert)",
                es = "Código ABS 41: Sensor de velocidad rueda delantera (señal anómala / circuito abierto)",
                de = "ABS-Code 41: Vorderrad-Geschwindigkeitssensor (anomales Signal / offener Stromkreis)"
            )
            absDtcCodes.clear()
            absDtcCodes.add(absDesc)

            iscW1 = "82F0"
            iscW2 = "8435"
            iscW3 = "8435"
            isISCLearningReset = false
            o2Trim1 = "01FC"
            o2Trim2 = "0255"
            o2Cycles = "000A"
            isO2Reset = false
            coCyl1 = "0x82 (+2)"
            coCyl2 = "0x80 (0)"
            coCyl3 = "0x81 (+1)"
            throttleCleaningLevel = 2
            throttleDirtPercentage = 42.0

            val simConnectedMsg = localizedMsg(
                en = "[SIMULATOR] Virtual OBD2 Adapter connected and active.",
                it = "[SIMULATORE] Adattatore Virtuale OBD2 connesso e attivo.",
                fr = "[SIMULATEUR] Adaptateur virtuel OBD2 connecté et actif.",
                es = "[SIMULADOR] Adaptador virtual OBD2 conectado y activo.",
                de = "[SIMULATOR] Virtueller OBD2-Adapter verbunden und aktiv."
            )
            terminalOutput.add(TerminalLine(text = simConnectedMsg))
        }
    }

    private fun stopDemoSimulation() {
        demoTimer?.cancel()
        demoTimer = null
        mainHandler.post {
            rpm = 0
            speed = 0
            terminalOutput.add(TerminalLine(text = "[DEMO] Modalità Simulazione disattivata."))
        }
    }

    fun toggleTelemetry() {
        isPollingPaused = !isPollingPaused
        if (isPollingPaused) {
            commandQueue.clear()
        } else {
            if (telemetryTimer == null) {
                startPolling()
            }
        }
    }

    fun toggleRecording() {
        isRecording = !isRecording
        if (isRecording) {
            if (isPollingPaused) {
                isPollingPaused = false
            }
            if (telemetryTimer == null) {
                startPolling()
            }

            val dateStr = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val outFile = File(context.filesDir, "telemetry_$dateStr.csv")
            currentTelemetryFile = outFile

            val header = "Timestamp,RPM,Speed,Gear,Temp,O2Voltage,TPS,IAT,EngineLoad,MAP,TimingAdvance,BatteryVoltage\n"
            try {
                outFile.writeText(header, StandardCharsets.UTF_8)
            } catch (_: Exception) {
            }
        }
    }

    private fun recordTelemetry() {
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
        val row = "$timestamp,$rpm,$speed,$currentGear,$temp,${String.format(Locale.US, "%.2f", o2Voltage)},$tps,$iat,$engineLoad,$map,$timingAdvance,$batteryVoltage\n"
        val file = currentTelemetryFile ?: return
        try {
            FileOutputStream(file, true).use { fos ->
                fos.write(row.toByteArray(StandardCharsets.UTF_8))
            }
            recordedRowsCount += 1
        } catch (_: Exception) {
        }
    }

    private fun rxAddress(txHeader: String): String {
        val v = txHeader.toIntOrNull(16) ?: return "7B8"
        return String.format("%03X", v + 8)
    }

    // MARK: - Diagnosi Centralina Motore (FI ECU)

    fun readErrors() {
        if (selectedECU == DiagnosticTargetECU.ABS) {
            readABSErrors()
            return
        }

        isReadingErrors = true
        commandQueue.clear()
        dtcCodes.clear()
        dtcCodes.add("Lettura centralina motore (FI ECU - 7E0) in corso...")

        enqueueCommand("ATH1")
        enqueueCommand("ATSH 7E0")
        enqueueCommand("ATCRA 7E8")
        enqueueCommand("03")
        enqueueCommand("ATH0")
        enqueueCommand("ATCRA")

        mainHandler.postDelayed({
            isReadingErrors = false
            if (dtcCodes.firstOrNull()?.contains("Lettura centralina motore") == true) {
                dtcCodes.clear()
                dtcCodes.add("Nessuna risposta dalla FI ECU (Verifica che il quadro moto sia su ON e l'adattatore connesso).")
            }
            sendAnonymousTelemetryReport()
        }, 4000)
    }

    fun clearErrors() {
        if (selectedECU == DiagnosticTargetECU.ABS) {
            clearABSErrors()
            return
        }
        commandQueue.clear()
        dtcCodes.clear()
        dtcCodes.add(
            localizedMsg(
                en = "Clearing FI ECU fault memory...",
                it = "Cancellazione errori FI ECU in corso...",
                fr = "Effacement mémoire défauts FI ECU...",
                es = "Borrando memoria de averías FI ECU...",
                de = "Löschen des FI ECU-Fehlerspeichers..."
            )
        )
        enqueueCommand("ATSH 7E0")
        enqueueCommand("ATCRA 7E8")
        enqueueCommand(SecurityVault.getClearEngineCommand())
        enqueueCommand("ATCRA")
        mainHandler.postDelayed({
            dtcCodes.clear()
            dtcCodes.add(
                localizedMsg(
                    en = "FI ECU fault clearing command sent (Mode 04).",
                    it = "Comando cancellazione errori FI ECU inviato (Mode 04).",
                    fr = "Commande d'effacement FI ECU envoyée (Mode 04).",
                    es = "Comando de borrado FI ECU enviado (Mode 04).",
                    de = "Befehl zum Löschen des FI ECU-Fehlerspeichers gesendet (Mode 04)."
                )
            )
        }, 2500)
    }

    // MARK: - Diagnosi Centralina ABS (ABS ECU su CANH/CANL)

    fun readABSErrors() {
        if (!bleManager.isConnected) {
            absDtcCodes.clear()
            absDtcCodes.add(
                localizedMsg(
                    en = "❌ ERROR: OBD2 adapter NOT connected via Bluetooth! Go to the Bluetooth tab and connect first.",
                    it = "❌ ERRORE: Adattatore UniCarScan NON connesso via Bluetooth! Vai nel tab Bluetooth e connettiti prima di interrogare l'ABS.",
                    fr = "❌ ERREUR : Adaptateur NON connecté via Bluetooth ! Connectez-vous d'abord dans l'onglet Bluetooth.",
                    es = "❌ ERROR: ¡Adaptador NO conectado por Bluetooth! Conéctate primero en la pestaña Bluetooth.",
                    de = "❌ FEHLER: Adapter NICHT über Bluetooth verbunden! Zuerst im Bluetooth-Tab verbinden."
                )
            )
            return
        }

        isReadingErrors = true
        val targetTx = absCanHeader
        val targetRx = rxAddress(targetTx)

        lastABSRawTrace.clear()
        absDtcCodes.clear()
        absDtcCodes.add("⏳ Interrogazione centralina ABS su CAN TX:$targetTx / RX:$targetRx in corso...")

        commandQueue.clear()

        mainHandler.postDelayed({
            isAwaitingResponse = false
            enqueueCommand("ATE0")
            enqueueCommand("ATH1")
            enqueueCommand("ATSH $targetTx")
            enqueueCommand("ATCRA $targetRx")
            enqueueCommand("ATFCSH $targetTx")
            enqueueCommand("ATFCSD 300000")
            enqueueCommand("ATFCSM 1")
            enqueueCommand("3E00")
            enqueueCommand("1003")
            enqueueCommand("1800FF00")

            mainHandler.postDelayed({
                enqueueCommand("1001")
                enqueueCommand("ATFCSM 0")
                enqueueCommand("ATCRA")
                enqueueCommand("ATH0")
                enqueueCommand("ATSH 7E0")
            }, 2500)
        }, 350)

        mainHandler.postDelayed({
            isReadingErrors = false
            if (absDtcCodes.firstOrNull()?.contains("Interrogazione centralina ABS") == true) {
                absDtcCodes.clear()
                if (lastABSRawTrace.isEmpty()) {
                    absDtcCodes.add("⚠️ NESSUNA RISPOSTA dall'adattatore (Timeout).")
                    absDtcCodes.add("Assicurati che il quadro della moto sia acceso (Key ON) e l'UniCarScan sia inizializzato.")
                } else {
                    val summary = lastABSRawTrace.joinToString(" | ")
                    absDtcCodes.add("❌ Nessuna centralina ha risposto all'indirizzo CAN $targetTx (Filtro RX $targetRx).")
                    absDtcCodes.add("Traccia risposte grezze: $summary")
                    absDtcCodes.add("💡 Seleziona l'indirizzo 7E3 (RX 7EB) che è l'indirizzo tipico del nodo ABS.")
                }
            }
            sendAnonymousTelemetryReport()
        }, 8000)
    }

    fun clearABSErrors() {
        if (!bleManager.isConnected) {
            absDtcCodes.clear()
            absDtcCodes.add(
                localizedMsg(
                    en = "❌ ERROR: OBD2 adapter NOT connected via Bluetooth!",
                    it = "❌ ERRORE: Adattatore UniCarScan NON connesso via Bluetooth!",
                    fr = "❌ ERREUR : Adaptateur NON connecté via Bluetooth !",
                    es = "❌ ERROR: ¡Adaptador NO conectado por Bluetooth!",
                    de = "❌ FEHLER: Adapter NICHT über Bluetooth verbunden!"
                )
            )
            return
        }

        isReadingErrors = true
        val targetTx = absCanHeader
        val targetRx = rxAddress(targetTx)

        lastABSRawTrace.clear()
        absDtcCodes.clear()
        absDtcCodes.add("⏳ Cancellazione storico errori ABS (TX:$targetTx / RX:$targetRx)...")
        commandQueue.clear()

        mainHandler.postDelayed({
            isAwaitingResponse = false
            enqueueCommand("ATE0")
            enqueueCommand("ATH1")
            enqueueCommand("ATSH $targetTx")
            enqueueCommand("ATCRA $targetRx")
            enqueueCommand(SecurityVault.getExtendedSessionCommand())
            enqueueCommand(SecurityVault.getClearABSCommand())

            mainHandler.postDelayed({
                enqueueCommand(SecurityVault.getDefaultSessionCommand())
                enqueueCommand("ATCRA")
                enqueueCommand("ATH0")
                enqueueCommand("ATSH 7E0")
            }, 2500)
        }, 350)

        mainHandler.postDelayed({
            isReadingErrors = false
            val trace = lastABSRawTrace.joinToString(" | ")
            if (absDtcCodes.none { it.contains("54 FF FF FF") }) {
                absDtcCodes.clear()
                absDtcCodes.add("Sequenza cancellazione errori ABS completata su CAN $targetTx (RX $targetRx).")
                absDtcCodes.add("Risposte ricevute: ${trace.ifEmpty { "Nessuna" }}")
                absDtcCodes.add("Spegnere e riaccendere il quadro (Key OFF -> Key ON).")
            }
        }, 6000)
    }

    fun scanABSAddresses() {
        if (!bleManager.isConnected) {
            absDtcCodes.clear()
            absDtcCodes.add(
                localizedMsg(
                    en = "❌ ERROR: OBD2 adapter NOT connected via Bluetooth! Connect before starting Auto-Scan.",
                    it = "❌ ERRORE: Adattatore UniCarScan NON connesso via Bluetooth! Connettiti prima di avviare l'Auto-Scan.",
                    fr = "❌ ERREUR : Adaptateur NON connecté via Bluetooth ! Connectez-vous avant de lancer l'Auto-Scan.",
                    es = "❌ ERROR: ¡Adaptador NO conectado por Bluetooth! Conéctate antes de iniciar el Auto-Scan.",
                    de = "❌ FEHLER: Adapter NICHT über Bluetooth verbunden! Vor dem Auto-Scan verbinden."
                )
            )
            return
        }

        isProbingABS = true
        isScanningABS = true
        commandQueue.clear()
        lastABSRawTrace.clear()
        absDtcCodes.clear()
        absDtcCodes.add("🔍 Scansione Bus CAN in corso (Polling sospeso)...")
        absDtcCodes.add("Sto interrogando: 7E3 (ABS Yamaha -> 7EB), 7DF (Broadcast), 7B0, 7E2, 760.")

        val candidateHeaders = listOf("7E3", "7DF", "7B0", "7E2", "760")
        mainHandler.postDelayed({
            isAwaitingResponse = false
            enqueueCommand("ATH1")
            enqueueCommand("ATCRA")

            for (header in candidateHeaders) {
                enqueueCommand("ATSH $header")
                enqueueCommand("3E00")
                enqueueCommand("1003")
                enqueueCommand("1902FF")
            }

            enqueueCommand("ATH0")
            enqueueCommand("ATSH 7E0")
        }, 350)

        mainHandler.postDelayed({
            isProbingABS = false
            isScanningABS = false
            if (lastABSRawTrace.isEmpty()) {
                absDtcCodes.clear()
                absDtcCodes.add("⚠️ Auto-Scan terminato: Nessuna risposta ricevuta dal bus CAN.")
                absDtcCodes.add("Verifica che il quadro della moto sia su ON.")
            } else {
                absDtcCodes.add(0, "✅ Auto-Scan completato! Nodo ABS rilevato su 7E3 (Risposta 7EB):")
            }
        }, 12000)
    }

    // MARK: - Funzioni Attuatori e Reset Apprendimento (Cod. 67 / Cod. 87)

    fun verifyEngineSafetyBeforeActuator(completion: (Boolean) -> Unit) {
        if (isDemoMode) {
            completion(true)
            return
        }
        if (!bleManager.isConnected) {
            actuatorStatusMessage = localizedMsg(
                en = "❌ Error: Adapter not connected.",
                it = "❌ Errore: Adattatore non connesso.",
                fr = "❌ Erreur : Adaptateur non connecté.",
                es = "❌ Error: Adaptador no conectado.",
                de = "❌ Fehler: Adapter nicht verbunden."
            )
            completion(false)
            return
        }

        bleManager.sendCommand("010C")
        bleManager.sendCommand("010D")
        mainHandler.postDelayed({
            if (rpm > 0) {
                actuatorStatusMessage = localizedMsg(
                    en = "❌ Safety Lock: Engine running ($rpm RPM). Turn off engine before proceeding.",
                    it = "❌ Blocco Sicurezza: Motore acceso ($rpm RPM). Spegnere il motore prima di procedere.",
                    fr = "❌ Sécurité : Moteur allumé ($rpm RPM). Coupez le moteur avant de continuer.",
                    es = "❌ Bloqueo de Seguridad: Motor encendido ($rpm RPM). Apaga el motor antes de continuar.",
                    de = "❌ Sicherheitsblockierung: Motor läuft ($rpm U/min). Vor dem Fortfahren Motor ausschalten."
                )
                completion(false)
            } else if (speed > 0) {
                actuatorStatusMessage = localizedMsg(
                    en = "❌ Safety Lock: Vehicle in motion ($speed km/h).",
                    it = "❌ Blocco Sicurezza: Veicolo in movimento ($speed km/h).",
                    fr = "❌ Sécurité : Véhicule en mouvement ($speed km/h).",
                    es = "❌ Bloqueo de Seguridad: Vehículo en movimiento ($speed km/h).",
                    de = "❌ Sicherheitsblockierung: Fahrzeug in Bewegung ($speed km/h)."
                )
                completion(false)
            } else {
                completion(true)
            }
        }, 350)
    }

    fun sendActuatorCommand(code: Int) {
        verifyEngineSafetyBeforeActuator { isSafe ->
            if (!isSafe) return@verifyEngineSafetyBeforeActuator

            isReadingErrors = true
            commandQueue.clear()
            lastABSRawTrace.clear()

            if (code == 67) {
                isExecutingISCReset = true
                preResetISCSnapshot = Triple(iscW1, iscW2, iscW3)
                actuatorStatusMessage = localizedMsg(
                    en = "⏳ Executing Throttle Body / ISC Idle Learning Reset (Code 67 -> 3B 54 01)...",
                    it = "⏳ Esecuzione Reset Apprendimento Corpi Farfallati / Minimo ISC (Cod. 67 -> 3B 54 01)...",
                    fr = "⏳ Exécution Réinitialisation Ralenti ISC (Code 67 -> 3B 54 01)...",
                    es = "⏳ Ejecutando Reinicio Aprendizaje Ralentí ISC (Cód. 67 -> 3B 54 01)...",
                    de = "⏳ Ausführung Drosselklappen- / ISC-Leerlaufreset (Code 67 -> 3B 54 01)..."
                )
            } else if (code == 87) {
                isExecutingO2Reset = true
                preResetO2Snapshot = Pair(o2Trim1, o2Trim2)
                actuatorStatusMessage = localizedMsg(
                    en = "⏳ Executing O2 Lambda Fuel Trim Reset (Code 87 -> 3B 52 01)...",
                    it = "⏳ Esecuzione Reset Apprendimento Sonda Lambda O2 (Cod. 87 -> 3B 52 01)...",
                    fr = "⏳ Exécution Réinitialisation Trim Lambda O2 (Code 87 -> 3B 52 01)...",
                    es = "⏳ Ejecutando Reinicio Trim Sonda Lambda O2 (Cód. 87 -> 3B 52 01)...",
                    de = "⏳ Ausführung Lambdasonden-Gemischadaptions-Reset (Code 87 -> 3B 52 01)..."
                )
            } else {
                actuatorStatusMessage = localizedMsg(
                    en = "⏳ Sending command (Code $code) to Engine ECU (7E0)...",
                    it = "⏳ Invio comando (Cod. $code) alla centralina Motore (7E0)...",
                    fr = "⏳ Envoi commande (Code $code) au calculateur Moteur (7E0)...",
                    es = "⏳ Enviando comando (Cód. $code) a la ECU Motor (7E0)...",
                    de = "⏳ Befehl (Code $code) an Motorsteuergerät (7E0) senden..."
                )
            }

            mainHandler.postDelayed({
                isAwaitingResponse = false
                enqueueCommand("ATH1")
                enqueueCommand("ATSH 7E0")
                enqueueCommand("ATCRA 7E8")
                enqueueCommand("ATFCSH 7E0")
                enqueueCommand("ATFCSD 300000")
                enqueueCommand("ATFCSM 1")
                enqueueCommand(SecurityVault.getExtendedSessionCommand())

                if (code == 67) {
                    enqueueCommand(SecurityVault.getResetISCCommand())
                    enqueueCommand("2154")
                } else if (code == 87) {
                    enqueueCommand(SecurityVault.getResetO2Command())
                    enqueueCommand("3B5801")
                    enqueueCommand("2152")
                    enqueueCommand("2158")
                }

                enqueueCommand(SecurityVault.getDefaultSessionCommand())
                enqueueCommand("ATFCSM 0")
                enqueueCommand("ATCRA")
                enqueueCommand("ATH0")
                enqueueCommand("ATSH 7E0")
            }, 350)

            mainHandler.postDelayed({
                isReadingErrors = false
                if (isExecutingISCReset) {
                    isExecutingISCReset = false
                    actuatorStatusMessage = localizedMsg(
                        en = "⚠️ ISC Reset timeout: no response received for register 0x54 (21 54).",
                        it = "⚠️ Timeout Reset ISC: nessuna risposta ricevuta per il registro 0x54 (21 54).",
                        fr = "⚠️ Délai d'attente Reset ISC dépassé : aucune réponse pour le registre 0x54 (21 54).",
                        es = "⚠️ Tiempo de espera agotado: sin respuesta para el registro ISC 0x54 (21 54).",
                        de = "⚠️ ISC-Reset Timeout: Keine Antwort für Register 0x54 (21 54) erhalten."
                    )
                    sendAnonymousTelemetryReport(operationType = "isc_reset", operationResult = "timeout")
                }
                if (isExecutingO2Reset) {
                    isExecutingO2Reset = false
                    actuatorStatusMessage = localizedMsg(
                        en = "⚠️ O2 Reset timeout: no response received for register 0x52 (21 52).",
                        it = "⚠️ Timeout Reset O2: nessuna risposta ricevuta per il registro 0x52 (21 52).",
                        fr = "⚠️ Délai d'attente Reset O2 dépassé : aucune réponse pour le registre 0x52 (21 52).",
                        es = "⚠️ Tiempo de espera agotado: sin respuesta para el registro O2 0x52 (21 52).",
                        de = "⚠️ O2-Reset Timeout: Keine Antwort für Register 0x52 (21 52) erhalten."
                    )
                    sendAnonymousTelemetryReport(operationType = "o2_reset", operationResult = "timeout")
                }
            }, 4500)
        }
    }

    fun verifyISCAndO2Values() {
        isReadingErrors = true
        commandQueue.clear()

        actuatorStatusMessage = localizedMsg(
            en = "🔍 Reading ISC Idle, O2 and CO parameters from Engine ECU (7E8)...",
            it = "🔍 Lettura parametri ISC (Minimo), Sonda O2 e CO dalla centralina Motore (7E8)...",
            fr = "🔍 Lecture paramètres ISC, Sonde O2 et CO du calculateur Moteur (7E8)...",
            es = "🔍 Leyendo parámetros ISC, Sonda O2 y CO de la ECU Motor (7E8)...",
            de = "🔍 Auslesen von ISC-, Lambda- und CO-Parametern aus Motor-ECU (7E8)..."
        )
        isReadingEngineParams = true
        iscW1 = "--"
        o2Trim1 = "--"
        coCyl1 = "--"

        mainHandler.postDelayed({
            isAwaitingResponse = false
            enqueueCommand("ATH1")
            enqueueCommand("ATSH 7E0")
            enqueueCommand("ATCRA 7E8")
            enqueueCommand("ATFCSH 7E0")
            enqueueCommand("ATFCSD 300000")
            enqueueCommand("ATFCSM 1")
            enqueueCommand("1003")
            enqueueCommand("2140")
            enqueueCommand("2141")
            enqueueCommand("2142")
            enqueueCommand("2152")
            enqueueCommand("2154")
            enqueueCommand("2158")
            enqueueCommand("1001")
            enqueueCommand("ATFCSM 0")
            enqueueCommand("ATCRA")
            enqueueCommand("ATH0")
            enqueueCommand("ATSH 7E0")
        }, 350)

        mainHandler.postDelayed({
            isReadingErrors = false
            lastVerificationTimestamp = Date()
            actuatorStatusMessage = localizedMsg(
                en = "✅ ISC, O2 sensor and CO parameters verification complete.",
                it = "✅ Verifica parametri ISC, Sonda O2 e CO completata.",
                fr = "✅ Vérification des paramètres ISC, Sonde O2 et CO terminée.",
                es = "✅ Verificación de parámetros ISC, Sonda O2 y CO completada.",
                de = "✅ Überprüfung der ISC-, Lambda- und CO-Parameter abgeschlossen."
            )
        }, 4500)
    }

    fun sendCustomCommand(cmd: String) {
        enqueueCommand(cmd)
    }

    private fun stripEcho(response: String, command: String): String {
        val text = response.trim()
        val cleanCmd = command.replace(" ", "").uppercase()
        if (cleanCmd.isEmpty()) return text

        val textNoSpaces = text.replace(" ", "").uppercase()
        if (!textNoSpaces.startsWith(cleanCmd)) return text
        if (textNoSpaces == cleanCmd) return ""

        var remaining = cleanCmd
        var index = 0
        while (index < text.length && remaining.isNotEmpty()) {
            val ch = text[index]
            if (ch.isWhitespace()) {
                index++
                continue
            }
            if (ch.uppercaseChar() == remaining.first()) {
                remaining = remaining.drop(1)
                index++
            } else {
                break
            }
        }
        return if (remaining.isEmpty()) text.substring(index).trim() else text
    }

    fun sendAnonymousTelemetryReport(
        operationType: String = "dtc_scan",
        operationResult: String = "completed"
    ) {
        if (isDemoMode || !bleManager.isConnected) return
        val peripheralName = bleManager.connectedDeviceName
        if (peripheralName.isBlank()) return

        val canNodes = mutableListOf<String>()
        if (dtcCodes.isNotEmpty() && !dtcCodes.first().contains("Nessuna risposta")) {
            canNodes.add("7E0/7E8")
        }
        if (absDtcCodes.isNotEmpty() && !absDtcCodes.first().contains("Nessuna risposta")) {
            canNodes.add(absCanHeader)
        }

        TelemetryService.sendCompatibilityTelemetry(
            adapterName = peripheralName,
            isCertified = BLEManager.isCertifiedAdapter(peripheralName),
            canHeaders = canNodes,
            engineDTCs = dtcCodes.filter {
                !it.contains("✅") && !it.contains("Nessun") && !it.contains("No fault") &&
                        !it.contains("Lettura") && !it.contains("Reading")
            },
            absDTCs = absDtcCodes.filter { it.contains("⚠️") },
            iscStatus = iscLearningStatus,
            o2Status = o2LearningStatus,
            dirtLevel = throttleCleaningLevel,
            dirtPct = throttleDirtPercentage,
            operationType = operationType,
            operationResult = operationResult
        )
    }

    private fun processIncomingData(data: String) {
        buffer += data
        if (buffer.contains(">")) {
            val responses = buffer.split(">")
            for (resp in responses) {
                val cleanRaw = resp.replace("\r", "").replace("\n", "").trim()
                if (cleanRaw.isEmpty()) continue

                val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
                val logLine = "[$timestamp] < $cleanRaw"
                mainHandler.post {
                    if (!isTerminalPaused) {
                        terminalOutput.add(TerminalLine(text = logLine))
                        if (terminalOutput.size > 150) {
                            terminalOutput.removeAt(0)
                        }
                    }
                }
                logToFile(logLine)

                val cleanResponse = stripEcho(cleanRaw, lastSentCommand)
                if (cleanResponse.isNotEmpty()) {
                    parseOBDResponse(cleanResponse.replace(" ", ""), cleanResponse)
                }
            }
            buffer = ""
            timeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            mainHandler.post {
                isAwaitingResponse = false
                processQueue()
            }
        }
    }

    private fun logToFile(text: String) {
        try {
            val logFile = File(context.filesDir, "obd2_log.txt")
            if (logFile.exists() && logFile.length() > 2 * 1024 * 1024) {
                val backup = File(context.filesDir, "obd2_log.prev.txt")
                backup.delete()
                logFile.renameTo(backup)
            }
            FileOutputStream(logFile, true).use { fos ->
                fos.write((text + "\n").toByteArray(StandardCharsets.UTF_8))
            }
        } catch (_: Exception) {
        }
    }

    private fun parseOBDResponse(hexStr: String, rawWithSpaces: String = "") {
        var cleanHex = hexStr.uppercase()

        val knownCANHeaders = listOf("7EB", "7E8", "7EA", "7B8", "7A8", "768")
        if (knownCANHeaders.none { cleanHex.startsWith(it) }) {
            for (header in knownCANHeaders) {
                val idx = cleanHex.indexOf(header)
                if (idx >= 0) {
                    cleanHex = cleanHex.substring(idx)
                    break
                }
            }
        }

        if (isReadingErrors || isProbingABS) {
            if (cleanHex != "OK") {
                val h = currentProbeHeader.ifEmpty { absCanHeader }
                val traceEntry = "[$h -> $lastSentCommand]: ${rawWithSpaces.ifEmpty { cleanHex }}"
                mainHandler.post {
                    lastABSRawTrace.add(traceEntry)
                    if (lastSentCommand.startsWith("31") || lastSentCommand.startsWith("2F") || lastSentCommand.startsWith("30")) {
                        actuatorStatusMessage = "Risposta ECU a [$lastSentCommand]: ${rawWithSpaces.ifEmpty { cleanHex }}"
                    }
                    if (isProbingABS && !cleanHex.contains("NODATA") && !cleanHex.contains("ERROR")) {
                        if (absDtcCodes.firstOrNull()?.contains("Scansione Bus CAN in corso") == true) {
                            absDtcCodes.clear()
                        }
                        val hitMsg = "🟢 NODO ATTIVO RILEVATO! $traceEntry"
                        if (!absDtcCodes.contains(hitMsg)) {
                            absDtcCodes.add(hitMsg)
                        }
                    }
                }
            }
        }

        when {
            cleanHex.startsWith("410C") && cleanHex.length >= 8 -> {
                cleanHex.substring(4, 8).toIntOrNull(16)?.let { v ->
                    mainHandler.post { rpm = v / 4 }
                }
            }
            cleanHex.startsWith("410D") && cleanHex.length >= 6 -> {
                cleanHex.substring(4, 6).toIntOrNull(16)?.let { v ->
                    mainHandler.post { speed = v }
                }
            }
            cleanHex.startsWith("4105") && cleanHex.length >= 6 -> {
                cleanHex.substring(4, 6).toIntOrNull(16)?.let { v ->
                    mainHandler.post { temp = v - 40 }
                }
            }
            cleanHex.startsWith("4114") && cleanHex.length >= 6 -> {
                cleanHex.substring(4, 6).toIntOrNull(16)?.let { v ->
                    mainHandler.post { o2Voltage = v.toDouble() / 200.0 }
                }
            }
            cleanHex.startsWith("4111") && cleanHex.length >= 6 -> {
                cleanHex.substring(4, 6).toIntOrNull(16)?.let { v ->
                    mainHandler.post { tps = v * 100 / 255 }
                }
            }
            cleanHex.startsWith("410F") && cleanHex.length >= 6 -> {
                cleanHex.substring(4, 6).toIntOrNull(16)?.let { v ->
                    mainHandler.post { iat = v - 40 }
                }
            }
            cleanHex.startsWith("4104") && cleanHex.length >= 6 -> {
                cleanHex.substring(4, 6).toIntOrNull(16)?.let { v ->
                    mainHandler.post { engineLoad = v * 100 / 255 }
                }
            }
            cleanHex.startsWith("410B") && cleanHex.length >= 6 -> {
                cleanHex.substring(4, 6).toIntOrNull(16)?.let { v ->
                    mainHandler.post { map = v }
                }
            }
            cleanHex.startsWith("410E") && cleanHex.length >= 6 -> {
                cleanHex.substring(4, 6).toIntOrNull(16)?.let { v ->
                    mainHandler.post { timingAdvance = (v / 2) - 64 }
                }
            }
            cleanHex.endsWith("V") -> {
                mainHandler.post { batteryVoltage = cleanHex }
            }
            knownCANHeaders.any { cleanHex.startsWith(it) } && cleanHex.length >= 5 -> {
                val canId = cleanHex.take(3)
                val payload = cleanHex.drop(3)

                if (canId == "7E8" && payload.contains("61")) {
                    parseYamahaKWP21Response(cleanHex)
                }

                mainHandler.post {
                    when {
                        payload.contains("7B54") -> {
                            actuatorStatusMessage = localizedMsg(
                                en = "⏳ Reset command accepted by ECU (7E8 -> 7B 54). Verifying idle learning reset...",
                                it = "⏳ Comando accettato dalla centralina (7E8 -> 7B 54). Verifica azzeramento valori in corso...",
                                fr = "⏳ Commande acceptée par l'ECU (7E8 -> 7B 54). Vérification de la réinitialisation...",
                                es = "⏳ Comando aceptado por la ECU (7E8 -> 7B 54). Verificando reinicio de valores...",
                                de = "⏳ Befehl vom Steuergerät akzeptiert (7E8 -> 7B 54). Überprüfung der Rücksetzung..."
                            )
                        }
                        payload.contains("7B52") -> {
                            actuatorStatusMessage = localizedMsg(
                                en = "⏳ O2 reset command accepted by ECU (7E8 -> 7B 52). Verifying fuel trim reset...",
                                it = "⏳ Comando accettato dalla centralina (7E8 -> 7B 52). Verifica azzeramento trim O2 in corso...",
                                fr = "⏳ Commande acceptée par l'ECU (7E8 -> 7B 52). Vérification du trim O2...",
                                es = "⏳ Comando aceptado por la ECU (7E8 -> 7B 52). Verificando reinicio del trim O2...",
                                de = "⏳ Befehl vom Steuergerät akzeptiert (7E8 -> 7B 52). Überprüfung des Lambdatrims..."
                            )
                        }
                        payload.contains("7F3B") -> {
                            isExecutingISCReset = false
                            isExecutingO2Reset = false
                            actuatorStatusMessage = localizedMsg(
                                en = "❌ Reset request rejected by Engine ECU (7E8 -> 7F 3B): $rawWithSpaces",
                                it = "❌ Richiesta di reset rifiutata dalla centralina Motore (7E8 -> 7F 3B): $rawWithSpaces",
                                fr = "❌ Demande de réinitialisation rejetée par l'ECU Moteur (7E8 -> 7F 3B) : $rawWithSpaces",
                                es = "❌ Solicitud de reinicio rechazada por la ECU Motor (7E8 -> 7F 3B): $rawWithSpaces",
                                de = "❌ Reset-Anforderung vom Motorsteuergerät abgelehnt (7E8 -> 7F 3B): $rawWithSpaces"
                            )
                        }
                        payload.contains("71") || payload.contains("6F") || payload.contains("70") -> {
                            actuatorStatusMessage = localizedMsg(
                                en = "✅ Routine executed by $canId: $rawWithSpaces",
                                it = "✅ Routine eseguita da $canId: $rawWithSpaces",
                                fr = "✅ Routine exécutée par $canId : $rawWithSpaces",
                                es = "✅ Rutina ejecutada por $canId: $rawWithSpaces",
                                de = "✅ Routine von $canId ausgeführt: $rawWithSpaces"
                            )
                        }
                    }
                }

                if (canId == "7EB" || canId == rxAddress(absCanHeader) || selectedECU == DiagnosticTargetECU.ABS || isProbingABS) {
                    if (canId != "7E8" || currentProbeHeader == "7E0") {
                        parseABSResponse(payload, canId)
                    } else if (isProbingABS && canId == "7E8") {
                        mainHandler.post {
                            val msg = "ℹ️ Risposta FI ECU (7E8) su broadcast: $payload"
                            if (!absDtcCodes.contains(msg)) absDtcCodes.add(msg)
                        }
                    }
                } else if (canId == "7E8") {
                    var cleanPayload = payload
                    if (cleanPayload.startsWith("0") && cleanPayload.length >= 4) {
                        cleanPayload = cleanPayload.drop(2)
                    }
                    if (cleanPayload.startsWith("43")) {
                        parseEngineDTC(cleanPayload)
                    }
                }
            }
            cleanHex.startsWith("59") || cleanHex.startsWith("58") || cleanHex.startsWith("54") ||
                    cleanHex.startsWith("50") || cleanHex.startsWith("7E") || cleanHex.startsWith("7F") -> {
                if (selectedECU == DiagnosticTargetECU.ABS || isProbingABS || cleanHex.startsWith("58")) {
                    parseABSResponse(cleanHex, rxAddress(absCanHeader))
                }
            }
            cleanHex.startsWith("43") -> {
                if (selectedECU == DiagnosticTargetECU.ABS) {
                    parseABSResponse(cleanHex, rxAddress(absCanHeader))
                } else {
                    parseEngineDTC(cleanHex)
                }
            }
            cleanHex.contains("NODATA") -> {
                mainHandler.post {
                    if (isReadingErrors && selectedECU == DiagnosticTargetECU.ENGINE) {
                        if (dtcCodes.firstOrNull()?.contains("Lettura") == true || dtcCodes.firstOrNull()?.contains("Reading") == true) {
                            dtcCodes.clear()
                            dtcCodes.add(
                                localizedMsg(
                                    en = "No fault codes stored on Engine ECU (NO DATA).",
                                    it = "Nessun errore memorizzato sulla centralina Motore (NO DATA).",
                                    fr = "Aucun code défaut mémorisé sur l'ECU Moteur (NO DATA).",
                                    es = "Sin códigos de error almacenados en la ECU Motor (NO DATA).",
                                    de = "Keine Fehlercodes im Motorsteuergerät gespeichert (NO DATA)."
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    private fun decodeDTCFromBytes(b1Hex: String, b2Hex: String): String {
        val b1 = b1Hex.toIntOrNull(16) ?: return "P$b1Hex$b2Hex"
        val prefixType = (b1 and 0xC0) shr 6
        val prefixes = listOf("P", "C", "B", "U")
        val prefix = prefixes.getOrElse(prefixType) { "P" }
        val firstDigit = (b1 and 0x30) shr 4
        val secondDigit = b1 and 0x0F
        return String.format("%s%X%X%s", prefix, firstDigit, secondDigit, b2Hex)
    }

    private fun parseEngineDTC(hexStr: String) {
        if (hexStr.startsWith("4300") || hexStr == "43") {
            mainHandler.post {
                if (dtcCodes.firstOrNull()?.contains("Lettura") == true || dtcCodes.firstOrNull()?.contains("Reading") == true) {
                    dtcCodes.clear()
                }
                val noErrorMsg = localizedMsg(
                    en = "✅ Engine ECU (FI ECU 7E8) responded: No fault codes in memory (43 00).",
                    it = "✅ La centralina Motore (FI ECU 7E8) ha risposto: Nessun errore in memoria (43 00).",
                    fr = "✅ L'ECU Moteur (FI ECU 7E8) a répondu : Aucun défaut en mémoire (43 00).",
                    es = "✅ La ECU Motor (FI ECU 7E8) respondió: Sin errores en memoria (43 00).",
                    de = "✅ Motorsteuergerät (FI ECU 7E8) antwortete: Keine Fehler im Speicher (43 00)."
                )
                if (!dtcCodes.contains(noErrorMsg)) {
                    dtcCodes.add(noErrorMsg)
                }
            }
            return
        }

        val payload = hexStr.drop(2)
        if (payload.isEmpty()) return

        val decodedCodes = mutableListOf<String>()
        val dtcHex = if (payload.length >= 6 && (payload.length - 2) % 4 == 0) payload.drop(2) else payload

        var idx = 0
        while (idx + 4 <= dtcHex.length) {
            val chunk = dtcHex.substring(idx, idx + 4)
            if (chunk != "0000") {
                val b1 = chunk.take(2)
                val b2 = chunk.drop(2)
                val pCode = decodeDTCFromBytes(b1, b2)
                val notInDb = localizedMsg(
                    en = "Fault code not found in offline DB",
                    it = "Guasto non presente nel DB offline",
                    fr = "Code défaut absent de la base locale",
                    es = "Código no presente en la BD local",
                    de = "Fehler nicht in lokaler Datenbank"
                )
                val errLabel = localizedMsg(en = "Fault", it = "Errore", fr = "Défaut", es = "Avería", de = "Fehler")
                val desc = getDTCDescription(pCode) ?: notInDb
                decodedCodes.add("$errLabel $pCode: $desc")
            }
            idx += 4
        }

        mainHandler.post {
            if (dtcCodes.firstOrNull()?.contains("Lettura") == true) {
                dtcCodes.clear()
            }
            for (code in decodedCodes) {
                if (!dtcCodes.contains(code)) {
                    dtcCodes.add(code)
                }
            }
        }
    }

    private fun parseABSResponse(hexStr: String, responderCANID: String) {
        var clean = hexStr.replace(responderCANID, "")

        if (clean.startsWith("0") && clean.length >= 4) {
            val serviceByte = clean.drop(2).take(2)
            if (serviceByte in listOf("50", "54", "58", "59", "7E", "7F", "43", "71")) {
                clean = clean.drop(2)
            }
        } else if (clean.startsWith("10") && clean.length >= 6) {
            var reassembled = ""
            val afterFF = clean.drop(4)
            if (afterFF.length >= 12) {
                reassembled += afterFF.take(12)
                var remainder = afterFF.drop(12)
                var cfIndex = 1
                while (remainder.isNotEmpty()) {
                    val cfHeader = String.format("2%1X", cfIndex % 16)
                    if (remainder.startsWith(cfHeader)) {
                        remainder = remainder.drop(2)
                    }
                    val chunk = remainder.take(14)
                    reassembled += chunk
                    remainder = remainder.drop(minOf(14, remainder.length))
                    cfIndex++
                }
                clean = reassembled
            }
        }

        if (clean.contains("54FFFFFF")) {
            mainHandler.post {
                absDtcCodes.clear()
                absDtcCodes.add(
                    localizedMsg(
                        en = "✅ ABS fault memory cleared successfully by ECU (7EB -> 54 FF FF FF)!",
                        it = "✅ Storico errori ABS cancellato con successo dalla centralina (7EB -> 54 FF FF FF)!",
                        fr = "✅ Mémoire défauts ABS effacée avec succès (7EB -> 54 FF FF FF) !",
                        es = "✅ ¡Memoria de averías ABS borrada con éxito (7EB -> 54 FF FF FF)!",
                        de = "✅ ABS-Fehlerspeicher erfolgreich vom Steuergerät gelöscht (7EB -> 54 FF FF FF)!"
                    )
                )
            }
            return
        }

        if (clean.startsWith("50") || clean.startsWith("7E")) {
            mainHandler.post {
                if (absDtcCodes.firstOrNull()?.contains("Interrogazione") == true ||
                    absDtcCodes.firstOrNull()?.contains("Scansione") == true
                ) {
                    absDtcCodes.clear()
                }
                val statusMsg = if (clean.startsWith("50")) {
                    localizedMsg(
                        en = "✅ Connection established with ABS ECU ($responderCANID - Diagnostic Session Active)",
                        it = "✅ Connessione stabilita con centralina ABS ($responderCANID - Sessione Diagnostica Attiva)",
                        fr = "✅ Connexion établie avec l'ECU ABS ($responderCANID - Session Diagnostique Active)",
                        es = "✅ Conexión establecida con ECU ABS ($responderCANID - Sesión Diagnóstica Activa)",
                        de = "✅ Verbindung zum ABS-Steuergerät hergestellt ($responderCANID - Diagnose-Sitzung aktiv)"
                    )
                } else {
                    localizedMsg(
                        en = "✅ ABS ECU ($responderCANID) online",
                        it = "✅ Centralina ABS ($responderCANID) online",
                        fr = "✅ ECU ABS ($responderCANID) en ligne",
                        es = "✅ ECU ABS ($responderCANID) en línea",
                        de = "✅ ABS-Steuergerät ($responderCANID) online"
                    )
                }
                if (!absDtcCodes.contains(statusMsg)) {
                    absDtcCodes.add(statusMsg)
                }
            }
            return
        }

        if (clean.startsWith("7F")) return

        if (clean.startsWith("58") && clean.length >= 4) {
            val numDTCHex = clean.drop(2).take(2)
            val numDTC = numDTCHex.toIntOrNull(16) ?: 0

            if (numDTC == 0) {
                mainHandler.post {
                    if (absDtcCodes.firstOrNull()?.contains("Interrogazione") == true) {
                        absDtcCodes.clear()
                    }
                    val msg = localizedMsg(
                        en = "🟢 No fault codes stored in ABS ECU (Response 7EB: 58 00 - 0 faults in memory).",
                        it = "🟢 Nessun errore presente nella centralina ABS (Risposta 7EB: 58 00 - 0 guasti in memoria).",
                        fr = "🟢 Aucun code défaut dans l'ECU ABS (Réponse 7EB : 58 00 - 0 défaut en mémoire).",
                        es = "🟢 Sin averías en la memoria ABS (Respuesta 7EB: 58 00 - 0 averías en memoria).",
                        de = "🟢 Keine Fehler im ABS-Steuergerät (Antwort 7EB: 58 00 - 0 Fehler im Speicher)."
                    )
                    if (!absDtcCodes.contains(msg)) {
                        absDtcCodes.add(msg)
                    }
                }
                return
            }

            val dtcPayload = clean.drop(4)
            val foundCodes = mutableListOf<String>()
            var idx = 0
            for (i in 0 until numDTC) {
                if (idx + 6 > dtcPayload.length) break
                val triplet = dtcPayload.substring(idx, idx + 6)
                val codeByte = triplet.drop(2).take(2)
                val statusByte = triplet.drop(4).take(2)
                val statusDesc = if (statusByte == "20") {
                    localizedMsg(en = "[Historical/Past]", it = "[Storico/Passato]", fr = "[Historique/Passé]", es = "[Histórico/Pasado]", de = "[Historisch/Vergangen]")
                } else {
                    localizedMsg(en = "[Active - State 0x$statusByte]", it = "[Attivo - Stato 0x$statusByte]", fr = "[Actif - État 0x$statusByte]", es = "[Activo - Estado 0x$statusByte]", de = "[Aktiv - Status 0x$statusByte]")
                }
                val formatted = "⚠️ $statusDesc " + lookupABSCode(codeByte)
                if (!foundCodes.contains(formatted)) {
                    foundCodes.add(formatted)
                }
                idx += 6
            }

            mainHandler.post {
                if (absDtcCodes.firstOrNull()?.contains("Interrogazione") == true) {
                    absDtcCodes.clear()
                }
                val headerMsg = localizedMsg(
                    en = "🔴 Detected $numDTC fault code(s) in ABS memory ($responderCANID):",
                    it = "🔴 Rilevati $numDTC codici errore nella memoria ABS ($responderCANID):",
                    fr = "🔴 Détection de $numDTC code(s) défaut dans la mémoire ABS ($responderCANID) :",
                    es = "🔴 Detectados $numDTC código(s) de avería en la memoria ABS ($responderCANID):",
                    de = "🔴 $numDTC Fehlercode(s) im ABS-Speicher erkannt ($responderCANID):"
                )
                if (!absDtcCodes.contains(headerMsg)) {
                    absDtcCodes.add(headerMsg)
                }
                for (code in foundCodes) {
                    if (!absDtcCodes.contains(code)) {
                        absDtcCodes.add(code)
                    }
                }
            }
        }
    }

    private fun parseYamahaKWP21Response(hexStr: String) {
        var clean = hexStr.replace("7E8", "")
        if (clean.startsWith("0") && clean.length >= 4) {
            clean = clean.drop(2)
        } else if (clean.startsWith("10") && clean.length >= 6) {
            var reassembled = ""
            val afterFF = clean.drop(4)
            if (afterFF.length >= 12) {
                reassembled += afterFF.take(12)
                var remainder = afterFF.drop(12)
                var cfIndex = 1
                while (remainder.isNotEmpty()) {
                    val cfHeader = String.format("2%1X", cfIndex % 16)
                    if (remainder.startsWith(cfHeader)) {
                        remainder = remainder.drop(2)
                    }
                    val chunk = remainder.take(14)
                    reassembled += chunk
                    remainder = remainder.drop(minOf(14, remainder.length))
                    cfIndex++
                }
                clean = reassembled
            }
        }

        if (!clean.startsWith("61") || clean.length < 6) return
        val localId = clean.drop(2).take(2)
        val dataHex = clean.drop(4)

        mainHandler.post {
            when (localId) {
                "40" -> {
                    val valHex = dataHex.take(2)
                    val delta = (valHex.toIntOrNull(16) ?: 128) - 128
                    coCyl1 = "0x$valHex (${if (delta >= 0) "+$delta" else "$delta"})"
                    isReadingEngineParams = false
                }
                "41" -> {
                    val valHex = dataHex.take(2)
                    val delta = (valHex.toIntOrNull(16) ?: 128) - 128
                    coCyl2 = "0x$valHex (${if (delta >= 0) "+$delta" else "$delta"})"
                    isReadingEngineParams = false
                }
                "42" -> {
                    val valHex = dataHex.take(2)
                    val delta = (valHex.toIntOrNull(16) ?: 128) - 128
                    coCyl3 = "0x$valHex (${if (delta >= 0) "+$delta" else "$delta"})"
                    isReadingEngineParams = false
                }
                "54" -> {
                    val w1 = dataHex.take(4)
                    val w2 = dataHex.drop(4).take(4)
                    val rawW3 = dataHex.drop(8).take(4)
                    val w3 = rawW3.ifEmpty { w2 }
                    val isReset = (w1 == "8000" && w2 == "8000" && (w3 == "8000" || rawW3.isEmpty()))
                    iscW1 = w1
                    iscW2 = w2
                    iscW3 = w3
                    isISCLearningReset = isReset
                    isReadingEngineParams = false

                    val v1 = abs((w1.toIntOrNull(16) ?: 0x8000) - 0x8000)
                    val v2 = abs((w2.toIntOrNull(16) ?: 0x8000) - 0x8000)
                    val v3 = abs((w3.toIntOrNull(16) ?: 0x8000) - 0x8000)
                    val maxDelta = maxOf(v1, v2, v3)
                    lastISCMaxDelta = maxDelta
                    val pct = minOf(100.0, (maxDelta.toDouble() / 8192.0) * 100.0)
                    throttleDirtPercentage = pct

                    throttleCleaningLevel = when {
                        isReset -> 0
                        pct < 35.0 -> 1
                        pct < 75.0 -> 2
                        else -> 3
                    }

                    if (isExecutingISCReset) {
                        isExecutingISCReset = false
                        val wasAlreadyReset = (preResetISCSnapshot?.first == "8000" &&
                                preResetISCSnapshot?.second == "8000" &&
                                (preResetISCSnapshot?.third == "8000" || preResetISCSnapshot?.third == "--"))

                        sendAnonymousTelemetryReport(
                            operationType = "isc_reset",
                            operationResult = if (isReset) "success" else "failed"
                        )

                        actuatorStatusMessage = if (isReset) {
                            if (wasAlreadyReset && preResetISCSnapshot?.first != "--") {
                                localizedMsg(
                                    en = "ℹ️ ISC values were already at factory zero (8000 8000 8000).",
                                    it = "ℹ️ I valori ISC erano già azzerati allo zero di fabbrica (8000 8000 8000).",
                                    fr = "ℹ️ Les valeurs ISC étaient déjà réinitialisées au zéro d'usine (8000 8000 8000).",
                                    es = "ℹ️ Los valores ISC ya estaban restablecidos al cero de fábrica (8000 8000 8000).",
                                    de = "ℹ️ ISC-Werte waren bereits auf Werksnull zurückgesetzt (8000 8000 8000)."
                                )
                            } else {
                                localizedMsg(
                                    en = "✅ Throttle Bodies / ISC Idle Reset CONFIRMED! Values reset to factory zero (8000 8000 8000).",
                                    it = "✅ Reset Apprendimento Corpi Farfallati / Minimo ISC CONFERMATO! Valori azzerati a 8000 8000 8000.",
                                    fr = "✅ Réinitialisation Ralenti ISC CONFIRMÉE ! Valeurs réinitialisées à 8000 8000 8000.",
                                    es = "✅ ¡Reinicio Aprendizaje Ralentí ISC CONFIRMADO! Valores restablecidos a 8000 8000 8000.",
                                    de = "✅ Drosselklappen- / ISC-Leerlaufreset BESTÄTIGT! Werte auf Werksnull 8000 8000 8000 zurückgesetzt."
                                )
                            }
                        } else {
                            localizedMsg(
                                en = "⚠️ Command accepted (7B 54), but ISC values NOT reset ($w1 $w2 $w3). Reset did not take effect.",
                                it = "⚠️ Comando accettato dalla centralina (7B 54), ma i valori ISC NON risultano azzerati ($w1 $w2 $w3). Reset non avvenuto.",
                                fr = "⚠️ Commande acceptée (7B 54), mais valeurs ISC NON réinitialisées ($w1 $w2 $w3).",
                                es = "⚠️ Comando aceptado (7B 54), pero los valores ISC NO están restablecidos ($w1 $w2 $w3).",
                                de = "⚠️ Befehl akzeptiert (7B 54), aber ISC-Werte NICHT zurückgesetzt ($w1 $w2 $w3)."
                            )
                        }
                    }
                }
                "52" -> {
                    val trim1 = dataHex.drop(4).take(4)
                    val trim2 = dataHex.drop(8).take(4)
                    val count = dataHex.drop(12).take(4)
                    o2Trim1 = trim1
                    o2Trim2 = trim2
                    o2Cycles = count
                    isO2Reset = (trim1 == "0200" && trim2 == "0200")
                    isReadingEngineParams = false

                    if (isExecutingO2Reset) {
                        isExecutingO2Reset = false
                        val wasAlreadyReset = (preResetO2Snapshot?.first == "0200" && preResetO2Snapshot?.second == "0200")

                        sendAnonymousTelemetryReport(
                            operationType = "o2_reset",
                            operationResult = if (isO2Reset) "success" else "failed"
                        )

                        actuatorStatusMessage = if (isO2Reset) {
                            if (wasAlreadyReset && preResetO2Snapshot?.first != "--") {
                                localizedMsg(
                                    en = "ℹ️ O2 Lambda trim was already at factory neutral baseline (0200 / 0200).",
                                    it = "ℹ️ I valori Trim Sonda Lambda O2 erano già neutri di fabbrica (0200 / 0200).",
                                    fr = "ℹ️ Les trims Sonde Lambda O2 étaient déjà neutres d'usine (0200 / 0200).",
                                    es = "ℹ️ Los trims de la Sonda Lambda O2 ya estaban en neutro de fábrica (0200 / 0200).",
                                    de = "ℹ️ Lambdatrim-Werte waren bereits auf Werksneutralwert (0200 / 0200)."
                                )
                            } else {
                                localizedMsg(
                                    en = "✅ O2 Lambda Fuel Trim Reset CONFIRMED! Trim reset to neutral (0200 / 0200).",
                                    it = "✅ Reset Apprendimento Sonda Lambda O2 CONFERMATO! Trim azzerato a neutro (0200 / 0200).",
                                    fr = "✅ Réinitialisation Trim Lambda O2 CONFIRMÉE ! Valeurs neutres (0200 / 0200).",
                                    es = "✅ ¡Reinicio Trim Sonda Lambda O2 CONFIRMADO! Valores en neutro (0200 / 0200).",
                                    de = "✅ Lambdasonden-Gemischadaptions-Reset BESTÄTIGT! Neutralwerte (0200 / 0200)."
                                )
                            }
                        } else {
                            localizedMsg(
                                en = "⚠️ Command accepted (7B 52), but O2 trims NOT reset ($trim1 / $trim2).",
                                it = "⚠️ Comando accettato dalla centralina (7B 52), ma i trim O2 NON risultano azzerati ($trim1 / $trim2).",
                                fr = "⚠️ Commande acceptée (7B 52), mais trims O2 NON réinitialisés ($trim1 / $trim2).",
                                es = "⚠️ Comando aceptado (7B 52), pero los trims O2 NO están restablecidos ($trim1 / $trim2).",
                                de = "⚠️ Befehl akzeptiert (7B 52), aber O2-Trims NICHT zurückgesetzt ($trim1 / $trim2)."
                            )
                        }
                    }
                }
                "58" -> {
                    val p1 = dataHex.take(4)
                    val code67Flag = dataHex.drop(4).take(4)
                    val code87Flag = dataHex.drop(8).take(4)
                    iscTarget = p1
                    ecuCode67Flag = code67Flag
                    ecuCode87Flag = code87Flag
                    if (code67Flag == "0002") {
                        throttleCleaningLevel = 3
                    }
                }
            }
        }
    }

    companion object {
        fun isDangerousCommand(cmd: String): Pair<Boolean, String> {
            val clean = cmd.replace(" ", "").uppercase()
            return when {
                clean.startsWith("2E") -> Pair(true, "Scrittura parametri EEPROM (Service 0x2E)")
                clean.startsWith("34") || clean.startsWith("35") || clean.startsWith("36") || clean.startsWith("37") ->
                    Pair(true, "Riprogrammazione memoria flash ECU (Service 0x34..0x37)")
                clean.startsWith("1101") -> Pair(true, "Hard Reset immediato della centralina (Service 0x11)")
                else -> Pair(false, "")
            }
        }
    }
}
