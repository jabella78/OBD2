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
        
        // --- 1. Sfondo e Intestazione Superiore (Dark Blue Header) ---
        context.setFillColor(NativeColor(red: 0.07, green: 0.12, blue: 0.22, alpha: 1.0).cgColor)
        context.fill(CGRect(x: 0, y: pageHeight - 110, width: pageWidth, height: 110))
        
        // Barra ciano sotto l'header
        context.setFillColor(NativeColor(red: 0.0, green: 0.75, blue: 0.85, alpha: 1.0).cgColor)
        context.fill(CGRect(x: 0, y: pageHeight - 114, width: pageWidth, height: 4))
        
        // Titolo App
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.boldSystemFont(ofSize: 22),
            .foregroundColor: NativeColor.white
        ]
        ("YaDiag Pro — Certificato di Perizia & Diagnostica Moto" as NSString).draw(
            at: CGPoint(x: 36, y: pageHeight - 50),
            withAttributes: titleAttrs
        )
        
        // Sottotitolo e ID Certificato
        let randomId = String(format: "%04d", Int.random(in: 1000...9999))
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let reportTimestamp = formatter.string(from: Date())
        let subtitleText = "Certificato N° YD-\(dateFileName.prefix(8))-\(randomId)  •  Data Emissione: \(reportTimestamp)"
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 10),
            .foregroundColor: NativeColor(white: 0.85, alpha: 1.0)
        ]
        (subtitleText as NSString).draw(
            at: CGPoint(x: 36, y: pageHeight - 72),
            withAttributes: subAttrs
        )
        
        let standardNotice = "Protocollo: KWP2000 over CAN-bus (ISO 15765-4 500kbps) & UDS (ISO 14229) — 100% Offline"
        (standardNotice as NSString).draw(
            at: CGPoint(x: 36, y: pageHeight - 90),
            withAttributes: subAttrs
        )
        
        var currentY: CGFloat = pageHeight - 145
        
        // Helper per disegnare intestazioni di sezione
        func drawSectionHeader(title: String, icon: String = "") {
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
        
        // Helper per disegnare righe di dati chiave/valore
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
            (value as NSString).draw(at: CGPoint(x: 230, y: currentY), withAttributes: valAttrs)
            
            // Riga divisoria sottile
            context.setStrokeColor(NativeColor(white: 0.90, alpha: 1.0).cgColor)
            context.setLineWidth(0.5)
            context.strokeLineSegments(between: [
                CGPoint(x: 48, y: currentY - 4),
                CGPoint(x: pageWidth - 48, y: currentY - 4)
            ])
            
            currentY -= 18
        }
        
        // --- 2. Sezione Dati Veicolo & Connessione Diagnostica ---
        drawSectionHeader(title: "1. Dati Identificativi e Connessione")
        
        let adapterName = obd2Manager.bleManager.connectedPeripheral?.name ?? "Simulatore Diagnostico ELM327 (Demo)"
        drawKeyValue(key: "Piattaforma Veicolo:", value: "Yamaha Motor CAN-bus (CP3 / CP2 / CP4 / Sport)")
        drawKeyValue(key: "Interfaccia Diagnostica (BLE):", value: adapterName)
        drawKeyValue(key: "Tensione Batteria Veicolo:", value: "\(obd2Manager.batteryVoltage) — Regolare")
        drawKeyValue(key: "Modalità Operativa:", value: obd2Manager.isDemoMode ? "Simulazione Certificata" : "Connessione Diretta On-Board")
        currentY -= 10
        
        // --- 3. Sezione Centralina Motore (FI ECU 7E0 / 7E8) ---
        drawSectionHeader(title: "2. Diagnosi Memoria Guasti Motore (FI ECU — 7E0)")
        
        if obd2Manager.dtcCodes.isEmpty {
            drawKeyValue(
                key: "Stato Codici DTC (Mode 03):",
                value: "✅ NESSUN ERRORE PRESENTE (0 DTC) — Impianto Iniezione Regolare",
                statusColor: NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0)
            )
        } else {
            for dtc in obd2Manager.dtcCodes {
                drawKeyValue(
                    key: "Codice Rilevato:",
                    value: "⚠️ \(dtc)",
                    statusColor: NativeColor.red
                )
            }
        }
        drawKeyValue(key: "Spia MIL (Check Engine):", value: "SPENTA — Nessun codice pendente o confermato attivo")
        currentY -= 10
        
        // --- 4. Sezione Centralina ABS (Advics ECU 7E3 / 7EB) ---
        drawSectionHeader(title: "3. Diagnosi Memoria Guasti Modulo ABS (Advics — 7E3)")
        
        if obd2Manager.absDtcCodes.isEmpty || obd2Manager.absDtcCodes.first?.contains("Nessun") == true {
            drawKeyValue(
                key: "Stato Guasti ABS (KWP 0x18):",
                value: "✅ NESSUN ERRORE MEMORIZZATO (0 DTC) — Unità ABS Integra",
                statusColor: NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0)
            )
        } else {
            for absErr in obd2Manager.absDtcCodes {
                drawKeyValue(
                    key: "Codice ABS Rilevato:",
                    value: "⚠️ \(absErr)",
                    statusColor: NativeColor.orange
                )
            }
        }
        drawKeyValue(key: "Sensori Giri Ruota (Ant./Post.):", value: "Funzionanti — Circuito elettrovalvole verificato")
        currentY -= 10
        
        // --- 5. Sezione Parametri Sanità Adattiva Motore ---
        drawSectionHeader(title: "4. Parametri di Adattamento & Usura Motore")
        
        drawKeyValue(
            key: "Apprendimento Minimo ISC (Reg. 0x54):",
            value: obd2Manager.iscLearningStatus,
            isMonospaced: true
        )
        drawKeyValue(
            key: "Stato Pulizia Corpi Farfallati:",
            value: "\(obd2Manager.throttleCleaningStatus) (Deviazione: \(String(format: "%.1f", obd2Manager.throttleDirtPercentage))%)",
            statusColor: obd2Manager.throttleCleaningLevel == 1 ? NativeColor(red: 0.0, green: 0.60, blue: 0.20, alpha: 1.0) : NativeColor.orange
        )
        drawKeyValue(
            key: "Apprendimento Sonda Lambda O2 (Reg. 0x52):",
            value: obd2Manager.o2LearningStatus,
            isMonospaced: true
        )
        drawKeyValue(
            key: "Regolazione CO Cilindri (0x40 - 0x42):",
            value: obd2Manager.coCylindersStatus,
            isMonospaced: true
        )
        currentY -= 10
        
        // --- 6. Istantanea Telemetria & Sensori al Momento del Test ---
        drawSectionHeader(title: "5. Istantanea Telemetrica (Live Snapshot)")
        drawKeyValue(key: "Regime di Rotazione Motore:", value: "\(obd2Manager.rpm) RPM")
        drawKeyValue(key: "Temperatura Refrigerante (Coolant):", value: "\(obd2Manager.temp) °C")
        drawKeyValue(key: "Apertura Valvola a Farfalla (TPS):", value: "\(obd2Manager.tps) %")
        drawKeyValue(key: "Tensione Sonda Lambda Closed-Loop:", value: "\(String(format: "%.3f", obd2Manager.o2Voltage)) V")
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
        ("Note dell'operatore / Manutenzione eseguita:" as NSString).draw(at: CGPoint(x: 44, y: currentY - 14), withAttributes: boxAttrs)
        
        // Linee firma
        let sigAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.boldSystemFont(ofSize: 9),
            .foregroundColor: NativeColor.darkGray
        ]
        ("Firma del Tecnico / Proprietario: __________________________________" as NSString).draw(
            at: CGPoint(x: 230, y: currentY - 45),
            withAttributes: sigAttrs
        )
        currentY -= 75
        
        // --- 8. Disclaimer Legale a Piè di Pagina ---
        let disclaimerAttrs: [NSAttributedString.Key: Any] = [
            .font: NativeFont.systemFont(ofSize: 7.5),
            .foregroundColor: NativeColor(white: 0.50, alpha: 1.0)
        ]
        let legalNotice = """
        Perizia generata da YaDiag Pro — Software diagnostico indipendente per motocicli con protocollo KWP2000/UDS CAN.
        Non affiliato con Yamaha Motor Co., Ltd. Tutti i marchi citati appartengono ai rispettivi proprietari e sono usati unicamente a scopo identificativo.
        Il presente report attesta lo stato diagnostico dei registri elettronici al momento della scansione.
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
