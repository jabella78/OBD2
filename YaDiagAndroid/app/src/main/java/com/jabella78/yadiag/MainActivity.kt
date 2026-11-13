package com.jabella78.yadiag

import android.Manifest
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import com.jabella78.yadiag.core.AIManager
import com.jabella78.yadiag.core.BLEManager
import com.jabella78.yadiag.core.KeychainHelper
import com.jabella78.yadiag.core.LocalizationManager
import com.jabella78.yadiag.core.OBD2Manager
import com.jabella78.yadiag.core.SecurityVault
import com.jabella78.yadiag.ui.ContentView
import com.jabella78.yadiag.ui.CyanAccent
import com.jabella78.yadiag.ui.DarkBg

class MainActivity : ComponentActivity() {

    private lateinit var bleManager: BLEManager
    private lateinit var obdManager: OBD2Manager
    private lateinit var aiManager: AIManager
    private lateinit var localizationManager: LocalizationManager

    private val bluetoothPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { _ ->
        bleManager.startScanning()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Prevent screen dimming/lock while riding or running bench diagnostics
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Initialize Core Security & Storage Singletons
        SecurityVault.init(applicationContext)
        KeychainHelper.init(applicationContext)
        localizationManager = LocalizationManager.getInstance(applicationContext)

        bleManager = BLEManager(applicationContext)
        obdManager = OBD2Manager(applicationContext, bleManager)
        aiManager = AIManager(applicationContext)

        val currentDeploymentId = loadDeploymentId()

        setContent {
            MaterialTheme(
                colorScheme = darkColorScheme(
                    primary = CyanAccent,
                    background = DarkBg,
                    surface = DarkBg
                )
            ) {
                ContentView(
                    bleManager = bleManager,
                    obdManager = obdManager,
                    aiManager = aiManager,
                    loc = localizationManager,
                    currentDeploymentId = currentDeploymentId,
                    onRequestPermissionsAndScan = { requestBluetoothPermissionsAndScan() }
                )
            }
        }
    }

    private fun requestBluetoothPermissionsAndScan() {
        val perms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT
            )
        } else {
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        }
        bluetoothPermissionLauncher.launch(perms)
    }

    private fun loadDeploymentId(): String {
        return try {
            assets.open("deployment_id.txt").bufferedReader().use { it.readText().trim() }
        } catch (_: Exception) {
            "1.2.0"
        }
    }
}
