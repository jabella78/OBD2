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
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Memory
import androidx.compose.material.icons.filled.OpenInNew
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.AppEdition
import com.jabella78.yadiag.core.AIManager
import com.jabella78.yadiag.core.AIProvider
import com.jabella78.yadiag.core.AppLanguage
import com.jabella78.yadiag.core.LocalizationManager
import com.jabella78.yadiag.core.ModelFetchState
import com.jabella78.yadiag.core.ShareHelper

@Composable
fun SettingsScreen(
    aiManager: AIManager,
    loc: LocalizationManager
) {
    val context = LocalContext.current
    val scrollState = rememberScrollState()
    var showLanguageMenu by remember { mutableStateOf(false) }
    var showProviderMenu by remember { mutableStateOf(false) }
    var showModelMenu by remember { mutableStateOf(false) }
    var showApiKeyPlaintext by remember { mutableStateOf(false) }

    val proEditionTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "YaDiag Pro Edition: ACTIVE"
        AppLanguage.FRENCH -> "Édition YaDiag Pro : ACTIVE"
        AppLanguage.SPANISH -> "Edición YaDiag Pro: ACTIVA"
        AppLanguage.GERMAN -> "YaDiag Pro Edition: AKTIV"
        AppLanguage.ITALIAN -> "Edizione YaDiag Pro: ATTIVA"
    }

    val freeEditionTitle = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "YaDiag Free Edition"
        AppLanguage.FRENCH -> "Édition YaDiag Free"
        AppLanguage.SPANISH -> "Edición YaDiag Free"
        AppLanguage.GERMAN -> "YaDiag Free Edition"
        AppLanguage.ITALIAN -> "Edizione YaDiag Free"
    }

    val freeEditionDesc = when (loc.currentLanguage) {
        AppLanguage.ITALIAN -> "Telemetria Live, Lettura DTC e Analisi AI attive. Passa a YaDiag Pro per sbloccare Cancellazione Errori (Mode 04), Certificato PDF, Reset ISC (Cod. 67) e Reset Lambda O2 (Cod. 87)."
        AppLanguage.FRENCH -> "Télémétrie Live, Lecture DTC et Analyse IA actives. Passez à YaDiag Pro pour débloquer l'Effacement DTC, Certificat PDF, Reset ISC (Code 67) et Reset Lambda O2 (Code 87)."
        AppLanguage.SPANISH -> "Telemetría Live, Lectura DTC y Análisis IA activos. Pasa a YaDiag Pro para desbloquear Borrado de Códigos, Certificado PDF, Reset ISC (Cód. 67) y Reset Lambda O2 (Cód. 87)."
        AppLanguage.GERMAN -> "Live-Telemetrie, DTC-Auslesen und KI-Analyse aktiv. Upgrade auf YaDiag Pro für Fehlerlöschung, PDF-Prüfbericht, ISC-Reset (Code 67) und Lambda-Reset (Code 87)."
        AppLanguage.ENGLISH -> "Live Telemetry, DTC Reading & AI Evaluation active. Upgrade to YaDiag Pro to unlock DTC Clearing (Mode 04), PDF Certificate, ISC Reset (Code 67) & O2 Reset (Code 87)."
    }

    val getProBtnLabel = when (loc.currentLanguage) {
        AppLanguage.ITALIAN -> "Ottieni YaDiag Pro"
        AppLanguage.FRENCH -> "Obtenir YaDiag Pro"
        AppLanguage.SPANISH -> "Obtener YaDiag Pro"
        AppLanguage.GERMAN -> "YaDiag Pro holen"
        AppLanguage.ENGLISH -> "Get YaDiag Pro"
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg)
            .verticalScroll(scrollState)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        // 1. Edition Status Card (Pro vs Free)
        if (AppEdition.isPro) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFFFFEB3B).copy(alpha = 0.08f))
                    .border(1.dp, Color(0xFFFFEB3B).copy(alpha = 0.35f), RoundedCornerShape(14.dp))
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
                        Icon(
                            imageVector = Icons.Default.Verified,
                            contentDescription = null,
                            tint = Color(0xFFFFD700),
                            modifier = Modifier.size(22.dp)
                        )
                        Text(
                            text = proEditionTitle,
                            color = Color.White,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(Color(0xFFFFEB3B).copy(alpha = 0.2f))
                            .padding(horizontal = 8.dp, vertical = 3.dp)
                    ) {
                        Text(
                            text = "Lifetime",
                            color = Color(0xFFFF9800),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
                Text(
                    text = loc.t("setup_pro_features_active"),
                    color = Color.Gray,
                    fontSize = 12.sp,
                    lineHeight = 16.sp
                )
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardBg)
                    .border(1.dp, CyanAccent.copy(alpha = 0.4f), RoundedCornerShape(14.dp))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Star,
                        contentDescription = null,
                        tint = Color(0xFFFF9800),
                        modifier = Modifier.size(26.dp)
                    )
                    Text(
                        text = freeEditionTitle,
                        color = Color.White,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Text(
                    text = freeEditionDesc,
                    color = Color.Gray,
                    fontSize = 12.sp,
                    lineHeight = 16.sp
                )
                Button(
                    onClick = { ShareHelper.openStoreUpgrade(context) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = CyanAccent),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Icon(Icons.Default.OpenInNew, contentDescription = null, tint = Color.Black, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = getProBtnLabel,
                        color = Color.Black,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        // 2. Selezione Lingua dell'Applicazione (identica a iOS SettingsView)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(CyanAccent.copy(alpha = 0.08f))
                .border(1.dp, CyanAccent.copy(alpha = 0.3f), RoundedCornerShape(14.dp))
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Icon(Icons.Default.Language, contentDescription = null, tint = CyanAccent, modifier = Modifier.size(26.dp))
                Column {
                    Text(
                        text = loc.t("setup_lang_section"),
                        color = Color.White,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = loc.t("setup_lang_desc"),
                        color = Color.Gray,
                        fontSize = 11.sp
                    )
                }
            }

            Box {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(CyanAccent.copy(alpha = 0.15f))
                        .border(1.dp, CyanAccent.copy(alpha = 0.5f), RoundedCornerShape(10.dp))
                        .clickable { showLanguageMenu = true }
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "${loc.language.flag}  ${loc.language.displayName}",
                        color = Color.White,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = Color.White)
                }

                DropdownMenu(
                    expanded = showLanguageMenu,
                    onDismissRequest = { showLanguageMenu = false }
                ) {
                    AppLanguage.entries.forEach { lang ->
                        DropdownMenuItem(
                            text = { Text("${lang.flag}  ${lang.displayName}") },
                            onClick = {
                                loc.updateLanguage(lang)
                                showLanguageMenu = false
                            }
                        )
                    }
                }
            }
        }

        Divider(color = Color.White.copy(alpha = 0.1f))

        // 3. Configurazione AI & Modelli LLM (identica a iOS SettingsView)
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(Icons.Default.Memory, contentDescription = null, tint = Color(0xFFAB47BC), modifier = Modifier.size(30.dp))
            Column {
                Text(
                    text = loc.t("setup_ai_section"),
                    color = Color.White,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = loc.t("setup_ai_desc"),
                    color = Color.Gray,
                    fontSize = 12.sp
                )
            }
        }

        // 1) Provider
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(
                text = loc.t("setup_provider_label"),
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
            Box {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(CardBg)
                        .clickable { showProviderMenu = true }
                        .padding(horizontal = 14.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = aiManager.selectedProvider.id,
                        color = Color.White,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = Color.White)
                }

                DropdownMenu(
                    expanded = showProviderMenu,
                    onDismissRequest = { showProviderMenu = false }
                ) {
                    AIProvider.entries.forEach { provider ->
                        DropdownMenuItem(
                            text = { Text(provider.id) },
                            onClick = {
                                aiManager.updateProvider(provider)
                                showProviderMenu = false
                            }
                        )
                    }
                }
            }
        }

        // 2) Modello LLM
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = loc.t("setup_model_label"),
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )

            if (aiManager.selectedProvider == AIProvider.CUSTOM) {
                Text(
                    text = loc.t("setup_custom_model_name"),
                    color = Color.Gray,
                    fontSize = 12.sp
                )
                OutlinedTextField(
                    value = aiManager.selectedModel,
                    onValueChange = { aiManager.updateSelectedModel(it) },
                    placeholder = { Text(loc.t("setup_custom_model_placeholder"), color = Color.Gray, fontSize = 12.sp) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = CyanAccent,
                        unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    )
                )

                Text(
                    text = loc.t("setup_custom_endpoint_label"),
                    color = Color.Gray,
                    fontSize = 12.sp
                )
                OutlinedTextField(
                    value = aiManager.customEndpoint,
                    onValueChange = { aiManager.updateCustomEndpoint(it) },
                    placeholder = { Text("http://localhost:11434/v1", color = Color.Gray, fontSize = 12.sp) },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = CyanAccent,
                        unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White
                    )
                )
            } else {
                Box {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(CardBg)
                            .clickable { showModelMenu = true }
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = aiManager.selectedModel,
                            color = Color.White,
                            fontSize = 13.sp,
                            fontFamily = FontFamily.Monospace
                        )
                        Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = Color.White)
                    }

                    DropdownMenu(
                        expanded = showModelMenu,
                        onDismissRequest = { showModelMenu = false }
                    ) {
                        aiManager.availableModels.forEach { model ->
                            DropdownMenuItem(
                                text = { Text(model, fontFamily = FontFamily.Monospace) },
                                onClick = {
                                    aiManager.updateSelectedModel(model)
                                    showModelMenu = false
                                }
                            )
                        }
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    val statusText = when (val st = aiManager.modelFetchState) {
                        is ModelFetchState.Loaded -> when (loc.currentLanguage) {
                            AppLanguage.ITALIAN -> "${st.count} modelli attivi caricati"
                            AppLanguage.FRENCH -> "${st.count} modèles actifs chargés"
                            AppLanguage.SPANISH -> "${st.count} modelos activos cargados"
                            AppLanguage.GERMAN -> "${st.count} aktive Modelle geladen"
                            AppLanguage.ENGLISH -> "${st.count} active models loaded"
                        }
                        is ModelFetchState.Failed -> st.message
                        is ModelFetchState.Loading -> "..."
                        else -> loc.t("setup_selected_model_picker")
                    }

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        modifier = Modifier.weight(1f)
                    ) {
                        if (aiManager.modelFetchState is ModelFetchState.Loaded) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Color(0xFF4CAF50), modifier = Modifier.size(14.dp))
                        } else if (aiManager.modelFetchState is ModelFetchState.Failed) {
                            Icon(Icons.Default.Warning, contentDescription = null, tint = Color(0xFFFF9800), modifier = Modifier.size(14.dp))
                        }
                        Text(
                            text = statusText,
                            color = Color.Gray,
                            fontSize = 11.sp
                        )
                    }

                    if (aiManager.selectedProvider.modelsListURL != null) {
                        Button(
                            onClick = { aiManager.fetchAvailableModels() },
                            enabled = aiManager.modelFetchState !is ModelFetchState.Loading,
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFAB47BC).copy(alpha = 0.2f)),
                            shape = RoundedCornerShape(8.dp),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                        ) {
                            if (aiManager.modelFetchState is ModelFetchState.Loading) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(12.dp),
                                    strokeWidth = 1.5.dp,
                                    color = Color(0xFFCE93D8)
                                )
                            } else {
                                Icon(Icons.Default.Refresh, contentDescription = null, tint = Color(0xFFCE93D8), modifier = Modifier.size(14.dp))
                            }
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = loc.t("setup_sync_btn"),
                                color = Color(0xFFCE93D8),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }

        // 3) Chiave API
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(CardBg)
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "${loc.t("setup_apikey_label")} ${aiManager.selectedProvider.id}:",
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )

            OutlinedTextField(
                value = aiManager.apiKey,
                onValueChange = { aiManager.updateApiKey(it) },
                placeholder = { Text("API Key (${aiManager.selectedProvider.id})", color = Color.Gray, fontSize = 13.sp) },
                singleLine = true,
                visualTransformation = if (showApiKeyPlaintext) VisualTransformation.None else PasswordVisualTransformation(),
                trailingIcon = {
                    IconButton(onClick = { showApiKeyPlaintext = !showApiKeyPlaintext }) {
                        Icon(
                            imageVector = if (showApiKeyPlaintext) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                            contentDescription = "Toggle visibility",
                            tint = Color.Gray
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = CyanAccent,
                    unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                )
            )

            Row(
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(Icons.Default.Security, contentDescription = null, tint = Color(0xFF4CAF50), modifier = Modifier.size(14.dp).padding(top = 2.dp))
                Text(
                    text = loc.t("setup_apikey_security"),
                    color = Color.Gray,
                    fontSize = 11.sp,
                    lineHeight = 15.sp
                )
            }
        }

        // 4) Guida ai Provider Supportati
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(Color(0xFFAB47BC).copy(alpha = 0.1f))
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(
                text = loc.t("setup_providers_guide"),
                color = Color(0xFFCE93D8),
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold
            )
            Text("• Google Gemini: gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-flash.", color = Color.Gray, fontSize = 11.sp)
            Text("• OpenAI: gpt-4o, gpt-4o-mini, o3-mini, o1-mini.", color = Color.Gray, fontSize = 11.sp)
            Text("• Anthropic Claude: claude-sonnet-4, claude-3-7-sonnet, claude-3-5-sonnet.", color = Color.Gray, fontSize = 11.sp)
            Text("• DeepSeek: deepseek-chat (V3), deepseek-reasoner (R1).", color = Color.Gray, fontSize = 11.sp)
            Text("• Groq: llama-3.3-70b-versatile, qwen-qwq-32b.", color = Color.Gray, fontSize = 11.sp)
            Text("• Custom: Localhost / Ollama / LM Studio (OpenAI Compatible).", color = Color.Gray, fontSize = 11.sp)
        }
    }
}
