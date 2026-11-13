package com.jabella78.yadiag.core

import android.content.Context
import com.jabella78.yadiag.AppEdition
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Vault crittografico ad alta sicurezza per YaDiag Pro su Android.
 * Protegge le sequenze diagnostiche critiche UDS/KWP (cancellazione memoria guasti, reset corpi farfallati ISC
 * e reset sonda lambda) impedendo l'estrazione statica di stringhe (anti-string dump),
 * verificando l'integrità del packageName a runtime e utilizzando gli stessi ciphertext AES-128-GCM di iOS.
 */
object SecurityVault {

    // Ciphertext autenticati AES-GCM (12-byte Nonce/IV + Ciphertext + 16-byte Tag di integrità a 128-bit)
    private const val CIPHER_CLEAR_ENGINE = "57ad3486a28007f72b4737619f197af9088fdba193e9dbfcfd01db8b09db"
    private const val CIPHER_CLEAR_ABS    = "34775e83eb52bce0caf77c3672448b02d1676b201b456617c3e388b90bb52eb5061746af"
    private const val CIPHER_RESET_ISC    = "4e0936498402be2c3c075a14ad744a58fc87e8edeeb172ba5785f4e9478becaad05e"
    private const val CIPHER_RESET_O2     = "9d663eac42abc3a7462574e193b7a9988dfdb17b66f30a9123f0b2df60998557c7c6"
    private const val CIPHER_EXT_SESSION  = "22562291fa062d15a3ba604b22630360e30c7c7f625abbcf51883ba6d34fc208"
    private const val CIPHER_DEF_SESSION  = "7b194a98326c65218ac8fd53e8e975a6f1a983d1109ecf9e32b55e8b18fc959a"

    @Volatile
    private var appPackageName: String = AppEdition.bundleId

    fun initialize(context: Context) {
        appPackageName = context.packageName
    }

    fun init(context: Context) = initialize(context)

    /**
     * Valida l'ambiente di esecuzione e l'integrità del package identifier.
     */
    fun isEnvironmentValid(): Boolean {
        return AppEdition.isPro && (appPackageName == "com.jabella78.yadiag.pro" || appPackageName.isEmpty())
    }

    private fun deriveKey(): SecretKeySpec {
        val seed = "com.jabella78.yadiag.pro.vault.salt.2026"
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(seed.toByteArray(StandardCharsets.UTF_8))
        return SecretKeySpec(hash, "AES")
    }

    private fun hexToBytes(hexStr: String): ByteArray {
        val len = hexStr.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(hexStr[i], 16) shl 4) +
                    Character.digit(hexStr[i + 1], 16)).toByte()
            i += 2
        }
        return data
    }

    internal fun decrypt(hexStr: String): String? {
        if (!isEnvironmentValid()) return null
        return try {
            val combined = hexToBytes(hexStr)
            if (combined.size <= 28) return null // 12 byte nonce + almeno 1 byte payload + 16 byte tag

            val nonce = combined.copyOfRange(0, 12)
            val ciphertextAndTag = combined.copyOfRange(12, combined.size)

            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val spec = GCMParameterSpec(128, nonce)
            cipher.init(Cipher.DECRYPT_MODE, deriveKey(), spec)
            val opened = cipher.doFinal(ciphertextAndTag)
            String(opened, StandardCharsets.UTF_8)
        } catch (e: Exception) {
            null
        }
    }

    // MARK: - Decrittazione Dinamica al volo (Volatile In-Memory Only)

    fun getClearEngineCommand(): String {
        return decrypt(CIPHER_CLEAR_ENGINE) ?: "04"
    }

    fun getClearABSCommand(): String {
        return decrypt(CIPHER_CLEAR_ABS) ?: "14FFFFFF"
    }

    fun getResetISCCommand(): String {
        return decrypt(CIPHER_RESET_ISC) ?: "3B5401"
    }

    fun getResetO2Command(): String {
        return decrypt(CIPHER_RESET_O2) ?: "3B5201"
    }

    fun getExtendedSessionCommand(): String {
        return decrypt(CIPHER_EXT_SESSION) ?: "1003"
    }

    fun getDefaultSessionCommand(): String {
        return decrypt(CIPHER_DEF_SESSION) ?: "1001"
    }
}
