package com.jabella78.yadiag.core

import android.os.Build
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

data class DiagnosticTelemetryReport(
    val appVersion: String,
    val osVersion: String,
    val deviceModel: String,
    val adapterName: String,
    val isAdapterCertified: Boolean,
    val detectedCANHeaders: List<String>,
    val activeDTCs: List<String>,
    val absDTCs: List<String>,
    val iscStatusSample: String,
    val o2StatusSample: String,
    val throttleDirtLevel: Int,
    val throttleDirtPct: Double,
    val operationType: String?,
    val operationResult: String?
) {
    fun toJsonString(): String {
        val obj = JSONObject()
        obj.put("app_version", appVersion)
        obj.put("os_version", osVersion)
        obj.put("device_model", deviceModel)
        obj.put("adapter_name", adapterName)
        obj.put("is_adapter_certified", isAdapterCertified)
        obj.put("detected_can_headers", JSONArray(detectedCANHeaders))
        obj.put("active_dtcs", JSONArray(activeDTCs))
        obj.put("abs_dtcs", JSONArray(absDTCs))
        obj.put("isc_status_sample", iscStatusSample)
        obj.put("o2_status_sample", o2StatusSample)
        obj.put("throttle_dirt_level", throttleDirtLevel)
        obj.put("throttle_dirt_pct", throttleDirtPct)
        obj.put("operation_type", operationType ?: JSONObject.NULL)
        obj.put("operation_result", operationResult ?: JSONObject.NULL)
        return obj.toString()
    }
}

object TelemetryService {
    var cloudIngestURLString: String = "https://dtucjtuhgtcrkkjjfvcr.supabase.co/rest/v1/telemetry_reports"
    var apiKey: String = "sb_publishable_BefsC-26ZRHndn105jFIKw_g4U-e7t0"

    private val ioScope = CoroutineScope(Dispatchers.IO)

    fun sendCompatibilityTelemetry(
        appVersion: String = "1.0.4 (104)",
        adapterName: String,
        isCertified: Boolean,
        canHeaders: List<String>,
        engineDTCs: List<String> = emptyList(),
        absDTCs: List<String> = emptyList(),
        iscStatus: String = "",
        o2Status: String = "",
        dirtLevel: Int = 0,
        dirtPct: Double = 0.0,
        operationType: String = "dtc_scan",
        operationResult: String = "completed"
    ) {
        if (adapterName.isBlank() || adapterName == "Simulated ELM327") return
        if (cloudIngestURLString.contains("YOUR_PROJECT_ID")) return

        val osVer = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
        val model = "${Build.MANUFACTURER} ${Build.MODEL}".trim()

        val report = DiagnosticTelemetryReport(
            appVersion = appVersion,
            osVersion = osVer,
            deviceModel = model,
            adapterName = adapterName,
            isAdapterCertified = isCertified,
            detectedCANHeaders = canHeaders,
            activeDTCs = engineDTCs,
            absDTCs = absDTCs,
            iscStatusSample = iscStatus,
            o2StatusSample = o2Status,
            throttleDirtLevel = dirtLevel,
            throttleDirtPct = dirtPct,
            operationType = operationType,
            operationResult = operationResult
        )

        ioScope.launch {
            try {
                val url = URL(cloudIngestURLString)
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 8000
                    readTimeout = 8000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("Authorization", "Bearer $apiKey")
                    setRequestProperty("apikey", apiKey)
                    setRequestProperty("Prefer", "return=minimal")
                }

                OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { writer ->
                    writer.write(report.toJsonString())
                    writer.flush()
                }

                conn.responseCode // Esegue la richiesta e chiude silenziosamente
                conn.disconnect()
            } catch (_: Exception) {
                // Fallisce silenziosamente in background come su iOS
            }
        }
    }
}
