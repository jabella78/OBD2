# YaDiag Android (Free & Pro)

Progetto nativo Android (**Kotlin + Jetpack Compose**) per **YaDiag Free** e **YaDiag Pro**, con parità funzionale 1:1 rispetto alle app iOS/macOS (`YaDiagFree.swiftpm` e `YaDiagPro.swiftpm`).

## Architettura & Product Flavors

Il progetto utilizza un singolo codice sorgente condiviso con **Gradle Product Flavors** configurati in [`app/build.gradle.kts`](app/build.gradle.kts):

| Caratteristica | Flavor `free` (`YaDiag Free`) | Flavor `pro` (`YaDiag Pro`) |
|---|---|---|
| **Application ID** | `com.jabella78.yadiag.free` | `com.jabella78.yadiag.pro` |
| **AppEdition.isPro** | `false` | `true` |
| **SecurityVault (AES-GCM)** | Disabilitato (doppio controllo package + firma) | Attivo (`com.jabella78.yadiag.pro`) |
| **Cruscotto Live & Simulatore** | ✅ | ✅ |
| **Lettura DTC Motore & ABS + AI** | ✅ | ✅ |
| **Lettura ISC (`0x54`), O2 (`0x52`), CO (`0x40..0x42`)** | ✅ | ✅ |
| **Cancellazione DTC (Motore `04` / ABS `14FFFFFF`)** | 🔒 Mostra popup upgrade a Pro | ✅ Sbloccato |
| **Reset Adattivi KWP2000 (Cod. 67 ISC & Cod. 87 O2)** | 🔒 Mostra popup upgrade a Pro | ✅ Sbloccato |
| **Certificato PDF A4 & Guida Reset Tagliando** | 🔒 Riservato a Pro | ✅ Sbloccato |

## Connettività Bluetooth Dual-Mode (BLE + Classic SPP)

Su Android [`BLEManager.kt`](app/src/main/java/com/jabella78/yadiag/core/BLEManager.kt) supporta nativamente:
1. **Bluetooth Low Energy (BLE GATT)**: UUID standard `FFF0`, `FFE0`, `E7810A71-...`, `18F0` con negoziazione `requestMtu(512)` per frame ISO-TP multi-linea.
2. **Bluetooth Classic SPP (RFCOMM)**: UUID `00001101-0000-1000-8000-00805F9B34FB` per adattatori associati nelle impostazioni Bluetooth di Android (es. OBDLink MX, Vgate Bluetooth 3.0).
3. **Simulatore Virtuale Integrato**: per test completi a banco senza connessione alla moto.

## Compilazione APK e Android App Bundle (AAB)

### Da Android Studio
1. Apri la cartella `YaDiagAndroid` in **Android Studio (Ladybug / Meerkat o successivo)**.
2. Apri il pannello **Build Variants** e seleziona:
   - `freeDebug` o `freeRelease` per **YaDiag Free**
   - `proDebug` o `proRelease` per **YaDiag Pro**
3. Usa **Build > Generate Signed App Bundle / APK...** per generare i pacchetti per Google Play Store.

### Da Terminale
```bash
cd YaDiagAndroid
# Compila APK Debug per entrambe le edizioni
./gradlew assembleFreeDebug assembleProDebug

# Compila Android App Bundle (.aab) Release per Google Play Store
./gradlew bundleFreeRelease bundleProRelease
```

### Sincronizzazione Automatica con iOS/macOS
Eseguendo [`../build.sh`](../build.sh) o [`../build_android.sh`](../build_android.sh) dalla root del repository, il database errori (`dtc_database.json`), il logo (`yadiag_logo.png`), il `deployment_id.txt` e il numero di versione vengono sincronizzati automaticamente dentro `YaDiagAndroid`.
