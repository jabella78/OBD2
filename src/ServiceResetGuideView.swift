import SwiftUI

struct ServiceResetProcedure: Identifiable {
    let id = UUID()
    let modelName: String
    let engineFamily: String
    let displayType: String
    let targetIndicators: [String]
    let steps: [String]
    let warningNote: String?
}

struct ServiceResetGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var lang = LocalizationManager.shared
    @State private var searchText: String = ""
    
    var navTitle: String {
        switch lang.currentLanguage {
        case .english: return "Service Reset Guide"
        case .italian: return "Guida Reset Tagliando"
        case .french: return "Guide Reset Entretien"
        case .spanish: return "Guía Reset Mantenimiento"
        case .german: return "Service-Reset-Anleitung"
        }
    }
    
    var closeButtonText: String {
        switch lang.currentLanguage {
        case .english: return "Close"
        case .italian: return "Chiudi"
        case .french: return "Fermer"
        case .spanish: return "Cerrar"
        case .german: return "Schließen"
        }
    }
    
    var headerTitle: String {
        switch lang.currentLanguage {
        case .english: return "Service & Dashboard Indicators Reset"
        case .italian: return "Reset Tagliando & Spie Cruscotto"
        case .french: return "Réinitialisation Entretien & Voyants"
        case .spanish: return "Reinicio de Servicio y Testigos"
        case .german: return "Service- & Kontrollleuchten-Reset"
        }
    }
    
    var headerDesc: String {
        switch lang.currentLanguage {
        case .english:
            return "On all Yamaha motorcycles and scooters, maintenance counters (Oil Trip, Service wrench, V-Belt) are stored internally in dashboard instrument cluster EEPROM. Follow the official manual button sequence for your model:"
        case .italian:
            return "Su tutte le moto e gli scooter Yamaha, il conteggio chilometrico dei tagliandi (Oil Trip, chiave inglese, V-Belt) è memorizzato internamente nella memoria della strumentazione. Segui la procedura ufficiale manuale dal cruscotto per il tuo modello:"
        case .french:
            return "Sur toutes les motos et scooters Yamaha, les compteurs d'entretien (Oil Trip, clé de vidange, V-Belt) sont stockés dans la mémoire du tableau de bord. Suivez la séquence manuelle officielle pour votre modèle :"
        case .spanish:
            return "En todas las motocicletas y scooters Yamaha, los contadores de mantenimiento (Oil Trip, llave inglesa, V-Belt) se guardan internamente en el cuadro de instrumentos. Sigue la secuencia oficial desde el tablero para tu modelo:"
        case .german:
            return "Bei allen Yamaha-Motorrädern und Rollern werden Wartungszähler (Oil Trip, Schraubenschlüssel, V-Belt) intern im Cockpit-Speicher abgelegt. Befolgen Sie die offizielle Tastenfolge für Ihr Modell:"
        }
    }
    
    var searchPlaceholder: String {
        switch lang.currentLanguage {
        case .english: return "Search model (e.g. Tracer, MT-07, TMAX)..."
        case .italian: return "Cerca modello (es. Tracer, MT-07, TMAX)..."
        case .french: return "Rechercher un modèle (ex. Tracer, MT-07, TMAX)..."
        case .spanish: return "Buscar modelo (ej. Tracer, MT-07, TMAX)..."
        case .german: return "Modell suchen (z.B. Tracer, MT-07, TMAX)..."
        }
    }
    
    var indicatorsLabel: String {
        switch lang.currentLanguage {
        case .english: return "Affected Indicators:"
        case .italian: return "Spie interessate:"
        case .french: return "Voyants concernés :"
        case .spanish: return "Testigos afectados:"
        case .german: return "Betroffene Anzeigen:"
        }
    }
    
    var stepsLabel: String {
        switch lang.currentLanguage {
        case .english: return "Official Step-by-Step Procedure:"
        case .italian: return "Procedura Ufficiale Passo-Passo:"
        case .french: return "Procédure Officielle Étape par Étape :"
        case .spanish: return "Procedimiento Oficial Paso a Paso:"
        case .german: return "Offizieller Schritt-für-Schritt-Ablauf:"
        }
    }
    
    var procedures: [ServiceResetProcedure] {
        switch lang.currentLanguage {
        case .english:
            return [
                ServiceResetProcedure(
                    modelName: "Tracer 900 / GT & MT-09 (2015–2020)",
                    engineFamily: "CP3 847cc Euro 4",
                    displayType: "Digital LCD & GT TFT Display",
                    targetIndicators: ["Wrench Icon", "OIL TRIP"],
                    steps: [
                        "Turn the ignition key to ON with engine stopped (engine stop switch set to RUN).",
                        "Press the SELECT button on the meter (or the handlebar thumbwheel on GT) until the 'OIL TRIP' or maintenance interval screen is displayed.",
                        "Press and hold the RESET button (or thumbwheel) for at least 3 seconds: the mileage display or wrench icon will start flashing rapidly.",
                        "While it is flashing, release and press and hold the RESET button again for 2–3 seconds.",
                        "The counter will reset to '0.0 km' and the maintenance warning light will turn off."
                    ],
                    warningNote: "If more than 5 seconds elapse while flashing without confirming, reset mode exits and you must repeat the sequence."
                ),
                ServiceResetProcedure(
                    modelName: "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                    engineFamily: "CP3 890cc Euro 5",
                    displayType: "Dual 3.5\" Full-Color TFT",
                    targetIndicators: ["Service Wrench", "Oil / Annual Maintenance"],
                    steps: [
                        "Turn the ignition key to ON (engine strictly stopped).",
                        "Push the right handlebar multi-function wheel inwards to open the Main Menu.",
                        "Scroll the wheel to 'Maintenance' and press inwards to enter.",
                        "Select the desired item: 'Oil' (Oil Change) or 'Annual' (Annual Service).",
                        "Highlight 'Reset' and press and hold the wheel inwards for 2 seconds until the confirmation prompt appears."
                    ],
                    warningNote: "On GT+ radar models, service status automatically syncs with the adaptive cruise control display."
                ),
                ServiceResetProcedure(
                    modelName: "MT-07 / Tracer 7 / XSR700 / R7",
                    engineFamily: "CP2 689cc Euro 4 / Euro 5",
                    displayType: "Compact Multi-function LCD",
                    targetIndicators: ["OIL TRIP", "Oil Change Light"],
                    steps: [
                        "Turn the ignition key to ON with engine stopped.",
                        "Press the left meter button (SELECT) repeatedly until 'OIL TRIP' is shown.",
                        "Press and hold the right button (RESET) for 3 seconds until the mileage begins flashing.",
                        "While flashing, press and hold the RESET button again for 3 seconds.",
                        "The trip meter resets to '0.0' and the warning light extinguishes."
                    ],
                    warningNote: "Yamaha CP2 standard oil service interval is 1,000 km for break-in, then every 10,000 km."
                ),
                ServiceResetProcedure(
                    modelName: "Ténéré 700 / Rally / World Raid",
                    engineFamily: "CP2 689cc Adventure",
                    displayType: "Vertical LCD / New 5\" Vertical TFT",
                    targetIndicators: ["OIL TRIP", "Service Icon"],
                    steps: [
                        "Classic LCD model (2019–2022): With ignition ON, scroll SELECT to 'OIL TRIP'. Hold RESET for 3s until flashing, then hold RESET again for 3s.",
                        "Color TFT model (2023+): Press the right handlebar wheel to enter Settings.",
                        "Scroll to 'Maintenance' ➔ Select 'Oil Service'.",
                        "Press and hold OK/Center button until confirmation chime or message appears."
                    ],
                    warningNote: "On World Raid dual-tank models, resetting service does not alter individual tank consumption statistics."
                ),
                ServiceResetProcedure(
                    modelName: "TMAX 530 / TMAX 560",
                    engineFamily: "Twin-Cylinder Maxi Scooter (2017+)",
                    displayType: "Dual Analog Dial + Center TFT",
                    targetIndicators: ["'OIL' Light", "'V-BELT' Light (20,000 km)"],
                    steps: [
                        "Turn ignition key or main switch to ON (engine off, on centerstand).",
                        "Press TRIP/INFO button on handlebar until 'OIL TRIP' or 'V-BELT TRIP' is displayed (depending on which light is active).",
                        "Press and hold RESET on meter or handlebar for 3–4 seconds until the text starts flashing.",
                        "Release and hold RESET again for 3 seconds.",
                        "The mileage resets to 0 and the warning indicator on the instrument cluster turns off."
                    ],
                    warningNote: "⚠️ Caution: The V-BELT light triggers every 20,000 km. Only reset after inspecting or replacing the CVT drive belt."
                ),
                ServiceResetProcedure(
                    modelName: "XMAX 125 / 300 / 400",
                    engineFamily: "Blue Core Sport Scooter",
                    displayType: "Center LCD Display",
                    targetIndicators: ["OIL CHANGE", "V-BELT TRIP"],
                    steps: [
                        "Turn Smart Key knob to ON with engine off.",
                        "Press handlebar TRIP button until 'OIL TRIP' (or 'V-BELT TRIP') is displayed.",
                        "Press and hold RESET button for 3 seconds until the digits begin flashing.",
                        "Briefly release and hold RESET again for 3 seconds until '0' is shown.",
                        "The indicator light extinguishes automatically."
                    ],
                    warningNote: "First oil service is at 1,000 km, subsequent changes are every 5,000 km."
                ),
                ServiceResetProcedure(
                    modelName: "YZF-R1 / R1M & MT-10 (2015+)",
                    engineFamily: "CP4 998cc Crossplane Superbike",
                    displayType: "High-Definition TFT Racing Display",
                    targetIndicators: ["Maintenance Warning", "Oil Service"],
                    steps: [
                        "Turn ignition to ON with engine off.",
                        "Press and hold the right handlebar wheel for 2 seconds to access 'System Settings'.",
                        "Scroll to 'Maintenance' and push wheel inwards to view component items.",
                        "Select the desired item ('Engine Oil', 'Oil Filter', or 'General Service').",
                        "Scroll to 'Reset' and hold wheel inwards until confirmation popup closes."
                    ],
                    warningNote: "On R1M models equipped with Öhlins Electronic Racing Suspension, service inspection includes electronic actuator calibration check."
                )
            ]
        case .french:
            return [
                ServiceResetProcedure(
                    modelName: "Tracer 900 / GT & MT-09 (2015–2020)",
                    engineFamily: "CP3 847cc Euro 4",
                    displayType: "Écran LCD Numérique & TFT GT",
                    targetIndicators: ["Clé d'Entretien", "OIL TRIP"],
                    steps: [
                        "Mettez le contact sur ON, moteur coupé (coupe-circuit sur RUN).",
                        "Appuyez sur le bouton SELECT au compteur (ou la molette au guidon de la GT) jusqu'à afficher l'écran 'OIL TRIP'.",
                        "Maintenez le bouton RESET enfoncé pendant 3 secondes : le kilométrage commence à clignoter rapidement.",
                        "Pendant le clignotement, relâchez puis maintenez à nouveau RESET enfoncé pendant 2 à 3 secondes.",
                        "Le compteur se remet à '0.0 km' et le témoin de révision s'éteint."
                    ],
                    warningNote: "Si plus de 5 secondes s'écoulent sans confirmer pendant le clignotement, la procédure est annulée."
                ),
                ServiceResetProcedure(
                    modelName: "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                    engineFamily: "CP3 890cc Euro 5",
                    displayType: "Double Écran TFT Couleur 3.5\"",
                    targetIndicators: ["Icône Entretien", "Vidange Huile / Annuel"],
                    steps: [
                        "Mettez le contact sur ON (moteur coupé).",
                        "Poussez la molette droite du guidon vers l'intérieur pour ouvrir le Menu Principal.",
                        "Faites défiler jusqu'à 'Maintenance' (Entretien) et validez en appuyant.",
                        "Sélectionnez la ligne souhaitée : 'Oil' (Vidange) ou 'Annual' (Entretien Annuel).",
                        "Mettez en surbrillance 'Reset' et maintenez la molette enfoncée 2 secondes pour confirmer."
                    ],
                    warningNote: "Sur les modèles GT+ équipés de radar, l'entretien est synchronisé avec le régulateur adaptatif."
                ),
                ServiceResetProcedure(
                    modelName: "MT-07 / Tracer 7 / XSR700 / R7",
                    engineFamily: "CP2 689cc Euro 4 / Euro 5",
                    displayType: "Écran LCD Compact",
                    targetIndicators: ["OIL TRIP", "Témoin Vidange"],
                    steps: [
                        "Mettez le contact sur ON, moteur coupé.",
                        "Appuyez sur SELECT jusqu'à afficher 'OIL TRIP'.",
                        "Maintenez RESET enfoncé pendant 3 secondes jusqu'au clignotement des chiffres.",
                        "Pendant le clignotement, maintenez à nouveau RESET enfoncé pendant 3 secondes.",
                        "Le compteur affiche '0.0' et le témoin s'éteint."
                    ],
                    warningNote: "L'intervalle d'huile standard CP2 est à 1 000 km (rodage) puis tous les 10 000 km."
                ),
                ServiceResetProcedure(
                    modelName: "TMAX 530 / TMAX 560",
                    engineFamily: "Maxi Scooter Bicylindre (2017+)",
                    displayType: "Double Cadran Analogique + TFT Central",
                    targetIndicators: ["Témoin 'OIL'", "Témoin 'V-BELT' (Courroie 20 000 km)"],
                    steps: [
                        "Mettez le contact sur ON (moteur coupé, sur béquille centrale).",
                        "Appuyez sur TRIP/INFO au guidon jusqu'à afficher 'OIL TRIP' ou 'V-BELT TRIP'.",
                        "Maintenez RESET enfoncé 3 à 4 secondes jusqu'au clignotement.",
                        "Relâchez puis maintenez à nouveau RESET pendant 3 secondes.",
                        "Le compteur revient à 0 et le voyant s'éteint."
                    ],
                    warningNote: "⚠️ Attention : Le témoin V-BELT s'allume tous les 20 000 km. Ne le réinitialisez qu'après avoir vérifié ou remplacé la courroie."
                )
            ]
        case .spanish:
            return [
                ServiceResetProcedure(
                    modelName: "Tracer 900 / GT & MT-09 (2015–2020)",
                    engineFamily: "CP3 847cc Euro 4",
                    displayType: "Pantalla LCD Digital y TFT GT",
                    targetIndicators: ["Llave de Servicio", "OIL TRIP"],
                    steps: [
                        "Gira la llave a la posición ON con motor apagado (interruptor en RUN).",
                        "Pulsa el botón SELECT en el cuadro (o la rueda del manillar en la GT) hasta ver 'OIL TRIP'.",
                        "Mantén pulsado RESET durante 3 segundos: los kilómetros empezarán a parpadear rápidamente.",
                        "Mientras parpadea, suelta y vuelve a mantener pulsado RESET durante 2 a 3 segundos.",
                        "El contador volverá a '0.0 km' y el testigo de servicio se apagará."
                    ],
                    warningNote: "Si pasan más de 5 segundos sin confirmar durante el parpadeo, la función se cancela."
                ),
                ServiceResetProcedure(
                    modelName: "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                    engineFamily: "CP3 890cc Euro 5",
                    displayType: "Doble Pantalla TFT a Color 3.5\"",
                    targetIndicators: ["Icono Llave", "Aceite / Anual"],
                    steps: [
                        "Pon el contacto en ON (motor rigurosamente apagado).",
                        "Presiona hacia adentro la rueda derecha del manillar para abrir el Menú Principal.",
                        "Gira hasta 'Maintenance' (Mantenimiento) y pulsa para entrar.",
                        "Selecciona 'Oil' (Aceite) o 'Annual' (Revisión Anual).",
                        "Resalta 'Reset' y mantén pulsada la rueda hacia adentro 2 segundos para confirmar."
                    ],
                    warningNote: "En las versiones GT+ con radar, el mantenimiento se sincroniza con el control de crucero adaptativo."
                ),
                ServiceResetProcedure(
                    modelName: "MT-07 / Tracer 7 / XSR700 / R7",
                    engineFamily: "CP2 689cc Euro 4 / Euro 5",
                    displayType: "Pantalla LCD Compacta",
                    targetIndicators: ["OIL TRIP", "Testigo Cambio Aceite"],
                    steps: [
                        "Gira la llave a ON con motor apagado.",
                        "Pulsa SELECT en el panel hasta que aparezca 'OIL TRIP'.",
                        "Mantén pulsado RESET durante 3 segundos hasta que el kilometraje parpadee.",
                        "Mientras parpadea, vuelve a mantener pulsado RESET durante 3 segundos.",
                        "El indicador se reinicia a '0.0' y la luz se apaga."
                    ],
                    warningNote: "Intervalo oficial de cambio de aceite CP2: 1.000 km rodaje, luego cada 10.000 km."
                ),
                ServiceResetProcedure(
                    modelName: "TMAX 530 / TMAX 560",
                    engineFamily: "Maxi Scooter Bicilíndrico (2017+)",
                    displayType: "Esferas Analógicas + TFT Central",
                    targetIndicators: ["Testigo 'OIL'", "Testigo 'V-BELT' (Correa 20.000 km)"],
                    steps: [
                        "Pon el contacto en ON (motor apagado, en caballete central).",
                        "Pulsa TRIP/INFO en el manillar hasta ver 'OIL TRIP' o 'V-BELT TRIP'.",
                        "Mantén pulsado RESET durante 3–4 segundos hasta que parpadee.",
                        "Suelta y vuelve a mantener pulsado RESET durante 3 segundos.",
                        "El contador vuelve a 0 y el testigo se apaga."
                    ],
                    warningNote: "⚠️ Atención: El testigo V-BELT se enciende cada 20.000 km. Reiniciar únicamente tras revisar o sustituir la correa de transmisión."
                )
            ]
        case .german:
            return [
                ServiceResetProcedure(
                    modelName: "Tracer 900 / GT & MT-09 (2015–2020)",
                    engineFamily: "CP3 847cc Euro 4",
                    displayType: "Digitales LCD- & GT TFT-Display",
                    targetIndicators: ["Schraubenschlüssel-Symbol", "OIL TRIP"],
                    steps: [
                        "Zündung auf ON drehen bei stehendem Motor (Killschalter auf RUN).",
                        "SELECT-Taste am Cockpit drücken (oder Daumenrad bei GT), bis 'OIL TRIP' angezeigt wird.",
                        "RESET-Taste (oder Daumenrad) mindestens 3 Sekunden gedrückt halten: Die Kilometeranzeige blinkt schnell.",
                        "Während des Blinkens loslassen und erneut RESET für 2–3 Sekunden gedrückt halten.",
                        "Der Zähler springt auf '0.0 km' und die Service-Warnleuchte erlischt."
                    ],
                    warningNote: "Verstreichen mehr als 5 Sekunden ohne Bestätigung während des Blinkens, wird der Vorgang abgebrochen."
                ),
                ServiceResetProcedure(
                    modelName: "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                    engineFamily: "CP3 890cc Euro 5",
                    displayType: "Doppel-3.5\" Vollfarb-TFT",
                    targetIndicators: ["Service-Schlüssel", "Öl- / Jahreswartung"],
                    steps: [
                        "Zündung auf ON schalten (Motor aus).",
                        "Rechtes Lenkerrad nach innen drücken, um das Hauptmenü zu öffnen.",
                        "Zu 'Maintenance' (Wartung) scrollen und bestätigen.",
                        "Gewünschten Eintrag wählen: 'Oil' (Ölwechsel) oder 'Annual' (Jahresinspektion).",
                        "'Reset' markieren und das Rad 2 Sekunden lang gedrückt halten."
                    ],
                    warningNote: "Bei GT+ Radar-Modellen synchronisiert sich der Service-Status automatisch mit dem Abstandstempomat."
                ),
                ServiceResetProcedure(
                    modelName: "MT-07 / Tracer 7 / XSR700 / R7",
                    engineFamily: "CP2 689cc Euro 4 / Euro 5",
                    displayType: "Kompaktes Multifunktions-LCD",
                    targetIndicators: ["OIL TRIP", "Ölwechselanzeige"],
                    steps: [
                        "Zündung auf ON schalten bei stehendem Motor.",
                        "SELECT-Taste drücken, bis 'OIL TRIP' erscheint.",
                        "RESET-Taste 3 Sekunden gedrückt halten, bis die Kilometeranzeige blinkt.",
                        "Während des Blinkens RESET erneut für 3 Sekunden gedrückt halten.",
                        "Der Zähler springt auf '0.0' und die Leuchte erlischt."
                    ],
                    warningNote: "Standard-Intervall für CP2: 1.000 km Einfahrservice, danach alle 10.000 km."
                ),
                ServiceResetProcedure(
                    modelName: "TMAX 530 / TMAX 560",
                    engineFamily: "Zweizylinder-Maxi-Roller (2017+)",
                    displayType: "Analoginstrumente + Zentral-TFT",
                    targetIndicators: ["'OIL'-Leuchte", "'V-BELT'-Leuchte (20.000 km)"],
                    steps: [
                        "Zündung auf ON (Motor aus, auf Hauptständer).",
                        "TRIP/INFO am Lenker drücken, bis 'OIL TRIP' oder 'V-BELT TRIP' erscheint.",
                        "RESET-Taste 3–4 Sekunden gedrückt halten, bis die Anzeige blinkt.",
                        "Loslassen und erneut 3 Sekunden lang RESET gedrückt halten.",
                        "Der Zähler wird auf 0 gesetzt und die Warnleuchte erlischt."
                    ],
                    warningNote: "⚠️ Vorsicht: V-BELT leuchtet alle 20.000 km auf. Nur nach tatsächlicher Riemenprüfung bzw. Wechsel zurücksetzen."
                )
            ]
        case .italian:
            return [
                ServiceResetProcedure(
                    modelName: "Tracer 900 / GT & MT-09 (2015–2020)",
                    engineFamily: "CP3 847cc Euro 4",
                    displayType: "Display Digitale LCD & TFT GT",
                    targetIndicators: ["Spia Chiave Inglese", "OIL TRIP"],
                    steps: [
                        "Ruota la chiave su ON a motore spento (interruttore d'arresto su RUN).",
                        "Premi il tasto SELECT sul cruscotto (o la rotellina sul manubrio della GT) fino a visualizzare la schermata dell'indicatore 'OIL TRIP' o dell'intervallo di manutenzione.",
                        "Tieni premuto il pulsante RESET (o rotellina) per almeno 3 secondi: il valore dei chilometri o la spia inizierà a lampeggiare velocemente.",
                        "Mentre il valore lampeggia, rilascia e tieni premuto nuovamente il tasto RESET per altri 2-3 secondi.",
                        "Il contatore si azzererà su '0.0 km' e la spia di manutenzione si spegnerà confermando l'avvenuto reset."
                    ],
                    warningNote: "Se lasci trascorrere più di 5 secondi mentre il valore lampeggia senza confermare, la modalità si disattiva e dovrai ripetere la sequenza."
                ),
                ServiceResetProcedure(
                    modelName: "Tracer 9 / GT / GT+ & MT-09 (2021+ Euro 5)",
                    engineFamily: "CP3 890cc Euro 5",
                    displayType: "Doppio Display TFT a Colori 3.5\"",
                    targetIndicators: ["Icona Tagliando", "Manutenzione Olio / Annuale"],
                    steps: [
                        "Accendi il quadro con chiave su ON (motore rigorosamente spento).",
                        "Premi verso l'interno la rotellina multifunzione destra sul manubrio per accedere al Menu Principale.",
                        "Ruota la rotellina fino alla voce 'Maintenance' (Manutenzione) e premila per entrare.",
                        "Seleziona la voce desiderata tra 'Oil' (Cambio Olio) oppure 'Annual' (Intervallo Annuale).",
                        "Evidenzia l'opzione 'Reset' e tieni premuta la rotellina verso l'interno per 2 secondi fino al messaggio di conferma."
                    ],
                    warningNote: "Nelle versioni con radar GT+, la voce di manutenzione si sincronizza automaticamente anche con il cruise control adattivo."
                ),
                ServiceResetProcedure(
                    modelName: "MT-07 / Tracer 7 / XSR700 / R7",
                    engineFamily: "CP2 689cc Euro 4 / Euro 5",
                    displayType: "Display LCD Compatto Multifunzione",
                    targetIndicators: ["OIL TRIP", "Spia Cambio Olio"],
                    steps: [
                        "Gira la chiave su ON a motore spento.",
                        "Premi il tasto sinistro della strumentazione (SELECT) fino a selezionare il display parziale 'OIL TRIP'.",
                        "Tieni premuto il tasto destro (RESET) per 3 secondi finché il chilometraggio non inizia a lampeggiare sul display.",
                        "Con i numeri lampeggianti, premi e mantieni premuto ancora il tasto RESET per altri 3 secondi.",
                        "Il chilometraggio verrà azzerato a '0.0' e la spia si spegnerà."
                    ],
                    warningNote: "L'intervallo standard Yamaha per il cambio olio sul motore CP2 è impostato a 1.000 km per il primo rodaggio e successivamente ogni 10.000 km."
                ),
                ServiceResetProcedure(
                    modelName: "Ténéré 700 / Rally / World Raid",
                    engineFamily: "CP2 689cc Adventure",
                    displayType: "Display LCD Verticale / Nuovo TFT Verticale 5\"",
                    targetIndicators: ["OIL TRIP", "Service Icon"],
                    steps: [
                        "Versione LCD classico (2019–2022): Con quadro su ON, scorri con il tasto SELECT fino a 'OIL TRIP'. Tieni premuto RESET per 3 secondi finché lampeggia, poi ripremi RESET per 3 secondi.",
                        "Versione TFT a colori (2023+): Premi la rotellina sul blocchetto destro per entrare nel menu delle impostazioni.",
                        "Scorri fino a 'Maintenance' ➔ Seleziona 'Oil Service'.",
                        "Tieni premuto il tasto centrale per azzerare il chilometraggio parziale fino al segnale di conferma."
                    ],
                    warningNote: "Sulla World Raid con doppio serbatoio, il reset del service non influisce sul calcolo dei consumi dei singoli serbatoi."
                ),
                ServiceResetProcedure(
                    modelName: "TMAX 530 / TMAX 560",
                    engineFamily: "Maxi Scooter Bicilindrico (2017+)",
                    displayType: "Doppio Quadrante Analogico + TFT Centrale",
                    targetIndicators: ["Spia 'OIL'", "Spia 'V-BELT' (Cinghia 20.000 km)"],
                    steps: [
                        "Gira la chiave su ON (motore spento, cavalletto centrale inserito).",
                        "Premi il tasto TRIP/INFO al manubrio fino a visualizzare la schermata dell'indicatore 'OIL TRIP' oppure 'V-BELT TRIP' (a seconda della spia accesa).",
                        "Tieni premuto il pulsante RESET sul cruscotto o al manubrio per 3-4 secondi fino a far lampeggiare la scritta.",
                        "Rilascia il pulsante e tieni nuovamente premuto RESET per altri 3 secondi.",
                        "L'indicatore tornerà a 0 e la spia sul quadro strumenti si spegnerà definitivamente."
                    ],
                    warningNote: "⚠️ Attenzione: La spia V-BELT si accende ogni 20.000 km. Resettarla solo dopo aver effettivamente verificato o sostituito la cinghia di trasmissione trapezoidale!"
                ),
                ServiceResetProcedure(
                    modelName: "XMAX 125 / 300 / 400",
                    engineFamily: "Sport Scooter Blue Core",
                    displayType: "Display LCD Multifunzione Centrale",
                    targetIndicators: ["OIL CHANGE", "V-BELT TRIP"],
                    steps: [
                        "Ruota il selettore Smart Key o la chiave su ON a motore spento.",
                        "Premi il pulsante TRIP sul manubrio fino a selezionare 'OIL TRIP' (o 'V-BELT TRIP').",
                        "Premi e mantieni premuto il pulsante RESET per almeno 3 secondi fino a quando il numero dei chilometri non comincia a lampeggiare.",
                        "Rilascia per un istante e tieni premuto nuovamente il tasto RESET per altri 3 secondi fino a visualizzare '0'.",
                        "La spia di avviso si spegnerà automaticamente."
                    ],
                    warningNote: "Il primo reset dell'olio compare a 1.000 km, i successivi ogni 5.000 km."
                ),
                ServiceResetProcedure(
                    modelName: "YZF-R1 / R1M & MT-10 (2015+)",
                    engineFamily: "CP4 998cc Crossplane Superbike",
                    displayType: "TFT Racing a Colori ad Alta Definizione",
                    targetIndicators: ["Maintenance Warning", "Oil Service"],
                    steps: [
                        "Ruota la chiave su ON con motore fermo.",
                        "Tenere premuta la rotellina multifunzione destra sul manubrio per 2 secondi per accedere al menu 'System Settings'.",
                        "Ruotare la rotellina fino a 'Maintenance' e premere per accedere alla lista componenti.",
                        "Selezionare l'intervallo interessato ('Engine Oil', 'Oil Filter' o 'General Service').",
                        "Premere a fondo la rotellina su 'Reset' e confermare alla richiesta del pop-up."
                    ],
                    warningNote: "Sulle R1M con sospensioni elettroniche Öhlins, l'intervallo di manutenzione include anche il check della taratura idraulica."
                )
            ]
        }
    }
    
    var filteredProcedures: [ServiceResetProcedure] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return procedures
        }
        return procedures.filter {
            $0.modelName.localizedCaseInsensitiveContains(searchText) ||
            $0.engineFamily.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header informativo
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text(headerTitle)
                            .font(.headline)
                            .bold()
                    }
                    Text(headerDesc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                
                // Barra di ricerca modello
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(searchPlaceholder, text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Lista delle procedure
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredProcedures) { proc in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(proc.modelName)
                                            .font(.headline)
                                            .foregroundColor(.cyan)
                                        Text(proc.engineFamily)
                                            .font(.caption2)
                                            .bold()
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(proc.displayType)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.cyan.opacity(0.15))
                                        .foregroundColor(.cyan)
                                        .cornerRadius(6)
                                }
                                
                                HStack(spacing: 6) {
                                    Text(indicatorsLabel)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    ForEach(proc.targetIndicators, id: \.self) { ind in
                                        Text(ind)
                                            .font(.caption2)
                                            .bold()
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.15))
                                            .foregroundColor(.orange)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Divider()
                                
                                Text(stepsLabel)
                                    .font(.caption)
                                    .bold()
                                
                                ForEach(Array(proc.steps.enumerated()), id: \.offset) { idx, step in
                                    HStack(alignment: .top, spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.cyan.opacity(0.2))
                                                .frame(width: 20, height: 20)
                                            Text("\(idx + 1)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.cyan)
                                        }
                                        Text(step)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                
                                if let note = proc.warningNote {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        Text(note)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(8)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                            .padding(14)
                            .background(Color.secondary.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(navTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(closeButtonText) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem {
                    Button(closeButtonText) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            #endif
        }
    }
}
