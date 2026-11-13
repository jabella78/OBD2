package com.jabella78.yadiag.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.AppEdition
import com.jabella78.yadiag.core.AppLanguage
import com.jabella78.yadiag.core.LocalizationManager

data class ModelCategory(
    val engineFamily: String,
    val subtitle: String,
    val models: List<String>,
    val years: String,
    val badgeColor: Color
)

@Composable
fun InfoScreen(
    loc: LocalizationManager,
    currentDeploymentId: String,
    onOpenServiceGuide: () -> Unit,
    onReviewDisclaimer: () -> Unit
) {
    val scrollState = rememberScrollState()
    val lang = loc.currentLanguage

    val infoTitle = when (lang) {
        AppLanguage.ENGLISH -> "Information & Compatibility"
        AppLanguage.ITALIAN -> "Informazioni & Compatibilità"
        AppLanguage.FRENCH -> "Informations & Compatibilité"
        AppLanguage.SPANISH -> "Información y Compatibilidad"
        AppLanguage.GERMAN -> "Informationen & Kompatibilität"
    }

    val infoSubtitle = "${AppEdition.appName} — $currentDeploymentId"

    val canOverviewTitle = when (lang) {
        AppLanguage.ENGLISH -> "CAN-bus Protocol Architecture"
        AppLanguage.ITALIAN -> "Compatibilità Protocolli CAN-bus"
        AppLanguage.FRENCH -> "Architecture Protocoles CAN-bus"
        AppLanguage.SPANISH -> "Arquitectura Protocolos CAN-bus"
        AppLanguage.GERMAN -> "CAN-Bus Protokollarchitektur"
    }

    val canOverviewDesc = when (lang) {
        AppLanguage.ENGLISH -> "YaDiag communicates via standard KWP2000 over CAN-bus (500 kbps, 11-bit standard ID) and UDS (ISO 14229) protocol. All Euro 4 (4-pin white diagnostic connector) and Euro 5 (standard 16-pin OBD2 connector) Japanese motorcycles and scooters share the same ECU network architecture for the Engine ECU (FI ECU 7E0/7E8) and ABS unit (Advics 7E3/7EB)."
        AppLanguage.ITALIAN -> "YaDiag comunica tramite standard KWP2000 su CAN-bus (500 kbps, 11-bit) e protocollo UDS (ISO 14229). Tutte le motociclette e scooter dotati di omologazione Euro 4 (connettore diagnostico 4-pin bianco) ed Euro 5 (connettore OBD2 standard a 16-pin) condividono la stessa architettura per la centralina motore (FI ECU 7E0/7E8) e centralina ABS (Advics 7E3/7EB)."
        AppLanguage.FRENCH -> "YaDiag communique via le standard KWP2000 sur CAN-bus (500 kbps, ID 11 bits) et le protocole UDS (ISO 14229). Toutes les motos et scooters homologués Euro 4 (prise blanche 4 broches) et Euro 5 (prise OBD2 standard 16 broches) partagent la même architecture calculateur moteur (FI ECU 7E0/7E8) et ABS (Advics 7E3/7EB)."
        AppLanguage.SPANISH -> "YaDiag se comunica mediante el estándar KWP2000 sobre CAN-bus (500 kbps, 11 bits) y protocolo UDS (ISO 14229). Todas las motocicletas y scooters con homologación Euro 4 (conector 4 pines blanco) y Euro 5 (conector OBD2 estándar 16 pines) comparten la misma arquitectura de centralita motor (FI ECU 7E0/7E8) y ABS (Advics 7E3/7EB)."
        AppLanguage.GERMAN -> "YaDiag kommuniziert über KWP2000 auf CAN-Bus (500 kbps, 11-Bit) und das UDS (ISO 14229) Protokoll. Alle nach Euro 4 (weißer 4-Pin-Stecker) und Euro 5 (16-Pin OBD2-Buchse) homologierten Modelle teilen die gleiche Architektur für das Motorsteuergerät (FI ECU 7E0/7E8) und das ABS-Modul (Advics 7E3/7EB)."
    }

    val modelsSectionTitle = when (lang) {
        AppLanguage.ENGLISH -> "Supported Engine Families & Models"
        AppLanguage.ITALIAN -> "Modelli e Piattaforme Motore Supportate"
        AppLanguage.FRENCH -> "Familles Moteur et Modèles Supportés"
        AppLanguage.SPANISH -> "Familias de Motor y Modelos Compatibles"
        AppLanguage.GERMAN -> "Unterstützte Motorfamilien & Modelle"
    }

    val transparencyTitle = when (lang) {
        AppLanguage.ENGLISH -> "Transparency & Compatibility Notice"
        AppLanguage.ITALIAN -> "Nota di Trasparenza & Compatibilità"
        AppLanguage.FRENCH -> "Note de Transparence & Compatibilité"
        AppLanguage.SPANISH -> "Nota de Transparencia y Compatibilidad"
        AppLanguage.GERMAN -> "Transparenz- & Kompatibilitätshinweis"
    }

    val transparencyBody = when (lang) {
        AppLanguage.ENGLISH -> "YaDiag Pro is an independent diagnostic software. Standard DTC fault diagnostics (Mode 03/04 for Engine and KWP 0x18 for ABS) and live telemetry operate on standard CAN-bus architecture. Advanced adaptive resets (ISC Code 67 and O2 sensor Code 87) are certified on the CP3 Euro 4 platform; on other models, access to specific internal Denso registers depends on the installed ECU firmware release. Service reminder resets (oil / wrench indicators) are performed directly on the motorcycle meter cluster via the official dashboard procedures documented in the guide."
        AppLanguage.ITALIAN -> "YaDiag Pro è un software diagnostico indipendente. Le funzionalità diagnostiche DTC (Mode 03/04 per Motore ed errore KWP 0x18 per ABS) e telemetria operano su standard CAN-bus. I reset adattivi (ISC Cod. 67 e Sonda Lambda Cod. 87) sono certificati sulla piattaforma CP3 Euro 4; per gli altri modelli l'accesso a specifici registri interni dipende dal firmware centralina Denso installato. Le procedure di azzeramento spia tagliando (chiave/olio) sono manuali da cruscotto e consultabili nella guida dedicata."
        AppLanguage.FRENCH -> "YaDiag Pro est un logiciel de diagnostic indépendant. Le diagnostic standard DTC et la télémétrie fonctionnent selon les normes CAN-bus. Les réinitialisations adaptatives (ISC Code 67 et sonde Lambda Code 87) sont certifiées sur plateforme CP3 Euro 4. La réinitialisation des rappels d'entretien (voyant vidange/clé) s'effectue manuellement au tableau de bord selon les procédures documentées."
        AppLanguage.SPANISH -> "YaDiag Pro es una herramienta de diagnóstico independiente. La diagnosis DTC y la telemetría operan sobre estándares CAN-bus. Los reinicios adaptativos (ISC Cód. 67 y Lambda Cód. 87) están certificados en la plataforma CP3 Euro 4. El reinicio de la luz de mantenimiento (aceite / llave) se realiza manualmente desde el cuadro de instrumentos mediante los pasos indicados en la guía."
        AppLanguage.GERMAN -> "YaDiag Pro ist eine unabhängige Diagnosesoftware. Die DTC-Diagnose und Telemetrie arbeiten nach CAN-Bus-Standards. Adaptive Resets (ISC Code 67 und Lambdasonde Code 87) sind auf der CP3 Euro 4 Plattform zertifiziert. Das Zurücksetzen der Wartungsanzeige erfolgt manuell über das Cockpit gemäß Anleitung."
    }

    val serviceGuideQuickBtnTitle = when (lang) {
        AppLanguage.ENGLISH -> "Official Service Reset Guide (Dashboard)"
        AppLanguage.ITALIAN -> "Guida Ufficiale Reset Tagliando (da cruscotto)"
        AppLanguage.FRENCH -> "Guide Officiel Reset Entretien (Compteur)"
        AppLanguage.SPANISH -> "Guía Oficial Reinicio Servicio (Tablero)"
        AppLanguage.GERMAN -> "Offizielle Service-Reset-Anleitung (Cockpit)"
    }

    val serviceGuideQuickBtnSubtitle = when (lang) {
        AppLanguage.ENGLISH -> "Step-by-step manual procedures to reset Oil Trip, wrench icon and V-Belt"
        AppLanguage.ITALIAN -> "Procedure manuali per azzerare Oil Trip, spia chiave e V-Belt per tutti i modelli"
        AppLanguage.FRENCH -> "Procédures manuelles pour réinitialiser Oil Trip, voyant clé et V-Belt"
        AppLanguage.SPANISH -> "Procedimientos manuales para reiniciar Oil Trip, testigo de llave y V-Belt"
        AppLanguage.GERMAN -> "Manuelle Tastenfolgen zum Zurücksetzen von Oil Trip, Schraubenschlüssel und V-Belt"
    }

    val categories = getModelCategories(lang)

    val featuresSectionTitle = when (lang) {
        AppLanguage.ENGLISH -> "Included Diagnostic Capabilities"
        AppLanguage.ITALIAN -> "Funzionalità Diagnostiche Incluse"
        AppLanguage.FRENCH -> "Fonctionnalités Diagnostic Incluses"
        AppLanguage.SPANISH -> "Funciones de Diagnóstico Incluidas"
        AppLanguage.GERMAN -> "Enthaltene Diagnosefunktionen"
    }

    val featuresList = when (lang) {
        AppLanguage.ENGLISH -> listOf(
            "Live Telemetry: Engine RPM, Speed, Calculated Gear, TPS Throttle, Coolant Temp, Battery Voltage, O2 Lambda, IAT, MAP.",
            "Engine DTC Diagnostics: Read and clear fault codes (DTC P-codes) with technical explanations.",
            "Advics ABS Advanced Diagnostics: KWP fault memory read (18 00 FF 00) with offline database of 23 active and historical codes.",
            "PDF Diagnostic Report: Export and share official diagnostic certificate & maintenance inspection report.",
            "Service Reset Guide: Official dashboard button procedures to reset Oil Trip, Annual Service and V-Belt.",
            "Throttle Body Wear & Cleaning: Monitor ISC stepper motor micro-step compensation (Register 0x54) and Code 67 status.",
            "Adaptive Resets: Throttle bodies / ISC idle stepper reset (Code 67) and O2 lambda closed-loop trim reset (Code 87).",
            "Raw Serial Terminal: Low-level OBD2/CAN command line to manually send ELM327 and KWP2000 frames."
        )
        AppLanguage.ITALIAN -> listOf(
            "Telemetria live: RPM, Velocità, Marcia calcolata, TPS, Temperatura liquido, Batteria, Tensione Lambda O2, IAT, MAP.",
            "Diagnosi Guasti Motore: Lettura e cancellazione codici DTC (DTC P-codes) con spiegazione contestuale.",
            "Diagnosi Avanzata ABS Advics: Lettura memoria guasti KWP (18 00 FF 00) con database offline di 23 codici storici e attivi.",
            "Certificato PDF & Perizia: Esportazione e condivisione report diagnostico con timbro data e stato di salute componenti.",
            "Guida Reset Tagliando: Procedure ufficiali manuali da cruscotto per azzeramento spia tagliando, Oil Trip e V-Belt.",
            "Stato Usura & Pulizia Corpi Farfallati: Monitoraggio compensazione micro-step ISC (Registro 0x54) e flag Cod. 67.",
            "Reset Adattivi: Reset corpi farfallati/minimo ISC (Cod. 67) e reset autoadattamento sonda lambda O2 (Cod. 87).",
            "Terminale Seriale Raw: Interfaccia a riga di comando OBD2/CAN per invio manuale di comandi ELM327/KWP2000."
        )
        AppLanguage.FRENCH -> listOf(
            "Télémétrie en direct : RPM, Vitesse, Rapport engagé, TPS, Température liquide, Batterie, Sonde Lambda O2, IAT, MAP.",
            "Diagnostic Moteur : Lecture et effacement des codes défaut (DTC) avec explications contextuelles.",
            "Diagnostic Avancé ABS Advics : Lecture mémoire défauts KWP (18 00 FF 00) avec base de données hors ligne de 23 codes.",
            "Rapport de Diagnostic PDF : Exportation et partage du certificat d'inspection et de maintenance officiel.",
            "Guide Reset Entretien : Procédures manuelles au compteur pour réinitialiser Oil Trip, vidange et V-Belt.",
            "Usure et Nettoyage Corps Papillon : Surveillance adaptation moteur pas-à-pas ISC (Registre 0x54) et Code 67.",
            "Réinitialisations Adaptatives : Reset ralenti ISC (Code 67) et reset trims sonde Lambda O2 (Code 87).",
            "Terminal Série Raw : Ligne de commande OBD2/CAN pour envoi manuel de trames ELM327/KWP2000."
        )
        AppLanguage.SPANISH -> listOf(
            "Telemetría en vivo: RPM, Velocidad, Marcha engranada, TPS, Temperatura refrigerante, Batería, Sonda Lambda O2, IAT, MAP.",
            "Diagnóstico de Motor: Lectura y borrado de averías (DTC) con explicaciones técnicas detalladas.",
            "Diagnóstico Avanzado ABS Advics: Lectura memoria KWP (18 00 FF 00) con base offline de 23 códigos.",
            "Certificado de Diagnóstico PDF: Exportación y compartición de informe técnico y peritaje oficial.",
            "Guía Reset Mantenimiento: Pasos oficiales desde el cuadro de instrumentos para reiniciar Oil Trip y correa V-Belt.",
            "Estado y Limpieza Cuerpos de Mariposa: Monitorización de adaptación motor paso a paso ISC (Registro 0x54) y Código 67.",
            "Reinicios Adaptativos: Reset de ralentí ISC (Código 67) y reset de trims de sonda Lambda O2 (Código 87).",
            "Terminal Serie Raw: Consola de comandos OBD2/CAN para envío manual de tramas ELM327/KWP2000."
        )
        AppLanguage.GERMAN -> listOf(
            "Live-Telemetrie: Drehzahl, Geschwindigkeit, Gangberechnung, TPS, Kühlmitteltemp., Batteriespannung, Lambdasonde, IAT, MAP.",
            "Motor-Fehlerdiagnose: Auslesen und Löschen von DTC-Fehlercodes mit technischen Erläuterungen.",
            "Erweiterte Advics ABS-Diagnose: KWP-Fehlerspeicher (18 00 FF 00) mit Offline-Datenbank für 23 Codes.",
            "PDF-Diagnosebericht: Export und Weitergabe des offiziellen Inspektions- und Wartungszertifikats.",
            "Service-Reset-Anleitung: Manuelle Cockpit-Abläufe zum Zurücksetzen von Oil Trip, Wartung und V-Belt.",
            "Drosselklappen-Verschleiß & Reinigung: Überwachung der ISC-Schrittmotor-Kompensation (Register 0x54) und Code 67.",
            "Adaptive Resets: Reset Drosselklappen/Leerlauf ISC (Code 67) und Reset der Lambdasonden-Trims (Code 87).",
            "Raw Serielles Terminal: OBD2/CAN-Befehlszeile zum manuellen Senden von ELM327- und KWP2000-Befehlen."
        )
    }

    val hardwareSectionTitle = when (lang) {
        AppLanguage.ENGLISH -> "Supported & Certified OBD2 Adapters"
        AppLanguage.ITALIAN -> "Adattatori OBD2 Supportati e Certificati"
        AppLanguage.FRENCH -> "Adaptateurs OBD2 Supportés et Certifiés"
        AppLanguage.SPANISH -> "Adaptadores OBD2 Compatibles y Certificados"
        AppLanguage.GERMAN -> "Unterstützte & Zertifizierte OBD2-Adapter"
    }

    val hardwareDesc = when (lang) {
        AppLanguage.ENGLISH -> "YaDiag utilizes advanced UDS/KWP2000 command sequences and ISO-TP CAN flow control (multi-frame). To ensure complete ECU safety and maximum refresh rates, the app includes an adapter compatibility filter."
        AppLanguage.ITALIAN -> "YaDiag utilizza sequenze avanzate di comandi UDS/KWP2000 e controllo di flusso CAN ISO-TP (frame lunghi). Per garantire la totale sicurezza della centralina e la massima velocità di aggiornamento, l'app include un selettore di compatibilità."
        AppLanguage.FRENCH -> "YaDiag utilise des séquences avancées UDS/KWP2000 et le contrôle de flux CAN ISO-TP (trames multiples). Pour assurer la sécurité du calculateur et un rafraîchissement maximal, l'application intègre un filtre de compatibilité."
        AppLanguage.SPANISH -> "YaDiag utiliza secuencias avanzadas de comandos UDS/KWP2000 y control de flusso CAN ISO-TP (tramas largas). Para garantizar la total seguridad de la centralita y máxima velocidad, la app incluye un filtro de adaptadores."
        AppLanguage.GERMAN -> "YaDiag verwendet fortschrittliche UDS/KWP2000-Befehlssequenzen und ISO-TP CAN-Flusskontrolle. Für höchste Steuergerätesicherheit und maximale Abtastraten verfügt die App über einen Kompatibilitätsfilter."
    }

    val certifiedAdaptersTitle = when (lang) {
        AppLanguage.ENGLISH -> "Certified & Recommended Adapters (STN / High-Speed Chipsets):"
        AppLanguage.ITALIAN -> "Adattatori Certificati e Raccomandati (Chipset STN / High-Speed):"
        AppLanguage.FRENCH -> "Adaptateurs Certifiés et Recommandés (Chipsets STN / Haute Vitesse) :"
        AppLanguage.SPANISH -> "Adaptadores Certificados y Recomendados (Chipsets STN / Alta Velocidad):"
        AppLanguage.GERMAN -> "Zertifizierte & Empfohlene Adapter (STN / High-Speed Chipsätze):"
    }

    val extendedModeWarning = when (lang) {
        AppLanguage.ENGLISH -> "⚠️ Extended Compatibility Mode (Other ELM327 BLE):\nWhen enabled in the Bluetooth tab, any generic BLE scanner can connect. Cheap clones ($5-10) are discouraged due to small memory buffers that fail on multi-frame ABS diagnostics or 35-byte payloads."
        AppLanguage.ITALIAN -> "⚠️ Modalità Compatibilità Estesa (Altri ELM327 BLE):\nAttivando l'opzione nella scheda Bluetooth, è possibile collegare qualsiasi altro adattatore diagnostico BLE generico. Si sconsigliano cloni cinesi ultra-economici (5-10€) a causa di buffer di memoria limitati che non supportano la diagnostica profonda ABS o i frame a 35 byte."
        AppLanguage.FRENCH -> "⚠️ Mode Compatibilité Étendue (Autres ELM327 BLE) :\nActivé dans l'onglet Bluetooth, tout scanner BLE générique peut se connecter. Les clones ultra-économiques (5-10€) sont déconseillés en raison de mémoires tampons insuffisantes pour le diagnostic ABS multi-trames."
        AppLanguage.SPANISH -> "⚠️ Modo Compatibilidad Extendida (Otros ELM327 BLE):\nAl activarlo en la pestaña Bluetooth, se puede conectar cualquier otro escáner BLE genérico. Se desaconsejan clones chinos muy económicos (5-10€) por búferes de memoria insuficientes para diagnósticos ABS largos."
        AppLanguage.GERMAN -> "⚠️ Erweiterter Kompatibilitätsmodus (Andere ELM327 BLE):\nBei Aktivierung im Bluetooth-Tab kann jeder generische BLE-Scanner verbunden werden. Günstige Klone (5-10€) werden wegen unzureichender Puffergröße für die ABS-Multiframe-Diagnose nicht empfohlen."
    }

    val cableTitle = when (lang) {
        AppLanguage.ENGLISH -> "• Motorcycle Diagnostic Cable:\n  - Euro 4 Models (2016–2020): 4-pin white motorcycle adapter cable to 16-pin OBD2 female.\n  - Euro 5 Models (2021+): Standard 16-pin OBD2 connector already present under the seat."
        AppLanguage.ITALIAN -> "• Cavo Adattatore per Moto:\n  - Modelli Euro 4 (2016–2020): Cavo adattatore Yamaha da connettore 4-pin bianco a presa standard OBD2 femmina 16-pin.\n  - Modelli Euro 5 (2021+): Presa standard OBD2 a 16-pin già presente di serie sotto la sella."
        AppLanguage.FRENCH -> "• Câble Adaptateur Moto :\n  - Modèles Euro 4 (2016–2020) : Câble adaptateur prise blanche 4 broches vers prise femelle OBD2 16 broches.\n  - Modèles Euro 5 (2021+) : Prise OBD2 standard 16 broches présente de série sous la selle."
        AppLanguage.SPANISH -> "• Cable Adaptador para Moto:\n  - Modelos Euro 4 (2016–2020): Cable adaptador de conector 4 pines blanco a toma hembra OBD2 16 pines.\n  - Modelos Euro 5 (2021+): Toma OBD2 estándar de 16 pines ya integrada de serie bajo el asiento."
        AppLanguage.GERMAN -> "• Motorrad-Diagnosekabel:\n  - Euro 4 Modelle (2016–2020): Adapterkabel von weißem 4-Pin-Stecker auf 16-Pin OBD2-Buchse.\n  - Euro 5 Modelle (2021+): Standard 16-Pin OBD2-Buchse serienmäßig unter der Sitzbank vorhanden."
    }

    val disclaimerSectionTitle = when (lang) {
        AppLanguage.ENGLISH -> "Legal Notice & Trademarks (Disclaimer)"
        AppLanguage.ITALIAN -> "Note Legali e Marchi Registrati (Disclaimer)"
        AppLanguage.FRENCH -> "Mentions Légales & Marques Déposées"
        AppLanguage.SPANISH -> "Aviso Legal y Marcas Registradas"
        AppLanguage.GERMAN -> "Rechtliche Hinweise & Marken (Disclaimer)"
    }

    val disclaimerSectionDesc = when (lang) {
        AppLanguage.ENGLISH -> "YaDiag is an independent diagnostic software developed for enthusiast and professional technical use. The application is not affiliated, endorsed, sponsored, or associated in any way with Yamaha Motor Co., Ltd. or its subsidiaries. All trademarks, model names, and commercial references belong to their respective owners and are used purely for hardware and software compatibility identification."
        AppLanguage.ITALIAN -> "YaDiag è un'applicazione diagnostica indipendente sviluppata ad uso amatoriale e professionale. L'applicazione non è affiliata, approvata, sponsorizzata o associata in alcun modo a Yamaha Motor Co., Ltd. né alle sue filiali. Tutti i marchi, i nomi dei modelli, i loghi e i riferimenti commerciali citati appartengono ai rispettivi proprietari e sono utilizzati esclusivamente a fini identificativi e descrittivi della compatibilità hardware e software."
        AppLanguage.FRENCH -> "YaDiag est une application de diagnostic indépendante développée à des fins techniques et professionnelles. L'application n'est pas affiliée, approuvée, parrainée ou associée de quelque manière que ce soit à Yamaha Motor Co., Ltd. ou à ses filiales. Toutes les marques et dénominations citées appartiennent à leurs propriétaires respectifs et sont utilisées uniquement à des fins d'identification."
        AppLanguage.SPANISH -> "YaDiag es una aplicación de diagnóstico independiente desarrollada para uso técnico y profesional. La aplicación no está afiliada, aprobada, patrocinada ni asociada en modo alguno con Yamaha Motor Co., Ltd. ni con sus filiales. Todas las marcas registradas y nombres comerciales pertenecen a sus respectivos propietarios y se utilizan únicamente con fines de identificación."
        AppLanguage.GERMAN -> "YaDiag ist eine unabhängige Diagnosesoftware für den technischen und professionellen Einsatz. Die Anwendung steht in keinerlei Verbindung zu Yamaha Motor Co., Ltd. oder deren Tochtergesellschaften und wird von diesen weder unterstützt noch empfohlen. Alle genannten Marken und Modellbezeichnungen dienen ausschließlich der Kompatibilitätsbeschreibung."
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg)
            .verticalScroll(scrollState)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        // Header Info
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            modifier = Modifier.padding(top = 6.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Info,
                contentDescription = null,
                tint = CyanAccent,
                modifier = Modifier.size(38.dp)
            )
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = infoTitle,
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = infoSubtitle,
                    color = Color.Gray,
                    fontSize = 12.sp
                )
            }
        }

        // Card Panoramica CAN-bus
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(CyanAccent.copy(alpha = 0.08f))
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = canOverviewTitle,
                color = CyanAccent,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = canOverviewDesc,
                color = Color.White.copy(alpha = 0.8f),
                fontSize = 12.sp,
                lineHeight = 17.sp
            )
        }

        // Sezione Modelli Supportati & Compatibilità Graduata
        Text(
            text = modelsSectionTitle,
            color = Color.White,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold
        )

        // Card Trasparenza & Disclaimer Compatibilità Funzioni Avanzate
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(10.dp))
                .background(Color(0xFFFF9800).copy(alpha = 0.1f))
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Security,
                    contentDescription = null,
                    tint = Color(0xFFFF9800),
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    text = transparencyTitle,
                    color = Color(0xFFFF9800),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
            Text(
                text = transparencyBody,
                color = Color.White.copy(alpha = 0.78f),
                fontSize = 11.sp,
                lineHeight = 16.sp
            )
        }

        // Bottone Accesso Rapido Guida Reset Tagliando da Cruscotto
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(10.dp))
                .background(CardBg)
                .border(1.dp, Color(0xFFFF9800).copy(alpha = 0.35f), RoundedCornerShape(10.dp))
                .clickable { onOpenServiceGuide() }
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Build,
                contentDescription = null,
                tint = Color(0xFFFF9800),
                modifier = Modifier.size(20.dp)
            )
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = serviceGuideQuickBtnTitle,
                    color = Color.White,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = serviceGuideQuickBtnSubtitle,
                    color = Color.Gray,
                    fontSize = 11.sp
                )
            }
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = Color.Gray
            )
        }

        // Lista Categorie Modelli con Badge Graduati
        val certifiedBadge = when (lang) {
            AppLanguage.ENGLISH -> "🟢 Certified 100%"
            AppLanguage.FRENCH -> "🟢 Certifié 100%"
            AppLanguage.SPANISH -> "🟢 Certificado 100%"
            AppLanguage.GERMAN -> "🟢 100% Zertifiziert"
            AppLanguage.ITALIAN -> "🟢 Certificato 100%"
        }
        val kwpBadge = when (lang) {
            AppLanguage.ENGLISH -> "🟡 KWP Compatible"
            AppLanguage.FRENCH -> "🟡 Compatible KWP"
            AppLanguage.SPANISH -> "🟡 Compatible KWP"
            AppLanguage.GERMAN -> "🟡 KWP-kompatibel"
            AppLanguage.ITALIAN -> "🟡 Compatibile KWP"
        }
        val obd2Badge = when (lang) {
            AppLanguage.ENGLISH -> "🔵 Standard OBD2"
            AppLanguage.FRENCH -> "🔵 Standard OBD2"
            AppLanguage.SPANISH -> "🔵 Estándar OBD2"
            AppLanguage.GERMAN -> "🔵 Standard-OBD2"
            AppLanguage.ITALIAN -> "🔵 Standard OBD2"
        }

        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            categories.forEach { cat ->
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(CardBg)
                        .padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = cat.engineFamily,
                            color = cat.badgeColor,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1f)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = cat.years,
                            color = cat.badgeColor,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier
                                .clip(RoundedCornerShape(6.dp))
                                .background(cat.badgeColor.copy(alpha = 0.15f))
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }

                    Text(
                        text = cat.subtitle,
                        color = Color.Gray,
                        fontSize = 11.sp
                    )

                    Divider(color = Color.White.copy(alpha = 0.08f))

                    cat.models.forEach { model ->
                        val isCertified = model.contains("Tracer 900") || (model.contains("MT-09") && !model.contains("Tracer 9"))
                        val isKwpEuro4 = !model.contains("Tracer 9") && (cat.badgeColor != Color(0xFFFF9800))

                        val rowColor = when {
                            isCertified -> Color(0xFF4CAF50)
                            isKwpEuro4 -> CyanAccent
                            else -> Color(0xFF2196F3)
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                                modifier = Modifier.weight(1f)
                            ) {
                                Icon(
                                    imageVector = if (isCertified) Icons.Default.Verified else Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = rowColor,
                                    modifier = Modifier.size(14.dp)
                                )
                                Text(
                                    text = model,
                                    color = Color.White,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            Text(
                                text = when {
                                    isCertified -> certifiedBadge
                                    isKwpEuro4 -> kwpBadge
                                    else -> obd2Badge
                                },
                                color = rowColor,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }

        // Sezione Funzionalità Diagnostiche
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(CardBg)
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = featuresSectionTitle,
                color = CyanAccent,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold
            )

            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                featuresList.forEach { item ->
                    Row(
                        verticalAlignment = Alignment.Top,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = CyanAccent,
                            modifier = Modifier
                                .size(15.dp)
                                .padding(top = 2.dp)
                        )
                        Text(
                            text = item,
                            color = Color.White.copy(alpha = 0.85f),
                            fontSize = 12.sp,
                            lineHeight = 17.sp
                        )
                    }
                }
            }
        }

        // Sezione Requisiti Hardware
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(CardBg)
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(
                text = hardwareSectionTitle,
                color = CyanAccent,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold
            )

            Text(
                text = hardwareDesc,
                color = Color.White.copy(alpha = 0.8f),
                fontSize = 12.sp,
                lineHeight = 17.sp
            )

            Text(
                text = certifiedAdaptersTitle,
                color = Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )

            val adapters = listOf(
                "UniCarScan serie UCSI: UCSI-2000, UCSI-2100, UCSI-3000 (BLE)",
                "vLinker serie (Vgate): vLinker MC+, vLinker BM+, vLinker FS/FD+ (BLE)",
                "OBDLink: OBDLink MX+ (BLE / SPP), OBDLink CX (BLE)",
                "Veepeak: OBDCheck BLE+",
                "Carista: Carista OBD Adapter (BLE)"
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color(0xFF4CAF50).copy(alpha = 0.08f))
                    .padding(10.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                adapters.forEach { adapter ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Verified,
                            contentDescription = null,
                            tint = Color(0xFF4CAF50),
                            modifier = Modifier.size(15.dp)
                        )
                        Text(
                            text = adapter,
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            Text(
                text = extendedModeWarning,
                color = Color.Gray,
                fontSize = 11.sp,
                lineHeight = 16.sp
            )

            Divider(color = Color.White.copy(alpha = 0.08f))

            Text(
                text = cableTitle,
                color = Color.White.copy(alpha = 0.85f),
                fontSize = 12.sp,
                lineHeight = 17.sp
            )
        }

        // Disclaimer Legale & Bottone Rilettura Termini
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(CardBg.copy(alpha = 0.7f))
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(
                text = disclaimerSectionTitle,
                color = Color.Gray,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = disclaimerSectionDesc,
                color = Color.Gray.copy(alpha = 0.85f),
                fontSize = 11.sp,
                lineHeight = 16.sp
            )

            Button(
                onClick = onReviewDisclaimer,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = CyanAccent.copy(alpha = 0.15f),
                    contentColor = CyanAccent
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Description,
                    contentDescription = null,
                    tint = CyanAccent,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = loc.t("info_read_terms"),
                    color = CyanAccent,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

private fun getModelCategories(lang: AppLanguage): List<ModelCategory> {
    val cp3Models = listOf(
        "Tracer 900 / Tracer 900 GT",
        "MT-09 / MT-09 SP",
        "Tracer 9 / Tracer 9 GT / GT+",
        "XSR900 / XSR900 GP / Abarth",
        "NIKEN / NIKEN GT"
    )
    val cp2Models = listOf(
        "MT-07 / MT-07 Moto Cage",
        "Tracer 700 / Tracer 7 / GT",
        "Ténéré 700 / Rally / World Raid / Explore",
        "XSR700 / XTribute",
        "YZF-R7"
    )
    val cp4Models = listOf(
        "MT-10 / MT-10 SP / Tourer",
        "YZF-R1 / YZF-R1M"
    )
    val scooterModels = listOf(
        "YZF-R3 / MT-03 (321cc)",
        "TMAX 530 / TMAX 560 (2017+)",
        "XMAX 125 / 300 / 400 (2017+)"
    )

    return when (lang) {
        AppLanguage.ITALIAN -> listOf(
            ModelCategory(
                engineFamily = "CP3 — Tre Cilindri Crossplane (847cc / 890cc)",
                subtitle = "Iniezione YCC-T Ride-by-Wire, ABS Advics 2 Canali",
                models = cp3Models,
                years = "2014 – 2026+",
                badgeColor = CyanAccent
            ),
            ModelCategory(
                engineFamily = "CP2 — Bicilindrico Parallelo (689cc)",
                subtitle = "Telemetria Completa, DTC Motore e Diagnostica ABS",
                models = cp2Models,
                years = "2014 – 2026+",
                badgeColor = Color(0xFF2196F3)
            ),
            ModelCategory(
                engineFamily = "CP4 — Quattro Cilindri Crossplane (998cc)",
                subtitle = "Piattaforma Superbike & Hypernaked YCC-T",
                models = cp4Models,
                years = "2015 – 2026+",
                badgeColor = Color(0xFFAB47BC)
            ),
            ModelCategory(
                engineFamily = "Sport & Maxi Scooter (Euro 4 / Euro 5)",
                subtitle = "Diagnostica Standard KWP2000 & UDS CAN-bus",
                models = scooterModels,
                years = "2016 – 2026+",
                badgeColor = Color(0xFFFF9800)
            )
        )
        AppLanguage.ENGLISH -> listOf(
            ModelCategory(
                engineFamily = "CP3 — Three-Cylinder Crossplane (847cc / 890cc)",
                subtitle = "YCC-T Ride-by-Wire Injection, Advics 2-Channel ABS",
                models = cp3Models,
                years = "2014 – 2026+",
                badgeColor = CyanAccent
            ),
            ModelCategory(
                engineFamily = "CP2 — Parallel-Twin (689cc)",
                subtitle = "Full Telemetry, Engine DTC and ABS Diagnostics",
                models = cp2Models,
                years = "2014 – 2026+",
                badgeColor = Color(0xFF2196F3)
            ),
            ModelCategory(
                engineFamily = "CP4 — Four-Cylinder Crossplane (998cc)",
                subtitle = "Superbike & Hypernaked YCC-T Platform",
                models = cp4Models,
                years = "2015 – 2026+",
                badgeColor = Color(0xFFAB47BC)
            ),
            ModelCategory(
                engineFamily = "Sport & Maxi Scooters (Euro 4 / Euro 5)",
                subtitle = "Standard KWP2000 & UDS CAN-bus Diagnostics",
                models = scooterModels,
                years = "2016 – 2026+",
                badgeColor = Color(0xFFFF9800)
            )
        )
        AppLanguage.FRENCH -> listOf(
            ModelCategory(
                engineFamily = "CP3 — Trois Cylindres Crossplane (847cc / 890cc)",
                subtitle = "Injection Ride-by-Wire YCC-T, ABS Advics 2 Canaux",
                models = cp3Models,
                years = "2014 – 2026+",
                badgeColor = CyanAccent
            ),
            ModelCategory(
                engineFamily = "CP2 — Bicylindre Parallèle (689cc)",
                subtitle = "Télémétrie Complète, DTC Moteur et Diagnostic ABS",
                models = cp2Models,
                years = "2014 – 2026+",
                badgeColor = Color(0xFF2196F3)
            ),
            ModelCategory(
                engineFamily = "CP4 — Quatre Cylindres Crossplane (998cc)",
                subtitle = "Plateforme Superbike & Hypernaked YCC-T",
                models = cp4Models,
                years = "2015 – 2026+",
                badgeColor = Color(0xFFAB47BC)
            ),
            ModelCategory(
                engineFamily = "Sport & Maxi Scooters (Euro 4 / Euro 5)",
                subtitle = "Diagnostic Standard KWP2000 & UDS CAN-bus",
                models = scooterModels,
                years = "2016 – 2026+",
                badgeColor = Color(0xFFFF9800)
            )
        )
        AppLanguage.SPANISH -> listOf(
            ModelCategory(
                engineFamily = "CP3 — Tres Cilindros Crossplane (847cc / 890cc)",
                subtitle = "Inyección YCC-T Ride-by-Wire, ABS Advics 2 Canales",
                models = cp3Models,
                years = "2014 – 2026+",
                badgeColor = CyanAccent
            ),
            ModelCategory(
                engineFamily = "CP2 — Bicilíndrico Paralelo (689cc)",
                subtitle = "Telemetría Completa, DTC Motor y Diagnóstico ABS",
                models = cp2Models,
                years = "2014 – 2026+",
                badgeColor = Color(0xFF2196F3)
            ),
            ModelCategory(
                engineFamily = "CP4 — Cuatro Cilindros Crossplane (998cc)",
                subtitle = "Plataforma Superbike e Hipernaked YCC-T",
                models = cp4Models,
                years = "2015 – 2026+",
                badgeColor = Color(0xFFAB47BC)
            ),
            ModelCategory(
                engineFamily = "Sport y Maxi Scooters (Euro 4 / Euro 5)",
                subtitle = "Diagnóstico Estándar KWP2000 y UDS CAN-bus",
                models = scooterModels,
                years = "2016 – 2026+",
                badgeColor = Color(0xFFFF9800)
            )
        )
        AppLanguage.GERMAN -> listOf(
            ModelCategory(
                engineFamily = "CP3 — Dreizylinder Crossplane (847cc / 890cc)",
                subtitle = "YCC-T Ride-by-Wire Einspritzung, Advics 2-Kanal ABS",
                models = cp3Models,
                years = "2014 – 2026+",
                badgeColor = CyanAccent
            ),
            ModelCategory(
                engineFamily = "CP2 — Zweizylinder-Reihenmotor (689cc)",
                subtitle = "Vollständige Telemetrie, Motor-DTC und ABS-Diagnose",
                models = cp2Models,
                years = "2014 – 2026+",
                badgeColor = Color(0xFF2196F3)
            ),
            ModelCategory(
                engineFamily = "CP4 — Vierzylinder Crossplane (998cc)",
                subtitle = "Superbike & Hypernaked YCC-T Plattform",
                models = cp4Models,
                years = "2015 – 2026+",
                badgeColor = Color(0xFFAB47BC)
            ),
            ModelCategory(
                engineFamily = "Sport & Maxi-Roller (Euro 4 / Euro 5)",
                subtitle = "Standard KWP2000 & UDS CAN-Bus Diagnose",
                models = scooterModels,
                years = "2016 – 2026+",
                badgeColor = Color(0xFFFF9800)
            )
        )
    }
}
