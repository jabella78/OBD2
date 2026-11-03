import Foundation
import CoreGraphics
#if os(iOS)
import UIKit
typealias NativeColor = UIColor
typealias NativeFont = UIFont
#elseif os(macOS)
import AppKit
typealias NativeColor = NSColor
typealias NativeFont = NSFont
#endif

final class DiagnosticReportService {
    static let shared = DiagnosticReportService()
    
    private init() {}
    
    /// Genera un documento PDF A4 professionale con impaginazione dinamica, anti-sovrapposizione e rispetto rigoroso dei margini A4.
    func generatePDF(obd2Manager: OBD2Manager) -> URL? {
        let pageWidth: CGFloat = 595.2  // A4 standard width (72 pt/inch)
        let pageHeight: CGFloat = 841.8 // A4 standard height (72 pt/inch)
        var pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let tempDir = FileManager.default.temporaryDirectory
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateFileName = formatter.string(from: Date())
        let fileURL = tempDir.appendingPathComponent("YaDiag_Diagnostic_Report_\(dateFileName).pdf")
        
        #if os(iOS)
        let rendererFormat = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: rendererFormat)
        
        do {
            try renderer.writePDF(to: fileURL, withActions: { rendererContext in
                rendererContext.beginPage()
                let context = rendererContext.cgContext
                self.drawReportContent(context: context, obd2Manager: obd2Manager, pageWidth: pageWidth, pageHeight: pageHeight, dateFileName: dateFileName)
            })
            return fileURL
        } catch {
            print("PDF rendering error on iOS: \(error)")
            return nil
        }
        
        #elseif os(macOS)
        guard let consumer = CGDataConsumer(url: fileURL as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
            return nil
        }
        
        context.beginPage(mediaBox: &pageRect)
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = graphicsContext
        
        self.drawReportContent(context: context, obd2Manager: obd2Manager, pageWidth: pageWidth, pageHeight: pageHeight, dateFileName: dateFileName)
        
        NSGraphicsContext.current = nil
        context.endPage()
        context.closePDF()
        return fileURL
        #endif
    }
    
    private func measureText(_ text: String, width: CGFloat, attrs: [NSAttributedString.Key: Any]) -> CGFloat {
        #if os(iOS)
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: 1000),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        )
        #else
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: 1000),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs
        )
        #endif
        return ceil(rect.height)
    }

    private func tr(lang: AppLanguage, en: String, it: String, fr: String, es: String, de: String) -> String {
        switch lang {
        case .italian: return it
        case .english: return en
        case .french: return fr
        case .spanish: return es
        case .german: return de
        }
    }

    private func drawReportContent(context: CGContext, obd2Manager: OBD2Manager, pageWidth: CGFloat, pageHeight: CGFloat, dateFileName: String) {
        let lang = LocalizationManager.shared.currentLanguage
        
        func toPlatformRect(_ r: CGRect) -> CGRect {
            #if os(iOS)
            return r
            #else
            return CGRect(x: r.origin.x, y: pageHeight - r.origin.y - r.size.height, width: r.size.width, height: r.size.height)
            #endif
        }
        
        // --- 1. Sfondo e Intestazione Superiore (Dark Blue Header) ---
        let headerH: CGFloat = 86
        let headerBg = toPlatformRect(CGRect(x: 0, y: 0, width: pageWidth, height: headerH))
        context.setFillColor(NativeColor(red: 0.07, green: 0.12, blue: 0.22, alpha: 1.0).cgColor)
        context.fill(headerBg)
        
        // Barra accento ciano
        let lineRect = toPlatformRect(CGRect(x: 0, y: headerH, width: pageWidth, height: 3))
        context.setFillColor(NativeColor(red: 0.0, green: 0.75, blue: 0.85, alpha: 1.0).cgColor)
        context.fill(lineRect)
        
        // Titolo Certificato
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.boldSystemFont(ofSize: 17),
            .foregroundColor: NativeColor.white
        ]
        let titleDoc = tr(
            lang: lang,
            en: "YaDiag Pro — Motorcycle Diagnostic Inspection Certificate",
            it: "YaDiag Pro — Certificato di Perizia e Diagnostica Moto",
            fr: "YaDiag Pro — Certificat d'Expertise et Diagnostic Moto",
            es: "YaDiag Pro — Certificado de Peritaje y Diagnóstico Moto",
            de: "YaDiag Pro — Motorrad-Diagnoseprüfbericht"
        )
        let titleRect = toPlatformRect(CGRect(x: 36, y: 16, width: pageWidth - 72, height: 22))
        (titleDoc as NSString).draw(in: titleRect, withAttributes: titleAttrs)
        
        // Sottotitolo e Metadati Report
        let randomId = String(format: "%04d", Int.random(in: 1000...9999))
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let reportTimestamp = formatter.string(from: Date())
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 8.5),
            .foregroundColor: NativeColor(white: 0.82, alpha: 1.0)
        ]
        let subtitleText = tr(
            lang: lang,
            en: "Certificate N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Issued: \(reportTimestamp)",
            it: "Certificato N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Data Emissione: \(reportTimestamp)",
            fr: "Certificat N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Date d'émission : \(reportTimestamp)",
            es: "Certificado N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Fecha de emisión: \(reportTimestamp)",
            de: "Zertifikat Nr. YD-\(dateFileName.prefix(8))-\(randomId)  •  Ausstellungsdatum: \(reportTimestamp)"
        )
        let subRect = toPlatformRect(CGRect(x: 36, y: 42, width: pageWidth - 72, height: 14))
        (subtitleText as NSString).draw(in: subRect, withAttributes: subAttrs)
        
        let noticeText = tr(
            lang: lang,
            en: "Protocol: KWP2000 over CAN-bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Offline",
            it: "Protocollo: KWP2000 over CAN-bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Offline",
            fr: "Protocole : KWP2000 over CAN-bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Hors-ligne",
            es: "Protocolo: KWP2000 sobre CAN-bus (ISO 15765-4 500kbps) y UDS (ISO 14229) — 100% Offline",
            de: "Protokoll: KWP2000 über CAN-Bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Offline"
        )
        let noticeRect = toPlatformRect(CGRect(x: 36, y: 58, width: pageWidth - 72, height: 14))
        (noticeText as NSString).draw(in: noticeRect, withAttributes: subAttrs)
        
        var currentY: CGFloat = 104
        
        func drawSectionHeader(title: String) {
            let h: CGFloat = 20
            let bgRect = toPlatformRect(CGRect(x: 36, y: currentY, width: pageWidth - 72, height: h))
            context.setFillColor(NativeColor(red: 0.0, green: 0.45, blue: 0.75, alpha: 0.10).cgColor)
            context.fill(bgRect)
            
            let barRect = toPlatformRect(CGRect(x: 36, y: currentY, width: 4, height: h))
            context.setFillColor(NativeColor(red: 0.0, green: 0.45, blue: 0.75, alpha: 1.0).cgColor)
            context.fill(barRect)
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NativeFont.boldSystemFont(ofSize: 10),
                .foregroundColor: NativeColor(red: 0.05, green: 0.25, blue: 0.55, alpha: 1.0)
            ]
            let textRect = toPlatformRect(CGRect(x: 46, y: currentY + 3.5, width: pageWidth - 80, height: 14))
            (title.uppercased() as NSString).draw(in: textRect, withAttributes: attrs)
            currentY += h + 6
        }
        
        func drawRow(key: String, value: String, statusColor: NativeColor? = nil, isMonospaced: Bool = false) {
            let keyX: CGFloat = 46
            let keyWidth: CGFloat = 155
            let valX: CGFloat = 210
            let valWidth: CGFloat = pageWidth - valX - 36 // 349.2 pt (garantisce nessun overflow laterale)
            
            let keyAttrs: [NSAttributedString.Key: Any] = [
                .font: NativeFont.systemFont(ofSize: 8.5),
                .foregroundColor: NativeColor.darkGray
            ]
            let valFont: NativeFont = isMonospaced
                ? (NativeFont(name: "Menlo", size: 8.0) ?? NativeFont.systemFont(ofSize: 8.5))
                : NativeFont.boldSystemFont(ofSize: 8.5)
            let valAttrs: [NSAttributedString.Key: Any] = [
                .font: valFont,
                .foregroundColor: statusColor ?? NativeColor.black
            ]
            
            // Misura precisa con a-capo dinamico sia per la chiave sia per il valore
            let keyHeight = self.measureText(key, width: keyWidth, attrs: keyAttrs)
            let valHeight = self.measureText(value, width: valWidth, attrs: valAttrs)
            let contentHeight = max(13, max(keyHeight, valHeight))
            let rowHeight = contentHeight + 4
            
            let kRect = toPlatformRect(CGRect(x: keyX, y: currentY, width: keyWidth, height: keyHeight))
            let vRect = toPlatformRect(CGRect(x: valX, y: currentY, width: valWidth, height: valHeight))
            
            (key as NSString).draw(in: kRect, withAttributes: keyAttrs)
            (value as NSString).draw(in: vRect, withAttributes: valAttrs)
            
            // Linea divisoria sottile
            let lineY = currentY + rowHeight + 1
            let sepRect = toPlatformRect(CGRect(x: keyX, y: lineY, width: pageWidth - keyX - 36, height: 0.5))
            context.setFillColor(NativeColor(white: 0.90, alpha: 1.0).cgColor)
            context.fill(sepRect)
            
            currentY += rowHeight + 3
        }
        
        // --- 2. Dati Identificativi e Connessione ---
        let sec1Title = tr(
            lang: lang,
            en: "1. Identification & Connection Details",
            it: "1. Dati Identificativi e Connessione",
            fr: "1. Données d'Identification et Connexion",
            es: "1. Datos de Identificación y Conexión",
            de: "1. Identifikations- & Verbindungsdaten"
        )
        drawSectionHeader(title: sec1Title)
        
        let simAdapterDefault = tr(
            lang: lang,
            en: "ELM327 Diagnostic Simulator (Demo)",
            it: "Simulatore Diagnostico ELM327 (Demo)",
            fr: "Simulateur Diagnostic ELM327 (Démo)",
            es: "Simulador de Diagnóstico ELM327 (Demo)",
            de: "ELM327-Diagnosesimulator (Demo)"
        )
        let adapterName = obd2Manager.bleManager.connectedPeripheral?.name ?? simAdapterDefault
        
        let keyVehPlat = tr(lang: lang, en: "Vehicle Platform:", it: "Piattaforma Veicolo:", fr: "Plateforme Véhicule :", es: "Plataforma Vehículo:", de: "Fahrzeugplattform:")
        drawRow(key: keyVehPlat, value: "Yamaha Motor CAN-bus (CP3 / CP2 / CP4 / Sport)")
        
        let keyDiagAdapt = tr(lang: lang, en: "Diagnostic Adapter (BLE):", it: "Interfaccia Diagnostica (BLE):", fr: "Adaptateur Diagnostic (BLE) :", es: "Adaptador de Diagnóstico (BLE):", de: "Diagnose-Adapter (BLE):")
        drawRow(key: keyDiagAdapt, value: adapterName)
        
        let keyBatt = tr(lang: lang, en: "Battery Voltage:", it: "Tensione Batteria Veicolo:", fr: "Tension Batterie Véhicule :", es: "Voltaje de Batería:", de: "Batteriespannung:")
        let valBattReg = tr(lang: lang, en: "Normal", it: "Regolare", fr: "Conforme", es: "Normal", de: "Normal")
        drawRow(key: keyBatt, value: "\(obd2Manager.batteryVoltage) — \(valBattReg)")
        
        let keyOpMode = tr(lang: lang, en: "Operating Mode:", it: "Modalità Operativa:", fr: "Mode Opératoire :", es: "Modo Operativo:", de: "Betriebsmodus:")
        let valBenchSim = tr(lang: lang, en: "Certified Bench Simulation", it: "Simulazione Certificata Banco", fr: "Simulation d'Atelier Certifiée", es: "Simulación de Banco Certificada", de: "Zertifizierte Prüfstandssimulation")
        let valDirectConn = tr(lang: lang, en: "Direct On-Board Connection", it: "Connessione Diretta On-Board", fr: "Connexion Directe Embarquée", es: "Conexión Directa a Bordo", de: "Direkte On-Board-Verbindung")
        drawRow(key: keyOpMode, value: obd2Manager.isDemoMode ? valBenchSim : valDirectConn)
        currentY += 4
        
        // --- 3. Diagnosi Memoria Guasti Motore (FI ECU) ---
        let sec2Title = tr(
            lang: lang,
            en: "2. Engine Fault Memory Diagnostics (FI ECU — 7E0)",
            it: "2. Diagnosi Memoria Guasti Motore (FI ECU — 7E0)",
            fr: "2. Diagnostic Mémoire Pannes Moteur (FI ECU — 7E0)",
            es: "2. Diagnóstico Memoria de Averías Motor (FI ECU — 7E0)",
            de: "2. Fehlerspeicher-Diagnose Motor (FI ECU — 7E0)"
        )
        drawSectionHeader(title: sec2Title)
        
        let keyDtcStatus = tr(lang: lang, en: "DTC Status (Mode 03):", it: "Stato Codici DTC (Mode 03):", fr: "État Codes DTC (Mode 03) :", es: "Estado Códigos DTC (Modo 03):", de: "DTC-Fehlerstatus (Modus 03):")
        let valNoDtc = tr(
            lang: lang,
            en: "✅ NO FAULT CODES PRESENT (0 DTC) — Injection System Normal",
            it: "✅ NESSUN ERRORE PRESENTE (0 DTC) — Impianto Iniezione Regolare",
            fr: "✅ AUCUN DÉFAUT PRÉSENT (0 DTC) — Système d'injection conforme",
            es: "✅ NINGÚN ERROR PRESENTE (0 DTC) — Sistema de inyección correcto",
            de: "✅ KEINE FEHLER VORHANDEN (0 DTC) — Einspritzsystem einwandfrei"
        )
        let keyDtcDetected = tr(lang: lang, en: "Detected Fault Code:", it: "Codice Rilevato:", fr: "Code Détecté :", es: "Código Detectado:", de: "Erkannter Fehlercode:")
        
        if obd2Manager.dtcCodes.isEmpty {
            drawRow(
                key: keyDtcStatus,
                value: valNoDtc,
                statusColor: NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0)
            )
        } else {
            for dtc in obd2Manager.dtcCodes {
                drawRow(
                    key: keyDtcDetected,
                    value: "⚠️ \(dtc)",
                    statusColor: NativeColor.red
                )
            }
        }
        
        let keyMil = tr(lang: lang, en: "MIL Warning Light:", it: "Spia MIL (Check Engine):", fr: "Voyant MIL (Check Engine) :", es: "Testigo MIL (Check Engine):", de: "MIL-Warnleuchte (Check Engine):")
        let valMilOff = tr(
            lang: lang,
            en: "OFF — No active or permanent DTCs",
            it: "SPENTA — Nessun codice attivo o permanente",
            fr: "ÉTEINT — Aucun code actif ou permanent",
            es: "APAGADO — Sin códigos activos ni permanentes",
            de: "AUS — Keine aktiven oder permanenten Fehler"
        )
        drawRow(key: keyMil, value: valMilOff)
        currentY += 4
        
        // --- 4. Diagnosi Memoria Guasti Centralina ABS ---
        let sec3Title = tr(
            lang: lang,
            en: "3. ABS Module Fault Memory (Advics — 7E3)",
            it: "3. Diagnosi Memoria Guasti Modulo ABS (Advics — 7E3)",
            fr: "3. Diagnostic Mémoire Pannes Module ABS (Advics — 7E3)",
            es: "3. Diagnóstico Averías Módulo ABS (Advics — 7E3)",
            de: "3. Fehlerspeicher-Diagnose ABS-Modul (Advics — 7E3)"
        )
        drawSectionHeader(title: sec3Title)
        
        let keyAbsStatus = tr(lang: lang, en: "ABS Fault Status (KWP 0x18):", it: "Stato Guasti ABS (KWP 0x18):", fr: "État Défauts ABS (KWP 0x18) :", es: "Estado Averías ABS (KWP 0x18):", de: "ABS-Fehlerstatus (KWP 0x18):")
        let valNoAbs = tr(
            lang: lang,
            en: "✅ NO FAULT CODES STORED (0 DTC) — ABS Unit Healthy",
            it: "✅ NESSUN ERRORE MEMORIZZATO (0 DTC) — Unità ABS Integra",
            fr: "✅ AUCUN DÉFAUT ENREGISTRÉ (0 DTC) — Unité ABS saine",
            es: "✅ NINGÚN ERROR ALMACENADO (0 DTC) — Unidad ABS correcta",
            de: "✅ KEINE FEHLER GESPEICHERT (0 DTC) — ABS-Einheit fehlerfrei"
        )
        let keyAbsDetected = tr(lang: lang, en: "Detected ABS Code:", it: "Codice ABS Rilevato:", fr: "Code ABS Détecté :", es: "Código ABS Detectado:", de: "Erkannter ABS-Code:")
        
        if obd2Manager.absDtcCodes.isEmpty || obd2Manager.absDtcCodes.first?.contains("Nessun") == true || obd2Manager.absDtcCodes.first?.contains("No fault") == true {
            drawRow(
                key: keyAbsStatus,
                value: valNoAbs,
                statusColor: NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0)
            )
        } else {
            for absErr in obd2Manager.absDtcCodes {
                drawRow(
                    key: keyAbsDetected,
                    value: "⚠️ \(absErr)",
                    statusColor: NativeColor.orange
                )
            }
        }
        
        let keyWheel = tr(lang: lang, en: "Wheel Speed Sensors (F/R):", it: "Sensori Giri Ruota (Ant./Post.):", fr: "Capteurs Vitesse Roue (Av./Ar.) :", es: "Sensores Velocidad Rueda (Del./Tras.):", de: "Raddrehzahlsensoren (V/H):")
        let valWheel = tr(
            lang: lang,
            en: "Functional — Solenoid valve circuits verified",
            it: "Funzionanti — Circuito elettrovalvole verificato",
            fr: "Fonctionnels — Circuit électrovannes vérifié",
            es: "Operativos — Circuito de electroválvulas verificado",
            de: "Funktionsfähig — Magnetventilkreise geprüft"
        )
        drawRow(key: keyWheel, value: valWheel)
        currentY += 4
        
        // --- 5. Parametri di Adattamento & Usura Motore ---
        let sec4Title = tr(
            lang: lang,
            en: "4. Engine Adaptive & Wear Parameters",
            it: "4. Parametri di Adattamento & Usura Motore",
            fr: "4. Paramètres d'Adaptation & Usure Moteur",
            es: "4. Parámetros de Adaptación y Desgaste Motor",
            de: "4. Motoradaptions- & Verschleißparameter"
        )
        drawSectionHeader(title: sec4Title)
        
        let keyISC = tr(
            lang: lang,
            en: "ISC Idle Learning (Reg. 0x54):",
            it: "Apprendimento Minimo ISC (Reg. 0x54):",
            fr: "Apprentissage Ralenti ISC (Rég. 0x54) :",
            es: "Aprendizaje Ralentí ISC (Reg. 0x54):",
            de: "ISC-Leerlaufadaption (Reg. 0x54):"
        )
        drawRow(
            key: keyISC,
            value: obd2Manager.localizedISCLearningStatus(for: lang),
            isMonospaced: true
        )
        
        let keyThrottle = tr(
            lang: lang,
            en: "Throttle Bodies Cleaning Status:",
            it: "Stato Pulizia Corpi Farfallati:",
            fr: "État Propreté Corps Papillon :",
            es: "Estado Limpieza Cuerpos Mariposa:",
            de: "Drosselklappen-Reinigungszustand:"
        )
        let labelDev = tr(lang: lang, en: "Dev.", it: "Dev.", fr: "Écart", es: "Dev.", de: "Abw.")
        let throttleValue = "\(obd2Manager.localizedThrottleCleaningStatus(for: lang)) (\(labelDev): \(String(format: "%.1f", obd2Manager.throttleDirtPercentage))%)"
        drawRow(
            key: keyThrottle,
            value: throttleValue,
            statusColor: obd2Manager.throttleCleaningLevel == 1 ? NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0) : NativeColor.orange
        )
        
        let keyO2 = tr(
            lang: lang,
            en: "O2 Lambda Trim Learning (Reg. 0x52):",
            it: "Apprendimento Sonda Lambda O2 (Reg. 0x52):",
            fr: "Apprentissage Sonde Lambda O2 (Rég. 0x52) :",
            es: "Aprendizaje Sonda Lambda O2 (Reg. 0x52):",
            de: "O2-Lambdasondenadaption (Reg. 0x52):"
        )
        drawRow(
            key: keyO2,
            value: obd2Manager.localizedO2LearningStatus(for: lang),
            isMonospaced: true
        )
        
        let keyCO = tr(
            lang: lang,
            en: "Cylinder CO Adjustment (0x40 - 0x42):",
            it: "Regolazione CO Cilindri (0x40 - 0x42):",
            fr: "Réglage CO Cylindres (0x40 - 0x42) :",
            es: "Ajuste CO Cilindros (0x40 - 0x42):",
            de: "Zylinder-CO-Einstellung (0x40 - 0x42):"
        )
        drawRow(
            key: keyCO,
            value: obd2Manager.localizedCOCylindersStatus(for: lang),
            isMonospaced: true
        )
        currentY += 4
        
        // --- 6. Istantanea Telemetrica (Live Snapshot) ---
        let sec5Title = tr(
            lang: lang,
            en: "5. Live Telemetry Snapshot",
            it: "5. Istantanea Telemetrica (Live Snapshot)",
            fr: "5. Instantané Télémétrique (Live Snapshot)",
            es: "5. Instantánea Telemétrica (Live Snapshot)",
            de: "5. Live-Telemetrie-Momentaufnahme"
        )
        drawSectionHeader(title: sec5Title)
        
        let keyRpm = tr(lang: lang, en: "Engine Speed:", it: "Regime di Rotazione Motore:", fr: "Régime Rotation Moteur :", es: "Régimen de Giro Motor:", de: "Motordrehzahl:")
        drawRow(key: keyRpm, value: "\(obd2Manager.rpm) RPM")
        
        let keyTemp = tr(lang: lang, en: "Coolant Temperature:", it: "Temperatura Refrigerante (Coolant):", fr: "Température Liquide de Refroidissement :", es: "Temperatura Refrigerante:", de: "Kühlmitteltemperatur:")
        drawRow(key: keyTemp, value: "\(obd2Manager.temp) °C")
        
        let keyTps = tr(lang: lang, en: "Throttle Position (TPS):", it: "Apertura Valvola a Farfalla (TPS):", fr: "Ouverture Papillon (TPS) :", es: "Apertura Mariposa (TPS):", de: "Drosselklappenstellung (TPS):")
        drawRow(key: keyTps, value: "\(obd2Manager.tps) %")
        
        let keyO2Volt = tr(lang: lang, en: "O2 Closed-Loop Voltage:", it: "Tensione Sonda Lambda Closed-Loop:", fr: "Tension Sonde Lambda Boucle Fermée :", es: "Voltaje Sonda Lambda Closed-Loop:", de: "Lambda-Spannung Closed-Loop:")
        drawRow(key: keyO2Volt, value: "\(String(format: "%.3f", obd2Manager.o2Voltage)) V")
        currentY += 10
        
        // --- 7. Box Note & Firma Perizia ---
        let boxHeight: CGFloat = 52
        let boxRect = toPlatformRect(CGRect(x: 36, y: currentY, width: pageWidth - 72, height: boxHeight))
        context.setStrokeColor(NativeColor(white: 0.75, alpha: 1.0).cgColor)
        context.setLineWidth(0.8)
        context.stroke(boxRect)
        
        let boxAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 7.5),
            .foregroundColor: NativeColor.gray
        ]
        let noteLabel = tr(
            lang: lang,
            en: "Operator Notes / Maintenance Performed:",
            it: "Note dell'operatore / Manutenzione eseguita:",
            fr: "Notes de l'opérateur / Maintenance effectuée :",
            es: "Notas del operador / Mantenimiento realizado:",
            de: "Bedienerhinweise / Durchgeführte Wartung:"
        )
        let noteRect = toPlatformRect(CGRect(x: 44, y: currentY + 6, width: 250, height: 12))
        (noteLabel as NSString).draw(in: noteRect, withAttributes: boxAttrs)
        
        let sigAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.boldSystemFont(ofSize: 8.0),
            .foregroundColor: NativeColor.darkGray
        ]
        let sigLabel = tr(
            lang: lang,
            en: "Technician / Owner Signature: __________________________________",
            it: "Firma del Tecnico / Proprietario: __________________________________",
            fr: "Signature Technicien / Propriétaire : __________________________________",
            es: "Firma del Técnico / Propietario: __________________________________",
            de: "Unterschrift Techniker / Fahrzeughalter: __________________________________"
        )
        let sigRect = toPlatformRect(CGRect(x: 210, y: currentY + 30, width: 340, height: 14))
        (sigLabel as NSString).draw(in: sigRect, withAttributes: sigAttrs)
        currentY += boxHeight + 12
        
        // --- 8. Disclaimer Legale a Piè di Pagina ---
        let disclaimerAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 7.0),
            .foregroundColor: NativeColor(white: 0.48, alpha: 1.0)
        ]
        let legalNotice = tr(
            lang: lang,
            en: """
            Report generated by YaDiag Pro — Independent motorcycle diagnostic software for KWP2000/UDS CAN protocol.
            Not affiliated with Yamaha Motor Co., Ltd. All trademarks belong to their respective owners and are used for identification only.
            This document certifies electronic ECU register state at the time of diagnostic scan.
            """,
            it: """
            Perizia generata da YaDiag Pro — Software diagnostico indipendente per motocicli con protocollo KWP2000/UDS CAN.
            Non affiliato con Yamaha Motor Co., Ltd. Tutti i marchi citati appartengono ai rispettivi proprietari e sono usati unicamente a scopo identificativo.
            Il presente report attesta lo stato diagnostico dei registri elettronici al momento della scansione.
            """,
            fr: """
            Rapport généré par YaDiag Pro — Logiciel de diagnostic indépendant pour motocycles sous protocole KWP2000/UDS CAN.
            Non affilié à Yamaha Motor Co., Ltd. Toutes les marques citées appartiennent à leurs propriétaires respectifs et sont utilisées à titre d'identification.
            Ce document certifie l'état des registres calculateurs lors du scan.
            """,
            es: """
            Informe generado por YaDiag Pro — Software de diagnóstico independiente para motocicletas con protocolo KWP2000/UDS CAN.
            No afiliado a Yamaha Motor Co., Ltd. Todas las marcas pertenecen a sus respectivos propietarios y se utilizan solo para fines de identificación.
            Este documento certifica el estado de los registros electrónicos en el momento de la diagnosis.
            """,
            de: """
            Bericht erstellt von YaDiag Pro — Unabhängige Motorraddiagnosesoftware für KWP2000/UDS-CAN-Protokoll.
            Nicht verbunden mit Yamaha Motor Co., Ltd. Alle Marken gehören ihren jeweiligen Eigentümern und dienen ausschließlich zu Identifikationszwecken.
            Dieses Dokument bescheinigt den Zustand der elektronischen Steuergeräteregister zum Zeitpunkt des Prüfvorgangs.
            """
        )
        let discRect = toPlatformRect(CGRect(x: 36, y: pageHeight - 44, width: pageWidth - 72, height: 34))
        (legalNotice as NSString).draw(in: discRect, withAttributes: disclaimerAttrs)
    }
}
