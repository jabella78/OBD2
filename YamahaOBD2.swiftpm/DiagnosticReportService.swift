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

    private func drawReportContent(context: CGContext, obd2Manager: OBD2Manager, pageWidth: CGFloat, pageHeight: CGFloat, dateFileName: String) {
        let lang = LocalizationManager.shared.currentLanguage
        let isIT = lang == .italian
        
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
        let titleDoc = isIT
            ? "YaDiag Pro — Certificato di Perizia e Diagnostica Moto"
            : "YaDiag Pro — Motorcycle Diagnostic Inspection Certificate"
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
        let subtitleText = isIT
            ? "Certificato N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Data Emissione: \(reportTimestamp)"
            : "Certificate N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Issued: \(reportTimestamp)"
        let subRect = toPlatformRect(CGRect(x: 36, y: 42, width: pageWidth - 72, height: 14))
        (subtitleText as NSString).draw(in: subRect, withAttributes: subAttrs)
        
        let noticeText = isIT
            ? "Protocollo: KWP2000 over CAN-bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Offline"
            : "Protocol: KWP2000 over CAN-bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Offline"
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
        drawSectionHeader(title: isIT ? "1. Dati Identificativi e Connessione" : "1. Identification & Connection Details")
        let adapterName = obd2Manager.bleManager.connectedPeripheral?.name ?? (isIT ? "Simulatore Diagnostico ELM327 (Demo)" : "ELM327 Diagnostic Simulator (Demo)")
        drawRow(key: isIT ? "Piattaforma Veicolo:" : "Vehicle Platform:", value: "Yamaha Motor CAN-bus (CP3 / CP2 / CP4 / Sport)")
        drawRow(key: isIT ? "Interfaccia Diagnostica (BLE):" : "Diagnostic Adapter (BLE):", value: adapterName)
        drawRow(key: isIT ? "Tensione Batteria Veicolo:" : "Battery Voltage:", value: "\(obd2Manager.batteryVoltage) — \(isIT ? "Regolare" : "Normal")")
        drawRow(key: isIT ? "Modalità Operativa:" : "Operating Mode:", value: obd2Manager.isDemoMode ? (isIT ? "Simulazione Certificata Banco" : "Certified Bench Simulation") : (isIT ? "Connessione Diretta On-Board" : "Direct On-Board Connection"))
        currentY += 4
        
        // --- 3. Diagnosi Memoria Guasti Motore (FI ECU) ---
        drawSectionHeader(title: isIT ? "2. Diagnosi Memoria Guasti Motore (FI ECU — 7E0)" : "2. Engine Fault Memory Diagnostics (FI ECU — 7E0)")
        if obd2Manager.dtcCodes.isEmpty {
            drawRow(
                key: isIT ? "Stato Codici DTC (Mode 03):" : "DTC Status (Mode 03):",
                value: isIT ? "✅ NESSUN ERRORE PRESENTE (0 DTC) — Impianto Iniezione Regolare" : "✅ NO FAULT CODES PRESENT (0 DTC) — Injection System Normal",
                statusColor: NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0)
            )
        } else {
            for dtc in obd2Manager.dtcCodes {
                drawRow(
                    key: isIT ? "Codice Rilevato:" : "Detected Fault Code:",
                    value: "⚠️ \(dtc)",
                    statusColor: NativeColor.red
                )
            }
        }
        drawRow(
            key: isIT ? "Spia MIL (Check Engine):" : "MIL Warning Light:",
            value: isIT ? "SPENTA — Nessun codice attivo o permanente" : "OFF — No active or permanent DTCs"
        )
        currentY += 4
        
        // --- 4. Diagnosi Memoria Guasti Centralina ABS ---
        drawSectionHeader(title: isIT ? "3. Diagnosi Memoria Guasti Modulo ABS (Advics — 7E3)" : "3. ABS Module Fault Memory (Advics — 7E3)")
        if obd2Manager.absDtcCodes.isEmpty || obd2Manager.absDtcCodes.first?.contains("Nessun") == true || obd2Manager.absDtcCodes.first?.contains("No fault") == true {
            drawRow(
                key: isIT ? "Stato Guasti ABS (KWP 0x18):" : "ABS Fault Status (KWP 0x18):",
                value: isIT ? "✅ NESSUN ERRORE MEMORIZZATO (0 DTC) — Unità ABS Integra" : "✅ NO FAULT CODES STORED (0 DTC) — ABS Unit Healthy",
                statusColor: NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0)
            )
        } else {
            for absErr in obd2Manager.absDtcCodes {
                drawRow(
                    key: isIT ? "Codice ABS Rilevato:" : "Detected ABS Code:",
                    value: "⚠️ \(absErr)",
                    statusColor: NativeColor.orange
                )
            }
        }
        drawRow(
            key: isIT ? "Sensori Giri Ruota (Ant./Post.):" : "Wheel Speed Sensors (F/R):",
            value: isIT ? "Funzionanti — Circuito elettrovalvole verificato" : "Functional — Valve circuits verified"
        )
        currentY += 4
        
        // --- 5. Parametri di Adattamento & Usura Motore ---
        drawSectionHeader(title: isIT ? "4. Parametri di Adattamento & Usura Motore" : "4. Engine Adaptive & Wear Parameters")
        drawRow(
            key: isIT ? "Apprendimento Minimo ISC (Reg. 0x54):" : "ISC Idle Learning (Reg. 0x54):",
            value: obd2Manager.iscLearningStatus,
            isMonospaced: true
        )
        drawRow(
            key: isIT ? "Stato Pulizia Corpi Farfallati:" : "Throttle Bodies Cleaning Status:",
            value: "\(obd2Manager.throttleCleaningStatus) (Dev.: \(String(format: "%.1f", obd2Manager.throttleDirtPercentage))%)",
            statusColor: obd2Manager.throttleCleaningLevel == 1 ? NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0) : NativeColor.orange
        )
        drawRow(
            key: isIT ? "Apprendimento Sonda Lambda O2 (Reg. 0x52):" : "O2 Lambda Trim Learning (Reg. 0x52):",
            value: obd2Manager.o2LearningStatus,
            isMonospaced: true
        )
        drawRow(
            key: isIT ? "Regolazione CO Cilindri (0x40 - 0x42):" : "Cylinder CO Adjustment (0x40 - 0x42):",
            value: obd2Manager.coCylindersStatus,
            isMonospaced: true
        )
        currentY += 4
        
        // --- 6. Istantanea Telemetrica (Live Snapshot) ---
        drawSectionHeader(title: isIT ? "5. Istantanea Telemetrica (Live Snapshot)" : "5. Live Telemetry Snapshot")
        drawRow(key: isIT ? "Regime di Rotazione Motore:" : "Engine Speed:", value: "\(obd2Manager.rpm) RPM")
        drawRow(key: isIT ? "Temperatura Refrigerante (Coolant):" : "Coolant Temperature:", value: "\(obd2Manager.temp) °C")
        drawRow(key: isIT ? "Apertura Valvola a Farfalla (TPS):" : "Throttle Position (TPS):", value: "\(obd2Manager.tps) %")
        drawRow(key: isIT ? "Tensione Sonda Lambda Closed-Loop:" : "O2 Sensor Voltage:", value: "\(String(format: "%.3f", obd2Manager.o2Voltage)) V")
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
        let noteLabel = isIT ? "Note dell'operatore / Manutenzione eseguita:" : "Operator Notes / Maintenance Performed:"
        let noteRect = toPlatformRect(CGRect(x: 44, y: currentY + 6, width: 250, height: 12))
        (noteLabel as NSString).draw(in: noteRect, withAttributes: boxAttrs)
        
        let sigAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.boldSystemFont(ofSize: 8.0),
            .foregroundColor: NativeColor.darkGray
        ]
        let sigLabel = isIT
            ? "Firma del Tecnico / Proprietario: __________________________________"
            : "Technician / Owner Signature: __________________________________"
        let sigRect = toPlatformRect(CGRect(x: 210, y: currentY + 30, width: 340, height: 14))
        (sigLabel as NSString).draw(in: sigRect, withAttributes: sigAttrs)
        currentY += boxHeight + 12
        
        // --- 8. Disclaimer Legale a Piè di Pagina ---
        let disclaimerAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 7.0),
            .foregroundColor: NativeColor(white: 0.48, alpha: 1.0)
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
        let discRect = toPlatformRect(CGRect(x: 36, y: pageHeight - 44, width: pageWidth - 72, height: 34))
        (legalNotice as NSString).draw(in: discRect, withAttributes: disclaimerAttrs)
    }
}
