package com.jabella78.yadiag.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material.icons.filled.Terminal
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.core.AIManager
import com.jabella78.yadiag.core.BLEManager
import com.jabella78.yadiag.core.LocalizationManager
import com.jabella78.yadiag.core.OBD2Manager

private data class NavTabItem(
    val index: Int,
    val labelKey: String,
    val icon: ImageVector
)

@Composable
fun ContentView(
    bleManager: BLEManager,
    obdManager: OBD2Manager,
    aiManager: AIManager,
    loc: LocalizationManager,
    currentDeploymentId: String,
    onRequestPermissionsAndScan: () -> Unit
) {
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("yadiag_prefs", android.content.Context.MODE_PRIVATE) }

    var lastAcceptedDeployment by remember {
        mutableStateOf(prefs.getString("lastAcceptedDeploymentBuild", "") ?: "")
    }
    var showingManualDisclaimer by remember { mutableStateOf(false) }
    var showServiceResetGuide by remember { mutableStateOf(false) }
    var selectedTab by remember { mutableIntStateOf(0) }

    val isDisclaimerRequired = lastAcceptedDeployment != currentDeploymentId
    val shouldShowDisclaimer = isDisclaimerRequired || showingManualDisclaimer

    // Exact 1:1 tab order and localization keys from iOS ContentView.swift
    val tabs = listOf(
        NavTabItem(0, "tab_dash", Icons.Default.Speed),
        NavTabItem(1, "tab_dtc", Icons.Default.Build),
        NavTabItem(2, "tab_term", Icons.Default.Terminal),
        NavTabItem(3, "tab_ble", Icons.Default.Bluetooth),
        NavTabItem(4, "tab_actuators", Icons.Default.Bolt),
        NavTabItem(5, "tab_setup", Icons.Default.Settings),
        NavTabItem(6, "tab_info", Icons.Default.Info)
    )

    Box(modifier = Modifier.fillMaxSize().background(DarkBg)) {
        if (shouldShowDisclaimer) {
            DisclaimerModal(
                loc = loc,
                appVersion = currentDeploymentId,
                isReopeningTerms = showingManualDisclaimer && !isDisclaimerRequired,
                onAccept = {
                    lastAcceptedDeployment = currentDeploymentId
                    prefs.edit().putString("lastAcceptedDeploymentBuild", currentDeploymentId).apply()
                    showingManualDisclaimer = false
                },
                onDismiss = {
                    showingManualDisclaimer = false
                }
            )
        } else {
            Scaffold(
                containerColor = DarkBg,
                bottomBar = {
                    val tabScroll = rememberScrollState()
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFF121620))
                            .horizontalScroll(tabScroll)
                            .padding(horizontal = 8.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        tabs.forEach { tab ->
                            val isSelected = selectedTab == tab.index
                            Column(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(if (isSelected) CyanAccent else Color.White.copy(alpha = 0.05f))
                                    .clickable { selectedTab = tab.index }
                                    .padding(horizontal = 12.dp, vertical = 6.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Icon(
                                    imageVector = tab.icon,
                                    contentDescription = loc.t(tab.labelKey),
                                    tint = if (isSelected) Color.Black else Color.Gray,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = loc.t(tab.labelKey),
                                    color = if (isSelected) Color.Black else Color.White,
                                    fontSize = 11.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                )
                            }
                        }
                    }
                }
            ) { innerPadding ->
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(innerPadding)
                ) {
                    when (selectedTab) {
                        0 -> DashboardScreen(bleManager = bleManager, obdManager = obdManager, loc = loc)
                        1 -> DiagnosticsScreen(
                            bleManager = bleManager,
                            obdManager = obdManager,
                            aiManager = aiManager,
                            loc = loc,
                            onOpenServiceGuide = { showServiceResetGuide = true }
                        )
                        2 -> TerminalScreen(obdManager = obdManager, loc = loc)
                        3 -> ConnectionScreen(
                            bleManager = bleManager,
                            obdManager = obdManager,
                            loc = loc,
                            onRequestPermissionsAndScan = onRequestPermissionsAndScan
                        )
                        4 -> ActuatorTestScreen(
                            bleManager = bleManager,
                            obdManager = obdManager,
                            loc = loc,
                            onOpenServiceGuide = { showServiceResetGuide = true }
                        )
                        5 -> SettingsScreen(aiManager = aiManager, loc = loc)
                        6 -> InfoScreen(
                            loc = loc,
                            currentDeploymentId = currentDeploymentId,
                            onOpenServiceGuide = { showServiceResetGuide = true },
                            onReviewDisclaimer = { showingManualDisclaimer = true }
                        )
                    }
                }
            }

            if (showServiceResetGuide) {
                ServiceResetGuideSheet(
                    loc = loc,
                    onDismiss = { showServiceResetGuide = false }
                )
            }
        }
    }
}
