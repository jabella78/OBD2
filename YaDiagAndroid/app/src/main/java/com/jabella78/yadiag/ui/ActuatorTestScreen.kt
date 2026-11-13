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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.AppEdition
import com.jabella78.yadiag.core.AppLanguage
import com.jabella78.yadiag.core.BLEManager
import com.jabella78.yadiag.core.LocalizationManager
import com.jabella78.yadiag.core.OBD2Manager
import com.jabella78.yadiag.core.ShareHelper

private data class ActuatorItem(
    val code: Int,
    val name: String,
    val description: String,
    val isDangerous: Boolean
)

@Composable
fun ActuatorTestScreen(
    bleManager: BLEManager,
    obdManager: OBD2Manager,
    loc: LocalizationManager,
    onOpenServiceGuide: () -> Unit
) {
    val context = LocalContext.current
    val scrollState = rememberScrollState()
    var selectedActuatorForReset by remember { mutableStateOf<ActuatorItem?>(null) }
    var showProUpgradeAlert by remember { mutableStateOf(false) }

    // 1:1 with iOS ActuatorTestView: in Demo mode, engine is considered stopped for reset testing
    val isEngineRunning = if (obdManager.isDemoMode) {
        false
    } else {
        obdManager.rpm > 0 || obdManager.speed > 0
    }

    val throttleStatusColor = when (obdManager.throttleCleaningLevel) {
        1 -> Color(0xFF4CAF50)
        2 -> Color(0xFFFF9800)
        3 -> Color.Red
        else -> Color.Gray
    }

    val engineActuators = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> listOf(
            ActuatorItem(
                code = 67,
                name = "Throttle Bodies / ISC Idle Learning Reset",
                description = "Manual p. 8-60 (Code 67 — KWP Command 3B 54 01): Clears adaptive values of the ISC stepper motor, returning register 0x54 to 80 00 | 80 00 | 80 00. To be performed after throttle body cleaning or synchronization.",
                isDangerous = true
            ),
            ActuatorItem(
                code = 87,
                name = "O2 Lambda Closed-Loop Trim Reset",
                description = "Manual p. 8-61 (Code 87 — KWP Command 3B 52 01): Clears closed-loop fuel correction memory from O2 sensor, returning register 0x52 to neutral factory values (02 00 / 02 00). To be performed after intake/exhaust service or O2 replacement.",
                isDangerous = true
            )
        )
        AppLanguage.FRENCH -> listOf(
            ActuatorItem(
                code = 67,
                name = "Reset Apprentissage Ralenti / Corps Papillon (ISC)",
                description = "Manuel p. 8-60 (Code 67 — Commande KWP 3B 54 01) : Réinitialise les valeurs adaptatives du moteur pas-à-pas ISC vers 80 00 | 80 00 | 80 00. À effectuer après nettoyage ou synchronisation des corps papillon.",
                isDangerous = true
            ),
            ActuatorItem(
                code = 87,
                name = "Reset Apprentissage Sonde Lambda O2 (Trim A/F)",
                description = "Manuel p. 8-61 (Code 87 — Commande KWP 3B 52 01) : Efface la mémoire de correction de richesse en boucle fermée et remet le registre 0x52 aux valeurs d'usine neutres (02 00 / 02 00).",
                isDangerous = true
            )
        )
        AppLanguage.SPANISH -> listOf(
            ActuatorItem(
                code = 67,
                name = "Reinicio Aprendizaje Ralentí / Mariposas (ISC)",
                description = "Manual pág. 8-60 (Cód. 67 — Comando KWP 3B 54 01): Borra los valores adaptativos del motor paso a paso ISC restableciendo el registro 0x54 a 80 00 | 80 00 | 80 00. Ejecutar tras limpieza o sincronización.",
                isDangerous = true
            ),
            ActuatorItem(
                code = 87,
                name = "Reinicio Aprendizaje Sonda Lambda O2 (Trim A/F)",
                description = "Manual pág. 8-61 (Cód. 87 — Comando KWP 3B 52 01): Borra la memoria de corrección en lazo cerrado y restaura el registro 0x52 a valores neutros de fábrica (02 00 / 02 00).",
                isDangerous = true
            )
        )
        AppLanguage.GERMAN -> listOf(
            ActuatorItem(
                code = 67,
                name = "Reset Drosselklappen- / ISC-Leerlaufadaption",
                description = "Handbuch S. 8-60 (Code 67 — KWP-Befehl 3B 54 01): Löscht die Adaptionswerte des ISC-Schrittmotors auf 80 00 | 80 00 | 80 00. Nach Reinigung oder Drosselklappensynchronisation durchführen.",
                isDangerous = true
            ),
            ActuatorItem(
                code = 87,
                name = "Reset Lambdasonden-Gemischadaption (A/F Trim)",
                description = "Handbuch S. 8-61 (Code 87 — KWP-Befehl 3B 52 01): Löscht den Closed-Loop Gemischkorrekturspeicher und setzt Register 0x52 auf neutrale Werkswerte (02 00 / 02 00) zurück.",
                isDangerous = true
            )
        )
        AppLanguage.ITALIAN -> listOf(
            ActuatorItem(
                code = 67,
                name = "Reset Apprendimento Corpi Farfallati / Minimo (ISC)",
                description = "Manuale pag. 8-60 (Cod. 67 — Comando KWP 3B 54 01): Cancella i valori adattivi del motorino passo-passo ISC dei corpi farfallati riportando il registro 0x54 a 80 00 | 80 00 | 80 00. Da eseguire dopo pulizia o allineamento corpi farfallati.",
                isDangerous = true
            ),
            ActuatorItem(
                code = 87,
                name = "Reset Apprendimento Sonda Lambda O2 (Trim A/F)",
                description = "Manuale pag. 8-61 (Cod. 87 — Comando KWP 3B 52 01): Cancella la memoria di correzione carburazione closed-loop della sonda O2 riportando il registro 0x52 ai valori neutri di fabbrica (02 00 / 02 00). Da eseguire dopo manutenzione aspirazione/scarico o sonda O2.",
                isDangerous = true
            )
        )
    }

    val bannerServiceTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Reset Service / Maintenance Warning?"
        AppLanguage.ITALIAN -> "Reset Spia Tagliando / Manutenzione?"
        AppLanguage.FRENCH -> "Reset Voyant Vidange / Entretien ?"
        AppLanguage.SPANISH -> "¿Reinicio Testigo Servicio / Aceite?"
        AppLanguage.GERMAN -> "Service- / Wartungsanzeige zurücksetzen?"
    }

    val bannerServiceDesc = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "On Yamaha motorcycles, service reset is performed directly on the dashboard."
        AppLanguage.ITALIAN -> "Su moto Yamaha il reset è gestito direttamente dalla strumentazione."
        AppLanguage.FRENCH -> "Sur les motos Yamaha, la réinitialisation se fait directement au compteur."
        AppLanguage.SPANISH -> "En motos Yamaha el reinicio se realiza directamente desde el cuadro."
        AppLanguage.GERMAN -> "Bei Yamaha-Motorrädern erfolgt der Service-Reset direkt am Cockpit."
    }

    val bannerServiceBtn = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Service Guide"
        AppLanguage.ITALIAN -> "Guida Reset"
        AppLanguage.FRENCH -> "Guide Reset"
        AppLanguage.SPANISH -> "Guía Reset"
        AppLanguage.GERMAN -> "Reset-Anleitung"
    }

    val engineParamsTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Engine Parameters"
        AppLanguage.ITALIAN -> "Parametri Motore"
        AppLanguage.FRENCH -> "Paramètres Moteur"
        AppLanguage.SPANISH -> "Parámetros del Motor"
        AppLanguage.GERMAN -> "Motorparameter"
    }

    val verifyValuesBtnText = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Verify Values"
        AppLanguage.ITALIAN -> "Verifica Valori"
        AppLanguage.FRENCH -> "Vérifier Valeurs"
        AppLanguage.SPANISH -> "Verificar Valores"
        AppLanguage.GERMAN -> "Werte Prüfen"
    }

    val iscParamTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "ISC Idle Stepper Learning (Code 67 — Reg. 0x54):"
        AppLanguage.ITALIAN -> "Apprendimento Minimo ISC (Cod. 67 — Reg. 0x54):"
        AppLanguage.FRENCH -> "Apprentissage Ralenti ISC (Code 67 — Reg. 0x54) :"
        AppLanguage.SPANISH -> "Aprendizaje Ralentí ISC (Cód. 67 — Reg. 0x54):"
        AppLanguage.GERMAN -> "ISC-Leerlaufadaption (Code 67 — Reg. 0x54):"
    }

    val throttleCleaningParamTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Throttle Body Cleaning Status:"
        AppLanguage.ITALIAN -> "Stato Pulizia Corpi Farfallati:"
        AppLanguage.FRENCH -> "État Propreté Corps Papillon :"
        AppLanguage.SPANISH -> "Estado Limpieza Cuerpos de Mariposa:"
        AppLanguage.GERMAN -> "Drosselklappen-Reinigungszustand:"
    }

    val o2ParamTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "O2 Lambda Sensor Learning (Code 87 — Reg. 0x52):"
        AppLanguage.ITALIAN -> "Apprendimento Sonda Lambda O2 (Cod. 87 — Reg. 0x52):"
        AppLanguage.FRENCH -> "Apprentissage Sonde Lambda O2 (Code 87 — Reg. 0x52) :"
        AppLanguage.SPANISH -> "Aprendizaje Sonda Lambda O2 (Cód. 87 — Reg. 0x52):"
        AppLanguage.GERMAN -> "O2-Lambdasondenadaption (Code 87 — Reg. 0x52):"
    }

    val coParamTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Cylinder CO Adjustment (Reg. 0x40 – 0x42):"
        AppLanguage.ITALIAN -> "Regolazione CO Cilindri (Reg. 0x40 – 0x42):"
        AppLanguage.FRENCH -> "Réglage CO Cylindres (Reg. 0x40 – 0x42) :"
        AppLanguage.SPANISH -> "Ajuste CO Cilindros (Reg. 0x40 – 0x42):"
        AppLanguage.GERMAN -> "Zylinder-CO-Einstellung (Reg. 0x40 – 0x42):"
    }

    val rawStatus = obdManager.actuatorStatusMessage
    val displayActuatorStatusMessage = if (rawStatus == "Pronto." || rawStatus == "Ready." || rawStatus.isEmpty()) {
        loc.t("act_status_ready")
    } else {
        rawStatus
    }

    fun adaptiveResetButtonTitle(code: Int): String = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Adaptive Reset (Code $code)"
        AppLanguage.ITALIAN -> "Reset Adattivo (Cod. $code)"
        AppLanguage.FRENCH -> "Reset Adaptatif (Code $code)"
        AppLanguage.SPANISH -> "Reinicio Adaptativo (Cód. $code)"
        AppLanguage.GERMAN -> "Adaptiver Reset (Code $code)"
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg)
            .verticalScroll(scrollState)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Text(
            text = loc.t("act_title"),
            color = Color.White,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )

        // Safety Banner
        if (isEngineRunning) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.Red.copy(alpha = 0.14f))
                    .border(1.dp, Color.Red.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                    .padding(14.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(Icons.Default.Warning, contentDescription = null, tint = Color.Red, modifier = Modifier.size(34.dp))
                Text(
                    text = loc.t("act_danger_title"),
                    color = Color.Red,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center
                )
                Text(
                    text = loc.t("act_danger_msg"),
                    color = Color.White.copy(alpha = 0.9f),
                    fontSize = 12.sp,
                    textAlign = TextAlign.Center
                )
            }
        } else {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF4CAF50), modifier = Modifier.size(18.dp))
                Text(
                    text = loc.t("act_ready_engine"),
                    color = Color(0xFF4CAF50),
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.White.copy(alpha = 0.08f))
                    .padding(10.dp)
            ) {
                Text(
                    text = displayActuatorStatusMessage,
                    color = Color.White,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // Engine Parameters Section (1:1 with iOS engineParametersSection)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(CyanAccent.copy(alpha = 0.08f))
                .border(1.dp, CyanAccent.copy(alpha = 0.25f), RoundedCornerShape(14.dp))
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.Speed, contentDescription = null, tint = CyanAccent, modifier = Modifier.size(20.dp))
                    Text(
                        text = engineParamsTitle,
                        color = CyanAccent,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }

                Button(
                    onClick = { obdManager.verifyISCAndO2Values() },
                    colors = ButtonDefaults.buttonColors(containerColor = CyanAccent),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Icon(Icons.Default.Refresh, contentDescription = null, tint = Color.Black, modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(5.dp))
                    Text(
                        text = verifyValuesBtnText,
                        color = Color.Black,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Divider(color = Color.White.copy(alpha = 0.12f))

            // 1. Minimo ISC (Cod. 67 - Reg. 0x54)
            val iscStatus = obdManager.iscLearningStatus
            val iscHighlight = iscStatus.contains("AZZERATO") || iscStatus.contains("RESET") ||
                    iscStatus.contains("RÉINITIALISÉ") || iscStatus.contains("RESTABLECIDO") || iscStatus.contains("ZURÜCKGESETZT")
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .padding(10.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(Icons.Default.Tune, contentDescription = null, tint = CyanAccent, modifier = Modifier.size(16.dp))
                    Text(
                        text = iscParamTitle,
                        color = Color.White,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Text(
                    text = iscStatus,
                    color = if (iscHighlight) Color(0xFFFF9800) else Color.White.copy(alpha = 0.9f),
                    fontSize = 12.sp,
                    fontFamily = FontFamily.Monospace,
                    lineHeight = 17.sp
                )
            }

            // 2. Stato Pulizia Corpi Farfallati
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .padding(10.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = CyanAccent, modifier = Modifier.size(16.dp))
                    Text(
                        text = throttleCleaningParamTitle,
                        color = Color.White,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Text(
                    text = obdManager.throttleCleaningStatus,
                    color = throttleStatusColor,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    lineHeight = 17.sp
                )
                if (obdManager.throttleCleaningLevel > 0) {
                    LinearProgressIndicator(
                        progress = (obdManager.throttleDirtPercentage / 100.0).toFloat().coerceIn(0f, 1f),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp)),
                        color = throttleStatusColor,
                        trackColor = Color.White.copy(alpha = 0.1f)
                    )
                }
            }

            // 3. Sonda Lambda O2 (Cod. 87 - Reg. 0x52)
            val o2Status = obdManager.o2LearningStatus
            val o2Highlight = o2Status.contains("AZZERATO") || o2Status.contains("RESET") ||
                    o2Status.contains("RÉINITIALISÉ") || o2Status.contains("RESTABLECIDO") || o2Status.contains("ZURÜCKGESETZT")
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .padding(10.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(Icons.Default.LocalFireDepartment, contentDescription = null, tint = Color(0xFFFF9800), modifier = Modifier.size(16.dp))
                    Text(
                        text = o2ParamTitle,
                        color = Color.White,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Text(
                    text = o2Status,
                    color = if (o2Highlight) Color(0xFFFF9800) else Color.White.copy(alpha = 0.9f),
                    fontSize = 12.sp,
                    fontFamily = FontFamily.Monospace,
                    lineHeight = 17.sp
                )
            }

            // 4. Regolazione CO Cilindri (0x40 - 0x42)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .padding(10.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(Icons.Default.Speed, contentDescription = null, tint = CyanAccent, modifier = Modifier.size(16.dp))
                    Text(
                        text = coParamTitle,
                        color = Color.White,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Text(
                    text = obdManager.coCylindersStatus,
                    color = Color.White.copy(alpha = 0.9f),
                    fontSize = 12.sp,
                    fontFamily = FontFamily.Monospace
                )
            }
        }

        // Card Informativa & Accesso Rapido Guida Reset Service (identica a iOS)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(Color(0xFFFF9800).copy(alpha = 0.12f))
                .border(1.dp, Color(0xFFFF9800).copy(alpha = 0.35f), RoundedCornerShape(12.dp))
                .clickable { onOpenServiceGuide() }
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(Icons.Default.Build, contentDescription = null, tint = Color(0xFFFF9800), modifier = Modifier.size(24.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = bannerServiceTitle,
                    color = Color.White,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = bannerServiceDesc,
                    color = Color.Gray,
                    fontSize = 11.sp
                )
            }
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color(0xFFFF9800))
                    .padding(horizontal = 10.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = bannerServiceBtn,
                    color = Color.White,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
            }
        }

        // Actuator Cards (Code 67 & Code 87)
        engineActuators.forEach { actuator ->
            val diagCodeLabel = when (loc.currentLanguage) {
                AppLanguage.SPANISH -> "DIAG Cód. ${actuator.code}"
                AppLanguage.ITALIAN -> "DIAG Cod. ${actuator.code}"
                else -> "DIAG Code ${actuator.code}"
            }

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardBg)
                    .border(1.dp, Color.White.copy(alpha = 0.1f), RoundedCornerShape(14.dp))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = actuator.name,
                        color = if (actuator.isDangerous) Color(0xFFFF9800) else Color.White,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(Color.White.copy(alpha = 0.12f))
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = diagCodeLabel,
                            color = Color.White,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Text(
                    text = actuator.description,
                    color = Color.Gray,
                    fontSize = 12.sp,
                    lineHeight = 17.sp
                )

                if (AppEdition.isPro) {
                    Button(
                        onClick = { selectedActuatorForReset = actuator },
                        enabled = !isEngineRunning,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color.Red.copy(alpha = 0.85f),
                            disabledContainerColor = Color.DarkGray
                        ),
                        shape = RoundedCornerShape(10.dp),
                        contentPadding = PaddingValues(vertical = 12.dp)
                    ) {
                        Icon(Icons.Default.Refresh, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = adaptiveResetButtonTitle(actuator.code),
                            color = Color.White,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                } else {
                    Button(
                        onClick = { showProUpgradeAlert = true },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFFF9800).copy(alpha = 0.18f)
                        ),
                        shape = RoundedCornerShape(10.dp),
                        contentPadding = PaddingValues(vertical = 12.dp)
                    ) {
                        Icon(Icons.Default.Lock, contentDescription = null, tint = Color(0xFFFF9800), modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "${adaptiveResetButtonTitle(actuator.code)} (YaDiag Pro)",
                            color = Color(0xFFFF9800),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }

    // Confirmation Dialog for ISC / O2 Reset (Pro)
    val actToConfirm = selectedActuatorForReset
    if (actToConfirm != null) {
        val alertConfirmTitle = when (loc.currentLanguage) {
            AppLanguage.ENGLISH -> "Confirm Adaptive Parameter Reset"
            AppLanguage.ITALIAN -> "Conferma Reset Parametri Adattivi"
            AppLanguage.FRENCH -> "Confirmer la Réinitialisation Adaptative"
            AppLanguage.SPANISH -> "Confirmar Reinicio de Parámetros Adaptativos"
            AppLanguage.GERMAN -> "Adaptiven Parameter-Reset Bestätigen"
        }

        val alertConfirmBtn = when (loc.currentLanguage) {
            AppLanguage.ENGLISH -> "Confirm and Execute Reset"
            AppLanguage.ITALIAN -> "Conferma ed Esegui Reset"
            AppLanguage.FRENCH -> "Confirmer et Réinitialiser"
            AppLanguage.SPANISH -> "Confirmar y Ejecutar Reinicio"
            AppLanguage.GERMAN -> "Bestätigen und Ausführen"
        }

        val alertMsg = if (actToConfirm.code == 67) {
            when (loc.currentLanguage) {
                AppLanguage.ENGLISH -> "You are about to reset throttle bodies / ISC idle stepper learning values (Code 67 — Register 0x54).\n\n⚠️ IMPORTANT: After reset, switch off ignition for 5 seconds, turn back ON and let engine idle (without touching the throttle) for several minutes until idle stabilizes."
                AppLanguage.FRENCH -> "Vous allez réinitialiser les valeurs d'apprentissage du ralenti ISC (Code 67 — Registre 0x54).\n\n⚠️ IMPORTANT : Coupez le contact pendant 5 secondes, remettez-le et laissez tourner le moteur au ralenti sans toucher à la poignée de gaz pendant quelques minutes."
                AppLanguage.SPANISH -> "Vas a reiniciar los valores de aprendizaje de ralentí ISC (Cód. 67 — Registro 0x54).\n\n⚠️ IMPORTANTE: Tras el reinicio, apaga el contacto 5 segundos, vuelve a encenderlo y deja el motor al ralentí sin acelerar durante unos minutos."
                AppLanguage.GERMAN -> "Sie setzen die Drosselklappen- / ISC-Leerlaufadaptionswerte zurück (Code 67 — Register 0x54).\n\n⚠️ WICHTIG: Nach dem Reset die Zündung für 5 Sekunden ausschalten, wieder einschalten und den Motor einige Minuten im Leerlauf laufen lassen (ohne Gas zu geben)."
                AppLanguage.ITALIAN -> "Stai per azzerare i valori di apprendimento dei corpi farfallati / valvola minimo ISC (Cod. 67 — Registro 0x54).\n\n⚠️ IMPORTANTE: Dopo il reset dovrai spegnere il quadro per 5 secondi, riaccenderlo e lasciar girare il motore al minimo (senza toccare l'acceleratore) per alcuni minuti fino a stabilizzazione del minimo."
            }
        } else {
            when (loc.currentLanguage) {
                AppLanguage.ENGLISH -> "You are about to reset O2 sensor closed-loop air/fuel learning values (Code 87 — Register 0x52).\n\n⚠️ IMPORTANT: The ECU will automatically learn new fuel trims during subsequent warm riding cycles."
                AppLanguage.FRENCH -> "Vous allez réinitialiser les valeurs d'auto-apprentissage de la sonde Lambda O2 (Code 87 — Registre 0x52).\n\n⚠️ IMPORTANT : Le calculateur réapprendra automatiquement les nouveaux correcteurs lors des prochains cycles de roulage à chaud."
                AppLanguage.SPANISH -> "Vas a reiniciar los valores de autoaprendizaje de la sonda Lambda O2 (Cód. 87 — Registro 0x52).\n\n⚠️ IMPORTANTE: La centralita aprenderá automáticamente las nuevas correcciones en los siguientes ciclos con motor caliente."
                AppLanguage.GERMAN -> "Sie setzen die O2-Lambdasonden Gemisch-Adaptionswerte zurück (Code 87 — Register 0x52).\n\n⚠️ WICHTIG: Das Steuergerät lernt die neuen Gemischtrims bei den folgenden Fahrzyklen bei warmem Motor automatisch an."
                AppLanguage.ITALIAN -> "Stai per azzerare i valori di auto-apprendimento carburazione della Sonda Lambda O2 (Cod. 87 — Registro 0x52).\n\n⚠️ IMPORTANTE: La centralina riapprenderà automaticamente i nuovi correttori A/F durante i successivi cicli di funzionamento a motore caldo."
            }
        }

        AlertDialog(
            onDismissRequest = { selectedActuatorForReset = null },
            title = { Text(alertConfirmTitle, fontWeight = FontWeight.Bold) },
            text = { Text(alertMsg) },
            confirmButton = {
                TextButton(
                    onClick = {
                        val code = actToConfirm.code
                        selectedActuatorForReset = null
                        obdManager.sendActuatorCommand(code)
                    }
                ) {
                    Text(alertConfirmBtn, color = Color.Red, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { selectedActuatorForReset = null }) {
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
                        "I reset adattivi KWP2000 (Reset ISC Codice 67 e Reset Fuel Trim O2 Codice 87) sono riservati alla versione completa YaDiag Pro."
                    } else {
                        "Adaptive KWP2000 resets (ISC Reset Code 67 and O2 Fuel Trim Reset Code 87) are exclusive to YaDiag Pro."
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
                        text = if (isIT) "Passa a YaDiag Pro" else "Upgrade to YaDiag Pro",
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
}
