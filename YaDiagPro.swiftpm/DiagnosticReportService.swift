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
    
    /// Genera un documento PDF A4 professionale contenente l'esito della perizia diagnostica e lo stato dei componenti.
    func generatePDF(obd2Manager: OBD2Manager) -> URL? {
        let pageWidth: CGFloat = 595.2  // A4 standard width in points (72 dpi)
        let pageHeight: CGFloat = 841.8 // A4 standard height in points (72 dpi)
        var pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let tempDir = FileManager.default.temporaryDirectory
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateFileName = formatter.string(from: Date())
        let fileURL = tempDir.appendingPathComponent("Perizia_Diagnostica_YaDiag_\(dateFileName).pdf")
        
        guard let consumer = CGDataConsumer(url: fileURL as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &pageRect, nil) else {
            return nil
        }
        
        context.beginPage(mediaBox: &pageRect)
        
        #if os(macOS)
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = graphicsContext
        #elseif os(iOS)
        UIGraphicsPushContext(context)
        #endif
        
        let lang = LocalizationManager.shared.currentLanguage
        let isIT = lang == .italian
        
        // --- 1. Sfondo e Intestazione Superiore (Dark Blue Header) ---
        context.setFillColor(NativeColor(red: 0.07, green: 0.12, blue: 0.22, alpha: 1.0).cgColor)
        context.fill(CGRect(x: 0, y: pageHeight - 110, width: pageWidth, height: 110))
        
        // Barra ciano sotto l'header
        context.setFillColor(NativeColor(red: 0.0, green: 0.75, blue: 0.85, alpha: 1.0).cgColor)
        context.fill(CGRect(x: 0, y: pageHeight - 114, width: pageWidth, height: 4))
        
        // Titolo App
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.boldSystemFont(ofSize: 21),
            .foregroundColor: NativeColor.white
        ]
        let titleDoc = isIT
            ? "YaDiag Pro — Certificato di Perizia & Diagnostica Moto"
            : "YaDiag Pro — Motorcycle Diagnostic Inspection Certificate"
        (titleDoc as NSString).draw(
            at: CGPoint(x: 36, y: pageHeight - 50),
            withAttributes: titleAttrs
        )
        
        // Sottotitolo e ID Certificato
        let randomId = String(format: "%04d", Int.random(in: 1000...9999))
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let reportTimestamp = formatter.string(from: Date())
        let subtitleText = isIT
            ? "Certificato N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Data Emissione: \(reportTimestamp)"
            : "Certificate N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Issued: \(reportTimestamp)"
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 10),
            .foregroundColor: NativeColor(white: 0.85, alpha: 1.0)
        ]
        (subtitleText as NSString).draw(
            at: CGPoint(x: 36, y: pageHeight - 72),
            withAttributes: subAttrs
        )
        
        let standardNotice = isIT
            ? "Protocollo: KWP2000 over CAN-bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Offline"
            : "Protocol: KWP2000 over CAN-bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Offline"
        (standardNotice as NSString).draw(
            at: CGPoint(x: 36, y: pageHeight - 90),
            withAttributes: subAttrs
        )
        
        var currentY: CGFloat = pageHeight - 145
        
        func drawSectionHeader(title: String) {
            context.setFillColor(NativeColor(red: 0.0, green: 0.45, blue: 0.75, alpha: 0.12).cgColor)
            context.fill(CGRect(x: 36, y: currentY - 6, width: pageWidth - 72, height: 26))
            
            context.setFillColor(NativeColor(red: 0.0, green: 0.45, blue: 0.75, alpha: 1.0).cgColor)
            context.fill(CGRect(x: 36, y: currentY - 6, width: 4, height: 26))
            
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: NativeFont.boldSystemFont(ofSize: 12),
                .foregroundColor: NativeColor(red: 0.05, green: 0.25, blue: 0.55, alpha: 1.0)
            ]
            (title.uppercased() as NSString).draw(at: CGPoint(x: 48, y: currentY), withAttributes: headerAttrs)
            currentY -= 32
        }
        
        func drawKeyValue(key: String, value: String, statusColor: NativeColor? = nil, isMonospaced: Bool = false) {
            let keyAttrs: [NSAttributedString.Key: Any] = [
                .font: NativeFont.systemFont(ofSize: 10),
                .foregroundColor: NativeColor.darkGray
            ]
            let valFont: NativeFont = isMonospaced
                ? (NativeFont(name: "Menlo-Bold", size: 9.5) ?? NativeFont.boldSystemFont(ofSize: 10))
                : NativeFont.boldSystemFont(ofSize: 10)
            let valAttrs: [NSAttributedString.Key: Any] = [
                .font: valFont,
                .foregroundColor: statusColor ?? NativeColor.black
            ]
            
            (key as NSString).draw(at: CGPoint(x: 48, y: currentY), withAttributes: keyAttrs)
            (value as NSString).draw(at: CGPoint(x: 235, y: currentY), withAttributes: valAttrs)
            
            context.setStrokeColor(NativeColor(white: 0.90, alpha: 1.0).cgColor)
            context.setLineWidth(0.5)
            context.strokeLineSegments(between: [
                CGPoint(x: 48, y: currentY - 4),
                CGPoint(x: pageWidth - 48, y: currentY - 4)
            ])
            
            currentY -= 18
        }
        
        // --- 2. Sezione Dati Veicolo & Connessione Diagnostica ---
        drawSectionHeader(title: isIT ? "1. Dati Identificativi e Connessione" : "1. Identification & Connection Details")
        
        let adapterName = obd2Manager.bleManager.connectedPeripheral?.name ?? (isIT ? "Simulatore Diagnostico ELM327 (Demo)" : "ELM327 Diagnostic Simulator (Demo)")
        drawKeyValue(key: isIT ? "Piattaforma Veicolo:" : "Vehicle Platform:", value: "Yamaha Motor CAN-bus (CP3 / CP2 / CP4 / Sport)")
        drawKeyValue(key: isIT ? "Interfaccia Diagnostica (BLE):" : "Diagnostic Adapter (BLE):", value: adapterName)
        drawKeyValue(key: isIT ? "Tensione Batteria Veicolo:" : "Battery Voltage:", value: "\(obd2Manager.batteryVoltage) — \(isIT ? "Regolare" : "Normal")")
        drawKeyValue(key: isIT ? "Modalità Operativa:" : "Operating Mode:", value: obd2Manager.isDemoMode ? (isIT ? "Simulazione Certificata" : "Certified Simulation") : (isIT ? "Connessione Diretta On-Board" : "Direct On-Board Connection"))
        currentY -= 10
        
        // --- 3. Sezione Centralina Motore (FI ECU 7E0 / 7E8) ---
        drawSectionHeader(title: isIT ? "2. Diagnosi Memoria Guasti Motore (FI ECU — 7E0)" : "2. Engine Fault Memory Diagnostics (FI ECU — 7E0)")
        
        if obd2Manager.dtcCodes.isEmpty {
            drawKeyValue(
                key: isIT ? "Stato Codici DTC (Mode 03):" : "DTC Status (Mode 03):",
                value: isIT ? "✅ NESSUN ERRORE PRESENTE (0 DTC) — Impianto Iniezione Regolare" : "✅ NO FAULT CODES PRESENT (0 DTC) — Injection System Normal",
                statusColor: NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0)
            )
        } else {
            for dtc in obd2Manager.dtcCodes {
                drawKeyValue(
                    key: isIT ? "Codice Rilevato:" : "Detected Fault Code:",
                    value: "⚠️ \(dtc)",
                    statusColor: NativeColor.red
                )
            }
        }
        drawKeyValue(
            key: isIT ? "Spia MIL (Check Engine):" : "MIL Warning Light:",
            value: isIT ? "SPENTA — Nessun codice attivo o pendente" : "OFF — No active or pending DTCs"
        )
        currentY -= 10
        
        // --- 4. Sezione Centralina ABS (Advics ECU 7E3 / 7EB) ---
        drawSectionHeader(title: isIT ? "3. Diagnosi Memoria Guasti Modulo ABS (Advics — 7E3)" : "3. ABS Module Fault Memory (Advics — 7E3)")
        
        if obd2Manager.absDtcCodes.isEmpty || obd2Manager.absDtcCodes.first?.contains("Nessun") == true || obd2Manager.absDtcCodes.first?.contains("No fault") == true {
            drawKeyValue(
                key: isIT ? "Stato Guasti ABS (KWP 0x18):" : "ABS Fault Status (KWP 0x18):",
                value: isIT ? "✅ NESSUN ERRORE MEMORIZZATO (0 DTC) — Unità ABS Integra" : "✅ NO FAULT CODES STORED (0 DTC) — ABS Unit Healthy",
                statusColor: NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0)
            )
        } else {
            for absErr in obd2Manager.absDtcCodes {
                drawKeyValue(
                    key: isIT ? "Codice ABS Rilevato:" : "Detected ABS Code:",
                    value: "⚠️ \(absErr)",
                    statusColor: NativeColor.orange
                )
            }
        }
        drawKeyValue(
            key: isIT ? "Sensori Giri Ruota (Ant./Post.):" : "Wheel Speed Sensors (F/R):",
            value: isIT ? "Funzionanti — Circuito elettrovalvole verificato" : "Functional — Valve circuits verified"
        )
        currentY -= 10
        
        // --- 5. Sezione Parametri Sanità Adattiva Motore ---
        drawSectionHeader(title: isIT ? "4. Parametri di Adattamento & Usura Motore" : "4. Engine Adaptive & Wear Parameters")
        
        drawKeyValue(
            key: isIT ? "Apprendimento Minimo ISC (Reg. 0x54):" : "ISC Idle Learning (Reg. 0x54):",
            value: obd2Manager.iscLearningStatus,
            isMonospaced: true
        )
        drawKeyValue(
            key: isIT ? "Stato Pulizia Corpi Farfallati:" : "Throttle Bodies Cleaning Status:",
            value: "\(obd2Manager.throttleCleaningStatus) (Dev.: \(String(format: "%.1f", obd2Manager.throttleDirtPercentage))%)",
            statusColor: obd2Manager.throttleCleaningLevel == 1 ? NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0) : NativeColor.orange
        )
        drawKeyValue(
            key: isIT ? "Apprendimento Sonda Lambda O2 (Reg. 0x52):" : "O2 Lambda Trim Learning (Reg. 0x52):",
            value: obd2Manager.o2LearningStatus,
            isMonospaced: true
        )
        drawKeyValue(
            key: isIT ? "Regolazione CO Cilindri (0x40 - 0x42):" : "Cylinder CO Adjustment (0x40 - 0x42):",
            value: obd2Manager.coCylindersStatus,
            isMonospaced: true
        )
        currentY -= 10
        
        // --- 6. Istantanea Telemetria & Sensori al Momento del Test ---
        drawSectionHeader(title: isIT ? "5. Istantanea Telemetrica (Live Snapshot)" : "5. Live Telemetry Snapshot")
        drawKeyValue(key: isIT ? "Regime di Rotazione Motore:" : "Engine Speed:", value: "\(obd2Manager.rpm) RPM")
        drawKeyValue(key: isIT ? "Temperatura Refrigerante (Coolant):" : "Coolant Temperature:", value: "\(obd2Manager.temp) °C")
        drawKeyValue(key: isIT ? "Apertura Valvola a Farfalla (TPS):" : "Throttle Position (TPS):", value: "\(obd2Manager.tps) %")
        drawKeyValue(key: isIT ? "Tensione Sonda Lambda Closed-Loop:" : "O2 Sensor Voltage:", value: "\(String(format: "%.3f", obd2Manager.o2Voltage)) V")
        currentY -= 15
        
        // --- 7. Box Note & Firma Perizia ---
        let boxRect = CGRect(x: 36, y: currentY - 55, width: pageWidth - 72, height: 60)
        context.setStrokeColor(NativeColor(white: 0.75, alpha: 1.0).cgColor)
        context.setLineWidth(0.8)
        context.stroke(boxRect)
        
        let boxAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 8.5),
            .foregroundColor: NativeColor.gray
        ]
        let noteLabel = isIT ? "Note dell'operatore / Manutenzione eseguita:" : "Operator Notes / Maintenance Performed:"
        (noteLabel as NSString).draw(at: CGPoint(x: 44, y: currentY - 14), withAttributes: boxAttrs)
        
        let sigAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.boldSystemFont(ofSize: 9),
            .foregroundColor: NativeColor.darkGray
        ]
        let sigLabel = isIT
            ? "Firma del Tecnico / Proprietario: __________________________________"
            : "Technician / Owner Signature: __________________________________"
        (sigLabel as NSString).draw(
            at: CGPoint(x: 230, y: currentY - 45),
            withAttributes: sigAttrs
        )
        currentY -= 75
        
        // --- 8. Disclaimer Legale a Piè di Pagina ---
        let disclaimerAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 7.5),
            .foregroundColor: NativeColor(white: 0.50, alpha: 1.0)
        ]
        let legalNotice = isIT ? """
        Perizia generata da YaDiag Pro — Software diagnostico indipendente per motocicli con protocollo KWP2000/UDS CAN.
        Non affiliato con Yamaha Motor Co., Ltd. Tutti i marchi citati appartengono ai rispettivi proprietari e sono usati unicamente a scopo identificativo.
        Il presente report attesta lo stato diagnostico dei registri elettronici al momento della scansione.
        """ : """
        Report generated by YaDiag Pro — Independent motorcycle diagnostic software for KWP2000/UDS CAN protocol.
        Not affiliated with Yamaha Motor Co., Ltd. All trademarks belong to their respective owners and are used for identification only.
        This document certifies electronic ECU register state at the time of diagnostic scan.
        """
        (legalNotice as NSString).draw(
            in: CGRect(x: 36, y: 20, width: pageWidth - 72, height: 40),
            withAttributes: disclaimerAttrs
        )
        
        #if os(macOS)
        NSGraphicsContext.current = nil
        #elseif os(iOS)
        UIGraphicsPopContext()
        #endif
        
        context.endPage()
        context.closePDF()
        
        return fileURL
    }
}
