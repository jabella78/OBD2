package com.jabella78.yadiag.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.Radar
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.AppEdition
import com.jabella78.yadiag.core.AIManager
import com.jabella78.yadiag.core.AppLanguage
import com.jabella78.yadiag.core.BLEManager
import com.jabella78.yadiag.core.DiagnosticReportService
import com.jabella78.yadiag.core.DiagnosticTargetECU
import com.jabella78.yadiag.core.LocalizationManager
import com.jabella78.yadiag.core.OBD2Manager
import com.jabella78.yadiag.core.ShareHelper
import java.nio.charset.StandardCharsets
import java.util.Locale

private enum class PendingAIMode {
    NONE, FAULTS, TELEMETRY
}

@Composable
fun DiagnosticsScreen(
    bleManager: BLEManager,
    obdManager: OBD2Manager,
    aiManager: AIManager,
    loc: LocalizationManager,
    onOpenServiceGuide: () -> Unit
) {
    val context = LocalContext.current
    var manualABSInput by remember { mutableStateOf("") }
    var showClearConfirmation by remember { mutableStateOf(false) }
    var showProUpgradeAlert by remember { mutableStateOf(false) }
    var showAIConsentAlert by remember { mutableStateOf(false) }
    var pendingAIMode by remember { mutableStateOf(PendingAIMode.NONE) }

    val selectedECU = obdManager.selectedECU
    val activeCodesList = if (selectedECU == DiagnosticTargetECU.ENGINE) obdManager.dtcCodes else obdManager.absDtcCodes

    val runAI: (PendingAIMode) -> Unit = { mode ->
        val snapshot = buildTelemetrySnapshot(obdManager)
        if (mode == PendingAIMode.FAULTS) {
            val faultCodes = if (selectedECU == DiagnosticTargetECU.ENGINE) {
                obdManager.activeDTCs.ifEmpty { activeCodesList.toList() }
            } else {
                obdManager.absDTCs.ifEmpty { activeCodesList.toList() }
            }
            aiManager.evaluateFaultCodes(
                codes = faultCodes,
                descriptions = obdManager.dtcDescriptions,
                telemetryContext = snapshot,
                language = loc.language
            )
        } else if (mode == PendingAIMode.TELEMETRY) {
            val csvFile = obdManager.currentTelemetryFile
            val contextStr = if (csvFile != null && csvFile.exists()) {
                try {
                    csvFile.readText(StandardCharsets.UTF_8).takeLast(3500) + "\n\nLive Snapshot:\n$snapshot"
                } catch (_: Exception) {
                    snapshot
                }
            } else {
                snapshot
            }
            aiManager.evaluateTelemetry(
                telemetryContext = contextStr,
                language = loc.language
            )
        }
    }

    val pdfBtnLabel = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "PDF Report"
        AppLanguage.ITALIAN -> "Certificato PDF"
        AppLanguage.FRENCH -> "Certificat PDF"
        AppLanguage.SPANISH -> "Certificado PDF"
        AppLanguage.GERMAN -> "PDF-Bericht"
    }

    val serviceGuideBtnLabel = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Service Guide"
        AppLanguage.ITALIAN -> "Guida Tagliando"
        AppLanguage.FRENCH -> "Guide Entretien"
        AppLanguage.SPANISH -> "Guía Mantenimiento"
        AppLanguage.GERMAN -> "Service-Anleitung"
    }

    val telemTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Telemetry (AI)"
        AppLanguage.FRENCH -> "Télémétrie (IA)"
        AppLanguage.SPANISH -> "Telemetría (IA)"
        AppLanguage.GERMAN -> "Telemetrie (KI)"
        AppLanguage.ITALIAN -> "Analisi Corsa (AI)"
    }

    val errHeader = if (selectedECU == DiagnosticTargetECU.ENGINE) {
        when (loc.currentLanguage) {
            AppLanguage.ENGLISH -> "Engine Fault Codes (FI ECU):"
            AppLanguage.FRENCH -> "Codes Défaut Moteur (FI ECU) :"
            AppLanguage.SPANISH -> "Códigos Avería Motor (FI ECU):"
            AppLanguage.GERMAN -> "Motor-Fehlercodes (FI ECU):"
            AppLanguage.ITALIAN -> "Codici Errore Motore (FI ECU):"
        }
    } else {
        when (loc.currentLanguage) {
            AppLanguage.ENGLISH -> "ABS Fault Codes (ABS ECU):"
            AppLanguage.FRENCH -> "Codes Défaut Freins (ABS ECU) :"
            AppLanguage.SPANISH -> "Códigos Avería Frenos (ABS ECU):"
            AppLanguage.GERMAN -> "ABS-Fehlercodes (ABS ECU):"
            AppLanguage.ITALIAN -> "Codici Errore Freni (ABS ECU):"
        }
    }

    val aiResultLabel = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "AI Diagnostic Assessment:"
        AppLanguage.FRENCH -> "Résultat Analyse IA :"
        AppLanguage.SPANISH -> "Resultado Análisis IA:"
        AppLanguage.GERMAN -> "KI-Analyseergebnis:"
        AppLanguage.ITALIAN -> "Risultato Analisi AI:"
    }

    val aiConsentTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Data Sharing with External AI Service"
        AppLanguage.ITALIAN -> "Condivisione Dati con Servizio AI Esterno"
        AppLanguage.FRENCH -> "Partage de Données avec Service d'IA Externe"
        AppLanguage.SPANISH -> "Compartir Datos con Servicio de IA Externo"
        AppLanguage.GERMAN -> "Datenweitergabe an externen KI-Dienst"
    }

    val aiConsentConfirm = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Consent and Send"
        AppLanguage.ITALIAN -> "Acconsenti e Invia"
        AppLanguage.FRENCH -> "Accepter et Envoyer"
        AppLanguage.SPANISH -> "Aceptar y Enviar"
        AppLanguage.GERMAN -> "Zustimmen und Senden"
    }

    val aiConsentBody = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Technical diagnostic data (fault codes or session telemetry) will be transmitted to the ${aiManager.selectedProvider.id} cloud endpoint to generate an expert mechanical assessment.\n\nNo personal data, vehicle registration or license plate details are collected or transmitted."
        AppLanguage.ITALIAN -> "I dati tecnici diagnostici (codici guasto o telemetria della sessione) verranno trasmessi all'endpoint cloud di ${aiManager.selectedProvider.id} per generare la valutazione meccanica specialistica.\n\nNessun dato personale o di identificazione veicolo/targa viene trasmesso."
        AppLanguage.FRENCH -> "Les données techniques de diagnostic et les codes défaut seront transmis à l'endpoint de ${aiManager.selectedProvider.id} pour analyse experte.\n\nAucune donnée personnelle ou d'immatriculation n'est transmise."
        AppLanguage.SPANISH -> "Los datos técnicos de diagnóstico y códigos de avería se enviarán al servicio de ${aiManager.selectedProvider.id} para generar el peritaje mecánico.\n\nNo se recoge ni comparte ningún dato personal ni matrícula."
        AppLanguage.GERMAN -> "Diagnosetechnische Daten (Fehlercodes oder Telemetrie) werden an den Cloud-Endpunkt von ${aiManager.selectedProvider.id} übermittelt, um eine mechanische Bewertung zu erstellen.\n\nEs werden keinerlei personenbezogene Daten oder Kennzeichen erfasst."
    }

    val scrollState = rememberScrollState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg)
            .verticalScroll(scrollState)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Text(
            text = loc.t("dtc_title"),
            color = Color.White,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )

        // Module Segmented Control (Engine FI ECU vs Brakes ABS ECU)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(CardBg)
                .padding(4.dp)
        ) {
            DiagnosticTargetECU.entries.forEach { ecu ->
                val isSelected = selectedECU == ecu
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(8.dp))
                        .background(if (isSelected) CyanAccent else Color.Transparent)
                        .clickable { obdManager.selectedECU = ecu }
                        .padding(vertical = 10.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = ecu.name(loc.currentLanguage),
                        color = if (isSelected) Color.Black else Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        // ABS Specific Address & Manual Code Bar (identico a iOS DiagnosticsView)
        if (selectedECU == DiagnosticTargetECU.ABS) {
            val canLabel = when (loc.currentLanguage) {
                AppLanguage.ENGLISH -> "ABS CAN Address:"
                AppLanguage.FRENCH -> "Adresse CAN ABS :"
                AppLanguage.SPANISH -> "Dirección CAN ABS:"
                AppLanguage.GERMAN -> "ABS CAN-Adresse:"
                AppLanguage.ITALIAN -> "Indirizzo CAN ABS:"
            }
            val searchPlaceholder = when (loc.currentLanguage) {
                AppLanguage.ENGLISH -> "ABS Code (11-64)"
                AppLanguage.FRENCH -> "Code ABS (11-64)"
                AppLanguage.SPANISH -> "Cód. ABS (11-64)"
                AppLanguage.GERMAN -> "ABS-Code (11-64)"
                AppLanguage.ITALIAN -> "Cod. ABS (11-64)"
            }
            val searchBtnLabel = when (loc.currentLanguage) {
                AppLanguage.ENGLISH -> "Search"
                AppLanguage.FRENCH -> "Chercher"
                AppLanguage.SPANISH -> "Buscar"
                AppLanguage.GERMAN -> "Suchen"
                AppLanguage.ITALIAN -> "Cerca"
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = canLabel,
                        color = Color.Gray,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold
                    )

                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf("7E3", "7B0", "7E2", "760").forEach { addr ->
                            val isSelected = obdManager.absCanHeader == addr
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(if (isSelected) CyanAccent else Color.White.copy(alpha = 0.1f))
                                    .clickable { obdManager.updateAbsHeader(addr) }
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text(
                                    text = addr,
                                    color = if (isSelected) Color.Black else Color.White,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = manualABSInput,
                        onValueChange = { manualABSInput = it },
                        placeholder = { Text(searchPlaceholder, color = Color.Gray, fontSize = 12.sp) },
                        singleLine = true,
                        modifier = Modifier.weight(1f),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = CyanAccent,
                            unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White
                        )
                    )
                    Button(
                        onClick = {
                            if (manualABSInput.isNotBlank()) {
                                obdManager.lookupManualABSCode(manualABSInput)
                                manualABSInput = ""
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2196F3)),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 10.dp)
                    ) {
                        Text(searchBtnLabel, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                    Button(
                        onClick = { obdManager.scanABSAddresses() },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF9800).copy(alpha = 0.2f)),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 10.dp)
                    ) {
                        Icon(Icons.Default.Radar, contentDescription = null, tint = Color(0xFFFF9800), modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Auto-Scan", color = Color(0xFFFF9800), fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        // Action Buttons (2x2 Grid + Row 3 PDF / Service Guide)
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            // Row 1: Scan DTC & Clear DTC
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Button(
                    onClick = { obdManager.readErrors() },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (selectedECU == DiagnosticTargetECU.ENGINE) Color(0xFF2196F3) else Color(0xFFFF9800)
                    ),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 12.dp)
                ) {
                    Icon(Icons.Default.Search, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = loc.t("scan_dtc_btn"),
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }

                if (AppEdition.isPro) {
                    Button(
                        onClick = { showClearConfirmation = true },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color.Red.copy(alpha = 0.2f)),
                        shape = RoundedCornerShape(10.dp),
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 12.dp)
                    ) {
                        Icon(Icons.Default.Delete, contentDescription = null, tint = Color.Red, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = loc.t("clear_dtc_btn"),
                            color = Color.Red,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1
                        )
                    }
                } else {
                    Button(
                        onClick = { showProUpgradeAlert = true },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = Color.White.copy(alpha = 0.1f)),
                        shape = RoundedCornerShape(10.dp),
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 12.dp)
                    ) {
                        Icon(Icons.Default.Lock, contentDescription = null, tint = Color(0xFFFF9800), modifier = Modifier.size(15.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "${loc.t("clear_dtc_btn")} (Pro)",
                            color = Color(0xFFFF9800),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1
                        )
                    }
                }
            }

            // Row 2: AI Fault Eval & AI Telemetry Eval
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Button(
                    onClick = {
                        pendingAIMode = PendingAIMode.FAULTS
                        showAIConsentAlert = true
                    },
                    enabled = !aiManager.isEvaluating,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF9C27B0)),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 12.dp)
                ) {
                    Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = loc.t("ai_eval_btn"),
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }

                Button(
                    onClick = {
                        pendingAIMode = PendingAIMode.TELEMETRY
                        showAIConsentAlert = true
                    },
                    enabled = !aiManager.isEvaluating,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = Color.White.copy(alpha = 0.14f)),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 12.dp)
                ) {
                    Icon(Icons.Default.ShowChart, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = telemTitle,
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }
            }

            // Row 3: PDF Report & Service Reset Guide
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Button(
                    onClick = {
                        if (AppEdition.isPro) {
                            val file = DiagnosticReportService.generatePDFReport(
                                context = context,
                                obdManager = obdManager,
                                bleManager = bleManager,
                                aiEvaluation = aiManager.evaluationResult,
                                language = loc.language
                            )
                            if (file != null) {
                                ShareHelper.shareFile(
                                    context = context,
                                    file = file,
                                    mimeType = "application/pdf",
                                    chooserTitle = pdfBtnLabel
                                )
                            }
                        } else {
                            showProUpgradeAlert = true
                        }
                    },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = CyanAccent.copy(alpha = 0.16f)),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 11.dp)
                ) {
                    Icon(Icons.Default.Description, contentDescription = null, tint = CyanAccent, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = if (AppEdition.isPro) pdfBtnLabel else "$pdfBtnLabel (Pro)",
                        color = CyanAccent,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }

                Button(
                    onClick = onOpenServiceGuide,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF9800).copy(alpha = 0.18f)),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 11.dp)
                ) {
                    Icon(Icons.Default.MenuBook, contentDescription = null, tint = Color(0xFFFF9800), modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = serviceGuideBtnLabel,
                        color = Color(0xFFFF9800),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }
            }
        }

        // Box Codici Errore Rilevati (identico a iOS DiagnosticsView)
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = errHeader,
                color = Color.Gray,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )

            if (activeCodesList.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color.White.copy(alpha = 0.06f))
                        .padding(14.dp)
                ) {
                    Text(
                        text = loc.t("no_dtc_message"),
                        color = Color.Gray,
                        fontSize = 13.sp
                    )
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    activeCodesList.forEach { codeLine ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(Color.White.copy(alpha = 0.08f))
                                .padding(12.dp),
                            verticalAlignment = Alignment.Top,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Info,
                                contentDescription = null,
                                tint = if (selectedECU == DiagnosticTargetECU.ENGINE) Color(0xFF2196F3) else Color(0xFFFF9800),
                                modifier = Modifier.size(18.dp).padding(top = 2.dp)
                            )
                            Text(
                                text = codeLine,
                                color = Color.White,
                                fontSize = 13.sp,
                                lineHeight = 18.sp,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            }
        }

        // Box Risultato Analisi AI
        if (aiManager.isEvaluating || aiManager.evaluationResult.isNotEmpty()) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(
                        Brush.verticalGradient(
                            listOf(Color(0xFF9C27B0).copy(alpha = 0.18f), CardBg)
                        )
                    )
                    .border(1.dp, Color(0xFF9C27B0).copy(alpha = 0.45f), RoundedCornerShape(14.dp))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color(0xFFCE93D8), modifier = Modifier.size(18.dp))
                        Text(
                            text = aiResultLabel,
                            color = Color(0xFFCE93D8),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (aiManager.isEvaluating) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp,
                                color = Color(0xFFCE93D8)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                        }
                        IconButton(
                            onClick = { aiManager.clearEvaluationResult() },
                            modifier = Modifier.size(24.dp)
                        ) {
                            Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.Gray)
                        }
                    }
                }

                Text(
                    text = aiManager.evaluationResult,
                    color = Color.White,
                    fontSize = 13.sp,
                    lineHeight = 19.sp
                )
            }
        }
    }

    // Clear Confirmation Alert (Pro)
    if (showClearConfirmation) {
        AlertDialog(
            onDismissRequest = { showClearConfirmation = false },
            title = { Text(loc.t("confirm_clear_title"), fontWeight = FontWeight.Bold) },
            text = { Text(loc.t("confirm_clear_msg")) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showClearConfirmation = false
                        obdManager.clearErrors()
                    }
                ) {
                    Text(loc.t("confirm_delete"), color = Color.Red, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showClearConfirmation = false }) {
                    Text(loc.t("cancel"))
                }
            }
        )
    }

    // Pro Upgrade Alert (Free)
    if (showProUpgradeAlert) {
        val isIT = loc.language == AppLanguage.ITALIAN
        AlertDialog(
            onDismissRequest = { showProUpgradeAlert = false },
            title = {
                Text(
                    text = if (isIT) "Funzione Esclusiva YaDiag Pro" else "YaDiag Pro Exclusive Feature",
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Text(
                    text = if (isIT) {
                        "La cancellazione dei codici di errore (Mode 04 / KWP 0x14), il Certificato PDF e i reset adattivi sono disponibili nella versione completa YaDiag Pro."
                    } else {
                        "Clearing fault codes (Mode 04 / KWP 0x14), PDF Diagnostic Reports and adaptive ECU resets are available in the full YaDiag Pro edition."
                    }
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showProUpgradeAlert = false
                        ShareHelper.openStoreUpgrade(context)
                    }
                ) {
                    Text(
                        text = if (isIT) "Scopri YaDiag Pro" else "Get YaDiag Pro",
                        color = CyanAccent,
                        fontWeight = FontWeight.Bold
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showProUpgradeAlert = false }) {
                    Text(loc.t("cancel"))
                }
            }
        )
    }

    // AI Data-Sharing Consent Dialog (identico a iOS DiagnosticsView)
    if (showAIConsentAlert) {
        AlertDialog(
            onDismissRequest = {
                showAIConsentAlert = false
                pendingAIMode = PendingAIMode.NONE
            },
            title = {
                Text(text = aiConsentTitle, fontWeight = FontWeight.Bold)
            },
            text = {
                Text(text = aiConsentBody)
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val mode = pendingAIMode
                        pendingAIMode = PendingAIMode.NONE
                        showAIConsentAlert = false
                        runAI(mode)
                    }
                ) {
                    Text(
                        text = aiConsentConfirm,
                        color = CyanAccent,
                        fontWeight = FontWeight.Bold
                    )
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showAIConsentAlert = false
                        pendingAIMode = PendingAIMode.NONE
                    }
                ) {
                    Text(loc.t("cancel"))
                }
            }
        )
    }
}

private fun buildTelemetrySnapshot(obdManager: OBD2Manager): String {
    val base = StringBuilder()
    base.append("RPM: ${obdManager.rpm}, Speed: ${obdManager.speed} km/h, ")
    base.append("Coolant Temp: ${obdManager.coolantTemp}°C, Intake Air Temp: ${obdManager.intakeTemp}°C, ")
    base.append("TPS: ${String.format(Locale.US, "%.1f", obdManager.throttlePos)}%, ")
    base.append("Engine Load: ${obdManager.engineLoad}%, ")
    base.append("MAP: ${obdManager.intakePressure} kPa, ")
    base.append("Battery: ${String.format(Locale.US, "%.2f", obdManager.batteryVoltageDouble)}V, ")
    base.append("Est. AFR: ${String.format(Locale.US, "%.1f", obdManager.estimatedAFR)}:1 (${String.format(Locale.US, "%.2f", obdManager.o2SensorVoltage)}V)")

    obdManager.iscLearningValue?.let { isc ->
        base.append(", ISC Idle Stepper Opening (0x54): ${String.format(Locale.US, "%.1f", isc)}%")
    }
    base.append(", Est. Throttle Body Buildup: ${String.format(Locale.US, "%.0f", obdManager.throttleDirtPercentage)}%")
    obdManager.o2CompensationValue?.let { o2 ->
        base.append(", O2 Fuel Trim (0x52): ${String.format(Locale.US, "%.1f", o2)}%")
    }
    if (obdManager.coAdjustmentValues.isNotEmpty()) {
        val coStr = obdManager.coAdjustmentValues.entries.sortedBy { it.key }.joinToString(", ") { "C${it.key}=${it.value}" }
        base.append(", Cylinder CO Trim: [$coStr]")
    }
    return base.toString()
}
