# Regole R8 / ProGuard per YaDiag Free & YaDiag Pro
-keepattributes *Annotation*,InnerClasses,Signature,EnclosingMethod

# Protezione e offuscamento SecurityVault
-keepclassmembers class com.jabella78.yadiag.core.SecurityVault {
    public *;
}

# Mantiene i modelli JSON per DTC e Telemetria
-keep class com.jabella78.yadiag.core.DTCLocalizedEntry { *; }
-keep class com.jabella78.yadiag.core.DiagnosticTelemetryReport { *; }

# Regole per Google Tink / AndroidX Security Crypto (EncryptedSharedPreferences)
-dontwarn com.google.crypto.tink.**
-dontwarn javax.annotation.**
-dontwarn com.google.errorprone.annotations.**
-keepclassmembers class * extends com.google.crypto.tink.shaded.protobuf.GeneratedMessageLite {
    <fields>;
}
