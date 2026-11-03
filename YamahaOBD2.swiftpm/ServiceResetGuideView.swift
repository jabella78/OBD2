import SwiftUI

struct ServiceResetProcedure: Identifiable {
    let id = UUID()
    let modelName: String
    let engineFamily: String
    let displayType: String
    let targetIndicators: [String] // es: ["Spia Chiave Inglese", "OIL TRIP", "V-BELT"]
    let steps: [String]
    let warningNote: String?
}

struct ServiceResetGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedProcedureIndex: Int = 0
    @State private var searchText: String = ""
    
    let procedures: [ServiceResetProcedure] = [
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
                "Tieni premuto il tasto centrale per azzerare il chilometraggio parziale fino al beep/segnale visivo di conferma."
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
                        Text("Reset Tagliando & Spie Cruscotto")
                            .font(.headline)
                            .bold()
                    }
                    Text("Su tutte le moto e gli scooter Yamaha, il conteggio chilometrico dei tagliandi (Oil Trip e V-Belt) è memorizzato internamente nella memoria della strumentazione. Segui la procedura ufficiale manuale dal cruscotto per il tuo modello:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                
                // Barra di ricerca modello
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Cerca modello (es. Tracer, MT-07, TMAX)...", text: $searchText)
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
                                    Text("Spie interessate:")
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
                                
                                Text("Procedura Ufficiale Passo-Passo:")
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
            .navigationTitle("Guida Reset Tagliando")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem {
                    Button("Chiudi") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            #endif
        }
    }
}
