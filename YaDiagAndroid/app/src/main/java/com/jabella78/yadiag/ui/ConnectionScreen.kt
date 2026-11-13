package com.jabella78.yadiag.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.BluetoothSearching
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Computer
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.core.AppLanguage
import com.jabella78.yadiag.core.BLEManager
import com.jabella78.yadiag.core.LocalizationManager
import com.jabella78.yadiag.core.OBD2Manager

@Composable
fun ConnectionScreen(
    bleManager: BLEManager,
    obdManager: OBD2Manager,
    loc: LocalizationManager,
    onRequestPermissionsAndScan: () -> Unit
) {
    val scrollState = rememberScrollState()

    val btStatus = if (bleManager.isBluetoothOn) {
        when (loc.currentLanguage) {
            AppLanguage.ENGLISH -> "Active"
            AppLanguage.GERMAN -> "Aktiv"
            AppLanguage.SPANISH -> "Activo"
            AppLanguage.FRENCH -> "Actif"
            AppLanguage.ITALIAN -> "Attivo"
        }
    } else {
        when (loc.currentLanguage) {
            AppLanguage.ENGLISH -> "Off"
            AppLanguage.GERMAN -> "Aus"
            AppLanguage.SPANISH -> "Apagado"
            AppLanguage.FRENCH -> "Éteint"
            AppLanguage.ITALIAN -> "Spento"
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg)
            .verticalScroll(scrollState)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = loc.t("ble_title"),
            color = Color.White,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )

        // Toggle Filtro Adattatori Certificati (identico a iOS ConnectionView)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(CardBg)
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = loc.t("ble_ext_mode"),
                    color = Color.White,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = if (bleManager.showOnlyCertifiedAdapters) {
                        "UniCarScan, vLinker, OBDLink, Veepeak, Carista"
                    } else {
                        loc.t("ble_ext_desc")
                    },
                    color = if (bleManager.showOnlyCertifiedAdapters) CyanAccent else Color(0xFFFF9800),
                    fontSize = 11.sp,
                    lineHeight = 15.sp
                )
            }
            Spacer(modifier = Modifier.width(10.dp))
            Switch(
                checked = !bleManager.showOnlyCertifiedAdapters,
                onCheckedChange = { extendedEnabled ->
                    bleManager.updateShowOnlyCertifiedAdapters(!extendedEnabled)
                },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = Color.Black,
                    checkedTrackColor = Color(0xFFFF9800)
                )
            )
        }

        // Bluetooth state row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(10.dp)
                    .clip(CircleShape)
                    .background(if (bleManager.isBluetoothOn) Color(0xFF4CAF50) else Color.Red)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "Bluetooth: $btStatus",
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
        }

        if (bleManager.isConnected) {
            val simPurple = Color(0xFFAB47BC)
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (bleManager.isVirtualSimulator) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(simPurple.copy(alpha = 0.14f))
                            .border(1.dp, simPurple.copy(alpha = 0.4f), RoundedCornerShape(12.dp))
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(Icons.Default.Computer, contentDescription = null, tint = simPurple, modifier = Modifier.size(28.dp))
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(
                                text = loc.t("ble_sim_active_banner"),
                                color = Color(0xFFCE93D8),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = bleManager.connectedDeviceName,
                                color = Color.White,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = loc.t("ble_simulated_protocol"),
                                color = Color.Gray,
                                fontSize = 11.sp
                            )
                        }
                    }
                } else {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color(0xFF4CAF50).copy(alpha = 0.12f))
                            .border(1.dp, Color(0xFF4CAF50).copy(alpha = 0.4f), RoundedCornerShape(12.dp))
                            .padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(Icons.Default.Bluetooth, contentDescription = null, tint = Color(0xFF4CAF50), modifier = Modifier.size(28.dp))
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(
                                text = loc.t("ble_connected_to"),
                                color = Color.Gray,
                                fontSize = 11.sp
                            )
                            Text(
                                text = bleManager.connectedDeviceName,
                                color = Color(0xFF4CAF50),
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                // CAN Bus 500k Init Button
                Button(
                    onClick = { obdManager.startInitialization() },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2196F3)),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(vertical = 14.dp)
                ) {
                    Icon(Icons.Default.Bolt, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "CAN Bus 500k Init",
                        color = Color.White,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                // Disconnect Button
                Button(
                    onClick = {
                        if (bleManager.isVirtualSimulator) {
                            obdManager.stopVirtualSimulatorMode()
                        } else {
                            bleManager.disconnect()
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Red.copy(alpha = 0.18f)),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(vertical = 12.dp)
                ) {
                    Icon(Icons.Default.Close, contentDescription = null, tint = Color.Red, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = if (bleManager.isVirtualSimulator) loc.t("ble_simulator_disconnect") else loc.t("ble_disconnect"),
                        color = Color.Red,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        } else {
            // Card Modalità Simulatore Senza Adattatore (identica a iOS ConnectionView)
            val simPurple = Color(0xFFAB47BC)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(simPurple.copy(alpha = 0.1f))
                    .border(1.dp, simPurple.copy(alpha = 0.35f), RoundedCornerShape(12.dp))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Icon(Icons.Default.Computer, contentDescription = null, tint = simPurple, modifier = Modifier.size(22.dp))
                    Column {
                        Text(
                            text = loc.t("ble_simulator_card_title"),
                            color = Color(0xFFCE93D8),
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = loc.t("ble_simulator_card_desc"),
                            color = Color.Gray,
                            fontSize = 11.sp
                        )
                    }
                }

                Button(
                    onClick = { obdManager.startVirtualSimulatorMode() },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF9C27B0)),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(vertical = 12.dp)
                ) {
                    Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = loc.t("ble_simulator_connect"),
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            // Scan Button
            Button(
                onClick = {
                    if (bleManager.isScanning) {
                        bleManager.stopScanning()
                    } else {
                        onRequestPermissionsAndScan()
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (bleManager.isScanning) Color(0xFFFF9800) else Color(0xFF2196F3)
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                if (bleManager.isScanning) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                        color = Color.Black
                    )
                } else {
                    Icon(Icons.Default.BluetoothSearching, contentDescription = null, tint = Color.White)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (bleManager.isScanning) loc.t("ble_stop_scan_btn") else loc.t("ble_scan_btn"),
                    color = if (bleManager.isScanning) Color.Black else Color.White,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            // Discovered Peripherals List
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(CardBg)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                if (bleManager.discoveredPeripherals.isEmpty()) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(Icons.Default.Search, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(32.dp))
                        Text(
                            text = loc.t("ble_no_devices"),
                            color = Color.Gray,
                            fontSize = 13.sp,
                            textAlign = TextAlign.Center
                        )
                        Text(
                            text = loc.t("ble_insert_hint"),
                            color = Color.Gray.copy(alpha = 0.8f),
                            fontSize = 11.sp,
                            textAlign = TextAlign.Center
                        )
                    }
                } else {
                    bleManager.discoveredPeripherals.forEach { item ->
                        val isCert = BLEManager.isCertifiedAdapter(item.name)
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color.White.copy(alpha = 0.04f))
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column(
                                modifier = Modifier.weight(1f),
                                verticalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Text(
                                    text = item.name,
                                    color = Color.White,
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.Bold
                                )
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(
                                        imageVector = if (isCert) Icons.Default.Verified else Icons.Default.Warning,
                                        contentDescription = null,
                                        tint = if (isCert) Color(0xFF4CAF50) else Color(0xFFFF9800),
                                        modifier = Modifier.size(14.dp)
                                    )
                                    Text(
                                        text = if (isCert) loc.t("ble_certified_badge") else loc.t("ble_generic_badge"),
                                        color = if (isCert) Color(0xFF4CAF50) else Color(0xFFFF9800),
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                    Text(
                                        text = if (item.isClassicSPP) "• Classic SPP" else "• BLE (${item.rssi} dBm)",
                                        color = Color.Gray,
                                        fontSize = 11.sp
                                    )
                                }
                            }

                            Button(
                                onClick = { bleManager.connect(item) },
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2196F3)),
                                shape = RoundedCornerShape(8.dp)
                            ) {
                                Text(
                                    text = loc.t("ble_connect"),
                                    color = Color.White,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
