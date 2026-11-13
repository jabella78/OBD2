package com.jabella78.yadiag.core

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

enum class AppLanguage(val rawValue: String) {
    ENGLISH("en"),
    ITALIAN("it"),
    FRENCH("fr"),
    SPANISH("es"),
    GERMAN("de");

    val displayName: String
        get() = when (this) {
            ITALIAN -> "Italiano"
            ENGLISH -> "English"
            FRENCH -> "Français"
            SPANISH -> "Español"
            GERMAN -> "Deutsch"
        }

    val flag: String
        get() = when (this) {
            ITALIAN -> "🇮🇹"
            ENGLISH -> "🇬🇧"
            FRENCH -> "🇫🇷"
            SPANISH -> "🇪🇸"
            GERMAN -> "🇩🇪"
        }

    companion object {
        val IT = ITALIAN
        val EN = ENGLISH
        val FR = FRENCH
        val ES = SPANISH
        val DE = GERMAN

        fun fromRaw(raw: String?): AppLanguage? = entries.find { it.rawValue == raw }
    }

    val code: String
        get() = rawValue
}

data class DisclaimerArticle(
    val title: String,
    val text: String
)

object LocalizationManager {
    private const val PREF_NAME = "yadiag_prefs"
    private const val KEY_LANG = "AppLanguage_v3"
    private var prefs: SharedPreferences? = null

    var currentLanguage by mutableStateOf(AppLanguage.ENGLISH)
        private set

    fun initialize(context: Context) {
        val sp = context.applicationContext.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs = sp
        val saved = sp.getString(KEY_LANG, null)
        currentLanguage = AppLanguage.fromRaw(saved) ?: AppLanguage.ENGLISH
    }

    fun setLanguage(lang: AppLanguage) {
        currentLanguage = lang
        prefs?.edit()?.putString(KEY_LANG, lang.rawValue)?.apply()
    }

    val language: AppLanguage
        get() = currentLanguage

    fun updateLanguage(lang: AppLanguage) = setLanguage(lang)

    fun getInstance(context: Context): LocalizationManager {
        initialize(context)
        return this
    }

    fun legalDisclaimerArticles(): List<Pair<String, String>> =
        disclaimerArticles.map { it.title to it.text }

    fun t(key: String): String {
        val map = localizedStrings[key] ?: return key
        return map[currentLanguage] ?: map[AppLanguage.ENGLISH] ?: key
    }

    private val localizedStrings: Map<String, Map<AppLanguage, String>> = mapOf(
        // Tabs
        "tab_dash" to mapOf(
            AppLanguage.ITALIAN to "Dash",
            AppLanguage.ENGLISH to "Dash",
            AppLanguage.FRENCH to "Tableau",
            AppLanguage.SPANISH to "Tablero",
            AppLanguage.GERMAN to "Cockpit"
        ),
        "tab_dtc" to mapOf(
            AppLanguage.ITALIAN to "DTC",
            AppLanguage.ENGLISH to "DTC",
            AppLanguage.FRENCH to "DTC",
            AppLanguage.SPANISH to "DTC",
            AppLanguage.GERMAN to "DTC"
        ),
        "tab_term" to mapOf(
            AppLanguage.ITALIAN to "Terminale",
            AppLanguage.ENGLISH to "Terminal",
            AppLanguage.FRENCH to "Terminal",
            AppLanguage.SPANISH to "Terminal",
            AppLanguage.GERMAN to "Terminal"
        ),
        "tab_ble" to mapOf(
            AppLanguage.ITALIAN to "Bluetooth",
            AppLanguage.ENGLISH to "Bluetooth",
            AppLanguage.FRENCH to "Bluetooth",
            AppLanguage.SPANISH to "Bluetooth",
            AppLanguage.GERMAN to "Bluetooth"
        ),
        "tab_actuators" to mapOf(
            AppLanguage.ITALIAN to "Test Attivi",
            AppLanguage.ENGLISH to "Active Tests",
            AppLanguage.FRENCH to "Tests Actifs",
            AppLanguage.SPANISH to "Pruebas Activas",
            AppLanguage.GERMAN to "Aktive Tests"
        ),
        "tab_setup" to mapOf(
            AppLanguage.ITALIAN to "Setup",
            AppLanguage.ENGLISH to "Setup",
            AppLanguage.FRENCH to "Configuration",
            AppLanguage.SPANISH to "Ajustes",
            AppLanguage.GERMAN to "Einstellungen"
        ),
        "tab_info" to mapOf(
            AppLanguage.ITALIAN to "Info & Modelli",
            AppLanguage.ENGLISH to "Info & Models",
            AppLanguage.FRENCH to "Info & Modèles",
            AppLanguage.SPANISH to "Info y Modelos",
            AppLanguage.GERMAN to "Info & Modelle"
        ),

        // Dashboard
        "dash_live_resume" to mapOf(
            AppLanguage.ITALIAN to "Avvia Live",
            AppLanguage.ENGLISH to "Start Live",
            AppLanguage.FRENCH to "Démarrer Live",
            AppLanguage.SPANISH to "Iniciar Live",
            AppLanguage.GERMAN to "Live Starten"
        ),
        "dash_live_pause" to mapOf(
            AppLanguage.ITALIAN to "Pausa Live",
            AppLanguage.ENGLISH to "Pause Live",
            AppLanguage.FRENCH to "Pause Live",
            AppLanguage.SPANISH to "Pausar Live",
            AppLanguage.GERMAN to "Live Pausieren"
        ),
        "dash_subtitle" to mapOf(
            AppLanguage.ITALIAN to "PRO TELEMETRY & DIAG • CAN-BUS 500 KBPS",
            AppLanguage.ENGLISH to "PRO TELEMETRY & DIAG • CAN-BUS 500 KBPS",
            AppLanguage.FRENCH to "TÉLÉMÉTRIE PRO & DIAG • CAN-BUS 500 KBPS",
            AppLanguage.SPANISH to "TELEMETRÍA PRO Y DIAG • CAN-BUS 500 KBPS",
            AppLanguage.GERMAN to "PROFI-TELEMETRIE & DIAGNOSE • CAN-BUS 500 KBPS"
        ),
        "ecu_connected" to mapOf(
            AppLanguage.ITALIAN to "Centralina Connessa",
            AppLanguage.ENGLISH to "ECU Connected",
            AppLanguage.FRENCH to "Calculateur Connecté",
            AppLanguage.SPANISH to "Centralita Conectada",
            AppLanguage.GERMAN to "Steuergerät Verbunden"
        ),
        "ecu_disconnected" to mapOf(
            AppLanguage.ITALIAN to "Disconnesso",
            AppLanguage.ENGLISH to "Disconnected",
            AppLanguage.FRENCH to "Déconnecté",
            AppLanguage.SPANISH to "Desconectado",
            AppLanguage.GERMAN to "Getrennt"
        ),
        "rpm_label" to mapOf(
            AppLanguage.ITALIAN to "Giri Motore",
            AppLanguage.ENGLISH to "Engine RPM",
            AppLanguage.FRENCH to "Régime Moteur",
            AppLanguage.SPANISH to "RPM Motor",
            AppLanguage.GERMAN to "Motordrehzahl"
        ),
        "speed_label" to mapOf(
            AppLanguage.ITALIAN to "Velocità",
            AppLanguage.ENGLISH to "Speed",
            AppLanguage.FRENCH to "Vitesse",
            AppLanguage.SPANISH to "Velocidad",
            AppLanguage.GERMAN to "Geschwindigkeit"
        ),
        "gear_label" to mapOf(
            AppLanguage.ITALIAN to "Marce",
            AppLanguage.ENGLISH to "Gear",
            AppLanguage.FRENCH to "Rapport",
            AppLanguage.SPANISH to "Marcha",
            AppLanguage.GERMAN to "Gang"
        ),
        "neutral_label" to mapOf(
            AppLanguage.ITALIAN to "Folle",
            AppLanguage.ENGLISH to "Neutral",
            AppLanguage.FRENCH to "Point Mort",
            AppLanguage.SPANISH to "Punto Muerto",
            AppLanguage.GERMAN to "Leerlauf"
        ),
        "coolant_temp" to mapOf(
            AppLanguage.ITALIAN to "Temperatura Liquido",
            AppLanguage.ENGLISH to "Coolant Temp",
            AppLanguage.FRENCH to "Temp. Liquide",
            AppLanguage.SPANISH to "Temp. Refrigerante",
            AppLanguage.GERMAN to "Kühlmitteltemp."
        ),
        "throttle_tps" to mapOf(
            AppLanguage.ITALIAN to "Apertura Farfalla (TPS)",
            AppLanguage.ENGLISH to "Throttle Position (TPS)",
            AppLanguage.FRENCH to "Ouverture Papillon (TPS)",
            AppLanguage.SPANISH to "Apertura Mariposa (TPS)",
            AppLanguage.GERMAN to "Drosselklappe (TPS)"
        ),
        "battery_volt" to mapOf(
            AppLanguage.ITALIAN to "Tensione Batteria",
            AppLanguage.ENGLISH to "Battery Voltage",
            AppLanguage.FRENCH to "Tension Batterie",
            AppLanguage.SPANISH to "Voltaje Batería",
            AppLanguage.GERMAN to "Batteriespannung"
        ),
        "lambda_afr" to mapOf(
            AppLanguage.ITALIAN to "Sonda Lambda / AFR",
            AppLanguage.ENGLISH to "O2 Sensor / AFR",
            AppLanguage.FRENCH to "Sonde Lambda / AFR",
            AppLanguage.SPANISH to "Sonda Lambda / AFR",
            AppLanguage.GERMAN to "Lambdasonde / AFR"
        ),
        "mix_stoich" to mapOf(
            AppLanguage.ITALIAN to "Stechiometrico (14.7 AFR)",
            AppLanguage.ENGLISH to "Stoichiometric (14.7 AFR)",
            AppLanguage.FRENCH to "Stœchiométrique (14.7 AFR)",
            AppLanguage.SPANISH to "Estequiométrico (14.7 AFR)",
            AppLanguage.GERMAN to "Stöchiometrisch (14.7 AFR)"
        ),
        "mix_lean" to mapOf(
            AppLanguage.ITALIAN to "Miscela Magra",
            AppLanguage.ENGLISH to "Lean Mixture",
            AppLanguage.FRENCH to "Mélange Pauvre",
            AppLanguage.SPANISH to "Mezcla Pobre",
            AppLanguage.GERMAN to "Mageres Gemisch"
        ),
        "mix_rich" to mapOf(
            AppLanguage.ITALIAN to "Miscela Grassa",
            AppLanguage.ENGLISH to "Rich Mixture",
            AppLanguage.FRENCH to "Mélange Riche",
            AppLanguage.SPANISH to "Mezcla Rica",
            AppLanguage.GERMAN to "Fettes Gemisch"
        ),
        "start_csv" to mapOf(
            AppLanguage.ITALIAN to "Avvia Registrazione CSV",
            AppLanguage.ENGLISH to "Start CSV Recording",
            AppLanguage.FRENCH to "Démarrer Enregistrement CSV",
            AppLanguage.SPANISH to "Iniciar Grabación CSV",
            AppLanguage.GERMAN to "CSV-Aufnahme Starten"
        ),
        "stop_csv" to mapOf(
            AppLanguage.ITALIAN to "Ferma Registrazione CSV",
            AppLanguage.ENGLISH to "Stop CSV Recording",
            AppLanguage.FRENCH to "Arrêter Enregistrement CSV",
            AppLanguage.SPANISH to "Detener Grabación CSV",
            AppLanguage.GERMAN to "CSV-Aufnahme Stoppen"
        ),
        "telemetry_start" to mapOf(
            AppLanguage.ITALIAN to "Avvia Telemetria Live",
            AppLanguage.ENGLISH to "Start Live Telemetry",
            AppLanguage.FRENCH to "Démarrer Télémétrie",
            AppLanguage.SPANISH to "Iniciar Telemetría",
            AppLanguage.GERMAN to "Live-Telemetrie Starten"
        ),
        "telemetry_stop" to mapOf(
            AppLanguage.ITALIAN to "Ferma Telemetria",
            AppLanguage.ENGLISH to "Stop Telemetry",
            AppLanguage.FRENCH to "Arrêter Télémétrie",
            AppLanguage.SPANISH to "Detener Telemetría",
            AppLanguage.GERMAN to "Telemetrie Stoppen"
        ),
        "telemetry_paused_notice" to mapOf(
            AppLanguage.ITALIAN to "Telemetria in pausa (Bus CAN libero per Diagnosi/Test)",
            AppLanguage.ENGLISH to "Telemetry paused (CAN Bus idle for Diagnostics/Tests)",
            AppLanguage.FRENCH to "Télémétrie en pause (Bus CAN libre pour Diagnostic)",
            AppLanguage.SPANISH to "Telemetría en pausa (Bus CAN libre para Diagnóstico)",
            AppLanguage.GERMAN to "Telemetrie pausiert (CAN-Bus frei für Diagnose)"
        ),
        "telemetry_active_notice" to mapOf(
            AppLanguage.ITALIAN to "Telemetria live attiva (Aggiornamento continuo)",
            AppLanguage.ENGLISH to "Live telemetry active (Continuous streaming)",
            AppLanguage.FRENCH to "Télémétrie live active (Flux continu)",
            AppLanguage.SPANISH to "Telemetría activa (Flujo continuo)",
            AppLanguage.GERMAN to "Live-Telemetrie aktiv (Kontinuierliches Streaming)"
        ),
        "samples_recorded" to mapOf(
            AppLanguage.ITALIAN to "Campioni registrati:",
            AppLanguage.ENGLISH to "Recorded samples:",
            AppLanguage.FRENCH to "Échantillons enregistrés :",
            AppLanguage.SPANISH to "Muestras registradas:",
            AppLanguage.GERMAN to "Aufgezeichnete Werte:"
        ),

        // Diagnostics (DTC)
        "dtc_title" to mapOf(
            AppLanguage.ITALIAN to "Diagnosi DTC Centralina",
            AppLanguage.ENGLISH to "ECU DTC Diagnostics",
            AppLanguage.FRENCH to "Diagnostic DTC Calculateur",
            AppLanguage.SPANISH to "Diagnóstico DTC Centralita",
            AppLanguage.GERMAN to "Steuergerät DTC-Diagnose"
        ),
        "scan_dtc_btn" to mapOf(
            AppLanguage.ITALIAN to "Scansione DTC (Mode 03/07/0A)",
            AppLanguage.ENGLISH to "Scan DTC (Mode 03/07/0A)",
            AppLanguage.FRENCH to "Scanner DTC (Mode 03/07/0A)",
            AppLanguage.SPANISH to "Escanear DTC (Mode 03/07/0A)",
            AppLanguage.GERMAN to "DTC Scannen (Mode 03/07/0A)"
        ),
        "scanning" to mapOf(
            AppLanguage.ITALIAN to "Scansione in corso...",
            AppLanguage.ENGLISH to "Scanning in progress...",
            AppLanguage.FRENCH to "Scan en cours...",
            AppLanguage.SPANISH to "Escaneo en curso...",
            AppLanguage.GERMAN to "Scan läuft..."
        ),
        "clear_dtc_btn" to mapOf(
            AppLanguage.ITALIAN to "Cancella Errori (Mode 04)",
            AppLanguage.ENGLISH to "Clear Codes (Mode 04)",
            AppLanguage.FRENCH to "Effacer Codes (Mode 04)",
            AppLanguage.SPANISH to "Borrar Códigos (Mode 04)",
            AppLanguage.GERMAN to "Fehler Löschen (Mode 04)"
        ),
        "clearing" to mapOf(
            AppLanguage.ITALIAN to "Azzeramento in corso...",
            AppLanguage.ENGLISH to "Clearing in progress...",
            AppLanguage.FRENCH to "Effacement en cours...",
            AppLanguage.SPANISH to "Borrando códigos...",
            AppLanguage.GERMAN to "Löschen läuft..."
        ),
        "ai_eval_btn" to mapOf(
            AppLanguage.ITALIAN to "Valutazione Diagnostica AI",
            AppLanguage.ENGLISH to "AI Diagnostic Analysis",
            AppLanguage.FRENCH to "Analyse Diagnostique IA",
            AppLanguage.SPANISH to "Evaluación Diagnóstica con IA",
            AppLanguage.GERMAN to "KI-Diagnoseanalyse"
        ),
        "mil_on" to mapOf(
            AppLanguage.ITALIAN to "Spia Motore (MIL): ACCESA",
            AppLanguage.ENGLISH to "Check Engine (MIL): ON",
            AppLanguage.FRENCH to "Voyant Moteur (MIL) : ALLUMÉ",
            AppLanguage.SPANISH to "Testigo Motor (MIL): ENCENDIDO",
            AppLanguage.GERMAN to "Motorkontrollleuchte (MIL): AN"
        ),
        "mil_off" to mapOf(
            AppLanguage.ITALIAN to "Spia Motore (MIL): SPENTA",
            AppLanguage.ENGLISH to "Check Engine (MIL): OFF",
            AppLanguage.FRENCH to "Voyant Moteur (MIL) : ÉTEINT",
            AppLanguage.SPANISH to "Testigo Motor (MIL): APAGADO",
            AppLanguage.GERMAN to "Motorkontrollleuchte (MIL): AUS"
        ),
        "no_dtc_message" to mapOf(
            AppLanguage.ITALIAN to "Nessun codice errore DTC rilevato nella centralina.",
            AppLanguage.ENGLISH to "No DTC fault codes detected in ECU.",
            AppLanguage.FRENCH to "Aucun code défaut DTC détecté dans le calculateur.",
            AppLanguage.SPANISH to "No se detectaron códigos de avería DTC en la centralita.",
            AppLanguage.GERMAN to "Keine DTC-Fehlercodes im Steuergerät erkannt."
        ),
        "confirm_clear_title" to mapOf(
            AppLanguage.ITALIAN to "Conferma Cancellazione Errori",
            AppLanguage.ENGLISH to "Confirm DTC Clearing",
            AppLanguage.FRENCH to "Confirmer l'effacement",
            AppLanguage.SPANISH to "Confirmar Borrado de Códigos",
            AppLanguage.GERMAN to "Fehlerlöschung Bestätigen"
        ),
        "confirm_clear_msg" to mapOf(
            AppLanguage.ITALIAN to "Sei sicuro di voler azzerare tutti i codici errore registrati nella centralina?",
            AppLanguage.ENGLISH to "Are you sure you want to clear all fault codes stored in the ECU?",
            AppLanguage.FRENCH to "Êtes-vous sûr de vouloir effacer tous les codes défaut mémorisés dans le calculateur ?",
            AppLanguage.SPANISH to "¿Estás seguro de que deseas borrar todos los códigos de error almacenados en la centralita?",
            AppLanguage.GERMAN to "Sind Sie sicher, dass Sie alle im Steuergerät gespeicherten Fehlercodes löschen möchten?"
        ),
        "cancel" to mapOf(
            AppLanguage.ITALIAN to "Annulla",
            AppLanguage.ENGLISH to "Cancel",
            AppLanguage.FRENCH to "Annuler",
            AppLanguage.SPANISH to "Cancelar",
            AppLanguage.GERMAN to "Abbrechen"
        ),
        "confirm_delete" to mapOf(
            AppLanguage.ITALIAN to "Cancella DTC",
            AppLanguage.ENGLISH to "Clear DTC",
            AppLanguage.FRENCH to "Effacer DTC",
            AppLanguage.SPANISH to "Borrar DTC",
            AppLanguage.GERMAN to "DTC Löschen"
        ),

        // BLE Connection
        "ble_title" to mapOf(
            AppLanguage.ITALIAN to "Gestione Connessione BLE",
            AppLanguage.ENGLISH to "BLE Connection Manager",
            AppLanguage.FRENCH to "Gestion Connexion BLE",
            AppLanguage.SPANISH to "Gestión de Conexión BLE",
            AppLanguage.GERMAN to "BLE-Verbindungsmanager"
        ),
        "ble_scan_btn" to mapOf(
            AppLanguage.ITALIAN to "Scansione Adattatori OBD2",
            AppLanguage.ENGLISH to "Scan OBD2 Adapters",
            AppLanguage.FRENCH to "Recherche Adaptateurs OBD2",
            AppLanguage.SPANISH to "Buscar Adaptadores OBD2",
            AppLanguage.GERMAN to "OBD2-Adapter Suchen"
        ),
        "ble_stop_scan_btn" to mapOf(
            AppLanguage.ITALIAN to "Ferma Scansione",
            AppLanguage.ENGLISH to "Stop Scan",
            AppLanguage.FRENCH to "Arrêter Recherche",
            AppLanguage.SPANISH to "Detener Búsqueda",
            AppLanguage.GERMAN to "Suche Beenden"
        ),
        "ble_connect" to mapOf(
            AppLanguage.ITALIAN to "Connetti",
            AppLanguage.ENGLISH to "Connect",
            AppLanguage.FRENCH to "Connecter",
            AppLanguage.SPANISH to "Conectar",
            AppLanguage.GERMAN to "Verbinden"
        ),
        "ble_disconnect" to mapOf(
            AppLanguage.ITALIAN to "Disconnetti",
            AppLanguage.ENGLISH to "Disconnect",
            AppLanguage.FRENCH to "Déconnecter",
            AppLanguage.SPANISH to "Desconectar",
            AppLanguage.GERMAN to "Trennen"
        ),
        "ble_connected_to" to mapOf(
            AppLanguage.ITALIAN to "Connesso a:",
            AppLanguage.ENGLISH to "Connected to:",
            AppLanguage.FRENCH to "Connecté à :",
            AppLanguage.SPANISH to "Conectado a:",
            AppLanguage.GERMAN to "Verbunden mit:"
        ),
        "ble_not_connected" to mapOf(
            AppLanguage.ITALIAN to "Non connesso ad alcun adattatore.",
            AppLanguage.ENGLISH to "Not connected to any adapter.",
            AppLanguage.FRENCH to "Non connecté à un adaptateur.",
            AppLanguage.SPANISH to "No conectado a ningún adaptador.",
            AppLanguage.GERMAN to "Nicht mit einem Adapter verbunden."
        ),
        "ble_ext_mode" to mapOf(
            AppLanguage.ITALIAN to "Modalità Compatibilità Estesa (Tutti i BLE)",
            AppLanguage.ENGLISH to "Extended Compatibility Mode (All BLE)",
            AppLanguage.FRENCH to "Mode Compatibilité Étendue (Tous BLE)",
            AppLanguage.SPANISH to "Modo Compatibilidad Extendida (Todos BLE)",
            AppLanguage.GERMAN to "Erweiterter Kompatibilitätsmodus (Alle BLE)"
        ),
        "ble_ext_desc" to mapOf(
            AppLanguage.ITALIAN to "Quando attiva mostra qualsiasi dispositivo BLE generico (ELM327). Quando disattivata filtra solo gli adattatori ad alte prestazioni certificati (UniCarScan, vLinker, OBDLink, Veepeak, Carista).",
            AppLanguage.ENGLISH to "When active, displays any generic BLE device (ELM327). When disabled, filters only high-performance certified adapters (UniCarScan, vLinker, OBDLink, Veepeak, Carista).",
            AppLanguage.FRENCH to "Lorsqu'il est activé, affiche tous les appareils BLE génériques (ELM327). Désactivé, filtre uniquement les adaptateurs certifiés haute performance (UniCarScan, vLinker, OBDLink, Veepeak, Carista).",
            AppLanguage.SPANISH to "Cuando está activo muestra cualquier dispositivo BLE genérico (ELM327). Cuando está desactivado filtra solo adaptadores certificados de alto rendimiento (UniCarScan, vLinker, OBDLink, Veepeak, Carista).",
            AppLanguage.GERMAN to "Wenn aktiviert, zeigt es beliebige generische BLE-Geräte (ELM327). Wenn deaktiviert, werden nur zertifizierte Hochleistungsadapter gefiltert (UniCarScan, vLinker, OBDLink, Veepeak, Carista)."
        ),
        "ble_simulator_card_title" to mapOf(
            AppLanguage.ITALIAN to "Simulatore OBD2 Virtuale (Offline)",
            AppLanguage.ENGLISH to "Virtual OBD2 Simulator (Offline)",
            AppLanguage.FRENCH to "Simulateur OBD2 Virtuel (Hors ligne)",
            AppLanguage.SPANISH to "Simulador OBD2 Virtual (Offline)",
            AppLanguage.GERMAN to "Virtueller OBD2-Simulator (Offline)"
        ),
        "ble_sim_active_banner" to mapOf(
            AppLanguage.ITALIAN to "SIMULATORE BANCO PROVA ATTIVO",
            AppLanguage.ENGLISH to "BENCH TEST SIMULATOR ACTIVE",
            AppLanguage.FRENCH to "SIMULATEUR BANC D'ESSAI ACTIF",
            AppLanguage.SPANISH to "SIMULADOR BANCO DE PRUEBAS ACTIVO",
            AppLanguage.GERMAN to "PRÜFSTAND-SIMULATOR AKTIV"
        ),
        "ble_simulator_card_desc" to mapOf(
            AppLanguage.ITALIAN to "Testa tutte le funzionalità dell'app senza moto né adattatore fisico.",
            AppLanguage.ENGLISH to "Test all app features without motorcycle or physical adapter.",
            AppLanguage.FRENCH to "Testez toutes les fonctionnalités sans moto ni adaptateur physique.",
            AppLanguage.SPANISH to "Prueba todas las funciones de la app sin moto ni adaptador físico.",
            AppLanguage.GERMAN to "Alle App-Funktionen ohne Motorrad oder physischen Adapter testen."
        ),
        "ble_simulator_connect" to mapOf(
            AppLanguage.ITALIAN to "Connetti Simulatore Virtuale",
            AppLanguage.ENGLISH to "Connect Virtual Simulator",
            AppLanguage.FRENCH to "Connecter le Simulateur Virtuel",
            AppLanguage.SPANISH to "Conectar Simulador Virtual",
            AppLanguage.GERMAN to "Virtuellen Simulator Verbinden"
        ),
        "ble_simulator_disconnect" to mapOf(
            AppLanguage.ITALIAN to "Disconnetti Simulatore",
            AppLanguage.ENGLISH to "Disconnect Simulator",
            AppLanguage.FRENCH to "Déconnecter le Simulateur",
            AppLanguage.SPANISH to "Desconectar Simulador",
            AppLanguage.GERMAN to "Simulator Trennen"
        ),
        "ble_bench_mode_title" to mapOf(
            AppLanguage.ITALIAN to "Simulatore Banco Prova (Demo)",
            AppLanguage.ENGLISH to "Bench Test Simulator (Demo)",
            AppLanguage.FRENCH to "Simulateur Banc d'Essai (Démo)",
            AppLanguage.SPANISH to "Simulador Banco de Pruebas (Demo)",
            AppLanguage.GERMAN to "Prüfstand-Simulator (Demo)"
        ),
        "ble_bench_mode_active" to mapOf(
            AppLanguage.ITALIAN to "Dati virtuali attivi (10 Hz)",
            AppLanguage.ENGLISH to "Virtual live data active (10 Hz)",
            AppLanguage.FRENCH to "Données virtuelles actives (10 Hz)",
            AppLanguage.SPANISH to "Datos virtuales activos (10 Hz)",
            AppLanguage.GERMAN to "Virtuelle Daten aktiv (10 Hz)"
        ),
        "ble_bench_mode_idle" to mapOf(
            AppLanguage.ITALIAN to "Modalità banco dinamico",
            AppLanguage.ENGLISH to "Dynamic bench mode",
            AppLanguage.FRENCH to "Mode banc d'essai dynamique",
            AppLanguage.SPANISH to "Modo banco dinámico",
            AppLanguage.GERMAN to "Dynamischer Prüfstandmodus"
        ),
        "ble_no_devices" to mapOf(
            AppLanguage.ITALIAN to "Nessun adattatore OBD2 rilevato nelle vicinanze.",
            AppLanguage.ENGLISH to "No OBD2 adapters detected nearby.",
            AppLanguage.FRENCH to "Aucun adaptateur OBD2 détecté à proximité.",
            AppLanguage.SPANISH to "No se detectaron adaptadores OBD2 cercanos.",
            AppLanguage.GERMAN to "Keine OBD2-Adapter in der Nähe gefunden."
        ),
        "ble_insert_hint" to mapOf(
            AppLanguage.ITALIAN to "Inserisci l'adattatore nella presa diagnostica della moto con il quadro acceso (Key ON).",
            AppLanguage.ENGLISH to "Plug adapter into bike diagnostic port with ignition turned ON (Key ON).",
            AppLanguage.FRENCH to "Branchez l'adaptateur sur la prise diag de la moto avec le contact allumé (Key ON).",
            AppLanguage.SPANISH to "Conecta el adaptador a la toma de diagnosis de la moto con el contacto dado (Key ON).",
            AppLanguage.GERMAN to "Adapter bei eingeschalteter Zündung (Key ON) an die Diagnosebuchse anschließen."
        ),
        "ble_certified_badge" to mapOf(
            AppLanguage.ITALIAN to "Certificato e Raccomandato",
            AppLanguage.ENGLISH to "Certified & Recommended",
            AppLanguage.FRENCH to "Certifié et Recommandé",
            AppLanguage.SPANISH to "Certificado y Recomendado",
            AppLanguage.GERMAN to "Zertifiziert & Empfohlen"
        ),
        "ble_generic_badge" to mapOf(
            AppLanguage.ITALIAN to "Compatibilità generica ELM327",
            AppLanguage.ENGLISH to "Generic ELM327 Compatibility",
            AppLanguage.FRENCH to "Compatibilité générique ELM327",
            AppLanguage.SPANISH to "Compatibilidad genérica ELM327",
            AppLanguage.GERMAN to "Generische ELM327-Kompatibilität"
        ),
        "ble_device_default" to mapOf(
            AppLanguage.ITALIAN to "Dispositivo OBD",
            AppLanguage.ENGLISH to "OBD Device",
            AppLanguage.FRENCH to "Appareil OBD",
            AppLanguage.SPANISH to "Dispositivo OBD",
            AppLanguage.GERMAN to "OBD-Gerät"
        ),
        "ble_simulated_protocol" to mapOf(
            AppLanguage.ITALIAN to "Protocollo CAN Bus 500k ISO 15765-4 simulato (Nessun Bluetooth richiesto)",
            AppLanguage.ENGLISH to "Simulated 500k ISO 15765-4 CAN Bus Protocol (No Bluetooth required)",
            AppLanguage.FRENCH to "Protocole CAN Bus 500k ISO 15765-4 simulé (Sans Bluetooth requis)",
            AppLanguage.SPANISH to "Protocolo CAN Bus 500k ISO 15765-4 simulado (Sin Bluetooth requerido)",
            AppLanguage.GERMAN to "Simuliertes 500k ISO 15765-4 CAN-Bus-Protokoll (Kein Bluetooth erforderlich)"
        ),

        // Terminal
        "term_title" to mapOf(
            AppLanguage.ITALIAN to "Console Terminale OBD2",
            AppLanguage.ENGLISH to "OBD2 Terminal Console",
            AppLanguage.FRENCH to "Console Terminal OBD2",
            AppLanguage.SPANISH to "Consola Terminal OBD2",
            AppLanguage.GERMAN to "OBD2-Terminal-Konsole"
        ),
        "term_desc" to mapOf(
            AppLanguage.ITALIAN to "Invia comandi personalizzati AT o CAN bus (es. 0100, 221101, ATZ):",
            AppLanguage.ENGLISH to "Send custom AT or CAN bus commands (e.g. 0100, 221101, ATZ):",
            AppLanguage.FRENCH to "Envoyez des commandes personnalisées AT ou CAN bus (ex: 0100, 221101, ATZ) :",
            AppLanguage.SPANISH to "Envía comandos personalizados AT o CAN bus (ej. 0100, 221101, ATZ):",
            AppLanguage.GERMAN to "Benutzerdefinierte AT- oder CAN-Bus-Befehle senden (z.B. 0100, 221101, ATZ):"
        ),
        "term_send" to mapOf(
            AppLanguage.ITALIAN to "Invia",
            AppLanguage.ENGLISH to "Send",
            AppLanguage.FRENCH to "Envoyer",
            AppLanguage.SPANISH to "Enviar",
            AppLanguage.GERMAN to "Senden"
        ),
        "term_clear" to mapOf(
            AppLanguage.ITALIAN to "Pulisci Console",
            AppLanguage.ENGLISH to "Clear Console",
            AppLanguage.FRENCH to "Effacer Console",
            AppLanguage.SPANISH to "Limpiar Consola",
            AppLanguage.GERMAN to "Konsole Leeren"
        ),
        "term_danger_alert" to mapOf(
            AppLanguage.ITALIAN to "Attenzione: il comando inserito interagisce con funzioni critiche. L'invio di sequenze errate potrebbe provocare errori permanenti o anomalie di funzionamento della centralina.",
            AppLanguage.ENGLISH to "Warning: The entered command interacts with critical ECU routines. Sending incorrect sequences may cause permanent ECU errors or malfunctions.",
            AppLanguage.FRENCH to "Attention : La commande saisie interagit avec des fonctions critiques. L'envoi de séquences incorrectes peut provoquer des erreurs permanentes.",
            AppLanguage.SPANISH to "Atención: El comando ingresado interactúa con funciones críticas. Enviar secuencias incorrectas puede provocar anomalías permanentes.",
            AppLanguage.GERMAN to "Achtung: Der eingegebene Befehl interagiert mit kritischen Steuergerätefunktionen. Falsche Sequenzen können dauerhafte Fehler verursachen."
        ),

        // Actuators
        "act_title" to mapOf(
            AppLanguage.ITALIAN to "Funzioni Speciali & Attuatori",
            AppLanguage.ENGLISH to "Special Functions & Actuators",
            AppLanguage.FRENCH to "Fonctions Spéciales & Actionneurs",
            AppLanguage.SPANISH to "Funciones Especiales y Actuadores",
            AppLanguage.GERMAN to "Sonderfunktionen & Aktoren"
        ),
        "act_category" to mapOf(
            AppLanguage.ITALIAN to "Unità di Controllo",
            AppLanguage.ENGLISH to "Control Unit",
            AppLanguage.FRENCH to "Unité de Contrôle",
            AppLanguage.SPANISH to "Unidad de Control",
            AppLanguage.GERMAN to "Steuergerät-Auswahl"
        ),
        "act_danger_title" to mapOf(
            AppLanguage.ITALIAN to "PERICOLO: MOTORE IN MOTO O RUOTE IN MOVIMENTO!",
            AppLanguage.ENGLISH to "DANGER: ENGINE RUNNING OR WHEELS IN MOTION!",
            AppLanguage.FRENCH to "DANGER : MOTEUR EN MARCHE OU ROUES EN MOUVEMENT !",
            AppLanguage.SPANISH to "¡PELIGRO: MOTOR EN MARCHA O RUEDAS EN MOVIMIENTO!",
            AppLanguage.GERMAN to "GEFAHR: MOTOR LÄUFT ODER RÄDER DREHEN SICH!"
        ),
        "act_danger_msg" to mapOf(
            AppLanguage.ITALIAN to "I reset adattivi sono disabilitati mentre il motore gira. Spegni il motore e lascia solo il quadro acceso (Key ON).",
            AppLanguage.ENGLISH to "Adaptive resets are disabled while the engine runs. Stop engine and keep ignition ON.",
            AppLanguage.FRENCH to "Les réinitialisations adaptatives sont désactivées pendant que le moteur tourne. Coupez le moteur et laissez le contact.",
            AppLanguage.SPANISH to "Los reinicios adaptativos están deshabilitados con el motor encendido. Apaga el motor y mantén el contacto.",
            AppLanguage.GERMAN to "Adaptive Resets sind bei laufendem Motor gesperrt. Motor ausschalten und nur Zündung eingeschaltet lassen."
        ),
        "act_ready_engine" to mapOf(
            AppLanguage.ITALIAN to "Motore fermo. Funzioni di verifica e reset adattivo FI ECU (7E0) sbloccate.",
            AppLanguage.ENGLISH to "Engine stopped. FI ECU (7E0) adaptive check and reset functions unlocked.",
            AppLanguage.FRENCH to "Moteur arrêté. Fonctions de contrôle et réinitialisation adaptative FI ECU (7E0) déverrouillées.",
            AppLanguage.SPANISH to "Motor apagado. Funciones de verificación y reinicio adaptativo FI ECU (7E0) desbloqueadas.",
            AppLanguage.GERMAN to "Motor aus. FI ECU (7E0) Prüf- und adaptive Resetfunktionen freigeschaltet."
        ),
        "act_start_btn" to mapOf(
            AppLanguage.ITALIAN to "Avvia Procedura",
            AppLanguage.ENGLISH to "Start Procedure",
            AppLanguage.FRENCH to "Démarrer la Procédure",
            AppLanguage.SPANISH to "Iniciar Procedimiento",
            AppLanguage.GERMAN to "Vorgang Starten"
        ),
        "act_executing_btn" to mapOf(
            AppLanguage.ITALIAN to "Esecuzione in corso...",
            AppLanguage.ENGLISH to "Executing...",
            AppLanguage.FRENCH to "Exécution en cours...",
            AppLanguage.SPANISH to "Ejecutando...",
            AppLanguage.GERMAN to "Wird ausgeführt..."
        ),
        "act_status_ready" to mapOf(
            AppLanguage.ITALIAN to "Pronto. Seleziona una procedura per iniziare il reset.",
            AppLanguage.ENGLISH to "Ready. Select an adaptive routine to start reset procedure.",
            AppLanguage.FRENCH to "Prêt. Sélectionnez une routine pour lancer la réinitialisation.",
            AppLanguage.SPANISH to "Listo. Selecciona una rutina para iniciar el reinicio.",
            AppLanguage.GERMAN to "Bereit. Wählen Sie eine adaptive Routine, um den Reset zu starten."
        ),

        // Setup (Language + AI)
        "setup_pro_features_active" to mapOf(
            AppLanguage.ITALIAN to "Tutte le funzioni professionali (Cancellazione Guasti DTC, Guida Reset Tagliando, Certificato Diagnostico PDF, Reset Corpi Farfallati ISC, Reset Lambda O2 e Diagnostica AI) sono attive su questa applicazione.",
            AppLanguage.ENGLISH to "All professional features (DTC Fault Clearing, Dashboard Service Reset Guide, PDF Diagnostic Reports, ISC Throttle Body Reset, Lambda O2 Reset, and AI Diagnostics) are active in this application.",
            AppLanguage.FRENCH to "Toutes les fonctions professionnelles (Effacement DTC, Guide Reset Vidange, Certificats PDF, Réinitialisation ISC/Lambda, et Diagnostic IA) sont actives.",
            AppLanguage.SPANISH to "Todas las funciones profesionales (Borrado de DTC, Guía Reset Aceite, Certificados PDF, Reinicios ISC/Lambda y Diagnóstico IA) están activas.",
            AppLanguage.GERMAN to "Alle professionellen Funktionen (DTC-Löschen, Service-Reset-Anleitung, PDF-Prüfbericht, ISC-/Lambda-Reset und KI-Diagnose) sind in dieser Version aktiv."
        ),
        "setup_lang_section" to mapOf(
            AppLanguage.ITALIAN to "Lingua dell'Applicazione",
            AppLanguage.ENGLISH to "Application Language",
            AppLanguage.FRENCH to "Langue de l'application",
            AppLanguage.SPANISH to "Idioma de la aplicación",
            AppLanguage.GERMAN to "App-Sprache"
        ),
        "setup_lang_desc" to mapOf(
            AppLanguage.ITALIAN to "Seleziona la lingua dell'interfaccia, dei menu e dei documenti legali.",
            AppLanguage.ENGLISH to "Select the language for user interface, menus and legal notices.",
            AppLanguage.FRENCH to "Sélectionnez la langue de l'interface, des menus et des mentions légales.",
            AppLanguage.SPANISH to "Selecciona el idioma de la interfaz, menús y documentos legales.",
            AppLanguage.GERMAN to "Wählen Sie die Sprache für Benutzeroberfläche, Menüs und Rechtshinweise."
        ),
        "setup_ai_section" to mapOf(
            AppLanguage.ITALIAN to "Configurazione AI & Modelli LLM",
            AppLanguage.ENGLISH to "AI & LLM Model Configuration",
            AppLanguage.FRENCH to "Configuration IA & Modèles LLM",
            AppLanguage.SPANISH to "Configuración de IA y Modelos LLM",
            AppLanguage.GERMAN to "KI- & LLM-Modellkonfiguration"
        ),
        "setup_ai_desc" to mapOf(
            AppLanguage.ITALIAN to "Personalizza il motore di intelligenza artificiale per diagnosi DTC e telemetria",
            AppLanguage.ENGLISH to "Customize AI engine for DTC diagnostics and telemetry analysis",
            AppLanguage.FRENCH to "Personnalisez le moteur d'IA pour diagnostics DTC et télémétrie",
            AppLanguage.SPANISH to "Personaliza el motor de IA para diagnósticos DTC y telemetría",
            AppLanguage.GERMAN to "KI-Engine für DTC-Diagnose und Telemetrie anpassen"
        ),
        "setup_provider_label" to mapOf(
            AppLanguage.ITALIAN to "1. Provider Intelligenza Artificiale:",
            AppLanguage.ENGLISH to "1. AI Provider:",
            AppLanguage.FRENCH to "1. Fournisseur d'IA :",
            AppLanguage.SPANISH to "1. Proveedor de IA:",
            AppLanguage.GERMAN to "1. KI-Anbieter:"
        ),
        "setup_model_label" to mapOf(
            AppLanguage.ITALIAN to "2. Modello LLM (Menu a tendina):",
            AppLanguage.ENGLISH to "2. LLM Model (Dropdown menu):",
            AppLanguage.FRENCH to "2. Modèle LLM (Menu déroulant) :",
            AppLanguage.SPANISH to "2. Modelo LLM (Menú desplegable):",
            AppLanguage.GERMAN to "2. LLM-Modell (Dropdown-Menü):"
        ),
        "setup_sync_btn" to mapOf(
            AppLanguage.ITALIAN to "Sincronizza Nuove Release",
            AppLanguage.ENGLISH to "Sync New Releases",
            AppLanguage.FRENCH to "Synchroniser Nouvelles Versions",
            AppLanguage.SPANISH to "Sincronizar Nuevas Versiones",
            AppLanguage.GERMAN to "Neue Versionen Synchronisieren"
        ),
        "setup_apikey_label" to mapOf(
            AppLanguage.ITALIAN to "3. Chiave API per",
            AppLanguage.ENGLISH to "3. API Key for",
            AppLanguage.FRENCH to "3. Clé API pour",
            AppLanguage.SPANISH to "3. Clave API para",
            AppLanguage.GERMAN to "3. API-Schlüssel für"
        ),
        "setup_apikey_security" to mapOf(
            AppLanguage.ITALIAN to "La chiave API viene conservata localmente sul tuo dispositivo e inviata solo ed esclusivamente all'endpoint del provider selezionato.",
            AppLanguage.ENGLISH to "The API key is stored locally on your device and sent solely to the selected provider endpoint.",
            AppLanguage.FRENCH to "La clé API est conservée localement sur votre appareil et envoyée uniquement au serveur du fournisseur sélectionné.",
            AppLanguage.SPANISH to "La clave API se almacena localmente en tu dispositivo y se envía únicamente al proveedor seleccionado.",
            AppLanguage.GERMAN to "Der API-Schlüssel wird lokal auf Ihrem Gerät gespeichert und ausschließlich an den ausgewählten Anbieter übertragen."
        ),
        "setup_providers_guide" to mapOf(
            AppLanguage.ITALIAN to "Guida ai Provider Supportati",
            AppLanguage.ENGLISH to "Supported Providers Guide",
            AppLanguage.FRENCH to "Guide des Fournisseurs Supportés",
            AppLanguage.SPANISH to "Guía de Proveedores Compatibles",
            AppLanguage.GERMAN to "Leitfaden Unterstützte Anbieter"
        ),
        "setup_custom_model_name" to mapOf(
            AppLanguage.ITALIAN to "Nome Modello Personalizzato (es. llama3, mistral, qwen2.5):",
            AppLanguage.ENGLISH to "Custom Model Name (e.g. llama3, mistral, qwen2.5):",
            AppLanguage.FRENCH to "Nom du modèle personnalisé (ex. llama3, mistral, qwen2.5) :",
            AppLanguage.SPANISH to "Nombre del modelo personalizado (ej. llama3, mistral, qwen2.5):",
            AppLanguage.GERMAN to "Benutzerdefinierter Modellname (z.B. llama3, mistral, qwen2.5):"
        ),
        "setup_custom_model_placeholder" to mapOf(
            AppLanguage.ITALIAN to "Nome modello",
            AppLanguage.ENGLISH to "Model name",
            AppLanguage.FRENCH to "Nom du modèle",
            AppLanguage.SPANISH to "Nombre del modelo",
            AppLanguage.GERMAN to "Modellname"
        ),
        "setup_custom_endpoint_label" to mapOf(
            AppLanguage.ITALIAN to "Base URL Endpoint OpenAI-compatible:",
            AppLanguage.ENGLISH to "OpenAI-compatible Endpoint Base URL:",
            AppLanguage.FRENCH to "URL de base du point de terminaison OpenAI-compatible :",
            AppLanguage.SPANISH to "URL base del endpoint compatible con OpenAI:",
            AppLanguage.GERMAN to "Basis-URL für OpenAI-kompatiblen Endpunkt:"
        ),
        "setup_selected_model_picker" to mapOf(
            AppLanguage.ITALIAN to "Modello Selezionato",
            AppLanguage.ENGLISH to "Selected Model",
            AppLanguage.FRENCH to "Modèle sélectionné",
            AppLanguage.SPANISH to "Modelo seleccionado",
            AppLanguage.GERMAN to "Ausgewähltes Modell"
        ),

        // Info & Legal Disclaimer
        "info_title" to mapOf(
            AppLanguage.ITALIAN to "YaDiag — Guida & Modelli Compatibili",
            AppLanguage.ENGLISH to "YaDiag — Guide & Compatible Models",
            AppLanguage.FRENCH to "YaDiag — Guide & Modèles Compatibles",
            AppLanguage.SPANISH to "YaDiag — Guía y Modelos Compatibles",
            AppLanguage.GERMAN to "YaDiag — Handbuch & Kompatible Modelle"
        ),
        "info_read_terms" to mapOf(
            AppLanguage.ITALIAN to "Rileggi Condizioni d'Uso & Disclaimer Legale",
            AppLanguage.ENGLISH to "Review Terms of Use & Legal Disclaimer",
            AppLanguage.FRENCH to "Relire les Conditions d'Utilisation & Mentions Légales",
            AppLanguage.SPANISH to "Releer Términos de Uso y Descargo Legal",
            AppLanguage.GERMAN to "Nutzungsbedingungen & Haftungsausschluss erneut lesen"
        ),
        "disclaimer_title" to mapOf(
            AppLanguage.ITALIAN to "Condizioni d'Uso ed Esonero di Responsabilità",
            AppLanguage.ENGLISH to "Terms of Use & Limitation of Liability",
            AppLanguage.FRENCH to "Conditions d'Utilisation & Limitation de Responsabilité",
            AppLanguage.SPANISH to "Términos de Uso y Exoneración de Responsabilidad",
            AppLanguage.GERMAN to "Nutzungsbedingungen & Haftungsausschluss"
        ),
        "disclaimer_version" to mapOf(
            AppLanguage.ITALIAN to "Versione Applicazione:",
            AppLanguage.ENGLISH to "Application Version:",
            AppLanguage.FRENCH to "Version de l'application :",
            AppLanguage.SPANISH to "Versión de la Aplicación:",
            AppLanguage.GERMAN to "Anwendungsversion:"
        ),
        "disclaimer_checkbox" to mapOf(
            AppLanguage.ITALIAN to "Dichiaro di essere maggiorenne, di aver letto attentamente e compreso le condizioni d'uso e mi assumo la piena ed esclusiva responsabilità per qualsiasi utilizzo dell'applicazione sul motoveicolo.",
            AppLanguage.ENGLISH to "I certify that I am of legal age, have carefully read and understood the terms of use, and assume full and exclusive responsibility for any use of this application on the vehicle.",
            AppLanguage.FRENCH to "Je déclare être majeur, avoir lu attentivement et compris les conditions d'utilisation, et j'assume l'entière responsabilité de toute utilisation de l'application sur le véhicule.",
            AppLanguage.SPANISH to "Declaro ser mayor de edad, haber leído atentamente y comprendido las condiciones de uso, y asumo la total y exclusiva responsabilidad por cualquier uso de la aplicación en el vehículo.",
            AppLanguage.GERMAN to "Ich erkläre, volljährig zu sein, die Nutzungsbedingungen aufmerksam gelesen und verstanden zu haben und übernehme die volle und ausschließliche Verantwortung für jegliche Nutzung der App am Fahrzeug."
        ),
        "disclaimer_accept" to mapOf(
            AppLanguage.ITALIAN to "Accetto e Assumo la Responsabilità",
            AppLanguage.ENGLISH to "Accept & Assume Full Responsibility",
            AppLanguage.FRENCH to "J'accepte et j'assume la responsabilité",
            AppLanguage.SPANISH to "Acepto y Asumo la Responsabilidad",
            AppLanguage.GERMAN to "Ich akzeptiere und übernehme die Verantwortung"
        ),
        "disclaimer_close" to mapOf(
            AppLanguage.ITALIAN to "Chiudi (Condizioni già accettate)",
            AppLanguage.ENGLISH to "Close (Terms already accepted)",
            AppLanguage.FRENCH to "Fermer (Conditions déjà acceptées)",
            AppLanguage.SPANISH to "Cerrar (Condiciones ya aceptadas)",
            AppLanguage.GERMAN to "Schließen (Bedingungen bereits akzeptiert)"
        ),
        "disclaimer_nav_title" to mapOf(
            AppLanguage.ITALIAN to "Informativa di Sicurezza & Condizioni Legali",
            AppLanguage.ENGLISH to "Safety Notice & Legal Terms",
            AppLanguage.FRENCH to "Avis de Sécurité & Conditions Légales",
            AppLanguage.SPANISH to "Aviso de Seguridad y Condiciones Legales",
            AppLanguage.GERMAN to "Sicherheitshinweise & Rechtliche Bedingungen"
        )
    )

    val disclaimerArticles: List<DisclaimerArticle>
        get() = when (currentLanguage) {
            AppLanguage.ITALIAN -> listOf(
                DisclaimerArticle(
                    title = "1. Natura del Software e Scopo Informativo",
                    text = "L'applicazione YaDiag è fornita 'NELLO STATO DI FATTO IN CUI SI TROVA' ('AS IS'), a titolo puramente amatoriale e di verifica tecnica. L'Applicazione non sostituisce l'assistenza ufficiale di officine autorizzate o le prescrizioni del manuale di servizio del costruttore."
                ),
                DisclaimerArticle(
                    title = "2. Consapevolezza dei Rischi Tecnici e Meccanici",
                    text = "L'invio di comandi diagnostici alla centralina motore (FI ECU) e ABS (inclusi spurgo pompe, reset ISC 0x54 e correzione O2/CO 0x52) comporta interventi diretti sul veicolo. Procedure errate su batterie scariche (< 12.8V) o a motore acceso possono causare malfunzionamenti o danni meccanici."
                ),
                DisclaimerArticle(
                    title = "3. Esonero Totale di Responsabilità (Artt. 1229 e 2043 C.C.)",
                    text = "Nei limiti massimi consentiti dalle leggi italiane ed europee (D.lgs. 206/2005 Codice del Consumo), lo sviluppatore declina ogni responsabilità per danni diretti, indiretti o incidentali (avarie al motore, danni elettrici/ABS, decadimento garanzia o sinistri) derivanti dall'uso dell'app."
                ),
                DisclaimerArticle(
                    title = "4. Sicurezza Stradale e Normative Vigenti",
                    text = "Tutti i test diagnostici e le cancellazioni errori devono essere eseguiti a veicolo fermo, in massima sicurezza e su suolo privato chiuso al traffico, nel rispetto del Codice della Strada (D.Lgs. 285/1992) e delle normative antinquinamento Euro 4 / Euro 5."
                ),
                DisclaimerArticle(
                    title = "5. Telemetria Diagnostica Anonima per Compatibilità Hardware",
                    text = "Al solo scopo di verificare e migliorare la compatibilità dell'app con i diversi modelli di moto, centraline e adattatori OBD2 Bluetooth, l'applicazione raccoglie e trasmette periodicamente a un server cloud sicuro dati tecnici aggregati in forma strettamente anonima (marca e modello adattatore BLE, versione protocollo ELM/KWP/UDS, ID centraline rilevate e codici diagnostici). NON vengono mai raccolti né trasmessi dati identificativi dell'utente, posizione GPS o numeri di targa/telaio (VIN)."
                )
            )
            AppLanguage.ENGLISH -> listOf(
                DisclaimerArticle(
                    title = "1. Software Nature & Informational Purpose",
                    text = "The YaDiag application is provided 'AS IS', solely for technical and informational purposes. The Application does not in any way replace official authorized workshop service, certified technicians, or manufacturer workshop manuals."
                ),
                DisclaimerArticle(
                    title = "2. Technical & Mechanical Risk Awareness",
                    text = "Sending diagnostic commands to engine (FI ECU) and ABS units (including pump bleeding, ISC 0x54 adaptive resets and O2/CO 0x52 fuel trims) directly interacts with vehicle control units. Incorrect procedures on low battery (< 12.8V) or running engines may cause mechanical failures or stalls."
                ),
                DisclaimerArticle(
                    title = "3. Full Limitation of Liability (EU Regulations)",
                    text = "To the maximum extent permitted by EU consumer laws and applicable civil legislation, the developer disclaims all liability for any direct, indirect, incidental, or consequential damages (engine failure, electrical/ABS damage, warranty voiding, or accidents) arising from using this app."
                ),
                DisclaimerArticle(
                    title = "4. Road Safety & Traffic Regulations",
                    text = "All advanced diagnostic tests, actuator routines, and DTC erasures must be carried out strictly with the vehicle stationary, in safe conditions on private closed grounds, in full compliance with traffic safety laws and Euro 4 / Euro 5 emissions standards."
                ),
                DisclaimerArticle(
                    title = "5. Anonymous Diagnostic Telemetry for Compatibility",
                    text = "To monitor, verify and improve hardware compatibility across various motorcycle models, ECU firmware revisions and BLE OBD2 adapters, the app periodically sends anonymous diagnostic telemetry to a secure cloud server (adapter model name, ELM/KWP protocol responses, detected CAN header IDs, and fault codes). No personal identity, GPS location, license plate, or vehicle VIN is ever collected or transmitted."
                )
            )
            AppLanguage.FRENCH -> listOf(
                DisclaimerArticle(
                    title = "1. Nature du Logiciel & But Informatif",
                    text = "L'application YaDiag est fournie 'EN L'ÉTAT' ('AS IS'), à titre technique et informatif. Elle ne remplace en aucun cas les ateliers agréés, les mécaniciens professionnels ni les manuels d'atelier officiels du constructeur."
                ),
                DisclaimerArticle(
                    title = "2. Conscience des Risques Techniques & Mécaniques",
                    text = "L'envoi de commandes aux calculateurs injection (FI ECU) et freinage (ABS ECU) — purge pompe ABS, reset adaptation ISC 0x54 et trims O2/CO 0x52 — modifie directement les paramètres véhicule. Une batterie faible (< 12.8V) ou un moteur tournant peut provoquer des pannes sévères."
                ),
                DisclaimerArticle(
                    title = "3. Exonération Totale de Responsabilité (Droit UE)",
                    text = "Dans les limites autorisées par le droit européen et le Code de la Consommation, le développeur décline toute responsabilité pour tout dommage direct, indirect ou accidentel (casse moteur, dégâts circuit de freinage/ABS, perte de garantie constructeur ou accidents)."
                ),
                DisclaimerArticle(
                    title = "4. Sécurité Routière & Réglementation",
                    text = "Tous les tests actionneurs et effacements de codes doivent être impérativement effectués sur véhicule à l'arrêt, en toute sécurité sur terrain privé fermé à la circulation, conformément au Code de la Route et aux normes d'émissions Euro 4 / Euro 5."
                ),
                DisclaimerArticle(
                    title = "5. Données de Diagnostic Anonymes & Compatibilité",
                    text = "Afin de vérifier et d'améliorer la compatibilité matérielle (adaptateurs BLE, protocoles ELM/KWP/UDS et versions calculateurs), l'application transmet des données techniques anonymisées vers un serveur cloud sécurisé. Aucune donnée d'identification personnelle, géolocalisation ou numéro de série n'est collectée."
                )
            )
            AppLanguage.SPANISH -> listOf(
                DisclaimerArticle(
                    title = "1. Naturaleza del Software y Propósito Informativo",
                    text = "La aplicación YaDiag se proporciona 'TAL CUAL' ('AS IS'), con fines puramente técnicos e informativos. No sustituye en modo alguno a los talleres oficiales, mecánicos certificados ni a los manuales de servicio oficiales del fabricante."
                ),
                DisclaimerArticle(
                    title = "2. Advertencia de Riesgos Técnicos y Mecánicos",
                    text = "El envío de comandos a las centralitas de inyección (FI ECU) y frenos (ABS) — purga de bomba ABS, reinicio adaptativo ISC 0x54 y ajuste O2/CO 0x52 — modifica directamente los sistemas del vehículo. Procedimientos indebidos con batería baja (< 12.8V) pueden causar daños mecánicos o fallos."
                ),
                DisclaimerArticle(
                    title = "3. Exoneración Total de Responsabilidad (Normativa UE)",
                    text = "En la medida máxima permitida por la legislación europea y de consumo, el desarrollador declina toda responsabilidad por daños directos, indirectos o accidentales (averías de motor, daños eléctricos/ABS, anulación de garantía o accidentes) derivados del uso de la aplicación."
                ),
                DisclaimerArticle(
                    title = "4. Seguridad Vial y Normativas Vigentes",
                    text = "Todas las pruebas de diagnóstico y borrado de averías deben ejecutarse exclusivamente con el vehículo detenido, en condiciones seguras en recinto privado cerrado al tráfico, cumpliendo las leyes de seguridad vial y normativas Euro 4 / Euro 5."
                ),
                DisclaimerArticle(
                    title = "5. Telemetría Diagnóstica Anónima para Compatibilidad",
                    text = "Con el único propósito de verificar y optimizar la compatibilidad entre modelos de motocicletas, centralitas y adaptadores OBD2 Bluetooth, la app transmite datos técnicos anónimos a un servidor en la nube (modelo de adaptador, versión de protocolo y códigos de diagnóstico). En ningún caso se recopila información personal, ubicación GPS o número de bastidor."
                )
            )
            AppLanguage.GERMAN -> listOf(
                DisclaimerArticle(
                    title = "1. Art der Software & Informationszweck",
                    text = "Die Anwendung YaDiag wird 'WIE BESEHEN' ('AS IS') zu rein technischen Informations- und Prüfzwecken bereitgestellt. Sie ersetzt keinesfalls Vertragswerkstätten, qualifizierte Mechaniker oder offizielle Werkstatthandbücher des Herstellers."
                ),
                DisclaimerArticle(
                    title = "2. Technische & Mechanische Risiken",
                    text = "Diagnosebefehle an Motor- (FI ECU) und ABS-Steuergeräte (einschließlich ABS-Pumpenentlüftung, ISC 0x54 Leerlaufreset und O2/CO 0x52 Trims) greifen direkt in Regelsysteme ein. Unsachgemäße Bedienung bei schwacher Batterie (< 12.8V) kann Fehlfunktionen oder Schäden verursachen."
                ),
                DisclaimerArticle(
                    title = "3. Vollständiger Haftungsausschluss (EU-Recht)",
                    text = "Soweit gesetzlich nach EU-Verbraucherrichtlinien zulässig, lehnt der Entwickler jegliche Haftung für direkte, indirekte oder beiläufig entstandene Schäden (Motorschäden, Defekte an Elektrik/ABS, Erlöschen der Herstellergarantie oder Unfälle) vollumfänglich ab."
                ),
                DisclaimerArticle(
                    title = "4. Verkehrssicherheit & Umweltnormen",
                    text = "Alle erweiterten Stellgliedtests und Fehlerspeicherlöschungen dürfen ausschließlich bei stehendem Fahrzeug auf abgesperrtem Privatgelände unter strikter Einhaltung der Straßenverkehrsordnung und Euro-4 / Euro-5 Abgasnormen erfolgen."
                ),
                DisclaimerArticle(
                    title = "5. Anonyme Diagnosedaten für Hardware-Kompatibilität",
                    text = "Zur kontinuierlichen Überprüfung und Optimierung der Kompatibilität verschiedener Motorrad- und Steuergeräte-Modelle sowie Bluetooth-OBD2-Adapter überträgt die App rein technische, anonymisierte Diagnosedaten an einen sicheren Cloud-Server. Es werden niemals personenbezogene Daten, GPS-Standorte oder Fahrgestellnummern (VIN) erfasst."
                )
            )
        }
}
