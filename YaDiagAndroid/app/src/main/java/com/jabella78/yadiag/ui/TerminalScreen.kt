package com.jabella78.yadiag.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.core.AppLanguage
import com.jabella78.yadiag.core.LocalizationManager
import com.jabella78.yadiag.core.OBD2Manager

@Composable
fun TerminalScreen(
    obdManager: OBD2Manager,
    loc: LocalizationManager
) {
    var customCommand by remember { mutableStateOf("") }
    var showDangerWarning by remember { mutableStateOf(false) }
    var dangerousCommandReason by remember { mutableStateOf("") }
    var pendingDangerousCommand by remember { mutableStateOf("") }
    val listState = rememberLazyListState()

    val logs = obdManager.terminalLogs
    LaunchedEffect(logs.size) {
        if (logs.isNotEmpty()) {
            listState.animateScrollToItem(logs.size - 1)
        }
    }

    val pauseLabel = if (loc.currentLanguage == AppLanguage.ITALIAN) "Pausa" else "Pause"

    val dangerAlertTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Critical Diagnostic Command"
        AppLanguage.FRENCH -> "Commande Diagnostique Critique"
        AppLanguage.SPANISH -> "Comando Diagnóstico Crítico"
        AppLanguage.GERMAN -> "Kritischer Diagnosebefehl"
        AppLanguage.ITALIAN -> "Comando Diagnostico Critico"
    }

    val dangerConfirmBtn = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Send Anyway (Expert Mode)"
        AppLanguage.FRENCH -> "Envoyer quand même (Mode Expert)"
        AppLanguage.SPANISH -> "Enviar de todos modos (Modo Experto)"
        AppLanguage.GERMAN -> "Trotzdem senden (Expertenmodus)"
        AppLanguage.ITALIAN -> "Invia Comunque (Modalità Esperto)"
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Header Row (1:1 with iOS TerminalView)
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = loc.t("term_title"),
                color = Color.White,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f)
            )

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = { obdManager.toggleTelemetry() },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (obdManager.isPollingPaused) Color(0xFF4CAF50) else Color(0xFFFF9800)
                    ),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp)
                ) {
                    Icon(
                        imageVector = if (obdManager.isPollingPaused) Icons.Default.PlayArrow else Icons.Default.Pause,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = if (obdManager.isPollingPaused) "Live" else pauseLabel,
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                Button(
                    onClick = { obdManager.clearTerminalLogs() },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.White.copy(alpha = 0.14f)),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = loc.t("term_clear"),
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        Text(
            text = loc.t("term_desc"),
            color = Color.Gray,
            fontSize = 11.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )

        // Console Log Box
        LazyColumn(
            state = listState,
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .clip(RoundedCornerShape(10.dp))
                .background(Color.Black.copy(alpha = 0.85f))
                .border(1.dp, Color.Gray.copy(alpha = 0.4f), RoundedCornerShape(10.dp))
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            itemsIndexed(logs) { _, line ->
                val lineColor = when {
                    line.contains(">") -> CyanAccent
                    line.contains("NO DATA") || line.contains("ERROR") || line.contains("TIMEOUT") -> Color(0xFFFF9800)
                    else -> Color(0xFF4CAF50)
                }
                Text(
                    text = line,
                    color = lineColor,
                    fontSize = 12.sp,
                    fontFamily = FontFamily.Monospace
                )
            }
        }

        // Command Input Row
        val submitCommand: () -> Unit = {
            val trimmed = customCommand.trim()
            if (trimmed.isNotEmpty()) {
                val (isDanger, reason) = OBD2Manager.isDangerousCommand(trimmed)
                if (isDanger) {
                    pendingDangerousCommand = trimmed
                    dangerousCommandReason = reason
                    showDangerWarning = true
                } else {
                    obdManager.sendCustomCommand(trimmed)
                    customCommand = ""
                }
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            OutlinedTextField(
                value = customCommand,
                onValueChange = { customCommand = it },
                placeholder = { Text("ATSH 7B0, 1003, 1902FF, ATMA...", color = Color.Gray, fontSize = 12.sp) },
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
                onClick = submitCommand,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2196F3)),
                shape = RoundedCornerShape(10.dp),
                contentPadding = PaddingValues(horizontal = 14.dp, vertical = 12.dp)
            ) {
                Icon(Icons.Default.Send, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = loc.t("term_send"),
                    color = Color.White,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }

    if (showDangerWarning) {
        AlertDialog(
            onDismissRequest = {
                showDangerWarning = false
                pendingDangerousCommand = ""
            },
            title = { Text(dangerAlertTitle, fontWeight = FontWeight.Bold) },
            text = { Text("${loc.t("term_danger_alert")}\n\n($dangerousCommandReason)") },
            confirmButton = {
                TextButton(
                    onClick = {
                        obdManager.sendCustomCommand(pendingDangerousCommand)
                        customCommand = ""
                        pendingDangerousCommand = ""
                        showDangerWarning = false
                    }
                ) {
                    Text(dangerConfirmBtn, color = Color.Red, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showDangerWarning = false
                        pendingDangerousCommand = ""
                    }
                ) {
                    Text(loc.t("cancel"))
                }
            }
        )
    }
}
