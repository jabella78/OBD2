import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case italian = "it"
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case german = "de"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .italian: return "Italiano"
        case .english: return "English"
        case .french: return "Français"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        }
    }
    
    public var flag: String {
        switch self {
        case .italian: return "🇮🇹"
        case .english: return "🇬🇧"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        }
    }
}

public class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @Published public var currentLanguage: AppLanguage = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage_v3")
        }
    }
    
    public init() {
        if let saved = UserDefaults.standard.string(forKey: "AppLanguage_v3"),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Default obbligatorio all'installazione: INGLESE (English)
            self.currentLanguage = .english
        }
    }
    
    public func t(_ key: String) -> String {
        return localizedStrings[key]?[currentLanguage] ?? localizedStrings[key]?[.english] ?? key
    }
    
    // MARK: - Dizionario Completo Multi-lingua (IT, EN, FR, ES, DE)
    private let localizedStrings: [String: [AppLanguage: String]] = [
        // Tabs
        "tab_dash": [
            .italian: "Dash",
            .english: "Dash",
            .french: "Tableau",
            .spanish: "Tablero",
            .german: "Cockpit"
        ],
        "tab_dtc": [
            .italian: "DTC",
            .english: "DTC",
            .french: "DTC",
            .spanish: "DTC",
            .german: "DTC"
        ],
        "tab_term": [
            .italian: "Terminale",
            .english: "Terminal",
            .french: "Terminal",
            .spanish: "Terminal",
            .german: "Terminal"
        ],
        "tab_ble": [
            .italian: "Bluetooth",
            .english: "Bluetooth",
            .french: "Bluetooth",
            .spanish: "Bluetooth",
            .german: "Bluetooth"
        ],
        "tab_actuators": [
            .italian: "Test Attivi",
            .english: "Active Tests",
            .french: "Tests Actifs",
            .spanish: "Pruebas Activas",
            .german: "Aktive Tests"
        ],
        "tab_setup": [
            .italian: "Setup",
            .english: "Setup",
            .french: "Configuration",
            .spanish: "Ajustes",
            .german: "Einstellungen"
        ],
        "tab_info": [
            .italian: "Info & Modelli",
            .english: "Info & Models",
            .french: "Info & Modèles",
            .spanish: "Info y Modelos",
            .german: "Info & Modelle"
        ],
        
        // Dashboard
        "dash_live_resume": [
            .italian: "Avvia Live",
            .english: "Start Live",
            .french: "Démarrer Live",
            .spanish: "Iniciar Live",
            .german: "Live Starten"
        ],
        "dash_live_pause": [
            .italian: "Pausa Live",
            .english: "Pause Live",
            .french: "Pause Live",
            .spanish: "Pausar Live",
            .german: "Live Pausieren"
        ],
        "dash_subtitle": [
            .italian: "PRO TELEMETRY & DIAG • CAN-BUS 500 KBPS",
            .english: "PRO TELEMETRY & DIAG • CAN-BUS 500 KBPS",
            .french: "TÉLÉMÉTRIE PRO & DIAG • CAN-BUS 500 KBPS",
            .spanish: "TELEMETRÍA PRO Y DIAG • CAN-BUS 500 KBPS",
            .german: "PROFI-TELEMETRIE & DIAGNOSE • CAN-BUS 500 KBPS"
        ],
        "ecu_connected": [
            .italian: "Centralina Connessa",
            .english: "ECU Connected",
            .french: "Calculateur Connecté",
            .spanish: "Centralita Conectada",
            .german: "Steuergerät Verbunden"
        ],
        "ecu_disconnected": [
            .italian: "Disconnesso",
            .english: "Disconnected",
            .french: "Déconnecté",
            .spanish: "Desconectado",
            .german: "Getrennt"
        ],
        "rpm_label": [
            .italian: "Giri Motore",
            .english: "Engine RPM",
            .french: "Régime Moteur",
            .spanish: "RPM Motor",
            .german: "Motordrehzahl"
        ],
        "speed_label": [
            .italian: "Velocità",
            .english: "Speed",
            .french: "Vitesse",
            .spanish: "Velocidad",
            .german: "Geschwindigkeit"
        ],
        "gear_label": [
            .italian: "Marce",
            .english: "Gear",
            .french: "Rapport",
            .spanish: "Marcha",
            .german: "Gang"
        ],
        "neutral_label": [
            .italian: "Folle",
            .english: "Neutral",
            .french: "Point Mort",
            .spanish: "Punto Muerto",
            .german: "Leerlauf"
        ],
        "coolant_temp": [
            .italian: "Temperatura Liquido",
            .english: "Coolant Temp",
            .french: "Temp. Liquide",
            .spanish: "Temp. Refrigerante",
            .german: "Kühlmitteltemp."
        ],
        "throttle_tps": [
            .italian: "Apertura Farfalla (TPS)",
            .english: "Throttle Position (TPS)",
            .french: "Ouverture Papillon (TPS)",
            .spanish: "Apertura Mariposa (TPS)",
            .german: "Drosselklappe (TPS)"
        ],
        "battery_volt": [
            .italian: "Tensione Batteria",
            .english: "Battery Voltage",
            .french: "Tension Batterie",
            .spanish: "Voltaje Batería",
            .german: "Batteriespannung"
        ],
        "lambda_afr": [
            .italian: "Sonda Lambda / AFR",
            .english: "O2 Sensor / AFR",
            .french: "Sonde Lambda / AFR",
            .spanish: "Sonda Lambda / AFR",
            .german: "Lambdasonde / AFR"
        ],
        "mix_stoich": [
            .italian: "Stechiometrico (14.7 AFR)",
            .english: "Stoichiometric (14.7 AFR)",
            .french: "Stœchiométrique (14.7 AFR)",
            .spanish: "Estequiométrico (14.7 AFR)",
            .german: "Stöchiometrisch (14.7 AFR)"
        ],
        "mix_lean": [
            .italian: "Miscela Magra",
            .english: "Lean Mixture",
            .french: "Mélange Pauvre",
            .spanish: "Mezcla Pobre",
            .german: "Mageres Gemisch"
        ],
        "mix_rich": [
            .italian: "Miscela Grassa",
            .english: "Rich Mixture",
            .french: "Mélange Riche",
            .spanish: "Mezcla Rica",
            .german: "Fettes Gemisch"
        ],
        "start_csv": [
            .italian: "Avvia Registrazione CSV",
            .english: "Start CSV Recording",
            .french: "Démarrer Enregistrement CSV",
            .spanish: "Iniciar Grabación CSV",
            .german: "CSV-Aufnahme Starten"
        ],
        "stop_csv": [
            .italian: "Ferma Registrazione CSV",
            .english: "Stop CSV Recording",
            .french: "Arrêter Enregistrement CSV",
            .spanish: "Detener Grabación CSV",
            .german: "CSV-Aufnahme Stoppen"
        ],
        "telemetry_start": [
            .italian: "Avvia Telemetria Live",
            .english: "Start Live Telemetry",
            .french: "Démarrer Télémétrie",
            .spanish: "Iniciar Telemetría",
            .german: "Live-Telemetrie Starten"
        ],
        "telemetry_stop": [
            .italian: "Ferma Telemetria",
            .english: "Stop Telemetry",
            .french: "Arrêter Télémétrie",
            .spanish: "Detener Telemetría",
            .german: "Telemetrie Stoppen"
        ],
        "telemetry_paused_notice": [
            .italian: "Telemetria in pausa (Bus CAN libero per Diagnosi/Test)",
            .english: "Telemetry paused (CAN Bus idle for Diagnostics/Tests)",
            .french: "Télémétrie en pause (Bus CAN libre pour Diagnostic)",
            .spanish: "Telemetría en pausa (Bus CAN libre para Diagnóstico)",
            .german: "Telemetrie pausiert (CAN-Bus frei für Diagnose)"
        ],
        "telemetry_active_notice": [
            .italian: "Telemetria live attiva (Aggiornamento continuo)",
            .english: "Live telemetry active (Continuous streaming)",
            .french: "Télémétrie live active (Flux continu)",
            .spanish: "Telemetría activa (Flujo continuo)",
            .german: "Live-Telemetrie aktiv (Kontinuierliches Streaming)"
        ],
        "samples_recorded": [
            .italian: "Campioni registrati:",
            .english: "Recorded samples:",
            .french: "Échantillons enregistrés :",
            .spanish: "Muestras registradas:",
            .german: "Aufgezeichnete Werte:"
        ],
        
        // Diagnostics (DTC)
        "dtc_title": [
            .italian: "Diagnosi DTC Centralina",
            .english: "ECU DTC Diagnostics",
            .french: "Diagnostic DTC Calculateur",
            .spanish: "Diagnóstico DTC Centralita",
            .german: "Steuergerät DTC-Diagnose"
        ],
        "scan_dtc_btn": [
            .italian: "Scansione DTC (Mode 03/07/0A)",
            .english: "Scan DTC (Mode 03/07/0A)",
            .french: "Scanner DTC (Mode 03/07/0A)",
            .spanish: "Escanear DTC (Mode 03/07/0A)",
            .german: "DTC Scannen (Mode 03/07/0A)"
        ],
        "scanning": [
            .italian: "Scansione in corso...",
            .english: "Scanning in progress...",
            .french: "Scan en cours...",
            .spanish: "Escaneo en curso...",
            .german: "Scan läuft..."
        ],
        "clear_dtc_btn": [
            .italian: "Cancella Errori (Mode 04)",
            .english: "Clear Codes (Mode 04)",
            .french: "Effacer Codes (Mode 04)",
            .spanish: "Borrar Códigos (Mode 04)",
            .german: "Fehler Löschen (Mode 04)"
        ],
        "clearing": [
            .italian: "Azzeramento in corso...",
            .english: "Clearing in progress...",
            .french: "Effacement en cours...",
            .spanish: "Borrando códigos...",
            .german: "Löschen läuft..."
        ],
        "ai_eval_btn": [
            .italian: "Valutazione Diagnostica AI",
            .english: "AI Diagnostic Analysis",
            .french: "Analyse Diagnostique IA",
            .spanish: "Evaluación Diagnóstica con IA",
            .german: "KI-Diagnoseanalyse"
        ],
        "mil_on": [
            .italian: "Spia Motore (MIL): ACCESA",
            .english: "Check Engine (MIL): ON",
            .french: "Voyant Moteur (MIL) : ALLUMÉ",
            .spanish: "Testigo Motor (MIL): ENCENDIDO",
            .german: "Motorkontrollleuchte (MIL): AN"
        ],
        "mil_off": [
            .italian: "Spia Motore (MIL): SPENTA",
            .english: "Check Engine (MIL): OFF",
            .french: "Voyant Moteur (MIL) : ÉTEINT",
            .spanish: "Testigo Motor (MIL): APAGADO",
            .german: "Motorkontrollleuchte (MIL): AUS"
        ],
        "no_dtc_message": [
            .italian: "Nessun codice errore DTC rilevato nella centralina.",
            .english: "No DTC fault codes detected in ECU.",
            .french: "Aucun code défaut DTC détecté dans le calculateur.",
            .spanish: "No se detectaron códigos de avería DTC en la centralita.",
            .german: "Keine DTC-Fehlercodes im Steuergerät erkannt."
        ],
        "confirm_clear_title": [
            .italian: "Conferma Cancellazione Errori",
            .english: "Confirm DTC Clearing",
            .french: "Confirmer l'effacement",
            .spanish: "Confirmar Borrado de Códigos",
            .german: "Fehlerlöschung Bestätigen"
        ],
        "confirm_clear_msg": [
            .italian: "Sei sicuro di voler azzerare tutti i codici errore registrati nella centralina?",
            .english: "Are you sure you want to clear all fault codes stored in the ECU?",
            .french: "Êtes-vous sûr de vouloir effacer tous les codes défaut mémorisés dans le calculateur ?",
            .spanish: "¿Estás seguro de que deseas borrar todos los códigos de error almacenados en la centralita?",
            .german: "Sind Sie sicher, dass Sie alle im Steuergerät gespeicherten Fehlercodes löschen möchten?"
        ],
        "cancel": [
            .italian: "Annulla",
            .english: "Cancel",
            .french: "Annuler",
            .spanish: "Cancelar",
            .german: "Abbrechen"
        ],
        "confirm_delete": [
            .italian: "Cancella DTC",
            .english: "Clear DTC",
            .french: "Effacer DTC",
            .spanish: "Borrar DTC",
            .german: "DTC Löschen"
        ],
        
        // BLE Connection
        "ble_title": [
            .italian: "Gestione Connessione BLE",
            .english: "BLE Connection Manager",
            .french: "Gestion Connexion BLE",
            .spanish: "Gestión de Conexión BLE",
            .german: "BLE-Verbindungsmanager"
        ],
        "ble_scan_btn": [
            .italian: "Scansione Adattatori OBD2",
            .english: "Scan OBD2 Adapters",
            .french: "Recherche Adaptateurs OBD2",
            .spanish: "Buscar Adaptadores OBD2",
            .german: "OBD2-Adapter Suchen"
        ],
        "ble_stop_scan_btn": [
            .italian: "Ferma Scansione",
            .english: "Stop Scan",
            .french: "Arrêter Recherche",
            .spanish: "Detener Búsqueda",
            .german: "Suche Beenden"
        ],
        "ble_connect": [
            .italian: "Connetti",
            .english: "Connect",
            .french: "Connecter",
            .spanish: "Conectar",
            .german: "Verbinden"
        ],
        "ble_disconnect": [
            .italian: "Disconnetti",
            .english: "Disconnect",
            .french: "Déconnecter",
            .spanish: "Desconectar",
            .german: "Trennen"
        ],
        "ble_connected_to": [
            .italian: "Connesso a:",
            .english: "Connected to:",
            .french: "Connecté à :",
            .spanish: "Conectado a:",
            .german: "Verbunden mit:"
        ],
        "ble_not_connected": [
            .italian: "Non connesso ad alcun adattatore.",
            .english: "Not connected to any adapter.",
            .french: "Non connecté à un adaptateur.",
            .spanish: "No conectado a ningún adaptador.",
            .german: "Nicht mit einem Adapter verbunden."
        ],
        "ble_ext_mode": [
            .italian: "Modalità Compatibilità Estesa (Tutti i BLE)",
            .english: "Extended Compatibility Mode (All BLE)",
            .french: "Mode Compatibilité Étendue (Tous BLE)",
            .spanish: "Modo Compatibilidad Extendida (Todos BLE)",
            .german: "Erweiterter Kompatibilitätsmodus (Alle BLE)"
        ],
        "ble_ext_desc": [
            .italian: "Quando attiva mostra qualsiasi dispositivo BLE generico (ELM327). Quando disattivata filtra solo gli adattatori ad alte prestazioni certificati (UniCarScan, vLinker, OBDLink, Veepeak, Carista).",
            .english: "When active, displays any generic BLE device (ELM327). When disabled, filters only high-performance certified adapters (UniCarScan, vLinker, OBDLink, Veepeak, Carista).",
            .french: "Lorsqu'il est activé, affiche tous les appareils BLE génériques (ELM327). Désactivé, filtre uniquement les adaptateurs certifiés haute performance (UniCarScan, vLinker, OBDLink, Veepeak, Carista).",
            .spanish: "Cuando está activo muestra cualquier dispositivo BLE genérico (ELM327). Cuando está desactivado filtra solo adaptadores certificados de alto rendimiento (UniCarScan, vLinker, OBDLink, Veepeak, Carista).",
            .german: "Wenn aktiviert, zeigt es beliebige generische BLE-Geräte (ELM327). Wenn deaktiviert, werden nur zertifizierte Hochleistungsadapter gefiltert (UniCarScan, vLinker, OBDLink, Veepeak, Carista)."
        ],
        "ble_simulator_card_title": [
            .italian: "Simulatore OBD2 Virtuale (Offline)",
            .english: "Virtual OBD2 Simulator (Offline)",
            .french: "Simulateur OBD2 Virtuel (Hors ligne)",
            .spanish: "Simulador OBD2 Virtual (Offline)",
            .german: "Virtueller OBD2-Simulator (Offline)"
        ],
        "ble_sim_active_banner": [
            .italian: "SIMULATORE BANCO PROVA ATTIVO",
            .english: "BENCH TEST SIMULATOR ACTIVE",
            .french: "SIMULATEUR BANC D'ESSAI ACTIF",
            .spanish: "SIMULADOR BANCO DE PRUEBAS ACTIVO",
            .german: "PRÜFSTAND-SIMULATOR AKTIV"
        ],
        "ble_simulator_card_desc": [
            .italian: "Testa tutte le funzionalità dell'app senza moto né adattatore fisico.",
            .english: "Test all app features without motorcycle or physical adapter.",
            .french: "Testez toutes les fonctionnalités sans moto ni adaptateur physique.",
            .spanish: "Prueba todas las funciones de la app sin moto ni adaptador físico.",
            .german: "Alle App-Funktionen ohne Motorrad oder physischen Adapter testen."
        ],
        "ble_simulator_connect": [
            .italian: "Connetti Simulatore Virtuale",
            .english: "Connect Virtual Simulator",
            .french: "Connecter le Simulateur Virtuel",
            .spanish: "Conectar Simulador Virtual",
            .german: "Virtuellen Simulator Verbinden"
        ],
        "ble_simulator_disconnect": [
            .italian: "Disconnetti Simulatore",
            .english: "Disconnect Simulator",
            .french: "Déconnecter le Simulateur",
            .spanish: "Desconectar Simulador",
            .german: "Simulator Trennen"
        ],
        "ble_bench_mode_title": [
            .italian: "Simulatore Banco Prova (Demo)",
            .english: "Bench Test Simulator (Demo)",
            .french: "Simulateur Banc d'Essai (Démo)",
            .spanish: "Simulador Banco de Pruebas (Demo)",
            .german: "Prüfstand-Simulator (Demo)"
        ],
        "ble_bench_mode_active": [
            .italian: "Dati virtuali attivi (10 Hz)",
            .english: "Virtual live data active (10 Hz)",
            .french: "Données virtuelles actives (10 Hz)",
            .spanish: "Datos virtuales activos (10 Hz)",
            .german: "Virtuelle Daten aktiv (10 Hz)"
        ],
        "ble_bench_mode_idle": [
            .italian: "Modalità banco dinamico",
            .english: "Dynamic bench mode",
            .french: "Mode banc d'essai dynamique",
            .spanish: "Modo banco dinámico",
            .german: "Dynamischer Prüfstandmodus"
        ],
        "ble_no_devices": [
            .italian: "Nessun adattatore OBD2 rilevato nelle vicinanze.",
            .english: "No OBD2 adapters detected nearby.",
            .french: "Aucun adaptateur OBD2 détecté à proximité.",
            .spanish: "No se detectaron adaptadores OBD2 cercanos.",
            .german: "Keine OBD2-Adapter in der Nähe gefunden."
        ],
        "ble_insert_hint": [
            .italian: "Inserisci l'adattatore nella presa diagnostica della moto con il quadro acceso (Key ON).",
            .english: "Plug adapter into bike diagnostic port with ignition turned ON (Key ON).",
            .french: "Branchez l'adaptateur sur la prise diag de la moto avec le contact allumé (Key ON).",
            .spanish: "Conecta el adaptador a la toma de diagnosis de la moto con el contacto dado (Key ON).",
            .german: "Adapter bei eingeschalteter Zündung (Key ON) an die Diagnosebuchse anschließen."
        ],
        "ble_certified_badge": [
            .italian: "Certificato e Raccomandato",
            .english: "Certified & Recommended",
            .french: "Certifié et Recommandé",
            .spanish: "Certificado y Recomendado",
            .german: "Zertifiziert & Empfohlen"
        ],
        "ble_generic_badge": [
            .italian: "Compatibilità generica ELM327",
            .english: "Generic ELM327 Compatibility",
            .french: "Compatibilité générique ELM327",
            .spanish: "Compatibilidad genérica ELM327",
            .german: "Generische ELM327-Kompatibilität"
        ],
        "ble_device_default": [
            .italian: "Dispositivo OBD",
            .english: "OBD Device",
            .french: "Appareil OBD",
            .spanish: "Dispositivo OBD",
            .german: "OBD-Gerät"
        ],
        "ble_simulated_protocol": [
            .italian: "Protocollo CAN Bus 500k ISO 15765-4 simulato (Nessun Bluetooth richiesto)",
            .english: "Simulated 500k ISO 15765-4 CAN Bus Protocol (No Bluetooth required)",
            .french: "Protocole CAN Bus 500k ISO 15765-4 simulé (Sans Bluetooth requis)",
            .spanish: "Protocolo CAN Bus 500k ISO 15765-4 simulado (Sin Bluetooth requerido)",
            .german: "Simuliertes 500k ISO 15765-4 CAN-Bus-Protokoll (Kein Bluetooth erforderlich)"
        ],
        
        // Terminal
        "term_title": [
            .italian: "Console Terminale OBD2",
            .english: "OBD2 Terminal Console",
            .french: "Console Terminal OBD2",
            .spanish: "Consola Terminal OBD2",
            .german: "OBD2-Terminal-Konsole"
        ],
        "term_desc": [
            .italian: "Invia comandi personalizzati AT o CAN bus (es. 0100, 221101, ATZ):",
            .english: "Send custom AT or CAN bus commands (e.g. 0100, 221101, ATZ):",
            .french: "Envoyez des commandes personnalisées AT ou CAN bus (ex: 0100, 221101, ATZ) :",
            .spanish: "Envía comandos personalizados AT o CAN bus (ej. 0100, 221101, ATZ):",
            .german: "Benutzerdefinierte AT- oder CAN-Bus-Befehle senden (z.B. 0100, 221101, ATZ):"
        ],
        "term_send": [
            .italian: "Invia",
            .english: "Send",
            .french: "Envoyer",
            .spanish: "Enviar",
            .german: "Senden"
        ],
        "term_clear": [
            .italian: "Pulisci Console",
            .english: "Clear Console",
            .french: "Effacer Console",
            .spanish: "Limpiar Consola",
            .german: "Konsole Leeren"
        ],
        "term_danger_alert": [
            .italian: "Attenzione: il comando inserito interagisce con funzioni critiche. L'invio di sequenze errate potrebbe provocare errori permanenti o anomalie di funzionamento della centralina.",
            .english: "Warning: The entered command interacts with critical ECU routines. Sending incorrect sequences may cause permanent ECU errors or malfunctions.",
            .french: "Attention : La commande saisie interagit avec des fonctions critiques. L'envoi de séquences incorrectes peut provoquer des erreurs permanentes.",
            .spanish: "Atención: El comando ingresado interactúa con funciones críticas. Enviar secuencias incorrectas puede provocar anomalías permanentes.",
            .german: "Achtung: Der eingegebene Befehl interagiert mit kritischen Steuergerätefunktionen. Falsche Sequenzen können dauerhafte Fehler verursachen."
        ],
        
        // Actuators
        "act_title": [
            .italian: "Funzioni Speciali & Attuatori",
            .english: "Special Functions & Actuators",
            .french: "Fonctions Spéciales & Actionneurs",
            .spanish: "Funciones Especiales y Actuadores",
            .german: "Sonderfunktionen & Aktoren"
        ],
        "act_category": [
            .italian: "Unità di Controllo",
            .english: "Control Unit",
            .french: "Unité de Contrôle",
            .spanish: "Unidad de Control",
            .german: "Steuergerät-Auswahl"
        ],
        "act_danger_title": [
            .italian: "PERICOLO: MOTORE IN MOTO O RUOTE IN MOVIMENTO!",
            .english: "DANGER: ENGINE RUNNING OR WHEELS IN MOTION!",
            .french: "DANGER : MOTEUR EN MARCHE OU ROUES EN MOUVEMENT !",
            .spanish: "¡PELIGRO: MOTOR EN MARCHA O RUEDAS EN MOVIMIENTO!",
            .german: "GEFAHR: MOTOR LÄUFT ODER RÄDER DREHEN SICH!"
        ],
        "act_danger_msg": [
            .italian: "I reset adattivi sono disabilitati mentre il motore gira. Spegni il motore e lascia solo il quadro acceso (Key ON).",
            .english: "Adaptive resets are disabled while the engine runs. Stop engine and keep ignition ON.",
            .french: "Les réinitialisations adaptatives sont désactivées pendant que le moteur tourne. Coupez le moteur et laissez le contact.",
            .spanish: "Los reinicios adaptativos están deshabilitados con el motor encendido. Apaga el motor y mantén el contacto.",
            .german: "Adaptive Resets sind bei laufendem Motor gesperrt. Motor ausschalten und nur Zündung eingeschaltet lassen."
        ],
        "act_ready_engine": [
            .italian: "Motore fermo. Funzioni di verifica e reset adattivo FI ECU (7E0) sbloccate.",
            .english: "Engine stopped. FI ECU (7E0) adaptive check and reset functions unlocked.",
            .french: "Moteur arrêté. Fonctions de contrôle et réinitialisation adaptative FI ECU (7E0) déverrouillées.",
            .spanish: "Motor apagado. Funciones de verificación y reinicio adaptativo FI ECU (7E0) desbloqueadas.",
            .german: "Motor aus. FI ECU (7E0) Prüf- und adaptive Resetfunktionen freigeschaltet."
        ],
        "act_start_btn": [
            .italian: "Avvia Procedura",
            .english: "Start Procedure",
            .french: "Démarrer la Procédure",
            .spanish: "Iniciar Procedimiento",
            .german: "Vorgang Starten"
        ],
        "act_executing_btn": [
            .italian: "Esecuzione in corso...",
            .english: "Executing...",
            .french: "Exécution en cours...",
            .spanish: "Ejecutando...",
            .german: "Wird ausgeführt..."
        ],
        "act_status_ready": [
            .italian: "Pronto. Seleziona una procedura per iniziare il reset.",
            .english: "Ready. Select an adaptive routine to start reset procedure.",
            .french: "Prêt. Sélectionnez une routine pour lancer la réinitialisation.",
            .spanish: "Listo. Selecciona una rutina para iniciar el reinicio.",
            .german: "Bereit. Wählen Sie eine adaptive Routine, um den Reset zu starten."
        ],
        
        // Setup (Language + AI)
        "setup_pro_features_active": [
            .italian: "Tutte le funzioni professionali (Cancellazione Guasti DTC, Guida Reset Tagliando, Certificato Diagnostico PDF, Reset Corpi Farfallati ISC, Reset Lambda O2 e Diagnostica AI) sono attive su questa applicazione.",
            .english: "All professional features (DTC Fault Clearing, Dashboard Service Reset Guide, PDF Diagnostic Reports, ISC Throttle Body Reset, Lambda O2 Reset, and AI Diagnostics) are active in this application.",
            .french: "Toutes les fonctions professionnelles (Effacement DTC, Guide Reset Vidange, Certificats PDF, Réinitialisation ISC/Lambda, et Diagnostic IA) sont actives.",
            .spanish: "Todas las funciones profesionales (Borrado de DTC, Guía Reset Aceite, Certificados PDF, Reinicios ISC/Lambda y Diagnóstico IA) están activas.",
            .german: "Alle professionellen Funktionen (DTC-Löschen, Service-Reset-Anleitung, PDF-Prüfbericht, ISC-/Lambda-Reset und KI-Diagnose) sind in dieser Version aktiv."
        ],
        "setup_lang_section": [
            .italian: "Lingua dell'Applicazione",
            .english: "Application Language",
            .french: "Langue de l'application",
            .spanish: "Idioma de la aplicación",
            .german: "App-Sprache"
        ],
        "setup_lang_desc": [
            .italian: "Seleziona la lingua dell'interfaccia, dei menu e dei documenti legali.",
            .english: "Select the language for user interface, menus and legal notices.",
            .french: "Sélectionnez la langue de l'interface, des menus et des mentions légales.",
            .spanish: "Selecciona el idioma de la interfaz, menús y documentos legales.",
            .german: "Wählen Sie die Sprache für Benutzeroberfläche, Menüs und Rechtshinweise."
        ],
        "setup_ai_section": [
            .italian: "Configurazione AI & Modelli LLM",
            .english: "AI & LLM Model Configuration",
            .french: "Configuration IA & Modèles LLM",
            .spanish: "Configuración de IA y Modelos LLM",
            .german: "KI- & LLM-Modellkonfiguration"
        ],
        "setup_ai_desc": [
            .italian: "Personalizza il motore di intelligenza artificiale per diagnosi DTC e telemetria",
            .english: "Customize AI engine for DTC diagnostics and telemetry analysis",
            .french: "Personnalisez le moteur d'IA pour diagnostics DTC et télémétrie",
            .spanish: "Personaliza el motor de IA para diagnósticos DTC y telemetría",
            .german: "KI-Engine für DTC-Diagnose und Telemetrie anpassen"
        ],
        "setup_provider_label": [
            .italian: "1. Provider Intelligenza Artificiale:",
            .english: "1. AI Provider:",
            .french: "1. Fournisseur d'IA :",
            .spanish: "1. Proveedor de IA:",
            .german: "1. KI-Anbieter:"
        ],
        "setup_model_label": [
            .italian: "2. Modello LLM (Menu a tendina):",
            .english: "2. LLM Model (Dropdown menu):",
            .french: "2. Modèle LLM (Menu déroulant) :",
            .spanish: "2. Modelo LLM (Menú desplegable):",
            .german: "2. LLM-Modell (Dropdown-Menü):"
        ],
        "setup_sync_btn": [
            .italian: "Sincronizza Nuove Release",
            .english: "Sync New Releases",
            .french: "Synchroniser Nouvelles Versions",
            .spanish: "Sincronizar Nuevas Versiones",
            .german: "Neue Versionen Synchronisieren"
        ],
        "setup_apikey_label": [
            .italian: "3. Chiave API per",
            .english: "3. API Key for",
            .french: "3. Clé API pour",
            .spanish: "3. Clave API para",
            .german: "3. API-Schlüssel für"
        ],
        "setup_apikey_security": [
            .italian: "La chiave API viene conservata localmente sul tuo dispositivo e inviata solo ed esclusivamente all'endpoint del provider selezionato.",
            .english: "The API key is stored locally on your device and sent solely to the selected provider endpoint.",
            .french: "La clé API est conservée localement sur votre appareil et envoyée uniquement au serveur du fournisseur sélectionné.",
            .spanish: "La clave API se almacena localmente en tu dispositivo y se envía únicamente al proveedor seleccionado.",
            .german: "Der API-Schlüssel wird lokal auf Ihrem Gerät gespeichert und ausschließlich an den ausgewählten Anbieter übertragen."
        ],
        "setup_providers_guide": [
            .italian: "Guida ai Provider Supportati",
            .english: "Supported Providers Guide",
            .french: "Guide des Fournisseurs Supportés",
            .spanish: "Guía de Proveedores Compatibles",
            .german: "Leitfaden Unterstützte Anbieter"
        ],
        "setup_custom_model_name": [
            .italian: "Nome Modello Personalizzato (es. llama3, mistral, qwen2.5):",
            .english: "Custom Model Name (e.g. llama3, mistral, qwen2.5):",
            .french: "Nom du modèle personnalisé (ex. llama3, mistral, qwen2.5) :",
            .spanish: "Nombre del modelo personalizado (ej. llama3, mistral, qwen2.5):",
            .german: "Benutzerdefinierter Modellname (z.B. llama3, mistral, qwen2.5):"
        ],
        "setup_custom_model_placeholder": [
            .italian: "Nome modello",
            .english: "Model name",
            .french: "Nom du modèle",
            .spanish: "Nombre del modelo",
            .german: "Modellname"
        ],
        "setup_custom_endpoint_label": [
            .italian: "Base URL Endpoint OpenAI-compatible:",
            .english: "OpenAI-compatible Endpoint Base URL:",
            .french: "URL de base du point de terminaison OpenAI-compatible :",
            .spanish: "URL base del endpoint compatible con OpenAI:",
            .german: "Basis-URL für OpenAI-kompatiblen Endpunkt:"
        ],
        "setup_selected_model_picker": [
            .italian: "Modello Selezionato",
            .english: "Selected Model",
            .french: "Modèle sélectionné",
            .spanish: "Modelo seleccionado",
            .german: "Ausgewähltes Modell"
        ],
        
        // Info & Legal Disclaimer
        "info_title": [
            .italian: "YaDiag — Guida & Modelli Compatibili",
            .english: "YaDiag — Guide & Compatible Models",
            .french: "YaDiag — Guide & Modèles Compatibles",
            .spanish: "YaDiag — Guía y Modelos Compatibles",
            .german: "YaDiag — Handbuch & Kompatible Modelle"
        ],
        "info_read_terms": [
            .italian: "Rileggi Condizioni d'Uso & Disclaimer Legale",
            .english: "Review Terms of Use & Legal Disclaimer",
            .french: "Relire les Conditions d'Utilisation & Mentions Légales",
            .spanish: "Releer Términos de Uso y Descargo Legal",
            .german: "Nutzungsbedingungen & Haftungsausschluss erneut lesen"
        ],
        "disclaimer_title": [
            .italian: "Condizioni d'Uso ed Esonero di Responsabilità",
            .english: "Terms of Use & Limitation of Liability",
            .french: "Conditions d'Utilisation & Limitation de Responsabilité",
            .spanish: "Términos de Uso y Exoneración de Responsabilidad",
            .german: "Nutzungsbedingungen & Haftungsausschluss"
        ],
        "disclaimer_version": [
            .italian: "Versione Applicazione:",
            .english: "Application Version:",
            .french: "Version de l'application :",
            .spanish: "Versión de la Aplicación:",
            .german: "Anwendungsversion:"
        ],
        "disclaimer_checkbox": [
            .italian: "Dichiaro di essere maggiorenne, di aver letto attentamente e compreso le condizioni d'uso e mi assumo la piena ed esclusiva responsabilità per qualsiasi utilizzo dell'applicazione sul motoveicolo.",
            .english: "I certify that I am of legal age, have carefully read and understood the terms of use, and assume full and exclusive responsibility for any use of this application on the vehicle.",
            .french: "Je déclare être majeur, avoir lu attentivement et compris les conditions d'utilisation, et j'assume l'entière responsabilité de toute utilisation de l'application sur le véhicule.",
            .spanish: "Declaro ser mayor de edad, haber leído atentamente y comprendido las condiciones de uso, y asumo la total y exclusiva responsabilidad por cualquier uso de la aplicación en el vehículo.",
            .german: "Ich erkläre, volljährig zu sein, die Nutzungsbedingungen aufmerksam gelesen und verstanden zu haben und übernehme die volle und ausschließliche Verantwortung für jegliche Nutzung der App am Fahrzeug."
        ],
        "disclaimer_accept": [
            .italian: "Accetto e Assumo la Responsabilità",
            .english: "Accept & Assume Full Responsibility",
            .french: "J'accepte et j'assume la responsabilité",
            .spanish: "Acepto y Asumo la Responsabilidad",
            .german: "Ich akzeptiere und übernehme die Verantwortung"
        ],
        "disclaimer_close": [
            .italian: "Chiudi (Condizioni già accettate)",
            .english: "Close (Terms already accepted)",
            .french: "Fermer (Conditions déjà acceptées)",
            .spanish: "Cerrar (Condiciones ya aceptadas)",
            .german: "Schließen (Bedingungen bereits akzeptiert)"
        ],
        "disclaimer_nav_title": [
            .italian: "Informativa di Sicurezza & Condizioni Legali",
            .english: "Safety Notice & Legal Terms",
            .french: "Avis de Sécurité & Conditions Légales",
            .spanish: "Aviso de Seguridad y Condiciones Legales",
            .german: "Sicherheitshinweise & Rechtliche Bedingungen"
        ]
    ]
    
    // MARK: - Testi Legali Completi Tradotti per DisclaimerView
    public struct DisclaimerArticle {
        public let title: String
        public let text: String
    }
    
    public var disclaimerArticles: [DisclaimerArticle] {
        switch currentLanguage {
        case .italian:
            return [
                DisclaimerArticle(
                    title: "1. Natura del Software e Scopo Informativo",
                    text: "L'applicazione YaDiag è fornita 'NELLO STATO DI FATTO IN CUI SI TROVA' ('AS IS'), a titolo puramente amatoriale e di verifica tecnica. L'Applicazione non sostituisce l'assistenza ufficiale di officine autorizzate o le prescrizioni del manuale di servizio del costruttore."
                ),
                DisclaimerArticle(
                    title: "2. Consapevolezza dei Rischi Tecnici e Meccanici",
                    text: "L'invio di comandi diagnostici alla centralina motore (FI ECU) e ABS (inclusi spurgo pompe, reset ISC 0x54 e correzione O2/CO 0x52) comporta interventi diretti sul veicolo. Procedure errate su batterie scariche (< 12.8V) o a motore acceso possono causare malfunzionamenti o danni meccanici."
                ),
                DisclaimerArticle(
                    title: "3. Esonero Totale di Responsabilità (Artt. 1229 e 2043 C.C.)",
                    text: "Nei limiti massimi consentiti dalle leggi italiane ed europee (D.lgs. 206/2005 Codice del Consumo), lo sviluppatore declina ogni responsabilità per danni diretti, indiretti o incidentali (avarie al motore, danni elettrici/ABS, decadimento garanzia o sinistri) derivanti dall'uso dell'app."
                ),
                DisclaimerArticle(
                    title: "4. Sicurezza Stradale e Normative Vigenti",
                    text: "Tutti i test diagnostici e le cancellazioni errori devono essere eseguiti a veicolo fermo, in massima sicurezza e su suolo privato chiuso al traffico, nel rispetto del Codice della Strada (D.Lgs. 285/1992) e delle normative antinquinamento Euro 4 / Euro 5."
                ),
                DisclaimerArticle(
                    title: "5. Telemetria Diagnostica Anonima per Compatibilità Hardware",
                    text: "Al solo scopo di verificare e migliorare la compatibilità dell'app con i diversi modelli di moto, centraline e adattatori OBD2 Bluetooth, l'applicazione raccoglie e trasmette periodicamente a un server cloud sicuro dati tecnici aggregati in forma strettamente anonima (marca e modello adattatore BLE, versione protocollo ELM/KWP/UDS, ID centraline rilevate e codici diagnostici). NON vengono mai raccolti né trasmessi dati identificativi dell'utente, posizione GPS o numeri di targa/telaio (VIN)."
                )
            ]
        case .english:
            return [
                DisclaimerArticle(
                    title: "1. Software Nature & Informational Purpose",
                    text: "The YaDiag application is provided 'AS IS', solely for technical and informational purposes. The Application does not in any way replace official authorized workshop service, certified technicians, or manufacturer workshop manuals."
                ),
                DisclaimerArticle(
                    title: "2. Technical & Mechanical Risk Awareness",
                    text: "Sending diagnostic commands to engine (FI ECU) and ABS units (including pump bleeding, ISC 0x54 adaptive resets and O2/CO 0x52 fuel trims) directly interacts with vehicle control units. Incorrect procedures on low battery (< 12.8V) or running engines may cause mechanical failures or stalls."
                ),
                DisclaimerArticle(
                    title: "3. Full Limitation of Liability (EU Regulations)",
                    text: "To the maximum extent permitted by EU consumer laws and applicable civil legislation, the developer disclaims all liability for any direct, indirect, incidental, or consequential damages (engine failure, electrical/ABS damage, warranty voiding, or accidents) arising from using this app."
                ),
                DisclaimerArticle(
                    title: "4. Road Safety & Traffic Regulations",
                    text: "All advanced diagnostic tests, actuator routines, and DTC erasures must be carried out strictly with the vehicle stationary, in safe conditions on private closed grounds, in full compliance with traffic safety laws and Euro 4 / Euro 5 emissions standards."
                ),
                DisclaimerArticle(
                    title: "5. Anonymous Diagnostic Telemetry for Compatibility",
                    text: "To monitor, verify and improve hardware compatibility across various motorcycle models, ECU firmware revisions and BLE OBD2 adapters, the app periodically sends anonymous diagnostic telemetry to a secure cloud server (adapter model name, ELM/KWP protocol responses, detected CAN header IDs, and fault codes). No personal identity, GPS location, license plate, or vehicle VIN is ever collected or transmitted."
                )
            ]
        case .french:
            return [
                DisclaimerArticle(
                    title: "1. Nature du Logiciel & But Informatif",
                    text: "L'application YaDiag est fournie 'EN L'ÉTAT' ('AS IS'), à titre technique et informatif. Elle ne remplace en aucun cas les ateliers agréés, les mécaniciens professionnels ni les manuels d'atelier officiels du constructeur."
                ),
                DisclaimerArticle(
                    title: "2. Conscience des Risques Techniques & Mécaniques",
                    text: "L'envoi de commandes aux calculateurs injection (FI ECU) et freinage (ABS ECU) — purge pompe ABS, reset adaptation ISC 0x54 et trims O2/CO 0x52 — modifie directement les paramètres véhicule. Une batterie faible (< 12.8V) ou un moteur tournant peut provoquer des pannes sévères."
                ),
                DisclaimerArticle(
                    title: "3. Exonération Totale de Responsabilité (Droit UE)",
                    text: "Dans les limites autorisées par le droit européen et le Code de la Consommation, le développeur décline toute responsabilité pour tout dommage direct, indirect ou accidentel (casse moteur, dégâts circuit de freinage/ABS, perte de garantie constructeur ou accidents)."
                ),
                DisclaimerArticle(
                    title: "4. Sécurité Routière & Réglementation",
                    text: "Tous les tests actionneurs et effacements de codes doivent être impérativement effectués sur véhicule à l'arrêt, en toute sécurité sur terrain privé fermé à la circulation, conformément au Code de la Route et aux normes d'émissions Euro 4 / Euro 5."
                ),
                DisclaimerArticle(
                    title: "5. Données de Diagnostic Anonymes & Compatibilité",
                    text: "Afin de vérifier et d'améliorer la compatibilité matérielle (adaptateurs BLE, protocoles ELM/KWP/UDS et versions calculateurs), l'application transmet des données techniques anonymisées vers un serveur cloud sécurisé. Aucune donnée d'identification personnelle, géolocalisation ou numéro de série n'est collectée."
                )
            ]
        case .spanish:
            return [
                DisclaimerArticle(
                    title: "1. Naturaleza del Software y Propósito Informativo",
                    text: "La aplicación YaDiag se proporciona 'TAL CUAL' ('AS IS'), con fines puramente técnicos e informativos. No sustituye en modo alguno a los talleres oficiales, mecánicos certificados ni a los manuales de servicio oficiales del fabricante."
                ),
                DisclaimerArticle(
                    title: "2. Advertencia de Riesgos Técnicos y Mecánicos",
                    text: "El envío de comandos a las centralitas de inyección (FI ECU) y frenos (ABS) — purga de bomba ABS, reinicio adaptativo ISC 0x54 y ajuste O2/CO 0x52 — modifica directamente los sistemas del vehículo. Procedimientos indebidos con batería baja (< 12.8V) pueden causar daños mecánicos o fallos."
                ),
                DisclaimerArticle(
                    title: "3. Exoneración Total de Responsabilidad (Normativa UE)",
                    text: "En la medida máxima permitida por la legislación europea y de consumo, el desarrollador declina toda responsabilidad por daños directos, indirectos o accidentales (averías de motor, daños eléctricos/ABS, anulación de garantía o accidentes) derivados del uso de la aplicación."
                ),
                DisclaimerArticle(
                    title: "4. Seguridad Vial y Normativas Vigentes",
                    text: "Todas las pruebas de diagnóstico y borrado de averías deben ejecutarse exclusivamente con el vehículo detenido, en condiciones seguras en recinto privado cerrado al tráfico, cumpliendo las leyes de seguridad vial y normativas Euro 4 / Euro 5."
                ),
                DisclaimerArticle(
                    title: "5. Telemetría Diagnóstica Anónima para Compatibilidad",
                    text: "Con el único propósito de verificar y optimizar la compatibilidad entre modelos de motocicletas, centralitas y adaptadores OBD2 Bluetooth, la app transmite datos técnicos anónimos a un servidor en la nube (modelo de adaptador, versión de protocolo y códigos de diagnóstico). En ningún caso se recopila información personal, ubicación GPS o número de bastidor."
                )
            ]
        case .german:
            return [
                DisclaimerArticle(
                    title: "1. Art der Software & Informationszweck",
                    text: "Die Anwendung YaDiag wird 'WIE BESEHEN' ('AS IS') zu rein technischen Informations- und Prüfzwecken bereitgestellt. Sie ersetzt keinesfalls Vertragswerkstätten, qualifizierte Mechaniker oder offizielle Werkstatthandbücher des Herstellers."
                ),
                DisclaimerArticle(
                    title: "2. Technische & Mechanische Risiken",
                    text: "Diagnosebefehle an Motor- (FI ECU) und ABS-Steuergeräte (einschließlich ABS-Pumpenentlüftung, ISC 0x54 Leerlaufreset und O2/CO 0x52 Trims) greifen direkt in Regelsysteme ein. Unsachgemäße Bedienung bei schwacher Batterie (< 12.8V) kann Fehlfunktionen oder Schäden verursachen."
                ),
                DisclaimerArticle(
                    title: "3. Vollständiger Haftungsausschluss (EU-Recht)",
                    text: "Soweit gesetzlich nach EU-Verbraucherrichtlinien zulässig, lehnt der Entwickler jegliche Haftung für direkte, indirekte oder beiläufig entstandene Schäden (Motorschäden, Defekte an Elektrik/ABS, Erlöschen der Herstellergarantie oder Unfälle) vollumfänglich ab."
                ),
                DisclaimerArticle(
                    title: "4. Verkehrssicherheit & Umweltnormen",
                    text: "Alle erweiterten Stellgliedtests und Fehlerspeicherlöschungen dürfen ausschließlich bei stehendem Fahrzeug auf abgesperrtem Privatgelände unter strikter Einhaltung der Straßenverkehrsordnung und Euro-4 / Euro-5 Abgasnormen erfolgen."
                ),
                DisclaimerArticle(
                    title: "5. Anonyme Diagnosedaten für Hardware-Kompatibilität",
                    text: "Zur kontinuierlichen Überprüfung und Optimierung der Kompatibilität verschiedener Motorrad- und Steuergeräte-Modelle sowie Bluetooth-OBD2-Adapter überträgt die App rein technische, anonymisierte Diagnosedaten an einen sicheren Cloud-Server. Es werden niemals personenbezogene Daten, GPS-Standorte oder Fahrgestellnummern (VIN) erfasst."
                )
            ]
        }
    }
}
