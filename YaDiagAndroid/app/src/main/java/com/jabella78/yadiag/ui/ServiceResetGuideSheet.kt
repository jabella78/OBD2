package com.jabella78.yadiag.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jabella78.yadiag.core.AppLanguage
import com.jabella78.yadiag.core.LocalizationManager

data class ServiceProcedureModel(
    val id: String,
    val familyName: String,
    val years: String,
    val dashboardType: String,
    val indicators: List<String>,
    val steps: List<String>,
    val note: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServiceResetGuideSheet(
    loc: LocalizationManager,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var searchText by remember { mutableStateOf("") }
    val lang = loc.currentLanguage
    val allModels = remember(lang) { getServiceProcedures(lang) }
    val filteredModels = remember(searchText, allModels) {
        if (searchText.isBlank()) allModels
        else allModels.filter {
            it.familyName.contains(searchText, ignoreCase = true) ||
                it.years.contains(searchText, ignoreCase = true) ||
                it.dashboardType.contains(searchText, ignoreCase = true)
        }
    }

    val navTitle = when (lang) {
        AppLanguage.ENGLISH -> "Service Reset Guide"
        AppLanguage.ITALIAN -> "Guida Reset Tagliando"
        AppLanguage.FRENCH -> "Guide Reset Entretien"
        AppLanguage.SPANISH -> "Guía Reset Mantenimiento"
        AppLanguage.GERMAN -> "Service-Reset-Anleitung"
    }

    val headerTitle = when (lang) {
        AppLanguage.ENGLISH -> "Service & Dashboard Indicators Reset"
        AppLanguage.ITALIAN -> "Reset Tagliando & Spie Cruscotto"
        AppLanguage.FRENCH -> "Réinitialisation Entretien & Voyants"
        AppLanguage.SPANISH -> "Reinicio de Servicio y Testigos"
        AppLanguage.GERMAN -> "Service- & Kontrollleuchten-Reset"
    }

    val headerDesc = when (lang) {
        AppLanguage.ENGLISH -> "On all Yamaha motorcycles and scooters, maintenance counters (Oil Trip, Service wrench, V-Belt) are stored internally in dashboard instrument cluster EEPROM. Follow the official manual button sequence for your model:"
        AppLanguage.ITALIAN -> "Su tutte le moto e gli scooter Yamaha, il conteggio chilometrico dei tagliandi (Oil Trip, chiave inglese, V-Belt) è memorizzato internamente nella memoria della strumentazione. Segui la procedura ufficiale manuale dal cruscotto per il tuo modello:"
        AppLanguage.FRENCH -> "Sur toutes les motos et scooters Yamaha, les compteurs d'entretien (Oil Trip, clé de vidange, V-Belt) sont stockés dans la mémoire du tableau de bord. Suivez la séquence manuelle officielle pour votre modèle :"
        AppLanguage.SPANISH -> "En todas las motocicletas y scooters Yamaha, los contadores de mantenimiento (Oil Trip, llave inglesa, V-Belt) se guardan internamente en el cuadro de instrumentos. Sigue la secuencia oficial desde el tablero para tu modelo:"
        AppLanguage.GERMAN -> "Bei allen Yamaha-Motorrädern und Rollern werden Wartungszähler (Oil Trip, Schraubenschlüssel, V-Belt) intern im Cockpit-Speicher abgelegt. Befolgen Sie die offizielle Tastenfolge für Ihr Modell:"
    }

    val searchPlaceholder = when (lang) {
        AppLanguage.ENGLISH -> "Search model (e.g. Tracer, MT-07, TMAX)..."
        AppLanguage.ITALIAN -> "Cerca modello (es. Tracer, MT-07, TMAX)..."
        AppLanguage.FRENCH -> "Rechercher un modèle (ex. Tracer, MT-07, TMAX)..."
        AppLanguage.SPANISH -> "Buscar modelo (ej. Tracer, MT-07, TMAX)..."
        AppLanguage.GERMAN -> "Modell suchen (z.B. Tracer, MT-07, TMAX)..."
    }

    val indicatorsLabel = when (lang) {
        AppLanguage.ENGLISH -> "Affected Indicators:"
        AppLanguage.ITALIAN -> "Spie interessate:"
        AppLanguage.FRENCH -> "Voyants concernés :"
        AppLanguage.SPANISH -> "Testigos afectados:"
        AppLanguage.GERMAN -> "Betroffene Anzeigen:"
    }

    val stepsLabel = when (lang) {
        AppLanguage.ENGLISH -> "Official Step-by-Step Procedure:"
        AppLanguage.ITALIAN -> "Procedura Ufficiale Passo-Passo:"
        AppLanguage.FRENCH -> "Procédure Officielle Étape par Étape :"
        AppLanguage.SPANISH -> "Procedimiento Oficial Paso a Paso:"
        AppLanguage.GERMAN -> "Offizieller Schritt-für-Schritt-Ablauf:"
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color(0xFF0D111A),
        contentColor = Color.White
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Top Bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(
                        imageVector = Icons.Default.Build,
                        contentDescription = null,
                        tint = Color(0xFFFF9800),
                        modifier = Modifier.size(26.dp)
                    )
                    Column {
                        Text(
                            text = navTitle,
                            color = Color.White,
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Black
                        )
                        Text(
                            text = headerTitle,
                            color = Color.Gray,
                            fontSize = 11.sp
                        )
                    }
                }
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.Gray)
                }
            }

            // Technical explanation banner
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color(0xFFFF9800).copy(alpha = 0.1f))
                    .border(1.dp, Color(0xFFFF9800).copy(alpha = 0.3f), RoundedCornerShape(12.dp))
                    .padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = headerDesc,
                    color = Color.White.copy(alpha = 0.85f),
                    fontSize = 12.sp,
                    lineHeight = 16.sp
                )
            }

            // Search Bar
            OutlinedTextField(
                value = searchText,
                onValueChange = { searchText = it },
                placeholder = { Text(searchPlaceholder, color = Color.Gray, fontSize = 13.sp) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = Color.Gray) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = CyanAccent,
                    unfocusedBorderColor = Color.White.copy(alpha = 0.15f),
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                )
            )

            // Scrollable Procedures List
            val scrollState = rememberScrollState()
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .verticalScroll(scrollState),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                filteredModels.forEach { item ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(16.dp))
                            .background(CardBg)
                            .border(1.dp, Color.White.copy(alpha = 0.08f), RoundedCornerShape(16.dp))
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.Top
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = item.familyName,
                                    color = CyanAccent,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "${item.years} • ${item.dashboardType}",
                                    color = Color.Gray,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }

                        // Indicator Badges
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = indicatorsLabel,
                                color = Color.Gray,
                                fontSize = 11.sp
                            )
                            item.indicators.forEach { badge ->
                                Text(
                                    text = badge,
                                    color = Color(0xFFFF9800),
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(6.dp))
                                        .background(Color(0xFFFF9800).copy(alpha = 0.15f))
                                        .padding(horizontal = 6.dp, vertical = 3.dp)
                                )
                            }
                        }

                        Divider(color = Color.White.copy(alpha = 0.1f))

                        Text(
                            text = stepsLabel,
                            color = Color.White,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )

                        // Numbered Steps
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            item.steps.forEachIndexed { idx, step ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    verticalAlignment = Alignment.Top,
                                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(22.dp)
                                            .clip(CircleShape)
                                            .background(CyanAccent.copy(alpha = 0.2f)),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = "${idx + 1}",
                                            color = CyanAccent,
                                            fontSize = 11.sp,
                                            fontWeight = FontWeight.Bold
                                        )
                                    }
                                    Text(
                                        text = step,
                                        color = Color.White.copy(alpha = 0.9f),
                                        fontSize = 12.sp,
                                        lineHeight = 17.sp,
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                        }

                        if (item.note.isNotEmpty()) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFFFEB3B).copy(alpha = 0.08f))
                                    .padding(10.dp),
                                verticalAlignment = Alignment.Top,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Warning,
                                    contentDescription = null,
                                    tint = Color(0xFFFFEB3B),
                                    modifier = Modifier.size(16.dp)
                                )
                                Text(
                                    text = item.note,
                                    color = Color(0xFFFFEB3B).copy(alpha = 0.9f),
                                    fontSize = 11.sp,
                                    lineHeight = 15.sp
                                )
                            }
                        }
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

private fun getServiceProcedures(language: AppLanguage): List<ServiceProcedureModel> {
    return when (language) {
        AppLanguage.ITALIAN -> listOf(
            ServiceProcedureModel(
                id = "cp3_lcd",
                familyName = "Tracer 900 / GT & MT-09 (2015–2020)",
                years = "CP3 847cc Euro 4",
                dashboardType = "Display Digitale LCD & TFT GT",
                indicators = listOf("Spia Chiave Inglese", "OIL TRIP"),
                steps = listOf(
                    "Ruota la chiave su ON a motore spento (interruttore d'arresto su RUN).",
                    "Premi il tasto SELECT sul cruscotto (o la rotellina sul manubrio della GT) fino a visualizzare la schermata dell'indicatore 'OIL TRIP' o dell'intervallo di manutenzione.",
                    "Tieni premuto il pulsante RESET (o rotellina) per almeno 3 secondi: il valore dei chilometri o la spia inizierà a lampeggiare velocemente.",
                    "Mentre il valore lampeggia, rilascia e tieni premuto nuovamente il tasto RESET per altri 2-3 secondi.",
                    "Il contatore si azzererà su '0.0 km' e la spia di manutenzione si spegnerà confermando l'avvenuto reset."
                ),
                note = "Se lasci trascorrere più di 5 secondi mentre il valore lampeggia senza confermare, la modalità si disattiva e dovrai ripetere la sequenza."
            ),
            ServiceProcedureModel(
                id = "cp3_tft",
                familyName = "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                years = "CP3 890cc Euro 5",
                dashboardType = "Doppio Display TFT a Colori 3.5\"",
                indicators = listOf("Icona Tagliando", "Manutenzione Olio / Annuale"),
                steps = listOf(
                    "Accendi il quadro con chiave su ON (motore rigorosamente spento).",
                    "Premi verso l'interno la rotellina multifunzione destra sul manubrio per accedere al Menu Principale.",
                    "Ruota la rotellina fino alla voce 'Maintenance' (Manutenzione) e premila per entrare.",
                    "Seleziona la voce desiderata tra 'Oil' (Cambio Olio) oppure 'Annual' (Intervallo Annuale).",
                    "Evidenzia l'opzione 'Reset' e tieni premuta la rotellina verso l'interno per 2 secondi fino al messaggio di conferma."
                ),
                note = "Nelle versioni con radar GT+, la voce di manutenzione si sincronizza automaticamente anche con il cruise control adattivo."
            ),
            ServiceProcedureModel(
                id = "cp2_all",
                familyName = "MT-07 / Tracer 7 / XSR700 / R7",
                years = "CP2 689cc Euro 4 / Euro 5",
                dashboardType = "Display LCD Compatto Multifunzione",
                indicators = listOf("OIL TRIP", "Spia Cambio Olio"),
                steps = listOf(
                    "Gira la chiave su ON a motore spento.",
                    "Premi il tasto sinistro della strumentazione (SELECT) fino a selezionare il display parziale 'OIL TRIP'.",
                    "Tieni premuto il tasto destro (RESET) per 3 secondi finché il chilometraggio non inizia a lampeggiare sul display.",
                    "Con i numeri lampeggianti, premi e mantieni premuto ancora il tasto RESET per altri 3 secondi.",
                    "Il chilometraggio verrà azzerato a '0.0' e la spia si spegnerà."
                ),
                note = "L'intervallo standard Yamaha per il cambio olio sul motore CP2 è impostato a 1.000 km per il primo rodaggio e successivamente ogni 10.000 km."
            ),
            ServiceProcedureModel(
                id = "tenere_700",
                familyName = "Ténéré 700 / Rally / World Raid",
                years = "CP2 689cc Adventure",
                dashboardType = "Display LCD Verticale / Nuovo TFT Verticale 5\"",
                indicators = listOf("OIL TRIP", "Service Icon"),
                steps = listOf(
                    "Versione LCD classico (2019–2022): Con quadro su ON, scorri con il tasto SELECT fino a 'OIL TRIP'. Tieni premuto RESET per 3 secondi finché lampeggia, poi ripremi RESET per 3 secondi.",
                    "Versione TFT a colori (2023+): Premi la rotellina sul blocchetto destro per entrare nel menu delle impostazioni.",
                    "Scorri fino a 'Maintenance' ➔ Seleziona 'Oil Service'.",
                    "Tieni premuto il tasto centrale per azzerare il chilometraggio parziale fino al segnale di conferma."
                ),
                note = "Sulla World Raid con doppio serbatoio, il reset del service non influisce sul calcolo dei consumi dei singoli serbatoi."
            ),
            ServiceProcedureModel(
                id = "tmax_530_560",
                familyName = "TMAX 530 / TMAX 560",
                years = "Maxi Scooter Bicilindrico (2017+)",
                dashboardType = "Doppio Quadrante Analogico + TFT Centrale",
                indicators = listOf("Spia 'OIL'", "Spia 'V-BELT' (20.000 km)"),
                steps = listOf(
                    "Gira la chiave su ON (motore spento, cavalletto centrale inserito).",
                    "Premi il tasto TRIP/INFO al manubrio fino a visualizzare la schermata dell'indicatore 'OIL TRIP' oppure 'V-BELT TRIP' (a seconda della spia accesa).",
                    "Tieni premuto il pulsante RESET sul cruscotto o al manubrio per 3-4 secondi fino a far lampeggiare la scritta.",
                    "Rilascia il pulsante e tieni nuovamente premuto RESET per altri 3 secondi.",
                    "L'indicatore tornerà a 0 e la spia sul quadro strumenti si spegnerà definitivamente."
                ),
                note = "⚠️ Attenzione: La spia V-BELT si accende ogni 20.000 km. Resettarla solo dopo aver effettivamente verificato o sostituito la cinghia di trasmissione trapezoidale!"
            ),
            ServiceProcedureModel(
                id = "xmax_nmax",
                familyName = "XMAX 125 / 300 / 400",
                years = "Sport Scooter Blue Core",
                dashboardType = "Display LCD Multifunzione Centrale",
                indicators = listOf("OIL CHANGE", "V-BELT TRIP"),
                steps = listOf(
                    "Ruota il selettore Smart Key o la chiave su ON a motore spento.",
                    "Premi il pulsante TRIP sul manubrio fino a selezionare 'OIL TRIP' (o 'V-BELT TRIP').",
                    "Premi e mantieni premuto il pulsante RESET per almeno 3 secondi fino a quando il numero dei chilometri non comincia a lampeggiare.",
                    "Rilascia per un istante e tieni premuto nuovamente il tasto RESET per altri 3 secondi fino a visualizzare '0'.",
                    "La spia di avviso si spegnerà automaticamente."
                ),
                note = "Il primo reset dell'olio compare a 1.000 km, i successivi ogni 5.000 km."
            ),
            ServiceProcedureModel(
                id = "cp4_r1_mt10",
                familyName = "YZF-R1 / R1M & MT-10 (2015+)",
                years = "CP4 998cc Crossplane Superbike",
                dashboardType = "TFT Racing a Colori ad Alta Definizione",
                indicators = listOf("Maintenance Warning", "Oil Service"),
                steps = listOf(
                    "Ruota la chiave su ON con motore fermo.",
                    "Tenere premuta la rotellina multifunzione destra sul manubrio per 2 secondi per accedere al menu 'System Settings'.",
                    "Ruotare la rotellina fino a 'Maintenance' e premere per accedere alla lista componenti.",
                    "Selezionare l'intervallo interessato ('Engine Oil', 'Oil Filter' o 'General Service').",
                    "Premere a fondo la rotellina su 'Reset' e confermare alla richiesta del pop-up."
                ),
                note = "Sulle R1M con sospensioni elettroniche Öhlins, l'intervallo di manutenzione include anche il check della taratura idraulica."
            )
        )

        AppLanguage.FRENCH -> listOf(
            ServiceProcedureModel(
                id = "cp3_lcd",
                familyName = "Tracer 900 / GT & MT-09 (2015–2020)",
                years = "CP3 847cc Euro 4",
                dashboardType = "Écran LCD Numérique & TFT GT",
                indicators = listOf("Clé d'Entretien", "OIL TRIP"),
                steps = listOf(
                    "Mettez le contact sur ON, moteur coupé (coupe-circuit sur RUN).",
                    "Appuyez sur le bouton SELECT au compteur (ou la molette au guidon de la GT) jusqu'à afficher l'écran 'OIL TRIP'.",
                    "Maintenez le bouton RESET enfoncé pendant 3 secondes : le kilométrage commence à clignoter rapidement.",
                    "Pendant le clignotement, relâchez puis maintenez à nouveau RESET enfoncé pendant 2 à 3 secondes.",
                    "Le compteur se remet à '0.0 km' et le témoin de révision s'éteint."
                ),
                note = "Si plus de 5 secondes s'écoulent sans confirmer pendant le clignotement, la procédure est annulée."
            ),
            ServiceProcedureModel(
                id = "cp3_tft",
                familyName = "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                years = "CP3 890cc Euro 5",
                dashboardType = "Double Écran TFT Couleur 3.5\"",
                indicators = listOf("Icône Entretien", "Vidange Huile / Annuel"),
                steps = listOf(
                    "Mettez le contact sur ON (moteur coupé).",
                    "Poussez la molette droite du guidon vers l'intérieur pour ouvrir le Menu Principal.",
                    "Faites défiler jusqu'à 'Maintenance' (Entretien) et validez en appuyant.",
                    "Sélectionnez la ligne souhaitée : 'Oil' (Vidange) ou 'Annual' (Entretien Annuel).",
                    "Mettez en surbrillance 'Reset' et maintenez la molette enfoncée 2 secondes pour confirmer."
                ),
                note = "Sur les modèles GT+ équipés de radar, l'entretien est synchronisé avec le régulateur adaptatif."
            ),
            ServiceProcedureModel(
                id = "cp2_all",
                familyName = "MT-07 / Tracer 7 / XSR700 / R7",
                years = "CP2 689cc Euro 4 / Euro 5",
                dashboardType = "Écran LCD Compact",
                indicators = listOf("OIL TRIP", "Témoin Vidange"),
                steps = listOf(
                    "Mettez le contact sur ON, moteur coupé.",
                    "Appuyez sur SELECT jusqu'à afficher 'OIL TRIP'.",
                    "Maintenez RESET enfoncé pendant 3 secondes jusqu'au clignotement des chiffres.",
                    "Pendant le clignotement, maintenez à nouveau RESET enfoncé pendant 3 secondes.",
                    "Le compteur affiche '0.0' et le témoin s'éteint."
                ),
                note = "L'intervalle d'huile standard CP2 est à 1 000 km (rodage) puis tous les 10 000 km."
            ),
            ServiceProcedureModel(
                id = "tmax_530_560",
                familyName = "TMAX 530 / TMAX 560",
                years = "Maxi Scooter Bicylindre (2017+)",
                dashboardType = "Double Cadran Analogique + TFT Central",
                indicators = listOf("Témoin 'OIL'", "Témoin 'V-BELT' (20 000 km)"),
                steps = listOf(
                    "Mettez le contact sur ON (moteur coupé, sur béquille centrale).",
                    "Appuyez sur TRIP/INFO au guidon jusqu'à afficher 'OIL TRIP' ou 'V-BELT TRIP'.",
                    "Maintenez RESET enfoncé 3 à 4 secondes jusqu'au clignotement.",
                    "Relâchez puis maintenez à nouveau RESET pendant 3 secondes.",
                    "Le compteur revient à 0 et le voyant s'éteint."
                ),
                note = "⚠️ Attention : Le témoin V-BELT s'allume tous les 20 000 km. Ne le réinitialisez qu'après avoir vérifié ou remplacé la courroie."
            )
        )

        AppLanguage.SPANISH -> listOf(
            ServiceProcedureModel(
                id = "cp3_lcd",
                familyName = "Tracer 900 / GT & MT-09 (2015–2020)",
                years = "CP3 847cc Euro 4",
                dashboardType = "Pantalla LCD Digital y TFT GT",
                indicators = listOf("Llave de Servicio", "OIL TRIP"),
                steps = listOf(
                    "Gira la llave a la posición ON con motor apagado (interruptor en RUN).",
                    "Pulsa el botón SELECT en el cuadro (o la rueda del manillar en la GT) hasta ver 'OIL TRIP'.",
                    "Mantén pulsado RESET durante 3 segundos: los kilómetros empezarán a parpadear rápidamente.",
                    "Mientras parpadea, suelta y vuelve a mantener pulsado RESET durante 2 a 3 segundos.",
                    "El contador volverá a '0.0 km' y el testigo de servicio se apagará."
                ),
                note = "Si pasan más de 5 segundos sin confirmar durante el parpadeo, la función se cancela."
            ),
            ServiceProcedureModel(
                id = "cp3_tft",
                familyName = "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                years = "CP3 890cc Euro 5",
                dashboardType = "Doble Pantalla TFT a Color 3.5\"",
                indicators = listOf("Icono Llave", "Aceite / Anual"),
                steps = listOf(
                    "Pon el contacto en ON (motor rigurosamente apagado).",
                    "Presiona hacia adentro la rueda derecha del manillar para abrir el Menú Principal.",
                    "Gira hasta 'Maintenance' (Mantenimiento) y pulsa para entrar.",
                    "Selecciona 'Oil' (Aceite) o 'Annual' (Revisión Anual).",
                    "Resalta 'Reset' y mantén pulsada la rueda hacia adentro 2 segundos para confirmar."
                ),
                note = "En las versiones GT+ con radar, el mantenimiento se sincroniza con el control de crucero adaptativo."
            ),
            ServiceProcedureModel(
                id = "cp2_all",
                familyName = "MT-07 / Tracer 7 / XSR700 / R7",
                years = "CP2 689cc Euro 4 / Euro 5",
                dashboardType = "Pantalla LCD Compacta",
                indicators = listOf("OIL TRIP", "Testigo Cambio Aceite"),
                steps = listOf(
                    "Gira la llave a ON con motor apagado.",
                    "Pulsa SELECT en el panel hasta que aparezca 'OIL TRIP'.",
                    "Mantén pulsado RESET durante 3 segundos hasta que el kilometraje parpadee.",
                    "Mientras parpadea, vuelve a mantener pulsado RESET durante 3 segundos.",
                    "El indicador se reinicia a '0.0' y la luz se apaga."
                ),
                note = "Intervalo oficial de cambio de aceite CP2: 1.000 km rodaje, luego cada 10.000 km."
            ),
            ServiceProcedureModel(
                id = "tmax_530_560",
                familyName = "TMAX 530 / TMAX 560",
                years = "Maxi Scooter Bicilíndrico (2017+)",
                dashboardType = "Esferas Analógicas + TFT Central",
                indicators = listOf("Testigo 'OIL'", "Testigo 'V-BELT' (20.000 km)"),
                steps = listOf(
                    "Pon el contacto en ON (motor apagado, en caballete central).",
                    "Pulsa TRIP/INFO en el manillar hasta ver 'OIL TRIP' o 'V-BELT TRIP'.",
                    "Mantén pulsado RESET durante 3–4 segundos hasta que parpadee.",
                    "Suelta y vuelve a mantener pulsado RESET durante 3 segundos.",
                    "El contador vuelve a 0 y el testigo se apaga."
                ),
                note = "⚠️ Atención: El testigo V-BELT se enciende cada 20.000 km. Reiniciar únicamente tras revisar o sustituir la correa de transmisión."
            )
        )

        AppLanguage.GERMAN -> listOf(
            ServiceProcedureModel(
                id = "cp3_lcd",
                familyName = "Tracer 900 / GT & MT-09 (2015–2020)",
                years = "CP3 847cc Euro 4",
                dashboardType = "Digitales LCD- & GT TFT-Display",
                indicators = listOf("Schraubenschlüssel-Symbol", "OIL TRIP"),
                steps = listOf(
                    "Zündung auf ON drehen bei stehendem Motor (Killschalter auf RUN).",
                    "SELECT-Taste am Cockpit drücken (oder Daumenrad bei GT), bis 'OIL TRIP' angezeigt wird.",
                    "RESET-Taste (oder Daumenrad) mindestens 3 Sekunden gedrückt halten: Die Kilometeranzeige blinkt schnell.",
                    "Während des Blinkens loslassen und erneut RESET für 2–3 Sekunden gedrückt halten.",
                    "Der Zähler springt auf '0.0 km' und die Service-Warnleuchte erlischt."
                ),
                note = "Verstreichen mehr als 5 Sekunden ohne Bestätigung während des Blinkens, wird der Vorgang abgebrochen."
            ),
            ServiceProcedureModel(
                id = "cp3_tft",
                familyName = "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                years = "CP3 890cc Euro 5",
                dashboardType = "Doppel-3.5\" Vollfarb-TFT",
                indicators = listOf("Service-Schlüssel", "Öl- / Jahreswartung"),
                steps = listOf(
                    "Zündung auf ON schalten (Motor aus).",
                    "Rechtes Lenkerrad nach innen drücken, um das Hauptmenü zu öffnen.",
                    "Zu 'Maintenance' (Wartung) scrollen und bestätigen.",
                    "Gewünschten Eintrag wählen: 'Oil' (Ölwechsel) oder 'Annual' (Jahresinspektion).",
                    "'Reset' markieren und das Rad 2 Sekunden lang gedrückt halten."
                ),
                note = "Bei GT+ Radar-Modellen synchronisiert sich der Service-Status automatisch mit dem Abstandstempomat."
            ),
            ServiceProcedureModel(
                id = "cp2_all",
                familyName = "MT-07 / Tracer 7 / XSR700 / R7",
                years = "CP2 689cc Euro 4 / Euro 5",
                dashboardType = "Kompaktes Multifunktions-LCD",
                indicators = listOf("OIL TRIP", "Ölwechselanzeige"),
                steps = listOf(
                    "Zündung auf ON schalten bei stehendem Motor.",
                    "SELECT-Taste drücken, bis 'OIL TRIP' erscheint.",
                    "RESET-Taste 3 Sekunden gedrückt halten, bis die Kilometeranzeige blinkt.",
                    "Während des Blinkens RESET erneut für 3 Sekunden gedrückt halten.",
                    "Der Zähler springt auf '0.0' und die Leuchte erlischt."
                ),
                note = "Standard-Intervall für CP2: 1.000 km Einfahrservice, danach alle 10.000 km."
            ),
            ServiceProcedureModel(
                id = "tmax_530_560",
                familyName = "TMAX 530 / TMAX 560",
                years = "Zweizylinder-Maxi-Roller (2017+)",
                dashboardType = "Analoginstrumente + Zentral-TFT",
                indicators = listOf("'OIL'-Leuchte", "'V-BELT'-Leuchte (20.000 km)"),
                steps = listOf(
                    "Zündung auf ON (Motor aus, auf Hauptständer).",
                    "TRIP/INFO am Lenker drücken, bis 'OIL TRIP' oder 'V-BELT TRIP' erscheint.",
                    "RESET-Taste 3–4 Sekunden gedrückt halten, bis die Anzeige blinkt.",
                    "Loslassen und erneut 3 Sekunden lang RESET gedrückt halten.",
                    "Der Zähler wird auf 0 gesetzt und die Warnleuchte erlischt."
                ),
                note = "⚠️ Vorsicht: V-BELT leuchtet alle 20.000 km auf. Nur nach tatsächlicher Riemenprüfung bzw. Wechsel zurücksetzen."
            )
        )

        AppLanguage.ENGLISH -> listOf(
            ServiceProcedureModel(
                id = "cp3_lcd",
                familyName = "Tracer 900 / GT & MT-09 (2015–2020)",
                years = "CP3 847cc Euro 4",
                dashboardType = "Digital LCD & GT TFT Display",
                indicators = listOf("Wrench Icon", "OIL TRIP"),
                steps = listOf(
                    "Turn the ignition key to ON with engine stopped (engine stop switch set to RUN).",
                    "Press the SELECT button on the meter (or the handlebar thumbwheel on GT) until the 'OIL TRIP' or maintenance interval screen is displayed.",
                    "Press and hold the RESET button (or thumbwheel) for at least 3 seconds: the mileage display or wrench icon will start flashing rapidly.",
                    "While it is flashing, release and press and hold the RESET button again for 2–3 seconds.",
                    "The counter will reset to '0.0 km' and the maintenance warning light will turn off."
                ),
                note = "If more than 5 seconds elapse while flashing without confirming, reset mode exits and you must repeat the sequence."
            ),
            ServiceProcedureModel(
                id = "cp3_tft",
                familyName = "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                years = "CP3 890cc Euro 5",
                dashboardType = "Dual 3.5\" Full-Color TFT",
                indicators = listOf("Service Wrench", "Oil / Annual Maintenance"),
                steps = listOf(
                    "Turn the ignition key to ON (engine strictly stopped).",
                    "Push the right handlebar multi-function wheel inwards to open the Main Menu.",
                    "Scroll the wheel to 'Maintenance' and press inwards to enter.",
                    "Select the desired item: 'Oil' (Oil Change) or 'Annual' (Annual Service).",
                    "Highlight 'Reset' and press and hold the wheel inwards for 2 seconds until the confirmation prompt appears."
                ),
                note = "On GT+ radar models, service status automatically syncs with the adaptive cruise control display."
            ),
            ServiceProcedureModel(
                id = "cp2_all",
                familyName = "MT-07 / Tracer 7 / XSR700 / R7",
                years = "CP2 689cc Euro 4 / Euro 5",
                dashboardType = "Compact Multi-function LCD",
                indicators = listOf("OIL TRIP", "Oil Change Light"),
                steps = listOf(
                    "Turn the ignition key to ON with engine stopped.",
                    "Press the left meter button (SELECT) repeatedly until 'OIL TRIP' is shown.",
                    "Press and hold the right button (RESET) for 3 seconds until the mileage begins flashing.",
                    "While flashing, press and hold the RESET button again for 3 seconds.",
                    "The trip meter resets to '0.0' and the warning light extinguishes."
                ),
                note = "Yamaha CP2 standard oil service interval is 1,000 km for break-in, then every 10,000 km."
            ),
            ServiceProcedureModel(
                id = "tenere_700",
                familyName = "Ténéré 700 / Rally / World Raid",
                years = "CP2 689cc Adventure",
                dashboardType = "Vertical LCD / New 5\" Vertical TFT",
                indicators = listOf("OIL TRIP", "Service Icon"),
                steps = listOf(
                    "Classic LCD model (2019–2022): With ignition ON, scroll SELECT to 'OIL TRIP'. Hold RESET for 3s until flashing, then hold RESET again for 3s.",
                    "Color TFT model (2023+): Press the right handlebar wheel to enter Settings.",
                    "Scroll to 'Maintenance' ➔ Select 'Oil Service'.",
                    "Press and hold OK/Center button until confirmation chime or message appears."
                ),
                note = "On World Raid dual-tank models, resetting service does not alter individual tank consumption statistics."
            ),
            ServiceProcedureModel(
                id = "tmax_530_560",
                familyName = "TMAX 530 / TMAX 560",
                years = "Twin-Cylinder Maxi Scooter (2017+)",
                dashboardType = "Dual Analog Dial + Center TFT",
                indicators = listOf("'OIL' Light", "'V-BELT' Light (20,000 km)"),
                steps = listOf(
                    "Turn ignition key or main switch to ON (engine off, on centerstand).",
                    "Press TRIP/INFO button on handlebar until 'OIL TRIP' or 'V-BELT TRIP' is displayed (depending on which light is active).",
                    "Press and hold RESET on meter or handlebar for 3–4 seconds until the text starts flashing.",
                    "Release and hold RESET again for 3 seconds.",
                    "The mileage resets to 0 and the warning indicator on the instrument cluster turns off."
                ),
                note = "⚠️ Caution: The V-BELT light triggers every 20,000 km. Only reset after inspecting or replacing the CVT drive belt."
            ),
            ServiceProcedureModel(
                id = "xmax_nmax",
                familyName = "XMAX 125 / 300 / 400",
                years = "Blue Core Sport Scooter",
                dashboardType = "Center LCD Display",
                indicators = listOf("OIL CHANGE", "V-BELT TRIP"),
                steps = listOf(
                    "Turn Smart Key knob to ON with engine off.",
                    "Press handlebar TRIP button until 'OIL TRIP' (or 'V-BELT TRIP') is displayed.",
                    "Press and hold RESET button for 3 seconds until the digits begin flashing.",
                    "Briefly release and hold RESET again for 3 seconds until '0' is shown.",
                    "The indicator light extinguishes automatically."
                ),
                note = "First oil service is at 1,000 km, subsequent changes are every 5,000 km."
            ),
            ServiceProcedureModel(
                id = "cp4_r1_mt10",
                familyName = "YZF-R1 / R1M & MT-10 (2015+)",
                years = "CP4 998cc Crossplane Superbike",
                dashboardType = "High-Definition TFT Racing Display",
                indicators = listOf("Maintenance Warning", "Oil Service"),
                steps = listOf(
                    "Turn ignition to ON with engine off.",
                    "Press and hold the right handlebar wheel for 2 seconds to access 'System Settings'.",
                    "Scroll to 'Maintenance' and push wheel inwards to view component items.",
                    "Select the desired item ('Engine Oil', 'Oil Filter', or 'General Service').",
                    "Scroll to 'Reset' and hold wheel inwards until confirmation popup closes."
                ),
                note = "On R1M models equipped with Öhlins Electronic Racing Suspension, service inspection includes electronic actuator calibration check."
            )
        )
    }
}
