import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case gemini = "Google Gemini"
    case openai = "OpenAI (ChatGPT)"
    case anthropic = "Anthropic Claude"
    case deepseek = "DeepSeek"
    case groq = "Groq"
    case custom = "Personalizzato (OpenAI-Compatible)"
    
    var id: String { rawValue }
    
    var defaultModel: String {
        switch self {
        case .gemini: return "gemini-4-flash"
        case .openai: return "gpt-5-preview"
        case .anthropic: return "claude-4-sonnet"
        case .deepseek: return "deepseek-v3"
        case .groq: return "llama-4-scout-preview"
        case .custom: return "llama3"
        }
    }
    
    var staticFallbackModels: [String] {
        switch self {
        case .gemini:
            return [
                "gemini-4-flash",
                "gemini-4-pro",
                "gemini-3.8-flash",
                "gemini-3.8-pro",
                "gemini-3.0-flash",
                "gemini-2.5-flash",
                "gemini-2.5-pro",
                "gemini-2.0-flash",
                "gemini-2.0-flash-thinking-exp",
                "gemini-2.0-pro-exp"
            ]
        case .openai:
            return [
                "gpt-5-preview",
                "gpt-5-mini",
                "gpt-4.5-preview",
                "o3",
                "o3-mini",
                "o1",
                "gpt-4o",
                "gpt-4o-mini"
            ]
        case .anthropic:
            return [
                "claude-4-sonnet",
                "claude-4-opus",
                "claude-3-7-sonnet-latest",
                "claude-3-5-sonnet-latest",
                "claude-3-5-haiku-latest"
            ]
        case .deepseek:
            return [
                "deepseek-v3",
                "deepseek-r1",
                "deepseek-chat",
                "deepseek-reasoner"
            ]
        case .groq:
            return [
                "llama-4-scout-preview",
                "llama-3.3-70b-versatile",
                "deepseek-r1-distill-llama-70b",
                "llama-3.1-8b-instant",
                "qwen-2.5-coder-32b"
            ]
        case .custom:
            return []
        }
    }
    
    var placeholderKey: String {
        switch self {
        case .gemini: return "AIzaSy..."
        case .openai: return "sk-proj-..."
        case .anthropic: return "sk-ant-..."
        case .deepseek: return "sk-..."
        case .groq: return "gsk_..."
        case .custom: return "Chiave API opzionale..."
        }
    }
}

enum ModelFetchState: Equatable {
    case ready
    case customEndpoint
    case catalogRefreshed(count: Int)
    case checking(provider: String)
    case claudeUpdated
    case offlineFallback(count: Int)
    case liveDiscoveredGoogle(count: Int)
    case liveDiscovered(count: Int)
    
    func localizedText(for lang: AppLanguage) -> String {
        switch self {
        case .ready:
            switch lang {
            case .italian: return "Pronto."
            case .english: return "Ready."
            case .french: return "Prêt."
            case .spanish: return "Listo."
            case .german: return "Bereit."
            }
        case .customEndpoint:
            switch lang {
            case .italian: return "Configurazione manuale endpoint personalizzato."
            case .english: return "Manual configuration for custom endpoint."
            case .french: return "Configuration manuelle du point de terminaison personnalisé."
            case .spanish: return "Configuración manual de endpoint personalizado."
            case .german: return "Manuelle Konfiguration für benutzerdefinierten Endpunkt."
            }
        case .catalogRefreshed(let count):
            switch lang {
            case .italian: return "🟢 Catalogo 2026 aggiornato (\(count) modelli). Inserisci l'API Key per sincronizzazione cloud."
            case .english: return "🟢 2026 catalog refreshed (\(count) models). Enter API Key for cloud sync."
            case .french: return "🟢 Catalogue 2026 actualisé (\(count) modèles). Entrez la clé API pour synchroniser."
            case .spanish: return "🟢 Catálogo 2026 actualizado (\(count) modelos). Introduce la clave API para sincronizar."
            case .german: return "🟢 Katalog 2026 aktualisiert (\(count) Modelle). API-Schlüssel für Cloud-Sync eingeben."
            }
        case .checking(let prov):
            switch lang {
            case .italian: return "Verifica modelli attivi su \(prov)..."
            case .english: return "Checking active models on \(prov)..."
            case .french: return "Vérification des modèles actifs sur \(prov)..."
            case .spanish: return "Comprobando modelos activos en \(prov)..."
            case .german: return "Prüfe aktive Modelle auf \(prov)..."
            }
        case .claudeUpdated:
            switch lang {
            case .italian: return "✅ Modelli Claude aggiornati alle ultime release attive (Claude 4 / 3.7)."
            case .english: return "✅ Claude models updated to latest active releases (Claude 4 / 3.7)."
            case .french: return "✅ Modèles Claude mis à jour vers les dernières versions actives (Claude 4 / 3.7)."
            case .spanish: return "✅ Modelos Claude actualizados a las últimas versiones activas (Claude 4 / 3.7)."
            case .german: return "✅ Claude-Modelle auf die neuesten aktiven Versionen aktualisiert (Claude 4 / 3.7)."
            }
        case .offlineFallback(let count):
            switch lang {
            case .italian: return "Offline: usate release attive salvate (\(count) modelli)."
            case .english: return "Offline: using saved active releases (\(count) models)."
            case .french: return "Hors ligne : utilisation des versions enregistrées (\(count) modèles)."
            case .spanish: return "Sin conexión: usando versiones guardadas (\(count) modelos)."
            case .german: return "Offline: gespeicherte Versionen verwendet (\(count) Modelle)."
            }
        case .liveDiscoveredGoogle(let count):
            switch lang {
            case .italian: return "🟢 Rilevate \(count) release attive online su Google AI Studio."
            case .english: return "🟢 Discovered \(count) active releases online on Google AI Studio."
            case .french: return "🟢 \(count) versions actives détectées en ligne sur Google AI Studio."
            case .spanish: return "🟢 Detectadas \(count) versiones activas en línea en Google AI Studio."
            case .german: return "🟢 \(count) aktive Versionen online auf Google AI Studio erkannt."
            }
        case .liveDiscovered(let count):
            switch lang {
            case .italian: return "🟢 Rilevate \(count) release attive online."
            case .english: return "🟢 Discovered \(count) active releases online."
            case .french: return "🟢 \(count) versions actives détectées en ligne."
            case .spanish: return "🟢 Detectadas \(count) versiones activas en línea."
            case .german: return "🟢 \(count) aktive Versionen online erkannt."
            }
        }
    }
}

class AIManager: ObservableObject {
    @Published var selectedProvider: AIProvider = .gemini {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "AISelectedProvider")
            self.apiKey = loadKeyForProvider(selectedProvider)
            self.loadCachedModelsForCurrentProvider()
            self.fetchLiveModels()
        }
    }
    
    @Published var selectedModel: String = "gemini-4-flash" {
        didSet {
            UserDefaults.standard.set(selectedModel, forKey: "AISelectedModel")
        }
    }
    
    @Published var apiKey: String = "" {
        didSet {
            saveKeyForCurrentProvider()
            if !apiKey.isEmpty {
                fetchLiveModels()
            }
        }
    }
    
    @Published var customEndpoint: String = "http://localhost:11434/v1" {
        didSet {
            UserDefaults.standard.set(customEndpoint, forKey: "AICustomEndpoint")
        }
    }
    
    @Published var availableModels: [String] = []
    @Published var isFetchingModels: Bool = false
    @Published var fetchState: ModelFetchState = .ready
    
    var modelFetchStatus: String {
        return fetchState.localizedText(for: LocalizationManager.shared.currentLanguage)
    }
    
    func localizedFetchStatus(for lang: AppLanguage) -> String {
        return fetchState.localizedText(for: lang)
    }
    
    @Published var evaluationResult: String = ""
    @Published var isEvaluating: Bool = false
    
    init() {
        // Cache wipe per forzare l'aggiornamento alle ultime release 2026 ed eliminare residui obsoleti memorizzati in precedenza
        let cacheVersion = UserDefaults.standard.integer(forKey: "AICacheVersion_2026_v6")
        if cacheVersion < 6 {
            for prov in AIProvider.allCases {
                UserDefaults.standard.removeObject(forKey: "CachedModels_\(prov.rawValue)")
            }
            UserDefaults.standard.removeObject(forKey: "AISelectedModel")
            UserDefaults.standard.set(6, forKey: "AICacheVersion_2026_v6")
        }
        
        if let raw = UserDefaults.standard.string(forKey: "AISelectedProvider"),
           let prov = AIProvider(rawValue: raw) {
            self.selectedProvider = prov
        } else {
            self.selectedProvider = .gemini
        }
        
        self.apiKey = loadKeyForProvider(self.selectedProvider)
        
        if let savedModel = UserDefaults.standard.string(forKey: "AISelectedModel"), !savedModel.isEmpty, !isModelDeprecated(savedModel) {
            self.selectedModel = savedModel
        } else {
            self.selectedModel = self.selectedProvider.defaultModel
        }
        
        if let savedEndpoint = UserDefaults.standard.string(forKey: "AICustomEndpoint"), !savedEndpoint.isEmpty {
            self.customEndpoint = savedEndpoint
        }
        
        self.loadCachedModelsForCurrentProvider()
        // Verifica ed aggiorna automaticamente i modelli all'apertura dell'app
        self.fetchLiveModels()
    }
    
    private func loadKeyForProvider(_ provider: AIProvider) -> String {
        let key = "AIKey_\(provider.rawValue)"
        if let val = UserDefaults.standard.string(forKey: key) {
            return val
        }
        if provider == .gemini, let oldGemini = UserDefaults.standard.string(forKey: "GeminiAPIKey") {
            return oldGemini
        }
        return ""
    }
    
    private func saveKeyForCurrentProvider() {
        let key = "AIKey_\(selectedProvider.rawValue)"
        UserDefaults.standard.set(apiKey, forKey: key)
        if selectedProvider == .gemini {
            UserDefaults.standard.set(apiKey, forKey: "GeminiAPIKey")
        }
    }
    
    // MARK: - Filtro Release Deprecate e Dismesse
    
    func isModelDeprecated(_ name: String) -> Bool {
        let lower = name.lowercased()
        
        // Google Gemini: qualsiasi release 1.x (1.0, 1.5) e pro-vision è obsoleta
        if lower.contains("gemini-1.") ||
           lower.contains("gemini-1.0") ||
           lower.contains("gemini-1.5") ||
           lower.contains("gemini-pro-vision") {
            return true
        }
        
        // OpenAI deprecati o dismessi (GPT-3.5, GPT-4 Turbo, instruct, davinci, babbage)
        if lower.contains("gpt-3.5") ||
           lower.contains("gpt-4-turbo") ||
           lower.contains("instruct") ||
           lower.contains("babbage") ||
           lower.contains("davinci") {
            return true
        }
        
        // Groq deprecati (Mixtral 8x7B, vecchie Llama 3 base)
        if lower.contains("mixtral") ||
           lower.contains("llama3-") ||
           (lower.contains("preview") && lower.contains("llama-3.2")) {
            return true
        }
        
        // Anthropic legacy
        if lower.contains("claude-1") || lower.contains("claude-2") {
            return true
        }
        
        return false
    }

    private func loadCachedModelsForCurrentProvider() {
        let cacheKey = "CachedModels_\(selectedProvider.rawValue)"
        let fallback = selectedProvider.staticFallbackModels
        if let cached = UserDefaults.standard.stringArray(forKey: cacheKey), !cached.isEmpty {
            var cleanCached = cached.filter { !self.isModelDeprecated($0) }
            // Assicura che tutte le release più recenti siano sempre presenti
            for m in fallback.reversed() {
                if !cleanCached.contains(m) {
                    cleanCached.insert(m, at: 0)
                }
            }
            self.availableModels = cleanCached
        } else {
            self.availableModels = fallback
        }
        
        // Se il modello selezionato è deprecato o non presente, reimposta sul default valido
        if isModelDeprecated(selectedModel) || (!self.availableModels.contains(selectedModel) && selectedProvider != .custom) {
            if let first = self.availableModels.first {
                self.selectedModel = first
            } else {
                self.selectedModel = selectedProvider.defaultModel
            }
        }
    }
    
    // MARK: - Query Live per Scoperta Nuovi Modelli (Fetch Automatico all'Avvio)
    
    func fetchLiveModels() {
        guard selectedProvider != .custom else {
            self.fetchState = .customEndpoint
            return
        }
        
        // Ricarica sempre il catalogo locale aggiornato
        self.loadCachedModelsForCurrentProvider()
        
        guard !apiKey.isEmpty else {
            let count = self.availableModels.count
            self.fetchState = .catalogRefreshed(count: count)
            return
        }
        
        DispatchQueue.main.async {
            self.isFetchingModels = true
            self.fetchState = .checking(provider: self.selectedProvider.rawValue)
        }
        
        switch selectedProvider {
        case .gemini:
            fetchGeminiModels()
        case .openai:
            fetchOpenAIModels(endpoint: "https://api.openai.com/v1/models")
        case .deepseek:
            fetchOpenAIModels(endpoint: "https://api.deepseek.com/models")
        case .groq:
            fetchOpenAIModels(endpoint: "https://api.groq.com/openai/v1/models")
        case .anthropic:
            DispatchQueue.main.async {
                self.isFetchingModels = false
                self.availableModels = self.selectedProvider.staticFallbackModels
                self.fetchState = .claudeUpdated
            }
        case .custom:
            break
        }
    }
    
    private func fetchGeminiModels() {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)") else {
            DispatchQueue.main.async { self.isFetchingModels = false }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isFetchingModels = false
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let modelsList = json["models"] as? [[String: Any]] else {
                    self.fetchState = .offlineFallback(count: self.availableModels.count)
                    return
                }
                
                var discovered: [String] = []
                for item in modelsList {
                    if let methods = item["supportedGenerationMethods"] as? [String],
                       methods.contains("generateContent"),
                       let name = item["name"] as? String {
                        let cleanName = name.replacingOccurrences(of: "models/", with: "")
                        let lower = cleanName.lowercased()
                        if !self.isModelDeprecated(cleanName) &&
                           !lower.contains("embedding") &&
                           !lower.contains("aqa") &&
                           !lower.contains("imagen") &&
                           !lower.contains("tts") &&
                           !lower.contains("whisper") {
                            discovered.append(cleanName)
                        }
                    }
                }
                
                // Unisci con i modelli d'avanguardia 2026 configurati
                for m in self.selectedProvider.staticFallbackModels.reversed() {
                    if !discovered.contains(m) {
                        discovered.insert(m, at: 0)
                    }
                }
                
                // Ordina preferendo le versioni più alte in cima (4, 3.8, 3.0, 2.5, 2.0)
                discovered.sort { a, b in
                    func score(_ s: String) -> Int {
                        if s.contains("4") { return 100 }
                        if s.contains("3.8") { return 90 }
                        if s.contains("3.0") { return 80 }
                        if s.contains("2.5") { return 70 }
                        if s.contains("2.0") { return 60 }
                        return 10
                    }
                    let sa = score(a)
                    let sb = score(b)
                    if sa != sb { return sa > sb }
                    return a < b
                }
                
                self.updateModelList(discovered)
                self.fetchState = .liveDiscoveredGoogle(count: discovered.count)
            }
        }.resume()
    }
    
    private func fetchOpenAIModels(endpoint: String) {
        guard let url = URL(string: endpoint) else {
            DispatchQueue.main.async { self.isFetchingModels = false }
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isFetchingModels = false
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataArray = json["data"] as? [[String: Any]] else {
                    self.fetchState = .offlineFallback(count: self.availableModels.count)
                    return
                }
                
                var discovered: [String] = []
                for item in dataArray {
                    if let id = item["id"] as? String {
                        if let shutdownDate = item["shutdown_date"] as? String, !shutdownDate.isEmpty {
                            continue
                        }
                        
                        let lower = id.lowercased()
                        let isValidOpenAI = lower.hasPrefix("gpt-5") ||
                                            lower.hasPrefix("gpt-4.5") ||
                                            lower.hasPrefix("gpt-4o") ||
                                            lower.hasPrefix("o1") ||
                                            lower.hasPrefix("o3") ||
                                            lower.hasPrefix("o4")
                        let isValidOther = lower.hasPrefix("deepseek") ||
                                           lower.hasPrefix("llama-4") ||
                                           lower.hasPrefix("llama-3.3") ||
                                           lower.hasPrefix("llama-3.1") ||
                                           lower.hasPrefix("qwen")
                        
                        if !self.isModelDeprecated(id) &&
                           (isValidOpenAI || isValidOther) &&
                           !lower.contains("embedding") && !lower.contains("audio") && !lower.contains("realtime") && !lower.contains("tts") && !lower.contains("moderation") {
                            discovered.append(id)
                        }
                    }
                }
                
                // Unisci con il catalogo d'avanguardia del provider
                for m in self.selectedProvider.staticFallbackModels.reversed() {
                    if !discovered.contains(m) {
                        discovered.insert(m, at: 0)
                    }
                }
                
                discovered.sort { a, b in
                    func score(_ s: String) -> Int {
                        if s.contains("gpt-5") || s.contains("llama-4") || s.contains("o3") { return 100 }
                        if s.contains("gpt-4.5") || s.contains("deepseek-v3") || s.contains("deepseek-r1") { return 90 }
                        if s.contains("o1") || s.contains("llama-3.3") { return 80 }
                        if s.contains("gpt-4o") { return 70 }
                        return 10
                    }
                    let sa = score(a)
                    let sb = score(b)
                    if sa != sb { return sa > sb }
                    return a < b
                }
                
                self.updateModelList(discovered)
                self.fetchState = .liveDiscovered(count: discovered.count)
            }
        }.resume()
    }
    
    private func updateModelList(_ list: [String]) {
        let cleanList = list.filter { !self.isModelDeprecated($0) }
        self.availableModels = cleanList
        let cacheKey = "CachedModels_\(selectedProvider.rawValue)"
        UserDefaults.standard.set(cleanList, forKey: cacheKey)
        if !self.availableModels.contains(selectedModel) {
            if let first = self.availableModels.first {
                self.selectedModel = first
            }
        }
    }
    
    // MARK: - Funzioni di Valutazione
    
    func evaluateFaultCodes(_ codes: [String]) {
        let lang = LocalizationManager.shared.currentLanguage
        
        guard !codes.isEmpty else {
            switch lang {
            case .italian: self.evaluationResult = "Nessun codice errore da valutare."
            case .english: self.evaluationResult = "No fault codes to evaluate."
            case .french: self.evaluationResult = "Aucun code défaut à évaluer."
            case .spanish: self.evaluationResult = "Ningún código de error para evaluar."
            case .german: self.evaluationResult = "Keine Fehlercodes zur Auswertung vorhanden."
            }
            return
        }
        guard !apiKey.isEmpty || selectedProvider == .custom else {
            switch lang {
            case .italian: self.evaluationResult = "Inserisci una API Key per \(selectedProvider.rawValue) nella scheda Setup."
            case .english: self.evaluationResult = "Please enter an API Key for \(selectedProvider.rawValue) in Setup."
            case .french: self.evaluationResult = "Veuillez saisir une clé API pour \(selectedProvider.rawValue) dans l'onglet Configuration."
            case .spanish: self.evaluationResult = "Introduce una clave API para \(selectedProvider.rawValue) en la pestaña Ajustes."
            case .german: self.evaluationResult = "Bitte geben Sie einen API-Schlüssel für \(selectedProvider.rawValue) im Setup ein."
            }
            return
        }
        
        isEvaluating = true
        switch lang {
        case .italian: self.evaluationResult = "Valutazione diagnostica in corso tramite \(selectedProvider.rawValue) (\(selectedModel))..."
        case .english: self.evaluationResult = "Diagnostic evaluation in progress via \(selectedProvider.rawValue) (\(selectedModel))..."
        case .french: self.evaluationResult = "Évaluation diagnostique en cours via \(selectedProvider.rawValue) (\(selectedModel))..."
        case .spanish: self.evaluationResult = "Evaluación diagnóstica en curso con \(selectedProvider.rawValue) (\(selectedModel))..."
        case .german: self.evaluationResult = "Diagnoseauswertung läuft über \(selectedProvider.rawValue) (\(selectedModel))..."
        }
        
        let codesStr = codes.joined(separator: ", ")
        let prompt: String
        switch lang {
        case .italian:
            prompt = "Sei un ingegnere e capo-meccanico specializzato in motoveicoli giapponesi. Ti fornisco i codici di errore (DTC) rilevati dalla centralina (FI ECU o ABS) tramite interfaccia OBD2: \(codesStr). Spiega in modo chiaro e pratico: 1) Significato esatto del guasto; 2) Possibili cause primarie (sensori, cablaggi, alimentazione o problemi meccanici); 3) Sequenza di controlli e interventi raccomandati da eseguire. Rispondi in italiano formattando la risposta in Markdown in modo ordinato."
        case .english:
            prompt = "You are a professional motorcycle master mechanic and diagnostic engineer specialized in Japanese motorcycles. Here are the fault codes (DTC) detected from the ECU (FI ECU or ABS) via OBD2 interface: \(codesStr). Explain clearly and practically: 1) Exact meaning of each fault; 2) Primary root causes (sensors, wiring, power supply, or mechanical issues); 3) Step-by-step diagnostic and troubleshooting procedure to resolve the issue. Respond in English formatted in clean Markdown."
        case .french:
            prompt = "Vous êtes un ingénieur mécanique et chef d'atelier spécialisé dans les motos japonaises. Voici les codes défaut (DTC) relevés sur le calculateur (FI ECU ou ABS) via interface OBD2 : \(codesStr). Expliquez de manière claire et pratique : 1) La signification exacte du défaut ; 2) Les causes probables (capteurs, faisceau électrique, alimentation ou problème mécanique) ; 3) La méthode de contrôle et de réparation recommandée. Répondez en français soigneusement mis en forme en Markdown."
        case .spanish:
            prompt = "Eres un ingeniero mecánico y jefe de taller especializado en motocicletas japonesas. Te proporciono los códigos de avería (DTC) detectados en la centralita (FI ECU o ABS) mediante interfaz OBD2: \(codesStr). Explica de forma clara y práctica: 1) Significado exacto de la avería; 2) Causas principales (sensores, cableado, alimentación o fallos mecánicos); 3) Secuencia recomendada de comprobaciones y reparación. Responde en español con formato Markdown claro y estructurado."
        case .german:
            prompt = "Sie sind ein erfahrener Zweirad-Mechanikermeister und Diagnosespezialist für japanische Motorräder. Hier sind die über die OBD2-Schnittstelle ausgelesenen Fehlercodes (DTC) des Steuergeräts (FI ECU oder ABS): \(codesStr). Erklären Sie praxisnah und präzise: 1) Genaue Fehlerbedeutung; 2) Häufigste Ursachen (Sensoren, Kabelbaum, Spannungsversorgung oder mechanische Probleme); 3) Empfohlene Prüfschritte und Reparaturmaßnahmen. Antworten Sie auf Deutsch, übersichtlich formatiert in Markdown."
        }
        
        sendPromptToLLM(prompt)
    }
    
    func evaluateTelemetry(csvData: String) {
        let lang = LocalizationManager.shared.currentLanguage
        guard !apiKey.isEmpty || selectedProvider == .custom else {
            switch lang {
            case .italian: self.evaluationResult = "Inserisci una API Key per \(selectedProvider.rawValue) nella scheda Setup."
            case .english: self.evaluationResult = "Please enter an API Key for \(selectedProvider.rawValue) in Setup."
            case .french: self.evaluationResult = "Veuillez saisir une clé API pour \(selectedProvider.rawValue) dans l'onglet Configuration."
            case .spanish: self.evaluationResult = "Introduce una clave API para \(selectedProvider.rawValue) en la pestaña Ajustes."
            case .german: self.evaluationResult = "Bitte geben Sie einen API-Schlüssel für \(selectedProvider.rawValue) im Setup ein."
            }
            return
        }
        guard !csvData.isEmpty else {
            switch lang {
            case .italian: self.evaluationResult = "Nessun dato di telemetria da analizzare. Registra prima dei dati nel cruscotto."
            case .english: self.evaluationResult = "No telemetry data to analyze. Start recording in Dashboard first."
            case .french: self.evaluationResult = "Aucune donnée de télémétrie à analyser. Démarrez d'abord l'enregistrement dans le tableau de bord."
            case .spanish: self.evaluationResult = "Sin datos de telemetría para analizar. Inicia primero la grabación en el Tablero."
            case .german: self.evaluationResult = "Keine Telemetriedaten vorhanden. Zuerst Aufnahme im Cockpit starten."
            }
            return
        }
        
        isEvaluating = true
        switch lang {
        case .italian: self.evaluationResult = "Analisi della telemetria in corso tramite \(selectedProvider.rawValue) (\(selectedModel))..."
        case .english: self.evaluationResult = "Telemetry analysis in progress via \(selectedProvider.rawValue) (\(selectedModel))..."
        case .french: self.evaluationResult = "Analyse de la télémétrie en cours via \(selectedProvider.rawValue) (\(selectedModel))..."
        case .spanish: self.evaluationResult = "Análisis de telemetría en curso con \(selectedProvider.rawValue) (\(selectedModel))..."
        case .german: self.evaluationResult = "Telemetrie-Analyse läuft über \(selectedProvider.rawValue) (\(selectedModel))..."
        }
        
        let prompt: String
        switch lang {
        case .italian:
            prompt = "Sei un ingegnere di pista esperto di telemetria e diagnostica moto. Analizza i seguenti campioni di telemetria OBD2 acquisiti su motoveicolo in formato CSV. Valuta il comportamento termico, l'erogazione, il regime di minimo, la tensione batteria e la sonda lambda. Segnala eventuali anomalie rispetto alle tolleranze standard e fornisci un riepilogo sintetico in italiano formattato in Markdown.\n\nDati Telemetria:\n\(csvData)"
        case .english:
            prompt = "You are a track engineer specialized in motorcycle telemetry and diagnostics. Analyze the following OBD2 telemetry samples acquired on a motorcycle in CSV format. Evaluate thermal behavior, engine delivery, idle RPM stability, battery voltage, and lambda O2 response. Highlight any deviation from standard operational tolerances and provide a clean Markdown summary in English.\n\nTelemetry Data:\n\(csvData)"
        case .french:
            prompt = "Vous êtes un ingénieur de piste expert en télémétrie et diagnostic moto. Analysez les échantillons de télémétrie OBD2 suivants au format CSV. Évaluez le comportement thermique, la réponse moteur, le régime de ralenti, la tension batterie et la sonde lambda. Signalez toute anomalie par rapport aux tolérances constructeur et fournissez une synthèse en français formatée en Markdown.\n\nDonnées Télémétrie:\n\(csvData)"
        case .spanish:
            prompt = "Eres un ingeniero de pista especialista en telemetría y diagnosis de motocicletas. Analiza las siguientes muestras de telemetría OBD2 adquiridas en formato CSV. Evalúa el comportamiento térmico, la entrega de potencia, el ralentí, el voltaje de la batería y la sonda lambda. Señala cualquier anomalía respecto a tolerancias estándar y proporciona un resumen conciso en español formateado en Markdown.\n\nDatos de Telemetría:\n\(csvData)"
        case .german:
            prompt = "Sie sind ein erfahrener Renningenieur für Motorrad-Telemetrie und Diagnose. Analysieren Sie die folgenden OBD2-Telemetriedaten eines Motorrads im CSV-Format. Bewerten Sie Temperaturverhalten, Gasannahme, Leerlaufstabilität, Batteriespannung und Lambdasonden-Regelung. Weisen Sie auf Abweichungen hin und erstellen Sie eine übersichtliche Zusammenfassung auf Deutsch in Markdown.\n\nTelemetriedaten:\n\(csvData)"
        }
        
        sendPromptToLLM(prompt)
    }
    
    // MARK: - Dispatcher Chiamate HTTP per i vari Provider
    
    private func sendPromptToLLM(_ prompt: String) {
        switch selectedProvider {
        case .gemini:
            callGeminiAPI(prompt: prompt)
        case .anthropic:
            callAnthropicAPI(prompt: prompt)
        case .openai, .deepseek, .groq, .custom:
            callOpenAICompatibleAPI(prompt: prompt)
        }
    }
    
    // 1) Google Gemini
    private func callGeminiAPI(prompt: String) {
        let model = selectedModel.isEmpty ? "gemini-4-flash" : selectedModel
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlStr) else {
            self.setResult("URL API non valido per Gemini.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            self.setResult("Errore nella preparazione richiesta: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                self.setResult("Errore di rete: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                self.setResult("Nessuna risposta ricevuta da Gemini.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    self.setResult(text)
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let errorDict = json["error"] as? [String: Any],
                          let msg = errorDict["message"] as? String {
                    self.setResult("Errore Gemini: \(msg)")
                } else {
                    self.setResult("Impossibile decodificare la risposta di Gemini.")
                }
            } catch {
                self.setResult("Errore decodifica JSON Gemini.")
            }
        }.resume()
    }
    
    // 2) OpenAI / DeepSeek / Groq / Local (Ollama/LMStudio)
    private func callOpenAICompatibleAPI(prompt: String) {
        let endpointUrlStr: String
        let model = selectedModel.isEmpty ? selectedProvider.defaultModel : selectedModel
        
        switch selectedProvider {
        case .openai:
            endpointUrlStr = "https://api.openai.com/v1/chat/completions"
        case .deepseek:
            endpointUrlStr = "https://api.deepseek.com/chat/completions"
        case .groq:
            endpointUrlStr = "https://api.groq.com/openai/v1/chat/completions"
        case .custom:
            var base = customEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            if base.hasSuffix("/") { base.removeLast() }
            endpointUrlStr = base.contains("/chat/completions") ? base : "\(base)/chat/completions"
        default:
            endpointUrlStr = "https://api.openai.com/v1/chat/completions"
        }
        
        guard let url = URL(string: endpointUrlStr) else {
            self.setResult("Endpoint URL non valido: \(endpointUrlStr)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "Sei un ingegnere meccanico ed esperto di telemetria e diagnostica moto."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.4
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            self.setResult("Errore preparazione JSON: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                self.setResult("Errore di rete: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                self.setResult("Nessuna risposta ricevuta dal server.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let choices = json["choices"] as? [[String: Any]],
                       let first = choices.first,
                       let message = first["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        self.setResult(content)
                        return
                    }
                    if let errDict = json["error"] as? [String: Any], let msg = errDict["message"] as? String {
                        self.setResult("Errore API \(self.selectedProvider.rawValue): \(msg)")
                        return
                    }
                }
                self.setResult("Risposta API non riconosciuta o vuota.")
            } catch {
                self.setResult("Errore decodifica JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // 3) Anthropic Claude
    private func callAnthropicAPI(prompt: String) {
        let model = selectedModel.isEmpty ? "claude-4-sonnet" : selectedModel
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            self.setResult("URL Anthropic non valido.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "system": "Sei un ingegnere meccanico ed esperto di telemetria e diagnostica moto.",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            self.setResult("Errore preparazione JSON: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                self.setResult("Errore di rete: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                self.setResult("Nessuna risposta ricevuta da Anthropic.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let contentArray = json["content"] as? [[String: Any]],
                       let first = contentArray.first,
                       let text = first["text"] as? String {
                        self.setResult(text)
                        return
                    }
                    if let errDict = json["error"] as? [String: Any], let msg = errDict["message"] as? String {
                        self.setResult("Errore Claude: \(msg)")
                        return
                    }
                }
                self.setResult("Risposta Claude non decodificabile.")
            } catch {
                self.setResult("Errore decodifica JSON Claude: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func setResult(_ text: String) {
        DispatchQueue.main.async {
            self.isEvaluating = false
            self.evaluationResult = text
        }
    }
}

