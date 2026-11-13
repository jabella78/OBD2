package com.jabella78.yadiag.core

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object DiagnosticReportService {

    fun generatePDFReport(
        context: Context,
        obdManager: OBD2Manager,
        bleManager: BLEManager,
        aiEvaluation: String,
        language: AppLanguage
    ): File? {
        val pageWidth = 595
        val pageHeight = 842
        val margin = 36f
        val contentWidth = pageWidth - (margin * 2)

        val dateFormat = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault())
        val dateStr = dateFormat.format(Date())

        val fileTimestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val outFile = File(context.cacheDir, "YaDiag_Report_$fileTimestamp.pdf")

        val pdfDocument = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, 1).create()
        val page = pdfDocument.startPage(pageInfo)
        val canvas = page.canvas

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        // 1. Header Banner (Dark Blue + Cyan Accent)
        paint.color = Color.rgb(13, 26, 46)
        canvas.drawRect(0f, 0f, pageWidth.toFloat(), 88f, paint)

        paint.color = Color.rgb(0, 179, 230)
        canvas.drawRect(0f, 88f, pageWidth.toFloat(), 92f, paint)

        // Draw Logo if available in assets
        try {
            context.assets.open("yadiag_logo.png").use { input ->
                val bmp = BitmapFactory.decodeStream(input)
                if (bmp != null) {
                    val dst = RectF(margin, 16f, margin + 56f, 16f + 56f)
                    canvas.drawBitmap(bmp, null, dst, paint)
                }
            }
        } catch (_: Exception) {
        }

        val titleX = margin + 68f
        drawText(
            canvas = canvas,
            text = "YaDiag — Yamaha OBD2 Diagnostics",
            x = titleX,
            y = 20f,
            width = contentWidth - 68f,
            textSize = 18f,
            color = Color.WHITE,
            bold = true
        )

        val subtitle = when (language) {
            AppLanguage.ITALIAN -> "CERTIFICATO DIAGNOSTICO E TELEMETRICO DEL VEICOLO"
            AppLanguage.ENGLISH -> "VEHICLE DIAGNOSTIC & TELEMETRY REPORT"
            AppLanguage.FRENCH -> "RAPPORT DE DIAGNOSTIC ET TÉLÉMÉTRIE DU VÉHICULE"
            AppLanguage.SPANISH -> "INFORME DE DIAGNÓSTICO Y TELEMETRÍA DEL VEHÍCULO"
            AppLanguage.GERMAN -> "FAHRZEUG-DIAGNOSE- & TELEMETRIEBERICHT"
        }
        drawText(
            canvas = canvas,
            text = subtitle,
            x = titleX,
            y = 44f,
            width = contentWidth - 68f,
            textSize = 10f,
            color = Color.rgb(102, 217, 255),
            bold = true
        )

        val adapterName = when {
            bleManager.isSimulationMode -> "Virtual Simulator"
            !bleManager.connectedPeripheralName.isNullOrEmpty() -> bleManager.connectedPeripheralName!!
            else -> "OBD2 CAN Adapter"
        }
        val metaLine = "Date: $dateStr   |   Adapter: $adapterName   |   Protocol: ISO 15765-4 CAN / KWP2000"
        drawText(
            canvas = canvas,
            text = metaLine,
            x = titleX,
            y = 62f,
            width = contentWidth - 68f,
            textSize = 8.5f,
            color = Color.argb(215, 255, 255, 255),
            bold = false
        )

        var yPos = 108f

        // 2. Section: Engine Telemetry Snapshot
        val sec1Title = when (language) {
            AppLanguage.ITALIAN -> "1. PARAMETRI TELEMETRICI MOTORE (MODE 01)"
            AppLanguage.ENGLISH -> "1. ENGINE TELEMETRY PARAMETERS (MODE 01)"
            AppLanguage.FRENCH -> "1. PARAMÈTRES TÉLÉMÉTRIQUES MOTEUR (MODE 01)"
            AppLanguage.SPANISH -> "1. PARÁMETROS TELEMÉTRICOS DEL MOTOR (MODE 01)"
            AppLanguage.GERMAN -> "1. MOTOR-TELEMETRIEPARAMETER (MODE 01)"
        }
        yPos = drawSectionHeader(canvas, sec1Title, margin, yPos, contentWidth)

        val afrStr = if (obdManager.o2SensorVoltage > 0) String.format(Locale.US, "%.1f:1", obdManager.estimatedAFR) else "N/A"
        val telemetryGrid = listOf(
            "RPM" to "${obdManager.rpm} rpm",
            "Speed" to "${obdManager.speed} km/h",
            "Coolant Temp" to "${obdManager.coolantTemp} °C",
            "Intake Air (IAT)" to "${obdManager.intakeTemp} °C",
            "Throttle (TPS)" to String.format(Locale.US, "%.1f %%", obdManager.throttlePos),
            "Engine Load" to "${obdManager.engineLoad} %",
            "MAP Pressure" to "${obdManager.intakePressure} kPa",
            "Battery Voltage" to String.format(Locale.US, "%.2f V", obdManager.batteryVoltageDouble),
            "Est. AFR / O2" to "$afrStr (${String.format(Locale.US, "%.2f", obdManager.o2SensorVoltage)}V)"
        )
        yPos = drawKeyValueGrid(canvas, telemetryGrid, margin, yPos, contentWidth, columns = 3)
        yPos += 12f

        // 3. Section: Yamaha KWP2000 & Throttle Body Health
        val sec2Title = when (language) {
            AppLanguage.ITALIAN -> "2. STATO CORPI FARFALLATI E PARAMETRI YAMAHA (KWP 0x21)"
            AppLanguage.ENGLISH -> "2. THROTTLE BODY HEALTH & YAMAHA PARAMETERS (KWP 0x21)"
            AppLanguage.FRENCH -> "2. ÉTAT CORPS DE PAPILLON & PARAMÈTRES YAMAHA (KWP 0x21)"
            AppLanguage.SPANISH -> "2. ESTADO CUERPOS DE ACELERACIÓN Y PARÁMETROS YAMAHA (KWP 0x21)"
            AppLanguage.GERMAN -> "2. DROSSELKLAPPENZUSTAND & YAMAHA-PARAMETER (KWP 0x21)"
        }
        yPos = drawSectionHeader(canvas, sec2Title, margin, yPos, contentWidth)

        val iscStr = obdManager.iscLearningValue?.let { String.format(Locale.US, "%.1f %%", it) } ?: "N/A"
        val dirtStr = obdManager.throttleDirtPercentage?.let { String.format(Locale.US, "%.0f %%", it) } ?: "N/A"
        val o2CompStr = obdManager.o2CompensationValue?.let { String.format(Locale.US, "%.1f %%", it) } ?: "N/A"
        val coStr = if (obdManager.coAdjustmentValues.isEmpty()) {
            "N/A"
        } else {
            obdManager.coAdjustmentValues.entries.sortedBy { it.key }.joinToString(" | ") { "C${it.key}: ${it.value}" }
        }

        val kwpGrid = listOf(
            "ISC Idle Stepper (0x54)" to iscStr,
            "Est. Throttle Buildup" to dirtStr,
            "O2 Fuel Trim (0x52)" to o2CompStr,
            "CO Cylinder Trim" to coStr
        )
        yPos = drawKeyValueGrid(canvas, kwpGrid, margin, yPos, contentWidth, columns = 2)
        yPos += 12f

        // 4. Section: Diagnostic Trouble Codes (Engine + ABS)
        val sec3Title = when (language) {
            AppLanguage.ITALIAN -> "3. CODICI DI ERRORE RILEVATI (CENTRALINA MOTORE E ABS)"
            AppLanguage.ENGLISH -> "3. DETECTED FAULT CODES (ENGINE FI & ABS ECUs)"
            AppLanguage.FRENCH -> "3. CODES DÉFAUTS DÉTECTÉS (CALCULATEUR MOTEUR & ABS)"
            AppLanguage.SPANISH -> "3. CÓDIGOS DE FALLA DETECTADOS (ECU MOTOR Y ABS)"
            AppLanguage.GERMAN -> "3. ERKANNTE FEHLERCODES (MOTOR- & ABS-STEUERGERÄT)"
        }
        yPos = drawSectionHeader(canvas, sec3Title, margin, yPos, contentWidth)

        val dtcBoxRect = RectF(margin, yPos, margin + contentWidth, yPos + 96f)
        val hasFaults = obdManager.activeDTCs.isNotEmpty() || obdManager.absDTCs.isNotEmpty()
        paint.style = Paint.Style.FILL
        paint.color = if (!hasFaults) Color.rgb(240, 250, 242) else Color.rgb(252, 242, 242)
        canvas.drawRoundRect(dtcBoxRect, 6f, 6f, paint)

        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1f
        paint.color = if (!hasFaults) Color.rgb(64, 166, 89) else Color.rgb(217, 64, 64)
        canvas.drawRoundRect(dtcBoxRect, 6f, 6f, paint)
        paint.style = Paint.Style.FILL

        var dtcTextY = yPos + 8f
        if (!hasFaults) {
            val cleanMsg = when (language) {
                AppLanguage.ITALIAN -> "✓ NESSUN CODICE DI ERRORE (DTC) ATTIVO RILEVATO NELLA CENTRALINA MOTORE O ABS."
                AppLanguage.ENGLISH -> "✓ NO ACTIVE FAULT CODES (DTC) DETECTED IN ENGINE OR ABS ECUs."
                AppLanguage.FRENCH -> "✓ AUCUN CODE DÉFAUT (DTC) ACTIF DÉTECTÉ DANS LE MOTEUR OU L'ABS."
                AppLanguage.SPANISH -> "✓ NO SE DETECTARON CÓDIGOS DE FALLA (DTC) ACTIVOS EN MOTOR O ABS."
                AppLanguage.GERMAN -> "✓ KEINE AKTIVEN FEHLERCODES (DTC) IM MOTOR- ODER ABS-STEUERGERÄT ERKANNT."
            }
            drawText(
                canvas = canvas,
                text = cleanMsg,
                x = margin + 12f,
                y = dtcTextY + 28f,
                width = contentWidth - 24f,
                textSize = 10f,
                color = Color.rgb(38, 128, 64),
                bold = true
            )
        } else {
            val allCodes = mutableListOf<String>()
            for (code in obdManager.activeDTCs) {
                val desc = obdManager.dtcDescriptions[code] ?: "Engine Fault"
                allCodes.add("[ENGINE] $code: $desc")
            }
            for (code in obdManager.absDTCs) {
                val desc = obdManager.dtcDescriptions[code] ?: "ABS Fault"
                allCodes.add("[ABS] $code: $desc")
            }
            for (line in allCodes.take(5)) {
                drawText(
                    canvas = canvas,
                    text = "• $line",
                    x = margin + 10f,
                    y = dtcTextY,
                    width = contentWidth - 20f,
                    textSize = 9f,
                    color = Color.rgb(153, 26, 26),
                    bold = true
                )
                dtcTextY += 16f
            }
        }
        yPos += 108f

        // 5. Section: AI Technical Summary
        val sec4Title = when (language) {
            AppLanguage.ITALIAN -> "4. VALUTAZIONE TECNICA AI / NOTE DIAGNOSTICHE"
            AppLanguage.ENGLISH -> "4. AI TECHNICAL EVALUATION / DIAGNOSTIC NOTES"
            AppLanguage.FRENCH -> "4. ÉVALUATION TECHNIQUE IA / NOTES DE DIAGNOSTIC"
            AppLanguage.SPANISH -> "4. EVALUACIÓN TÉCNICA IA / NOTAS DE DIAGNÓSTICO"
            AppLanguage.GERMAN -> "4. TECHNISCHE KI-BEWERTUNG / DIAGNOSEHINWEISE"
        }
        yPos = drawSectionHeader(canvas, sec4Title, margin, yPos, contentWidth)

        val aiBoxHeight = 165f
        val aiBoxRect = RectF(margin, yPos, margin + contentWidth, yPos + aiBoxHeight)
        paint.style = Paint.Style.FILL
        paint.color = Color.rgb(247, 249, 252)
        canvas.drawRoundRect(aiBoxRect, 6f, 6f, paint)

        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 0.8f
        paint.color = Color.rgb(204, 212, 224)
        canvas.drawRoundRect(aiBoxRect, 6f, 6f, paint)
        paint.style = Paint.Style.FILL

        val cleanedAI = aiEvaluation
            .replace("**", "")
            .replace("### ", "")
            .replace("## ", "")
            .trim()

        val defaultAiText = when (language) {
            AppLanguage.ITALIAN -> "Nessuna valutazione AI eseguita in questa sessione. Tutte le letture telemetriche e i registri DTC sono riportati nelle sezioni superiori per l'ispezione meccanica."
            AppLanguage.ENGLISH -> "No AI evaluation performed in this session. All telemetry readings and DTC registers are reported above for mechanical inspection."
            AppLanguage.FRENCH -> "Aucune évaluation IA effectuée au cours de cette session. Toutes les lectures télémétriques et les registres DTC sont indiqués ci-dessus."
            AppLanguage.SPANISH -> "No se realizó evaluación de IA en esta sesión. Todas las lecturas telemétricas y registros DTC se informan arriba."
            AppLanguage.GERMAN -> "Keine KI-Bewertung in dieser Sitzung durchgeführt. Alle Telemetriewerte und DTC-Register sind oben aufgeführt."
        }

        val aiTextToDraw = cleanedAI.ifEmpty { defaultAiText }
        drawMultilineText(
            canvas = canvas,
            text = aiTextToDraw,
            x = margin + 10f,
            y = yPos + 8f,
            width = (contentWidth - 20f).toInt(),
            maxHeight = (aiBoxHeight - 16f).toInt(),
            textSize = 8.5f,
            color = Color.rgb(38, 46, 56)
        )
        yPos += aiBoxHeight + 14f

        // 6. Workshop / Owner Verification Box
        val signBoxHeight = 64f
        val signRect = RectF(margin, yPos, margin + contentWidth, yPos + signBoxHeight)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 0.8f
        paint.color = Color.rgb(191, 199, 209)
        canvas.drawRoundRect(signRect, 6f, 6f, paint)
        paint.style = Paint.Style.FILL

        val notesLabel = when (language) {
            AppLanguage.ITALIAN -> "KM / Targa Veicolo: ___________________________     Data / Firma Operatore: ___________________________"
            AppLanguage.ENGLISH -> "Odometer / Plate: _____________________________     Date / Operator Signature: ________________________"
            AppLanguage.FRENCH -> "Kilométrage / Plaque : ________________________     Date / Signature Opérateur : ______________________"
            AppLanguage.SPANISH -> "Kilometraje / Matrícula: ______________________     Fecha / Firma Operador: ___________________________"
            AppLanguage.GERMAN -> "Kilometerstand / Kennzeichen: _________________     Datum / Unterschrift Prüfer: ______________________"
        }
        drawText(
            canvas = canvas,
            text = notesLabel,
            x = margin + 12f,
            y = yPos + 36f,
            width = contentWidth - 24f,
            textSize = 9f,
            color = Color.rgb(77, 89, 102),
            bold = false
        )

        // 7. Footer Disclaimer
        val footerText = "Generated by YaDiag OBD2 Diagnostic Suite • Independent tool not affiliated with Yamaha Motor Co., Ltd. • For informational and diagnostic support purposes only."
        drawText(
            canvas = canvas,
            text = footerText,
            x = margin,
            y = pageHeight - 28f,
            width = contentWidth,
            textSize = 7.5f,
            color = Color.rgb(128, 135, 145),
            bold = false
        )

        pdfDocument.finishPage(page)

        return try {
            FileOutputStream(outFile).use { out ->
                pdfDocument.writeTo(out)
            }
            pdfDocument.close()
            outFile
        } catch (_: Exception) {
            pdfDocument.close()
            null
        }
    }

    private fun drawSectionHeader(
        canvas: Canvas,
        title: String,
        x: Float,
        y: Float,
        width: Float
    ): Float {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(230, 237, 245)
            style = Paint.Style.FILL
        }
        val barRect = RectF(x, y, x + width, y + 20f)
        canvas.drawRoundRect(barRect, 4f, 4f, paint)

        drawText(
            canvas = canvas,
            text = title,
            x = x + 8f,
            y = y + 4f,
            width = width - 16f,
            textSize = 9.5f,
            color = Color.rgb(20, 46, 82),
            bold = true
        )
        return y + 26f
    }

    private fun drawKeyValueGrid(
        canvas: Canvas,
        items: List<Pair<String, String>>,
        x: Float,
        y: Float,
        width: Float,
        columns: Int
    ): Float {
        val colWidth = width / columns
        val rowHeight = 28f
        val rows = (items.size + columns - 1) / columns
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        for ((idx, item) in items.withIndex()) {
            val row = idx / columns
            val col = idx % columns
            val cellX = x + (col * colWidth)
            val cellY = y + (row * rowHeight)

            val cellRect = RectF(cellX + 2f, cellY + 2f, cellX + colWidth - 2f, cellY + rowHeight - 2f)
            paint.style = Paint.Style.FILL
            paint.color = Color.rgb(250, 251, 253)
            canvas.drawRoundRect(cellRect, 4f, 4f, paint)

            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 0.6f
            paint.color = Color.rgb(222, 227, 235)
            canvas.drawRoundRect(cellRect, 4f, 4f, paint)

            drawText(
                canvas = canvas,
                text = item.first,
                x = cellX + 8f,
                y = cellY + 4f,
                width = colWidth - 16f,
                textSize = 7.5f,
                color = Color.rgb(102, 115, 128),
                bold = false
            )
            drawText(
                canvas = canvas,
                text = item.second,
                x = cellX + 8f,
                y = cellY + 14f,
                width = colWidth - 16f,
                textSize = 9.5f,
                color = Color.rgb(18, 28, 41),
                bold = true
            )
        }

        return y + (rows * rowHeight)
    }

    private fun drawText(
        canvas: Canvas,
        text: String,
        x: Float,
        y: Float,
        width: Float,
        textSize: Float,
        color: Int,
        bold: Boolean
    ) {
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            this.textSize = textSize
            this.typeface = if (bold) Typeface.create(Typeface.DEFAULT, Typeface.BOLD) else Typeface.DEFAULT
        }
        canvas.drawText(text, x, y + textSize, textPaint)
    }

    private fun drawMultilineText(
        canvas: Canvas,
        text: String,
        x: Float,
        y: Float,
        width: Int,
        maxHeight: Int,
        textSize: Float,
        color: Int
    ) {
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            this.textSize = textSize
            this.typeface = Typeface.DEFAULT
        }
        val layout = StaticLayout.Builder
            .obtain(text, 0, text.length, textPaint, width)
            .setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .setLineSpacing(1.5f, 1.0f)
            .setIncludePad(false)
            .build()

        canvas.save()
        canvas.clipRect(x, y, x + width, y + maxHeight)
        canvas.translate(x, y)
        layout.draw(canvas)
        canvas.restore()
    }
}
