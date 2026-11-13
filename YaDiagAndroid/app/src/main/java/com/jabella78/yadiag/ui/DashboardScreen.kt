package com.jabella78.yadiag.ui

import android.graphics.BitmapFactory
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
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
import androidx.compose.material.icons.filled.Computer
import androidx.compose.material.icons.filled.FiberManualRecord
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.AppEdition
import com.jabella78.yadiag.core.AppLanguage
import com.jabella78.yadiag.core.BLEManager
import com.jabella78.yadiag.core.LocalizationManager
import com.jabella78.yadiag.core.OBD2Manager
import com.jabella78.yadiag.core.ShareHelper
import java.util.Locale
import kotlin.math.cos
import kotlin.math.sin

val DarkBg = Color(0xFF0A0D12)
val CardBg = Color(0xFF1A1F2B)
val CyanAccent = Color(0xFF00D4FF)

@Composable
fun DashboardScreen(
    bleManager: BLEManager,
    obdManager: OBD2Manager,
    loc: LocalizationManager
) {
    val context = LocalContext.current
    val scrollState = rememberScrollState()

    val logoBitmap = remember {
        try {
            context.assets.open("yadiag_logo.png").use { stream ->
                BitmapFactory.decodeStream(stream)?.asImageBitmap()
            }
        } catch (_: Exception) {
            null
        }
    }

    val recordCsvBtnText = if (obdManager.isRecording) {
        when (loc.currentLanguage) {
            AppLanguage.ENGLISH -> "Stop CSV"
            AppLanguage.ITALIAN -> "Stop CSV"
            AppLanguage.FRENCH -> "Arrêter CSV"
            AppLanguage.SPANISH -> "Detener CSV"
            AppLanguage.GERMAN -> "CSV Stoppen"
        }
    } else {
        when (loc.currentLanguage) {
            AppLanguage.ENGLISH -> "Record CSV"
            AppLanguage.ITALIAN -> "Registra CSV"
            AppLanguage.FRENCH -> "Enregistrer CSV"
            AppLanguage.SPANISH -> "Grabar CSV"
            AppLanguage.GERMAN -> "CSV Aufnehmen"
        }
    }

    val exportCsvBtnText = when (loc.currentLanguage) {
        AppLanguage.ENGLISH -> "Export CSV"
        AppLanguage.ITALIAN -> "Esporta CSV"
        AppLanguage.FRENCH -> "Exporter CSV"
        AppLanguage.SPANISH -> "Exportar CSV"
        AppLanguage.GERMAN -> "CSV Exportieren"
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBg)
            .verticalScroll(scrollState)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Header Centrale YaDiag (identico a iOS DashboardView)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 4.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (logoBitmap != null) {
                Image(
                    bitmap = logoBitmap,
                    contentDescription = "YaDiag Logo",
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .size(50.dp)
                        .clip(RoundedCornerShape(12.dp))
                )
                Spacer(modifier = Modifier.width(12.dp))
            }
            Column {
                Text(
                    text = AppEdition.appName,
                    color = CyanAccent,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Black
                )
                Text(
                    text = loc.t("dash_subtitle"),
                    color = CyanAccent.copy(alpha = 0.85f),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // Control Center: Telemetria Live, Registra CSV, Esporta CSV e Simulatore Banco Prova (Demo)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(Color.White.copy(alpha = 0.05f))
                .padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // 1. Tasto Telemetria Live (Play/Pausa)
                Button(
                    onClick = { obdManager.toggleTelemetry() },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (obdManager.isPollingPaused) Color(0xFF4CAF50) else Color(0xFFFF9800)
                    ),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 10.dp)
                ) {
                    Icon(
                        imageVector = if (obdManager.isPollingPaused) Icons.Default.PlayArrow else Icons.Default.Pause,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = if (obdManager.isPollingPaused) loc.t("dash_live_resume") else loc.t("dash_live_pause"),
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }

                // 2. Tasto Registrazione CSV Telemetria
                Button(
                    onClick = { obdManager.toggleRecording() },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (obdManager.isRecording) Color.Red else Color.White.copy(alpha = 0.14f)
                    ),
                    shape = RoundedCornerShape(10.dp),
                    contentPadding = PaddingValues(horizontal = 10.dp, vertical = 10.dp)
                ) {
                    Icon(
                        imageVector = if (obdManager.isRecording) Icons.Default.Stop else Icons.Default.FiberManualRecord,
                        contentDescription = null,
                        tint = if (obdManager.isRecording) Color.White else Color.Red,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = recordCsvBtnText,
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1
                    )
                }

                // 3. Tasto Esporta CSV
                if (obdManager.currentTelemetryFile != null && !obdManager.isRecording) {
                    Button(
                        onClick = {
                            ShareHelper.shareFile(
                                context = context,
                                file = obdManager.getCSVFile(),
                                mimeType = "text/csv",
                                chooserTitle = exportCsvBtnText
                            )
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = CyanAccent.copy(alpha = 0.2f)
                        ),
                        shape = RoundedCornerShape(10.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 10.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = exportCsvBtnText,
                            tint = CyanAccent,
                            modifier = Modifier.size(15.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = exportCsvBtnText,
                            color = CyanAccent,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1
                        )
                    }
                }
            }

            // Riga 2: Card dedicata al Simulatore Banco Prova (Demo) con Switch Toggle
            val demoPurple = Color(0xFFAB47BC)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(if (obdManager.isDemoMode) demoPurple.copy(alpha = 0.15f) else Color.White.copy(alpha = 0.05f))
                    .border(
                        width = 1.dp,
                        color = if (obdManager.isDemoMode) demoPurple.copy(alpha = 0.45f) else Color.White.copy(alpha = 0.12f),
                        shape = RoundedCornerShape(10.dp)
                    )
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    modifier = Modifier.weight(1f),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Computer,
                        contentDescription = null,
                        tint = if (obdManager.isDemoMode) demoPurple else Color.Gray,
                        modifier = Modifier.size(20.dp)
                    )
                    Column {
                        Text(
                            text = loc.t("ble_bench_mode_title"),
                            color = if (obdManager.isDemoMode) Color(0xFFCE93D8) else Color.White,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1
                        )
                        Text(
                            text = if (obdManager.isDemoMode) loc.t("ble_bench_mode_active") else loc.t("ble_bench_mode_idle"),
                            color = Color.Gray,
                            fontSize = 11.sp,
                            maxLines = 1
                        )
                    }
                }

                Switch(
                    checked = obdManager.isDemoMode,
                    onCheckedChange = { obdManager.toggleDemoMode() },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Color.White,
                        checkedTrackColor = demoPurple
                    )
                )
            }
        }

        // Main Analog Tachometer & Speed / Gear Row
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            AnalogTachometerView(rpm = obdManager.rpm)

            // Speed & Calculated Gear Card (identica a iOS)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(20.dp))
                    .background(CardBg)
                    .border(1.5.dp, Color(0xFF4CAF50).copy(alpha = 0.45f), RoundedCornerShape(20.dp))
                    .padding(vertical = 14.dp, horizontal = 20.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = loc.t("speed_label"),
                        color = Color.Gray,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "${obdManager.speed}",
                        color = Color(0xFF4CAF50),
                        fontSize = 52.sp,
                        fontWeight = FontWeight.Black,
                        fontFamily = FontFamily.Monospace
                    )
                    Text(
                        text = "km/h",
                        color = Color.Gray,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Divider(
                    color = Color.White.copy(alpha = 0.15f),
                    modifier = Modifier
                        .height(70.dp)
                        .width(1.dp)
                )

                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = loc.t("gear_label"),
                        color = Color.Gray,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    val gearColor = if (obdManager.currentGear == "N") Color(0xFF4CAF50) else Color.White
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(Color.White.copy(alpha = 0.06f))
                            .border(1.5.dp, gearColor.copy(alpha = 0.5f), RoundedCornerShape(12.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = obdManager.currentGear,
                            color = gearColor,
                            fontSize = 38.sp,
                            fontWeight = FontWeight.Black,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                }
            }
        }

        // O2 Sensor / Lambda AFR Card
        O2SensorBarView(voltage = obdManager.o2Voltage, loc = loc)

        // Secondary Metrics Grid (6 Circular Gauges - 2x3)
        val airLabel = when (loc.currentLanguage) {
            AppLanguage.ENGLISH, AppLanguage.FRENCH -> "Air"
            AppLanguage.GERMAN -> "Luft"
            AppLanguage.SPANISH -> "Aire"
            AppLanguage.ITALIAN -> "Aria"
        }
        val battLabel = when (loc.currentLanguage) {
            AppLanguage.GERMAN, AppLanguage.FRENCH -> "Batterie"
            AppLanguage.ENGLISH -> "Battery"
            AppLanguage.SPANISH -> "Batería"
            AppLanguage.ITALIAN -> "Batteria"
        }
        val battDouble = obdManager.batteryVoltageDouble

        val gauges = listOf(
            GaugeItemData(
                title = "Temp",
                value = "${obdManager.temp}",
                unit = "°C",
                progress = (obdManager.temp / 120f).coerceIn(0f, 1f),
                color = when {
                    obdManager.temp < 71 -> Color(0xFF2196F3)
                    obdManager.temp < 105 -> Color(0xFF4CAF50)
                    obdManager.temp < 116 -> Color(0xFFFF9800)
                    else -> Color.Red
                }
            ),
            GaugeItemData(
                title = "TPS",
                value = "${obdManager.tps}",
                unit = "%",
                progress = (obdManager.tps / 100f).coerceIn(0f, 1f),
                color = Color(0xFF2196F3)
            ),
            GaugeItemData(
                title = "Load",
                value = "${obdManager.engineLoad}",
                unit = "%",
                progress = (obdManager.engineLoad / 100f).coerceIn(0f, 1f),
                color = Color(0xFFAB47BC)
            ),
            GaugeItemData(
                title = airLabel,
                value = "${obdManager.iat}",
                unit = "°C",
                progress = (obdManager.iat / 60f).coerceIn(0f, 1f),
                color = CyanAccent
            ),
            GaugeItemData(
                title = "MAP",
                value = "${obdManager.map}",
                unit = "kPa",
                progress = (obdManager.map / 110f).coerceIn(0f, 1f),
                color = Color(0xFFFFEB3B)
            ),
            GaugeItemData(
                title = battLabel,
                value = String.format(Locale.US, "%.1f", battDouble),
                unit = "V",
                progress = (battDouble.toFloat() / 16f).coerceIn(0f, 1f),
                color = if (battDouble < 12.0) Color.Red else Color(0xFF4CAF50)
            )
        )

        for (rowItems in gauges.chunked(3)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                for (item in rowItems) {
                    Box(modifier = Modifier.weight(1f)) {
                        CircularGaugeView(item = item)
                    }
                }
            }
        }
    }
}

@Composable
fun AnalogTachometerView(rpm: Int) {
    val maxRPM = 13000f
    val redlineRPM = 10000f
    val animatedRpm by animateFloatAsState(
        targetValue = rpm.toFloat().coerceIn(0f, maxRPM),
        animationSpec = spring(dampingRatio = 0.75f, stiffness = Spring.StiffnessMediumLow),
        label = "rpmNeedle"
    )

    Box(
        modifier = Modifier
            .size(240.dp)
            .clip(CircleShape)
            .background(Color.Black)
            .border(3.dp, Color.Gray.copy(alpha = 0.5f), CircleShape)
            .padding(10.dp),
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val strokeWidth = 12.dp.toPx()
            val arcPadding = strokeWidth / 2f + 10.dp.toPx()
            val arcSize = Size(size.width - arcPadding * 2, size.height - arcPadding * 2)
            val topLeft = Offset(arcPadding, arcPadding)

            drawArc(
                color = Color.White.copy(alpha = 0.08f),
                startAngle = 140f,
                sweepAngle = 260f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )

            val redStart = 140f + (260f * (redlineRPM / maxRPM))
            val redSweep = 260f * (1f - (redlineRPM / maxRPM))
            drawArc(
                color = Color.Red.copy(alpha = 0.35f),
                startAngle = redStart,
                sweepAngle = redSweep,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Butt)
            )

            val progress = (animatedRpm / maxRPM).coerceIn(0f, 1f)
            val activeSweep = 260f * progress
            drawArc(
                color = if (rpm >= redlineRPM.toInt()) Color.Red else CyanAccent,
                startAngle = 140f,
                sweepAngle = activeSweep,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )

            val center = Offset(size.width / 2f, size.height / 2f)
            val outerRadius = (size.minDimension / 2f) - 2.dp.toPx()

            for (tick in 0..13) {
                val fraction = tick / 13f
                val angleDeg = 140f + (fraction * 260f)
                val angleRad = Math.toRadians(angleDeg.toDouble())
                val tickLen = if (tick % 2 == 0) 12.dp.toPx() else 7.dp.toPx()
                val innerTickRadius = outerRadius - tickLen
                val startPt = Offset(
                    x = center.x + (innerTickRadius * cos(angleRad)).toFloat(),
                    y = center.y + (innerTickRadius * sin(angleRad)).toFloat()
                )
                val endPt = Offset(
                    x = center.x + (outerRadius * cos(angleRad)).toFloat(),
                    y = center.y + (outerRadius * sin(angleRad)).toFloat()
                )
                drawLine(
                    color = if (tick >= 10) Color.Red else Color.White,
                    start = startPt,
                    end = endPt,
                    strokeWidth = if (tick % 2 == 0) 3.dp.toPx() else 1.5.dp.toPx()
                )
            }

            // Needle
            val needleAngleDeg = 140f + (progress * 260f)
            val needleRad = Math.toRadians(needleAngleDeg.toDouble())
            val needleLength = (size.minDimension / 2f) - 26.dp.toPx()
            val needleEnd = Offset(
                x = center.x + (needleLength * cos(needleRad)).toFloat(),
                y = center.y + (needleLength * sin(needleRad)).toFloat()
            )
            drawLine(
                color = Color.Red,
                start = center,
                end = needleEnd,
                strokeWidth = 4.dp.toPx(),
                cap = StrokeCap.Round
            )
            drawCircle(
                color = Color.Black,
                radius = 12.dp.toPx(),
                center = center
            )
            drawCircle(
                color = Color.Red,
                radius = 5.dp.toPx(),
                center = center
            )
        }

        // Digital Readout at bottom of tachometer
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "$rpm",
                color = Color.White,
                fontSize = 26.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace
            )
            Text(
                text = "RPM",
                color = Color.Gray,
                fontSize = 11.sp
            )
        }
    }
}

@Composable
fun O2SensorBarView(voltage: Double, loc: LocalizationManager) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(15.dp))
            .background(CardBg)
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = loc.t("lambda_afr"),
            color = Color.Gray,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = String.format(Locale.US, "%.2f V", voltage),
            color = Color.White,
            fontSize = 26.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace
        )

        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(20.dp)
                .clip(RoundedCornerShape(10.dp))
        ) {
            drawRect(
                brush = Brush.horizontalGradient(
                    listOf(Color.Red, Color(0xFF4CAF50), Color(0xFF2196F3))
                ),
                size = size
            )
            val ratio = (voltage / 1.2).coerceIn(0.0, 1.0).toFloat()
            val markerX = (ratio * size.width).coerceIn(4f, size.width - 4f)
            drawLine(
                color = Color.White,
                start = Offset(markerX, 0f),
                end = Offset(markerX, size.height),
                strokeWidth = 4.dp.toPx()
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(loc.t("mix_lean"), color = Color.Red, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
            Text(loc.t("mix_stoich"), color = Color(0xFF4CAF50), fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
            Text(loc.t("mix_rich"), color = Color(0xFF2196F3), fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

data class GaugeItemData(
    val title: String,
    val value: String,
    val unit: String,
    val progress: Float,
    val color: Color
)

@Composable
fun CircularGaugeView(item: GaugeItemData) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(CardBg)
            .padding(vertical = 12.dp, horizontal = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier.size(80.dp),
            contentAlignment = Alignment.Center
        ) {
            Canvas(modifier = Modifier.fillMaxSize().padding(6.dp)) {
                val stroke = 8.dp.toPx()
                drawArc(
                    color = Color.Gray.copy(alpha = 0.3f),
                    startAngle = -90f,
                    sweepAngle = 360f,
                    useCenter = false,
                    style = Stroke(width = stroke, cap = StrokeCap.Round)
                )
                drawArc(
                    color = item.color,
                    startAngle = -90f,
                    sweepAngle = 360f * item.progress.coerceIn(0f, 1f),
                    useCenter = false,
                    style = Stroke(width = stroke, cap = StrokeCap.Round)
                )
            }

            Text(
                text = item.value,
                color = Color.White,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        }

        Text(
            text = item.title,
            color = Color.Gray,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1
        )
        Text(
            text = item.unit,
            color = Color.Gray,
            fontSize = 10.sp
        )
    }
}
