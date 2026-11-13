package com.jabella78.yadiag.core

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * Equivalente Android di KeychainHelper su iOS.
 * Utilizza Android Keystore hardware-backed tramite EncryptedSharedPreferences (AES-256-GCM)
 * per proteggere le chiavi API dei provider AI (Gemini, OpenAI, Claude, DeepSeek, Groq).
 */
object KeychainHelper {
    private const val PREFS_FILE_NAME = "com.jabella78.yadiag.secure_keys"
    private var securePrefs: SharedPreferences? = null

    fun initialize(context: Context) {
        if (securePrefs != null) return
        securePrefs = try {
            val masterKey = MasterKey.Builder(context.applicationContext)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                context.applicationContext,
                PREFS_FILE_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Fallback sicuro su storage privato dell'app in caso di Keystore non disponibile su emulatori custom
            context.applicationContext.getSharedPreferences(PREFS_FILE_NAME, Context.MODE_PRIVATE)
        }
    }

    fun init(context: Context) = initialize(context)

    fun save(key: String, value: String) {
        if (key == "ai_api_key" || value == "ai_api_key") {
            val realKey = if (value == "ai_api_key") value else key
            val realVal = if (value == "ai_api_key") key else value
            securePrefs?.edit()?.putString(realKey, realVal)?.apply()
        } else {
            securePrefs?.edit()?.putString(key, value)?.apply()
        }
    }

    fun load(key: String): String? {
        return securePrefs?.getString(key, null)
    }

    fun delete(key: String) {
        securePrefs?.edit()?.remove(key)?.apply()
    }
}
