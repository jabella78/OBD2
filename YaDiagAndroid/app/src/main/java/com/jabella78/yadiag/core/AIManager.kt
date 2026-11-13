package com.jabella78.yadiag.core

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

enum class AIProvider(val id: String) {
    GEMINI("Google Gemini"),
    OPENAI("OpenAI"),
    ANTHROPIC("Anthropic (Claude)"),
    DEEPSEEK("DeepSeek"),
    GROQ("Groq"),
    CUSTOM("Custom (OpenAI Format)");

    val defaultBaseURL: String
        get() = when (this) {
            GEMINI -> "https://generativelanguage.googleapis.com/v1beta/models/"
            OPENAI -> "https://api.openai.com/v1/chat/completions"
            ANTHROPIC -> "https://api.anthropic.com/v1/messages"
            DEEPSEEK -> "https://api.deepseek.com/chat/completions"
            GROQ -> "https://api.groq.com/openai/v1/chat/completions"
            CUSTOM -> "https://your-custom-endpoint.com/v1/chat/completions"
        }

    val modelsListURL: String?
        get() = when (this) {
            GEMINI -> "https://generativelanguage.googleapis.com/v1beta/models"
            OPENAI -> "https://api.openai.com/v1/models"
            DEEPSEEK -> "https://api.deepseek.com/models"
            GROQ -> "https://api.groq.com/openai/v1/models"
            ANTHROPIC, CUSTOM -> null
        }

    val fallbackModels: List<String>
        get() = when (this) {
            GEMINI -> listOf("gemini-2.5-flash", "gemini-2.5-pro", "gemini-2.0-flash", "gemini-2.0-flash-lite")
            OPENAI -> listOf("gpt-4o", "gpt-4o-mini", "o3-mini", "o1-mini")
            ANTHROPIC -> listOf("claude-sonnet-4-20250514", "claude-3-7-sonnet-20250219", "claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022")
            DEEPSEEK -> listOf("deepseek-chat", "deepseek-reasoner")
            GROQ -> listOf("llama-3.3-70b-versatile", "llama-3.1-8b-instant", "qwen-qwq-32b", "gemma2-9b-it")
            CUSTOM -> listOf("local-model", "llama3")
        }

    val defaultModel: String
        get() = fallbackModels.firstOrNull() ?: ""

    companion object {
        fun fromId(id: String): AIProvider {
            return entries.firstOrNull { it.id == id } ?: GEMINI
        }
    }
}

sealed class ModelFetchState {
    data object Idle : ModelFetchState()
    data object Loading : ModelFetchState()
    data class Loaded(val count: Int) : ModelFetchState()
    data class Failed(val message: String) : ModelFetchState()
}

class AIManager(context: Context) {
    private val prefs = context.getSharedPreferences("yadiag_ai_prefs", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    var selectedProvider: AIProvider by mutableStateOf(
        AIProvider.fromId(prefs.getString("ai_provider", AIProvider.GEMINI.id) ?: AIProvider.GEMINI.id)
    )
        private set

    var apiKey: String by mutableStateOf("")
        private set

    var selectedModel: String by mutableStateOf(
        prefs.getString("ai_model", AIProvider.GEMINI.defaultModel) ?: AIProvider.GEMINI.defaultModel
    )
        private set

    var customEndpoint: String by mutableStateOf(
        prefs.getString("ai_custom_endpoint", AIProvider.GEMINI.defaultBaseURL) ?: AIProvider.GEMINI.defaultBaseURL
    )
        private set

    var availableModels: List<String> by mutableStateOf(emptyList())
        private set

    var modelFetchState: ModelFetchState by mutableStateOf(ModelFetchState.Idle)
        private set

    var isEvaluating: Boolean by mutableStateOf(false)
        private set

    var evaluationResult: String by mutableStateOf("")
        private set

    private var cachedModelsByProvider: MutableMap<String, List<String>> = mutableMapOf()

    init {
        // Migrate legacy plaintext API key if present
        val legacyKey = prefs.getString("ai_api_key", null)
        if (!legacyKey.isNullOrEmpty()) {
            KeychainHelper.save(legacyKey, "ai_api_key")
            prefs.edit().remove("ai_api_key").apply()
        }
        apiKey = KeychainHelper.load("ai_api_key") ?: ""

        loadCachedModels()
        refreshActiveModelList()
    }

    fun updateProvider(provider: AIProvider) {
        if (selectedProvider == provider) return
        selectedProvider = provider
        prefs.edit().putString("ai_provider", provider.id).apply()
        updateCustomEndpoint(provider.defaultBaseURL)
        refreshActiveModelList()
        if (apiKey.isNotEmpty() && provider.modelsListURL != null) {
            fetchAvailableModels()
        }
    }

    fun updateApiKey(newKey: String) {
        apiKey = newKey
        KeychainHelper.save(newKey, "ai_api_key")
    }

    fun updateSelectedModel(model: String) {
        selectedModel = model
        prefs.edit().putString("ai_model", model).apply()
    }

    fun updateCustomEndpoint(endpoint: String) {
        customEndpoint = endpoint
        prefs.edit().putString("ai_custom_endpoint", endpoint).apply()
    }

    fun clearEvaluationResult() {
        evaluationResult = ""
    }

    private fun refreshActiveModelList() {
        val cached = cachedModelsByProvider[selectedProvider.id]
        val list = if (!cached.isNullOrEmpty()) cached else selectedProvider.fallbackModels
        availableModels = list
        if (!list.contains(selectedModel)) {
            updateSelectedModel(list.firstOrNull() ?: selectedProvider.defaultModel)
        }
    }

    private fun loadCachedModels() {
        val raw = prefs.getString("ai_cached_models_v1", null) ?: return
        try {
            val obj = JSONObject(raw)
            val keys = obj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val arr = obj.getJSONArray(key)
                val models = mutableListOf<String>()
                for (i in 0 until arr.length()) {
                    models.add(arr.getString(i))
                }
                cachedModelsByProvider[key] = models
            }
        } catch (_: Exception) {
        }
    }

    private fun saveCachedModels() {
        try {
            val obj = JSONObject()
            for ((k, v) in cachedModelsByProvider) {
                val arr = JSONArray()
                v.forEach { arr.put(it) }
                obj.put(k, arr)
            }
            prefs.edit().putString("ai_cached_models_v1", obj.toString()).apply()
        } catch (_: Exception) {
        }
    }

    fun fetchAvailableModels() {
        val trimmedKey = apiKey.trim()
        if (trimmedKey.isEmpty()) {
            modelFetchState = ModelFetchState.Failed("Missing API Key")
            return
        }

        val provider = selectedProvider
        val listURLString = provider.modelsListURL
        if (listURLString == null) {
            availableModels = provider.fallbackModels
            modelFetchState = ModelFetchState.Loaded(provider.fallbackModels.size)
            return
        }

        modelFetchState = ModelFetchState.Loading

        scope.launch {
            try {
                val fetched = withContext(Dispatchers.IO) {
                    when (provider) {
                        AIProvider.GEMINI -> fetchGeminiModels(listURLString, trimmedKey)
                        AIProvider.OPENAI, AIProvider.DEEPSEEK, AIProvider.GROQ ->
                            fetchOpenAIModels(listURLString, trimmedKey, provider)
                        else -> provider.fallbackModels
                    }
                }

                if (fetched.isNotEmpty()) {
                    cachedModelsByProvider[provider.id] = fetched
                    saveCachedModels()
                    if (selectedProvider == provider) {
                        availableModels = fetched
                        if (!fetched.contains(selectedModel)) {
                            updateSelectedModel(fetched.first())
                        }
                        modelFetchState = ModelFetchState.Loaded(fetched.size)
                    }
                } else {
                    if (selectedProvider == provider) {
                        availableModels = provider.fallbackModels
                        modelFetchState = ModelFetchState.Failed("No compatible models found")
                    }
                }
            } catch (e: Exception) {
                if (selectedProvider == provider) {
                    availableModels = cachedModelsByProvider[provider.id] ?: provider.fallbackModels
                    modelFetchState = ModelFetchState.Failed(e.localizedMessage ?: "Error")
                }
            }
        }
    }

    private fun fetchGeminiModels(baseURL: String, key: String): List<String> {
        val url = URL("$baseURL?key=$key")
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 10000
            readTimeout = 10000
        }

        val code = conn.responseCode
        val body = (if (code in 200..299) conn.inputStream else conn.errorStream)
            ?.bufferedReader()?.use { it.readText() } ?: ""

        if (code != 200) {
            throw Exception(extractAPIErrorMessage(body) ?: "HTTP $code")
        }

        val json = JSONObject(body)
        val modelsArray = json.optJSONArray("models") ?: return emptyList()

        val validModels = mutableListOf<String>()
        for (i in 0 until modelsArray.length()) {
            val m = modelsArray.getJSONObject(i)
            val rawName = m.optString("name", "")
            val methodsArr = m.optJSONArray("supportedGenerationMethods")
            var supportsGenerate = false
            if (methodsArr != null) {
                for (j in 0 until methodsArr.length()) {
                    if (methodsArr.optString(j) == "generateContent") {
                        supportsGenerate = true
                        break
                    }
                }
            }
            if (!supportsGenerate) continue

            val id = rawName.removePrefix("models/")
            val lower = id.lowercase()

            if (!lower.startsWith("gemini-")) continue
            if (lower.startsWith("gemini-1.0") || lower.startsWith("gemini-1.5") || lower == "gemini-pro" || lower == "gemini-pro-vision") continue
            if (lower.contains("embedding") || lower.contains("imagen") || lower.contains("veo") ||
                lower.contains("aqa") || lower.contains("tts") || lower.contains("audio") ||
                lower.contains("robotics") || lower.contains("computer-use") || lower.contains("learnlm")
            ) continue

            val description = m.optString("description", "").lowercase()
            if (description.contains("deprecated") || description.contains("discontinued")) continue

            validModels.add(id)
        }

        return validModels.sortedWith { a, b ->
            val aStable = !a.contains("exp") && !a.contains("preview")
            val bStable = !b.contains("exp") && !b.contains("preview")
            if (aStable != bStable) {
                if (aStable) -1 else 1
            } else {
                b.compareTo(a)
            }
        }
    }

    private fun fetchOpenAIModels(urlString: String, key: String, provider: AIProvider): List<String> {
        val url = URL(urlString)
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            setRequestProperty("Authorization", "Bearer $key")
            connectTimeout = 10000
            readTimeout = 10000
        }

        val code = conn.responseCode
        val body = (if (code in 200..299) conn.inputStream else conn.errorStream)
            ?.bufferedReader()?.use { it.readText() } ?: ""

        if (code != 200) {
            throw Exception(extractAPIErrorMessage(body) ?: "HTTP $code")
        }

        val json = JSONObject(body)
        val dataArray = json.optJSONArray("data") ?: return emptyList()

        val validModels = mutableListOf<String>()
        for (i in 0 until dataArray.length()) {
            val item = dataArray.getJSONObject(i)
            val id = item.optString("id", "")
            if (id.isEmpty()) continue
            if (item.optBoolean("deprecated", false)) continue
            if (item.has("active") && !item.optBoolean("active", true)) continue

            val lower = id.lowercase()
            if (lower.contains("embedding") || lower.contains("whisper") || lower.contains("tts") ||
                lower.contains("dall-e") || lower.contains("moderation") || lower.contains("realtime") ||
                lower.contains("audio") || lower.contains("transcribe") || lower.contains("guard") ||
                lower.contains("vision-preview") || lower.contains("instruct") || lower.contains("babbage") ||
                lower.contains("davinci")
            ) continue

            if (provider == AIProvider.OPENAI) {
                if (!(lower.startsWith("gpt-4") || lower.startsWith("gpt-5") || lower.startsWith("o1") || lower.startsWith("o3") || lower.startsWith("o4"))) continue
                if (lower.contains("0314") || lower.contains("0613") || lower.contains("1106") || lower.contains("0125")) continue
            }

            validModels.add(id)
        }

        return validModels.sorted()
    }

    private fun extractAPIErrorMessage(body: String): String? {
        return try {
            val json = JSONObject(body)
            val errObj = json.optJSONObject("error")
            if (errObj != null) {
                errObj.optString("message").takeIf { it.isNotEmpty() }
            } else {
                json.optString("message").takeIf { it.isNotEmpty() }
            }
        } catch (_: Exception) {
            null
        }
    }

    fun evaluateFaultCodes(
        codes: List<String>,
        descriptions: Map<String, String>,
        telemetryContext: String,
        language: AppLanguage = AppLanguage.ITALIAN
    ) {
        if (apiKey.trim().isEmpty()) {
            val msg = when (language) {
                AppLanguage.ITALIAN -> "Errore: Chiave API mancante. Inseriscila nelle Impostazioni per abilitare l'Intelligenza Artificiale."
                AppLanguage.ENGLISH -> "Error: Missing API Key. Please enter it in Settings to enable AI evaluation."
                AppLanguage.FRENCH -> "Erreur: Clé API manquante. Veuillez la saisir dans les Paramètres pour activer l'IA."
                AppLanguage.SPANISH -> "Error: Falta la clave API. Introdúcela en Ajustes para activar la IA."
                AppLanguage.GERMAN -> "Fehler: API-Schlüssel fehlt. Bitte in den Einstellungen eingeben, um die KI zu aktivieren."
            }
            evaluationResult = msg
            return
        }

        if (codes.isEmpty()) {
            val msg = when (language) {
                AppLanguage.ITALIAN -> "Nessun codice di errore (DTC) rilevato da analizzare. La moto sembra in perfetto stato!"
                AppLanguage.ENGLISH -> "No trouble codes (DTC) detected to analyze. The motorcycle appears to be in great condition!"
                AppLanguage.FRENCH -> "Aucun code d'erreur (DTC) détecté à analyser. La moto semble en parfait état !"
                AppLanguage.SPANISH -> "¡No se detectaron códigos de falla (DTC) para analizar. La motocicleta parece estar en perfecto estado!"
                AppLanguage.GERMAN -> "Keine Fehlercodes (DTC) zur Analyse erkannt. Das Motorrad scheint in einwandfreiem Zustand zu sein!"
            }
            evaluationResult = msg
            return
        }

        isEvaluating = true
        evaluationResult = when (language) {
            AppLanguage.ITALIAN -> "Analisi in corso con ${selectedProvider.id} ($selectedModel)... Attendere prego."
            AppLanguage.ENGLISH -> "Analyzing with ${selectedProvider.id} ($selectedModel)... Please wait."
            AppLanguage.FRENCH -> "Analyse en cours avec ${selectedProvider.id} ($selectedModel)... Veuillez patienter."
            AppLanguage.SPANISH -> "Analizando con ${selectedProvider.id} ($selectedModel)... Por favor espere."
            AppLanguage.GERMAN -> "Analyse läuft mit ${selectedProvider.id} ($selectedModel)... Bitte warten."
        }

        val unknownLabel = when (language) {
            AppLanguage.ITALIAN -> "Guasto sconosciuto"
            AppLanguage.ENGLISH -> "Unknown fault"
            AppLanguage.FRENCH -> "Défaut inconnu"
            AppLanguage.SPANISH -> "Fallo desconocido"
            AppLanguage.GERMAN -> "Unbekannter Fehler"
        }

        val dtcListString = codes.joinToString("\n") { code ->
            val desc = descriptions[code] ?: unknownLabel
            "- $code: $desc"
        }

        val prompt = when (language) {
            AppLanguage.ITALIAN -> """
            Sei un Ingegnere Meccanico Esperto specializzato in diagnostica elettronica per motociclette Yamaha (in particolare motori CP3 come Tracer 900, MT-09, XSR900, e simili come MT-07, Ténéré 700, TMAX).
            
            L'utente ha appena eseguito una scansione OBD2 sulla sua moto trovando i seguenti codici di errore (DTC):
            $dtcListString
            
            Contesto telemetrico attuale della moto:
            $telemetryContext
            
            Per favore, fornisci una relazione tecnica chiara, concisa e strutturata in italiano:
            1. **Gravità del Problema**: Indica chiaramente se è sicuro continuare a guidare la moto o se bisogna fermarsi immediatamente.
            2. **Causa Tecnica**: Spiega cosa significano questi errori e come potrebbero essere correlati tra loro (es. un calo di tensione della batteria che genera errori a cascata sull'ABS o sulla farfalla YCC-T).
            3. **Controlli Consigliati (Fai-da-te)**: Elenca 2 o 3 verifiche pratiche che il motociclista può fare subito (es. controllo morsetti batteria, fusibili, pulizia sensori, connettori ossidati).
            4. **Intervento in Officina**: Cosa dovrà fare il meccanico se i controlli base non risolvono.
            """.trimIndent()

            AppLanguage.ENGLISH -> """
            You are an Expert Motorcycle Mechanical Engineer specialized in electronic diagnostics for Yamaha motorcycles (especially CP3 engines like Tracer 900, MT-09, XSR900, as well as MT-07, Ténéré 700, TMAX).
            
            The user just performed an OBD2 scan on their motorcycle and found the following Diagnostic Trouble Codes (DTC):
            $dtcListString
            
            Current motorcycle telemetry context:
            $telemetryContext
            
            Please provide a clear, concise, and structured technical report in English:
            1. **Severity Assessment**: Clearly state whether it is safe to continue riding or if the motorcycle must be stopped immediately.
            2. **Technical Root Cause**: Explain what these codes mean and how they might relate to each other (e.g., low battery voltage triggering cascading ABS or YCC-T throttle faults).
            3. **Recommended DIY Checks**: List 2 or 3 practical checks the rider can perform right away (e.g., battery terminals, fuses, sensor cleaning, corroded connectors).
            4. **Workshop Action**: What a professional mechanic will need to do if basic checks do not resolve the issue.
            """.trimIndent()

            AppLanguage.FRENCH -> """
            Vous êtes un Ingénieur Mécanicien Expert spécialisé dans le diagnostic électronique des motos Yamaha (en particulier les moteurs CP3 comme Tracer 900, MT-09, XSR900, ainsi que MT-07, Ténéré 700, TMAX).
            
            L'utilisateur vient d'effectuer un scan OBD2 sur sa moto et a trouvé les codes défauts (DTC) suivants :
            $dtcListString
            
            Contexte télémétrique actuel de la moto :
            $telemetryContext
            
            Veuillez fournir un rapport technique clair, concis et structuré en français :
            1. **Gravité du Problème** : Indiquez clairement s'il est sûr de continuer à rouler ou s'il faut s'arrêter immédiatement.
            2. **Cause Technique** : Expliquez la signification de ces codes et comment ils peuvent être liés (ex. chute de tension batterie générant des erreurs en cascade sur l'ABS ou le boîtier papillon YCC-T).
            3. **Vérifications Recommandées (DIY)** : Listez 2 ou 3 contrôles pratiques que le motard peut faire immédiatement (bornes batterie, fusibles, nettoyage capteurs, connecteurs oxydés).
            4. **Intervention en Atelier** : Ce que le mécanicien devra faire si les contrôles de base ne suffisent pas.
            """.trimIndent()

            AppLanguage.SPANISH -> """
            Eres un Ingeniero Mecánico Experto especializado en diagnóstico electrónico para motocicletas Yamaha (especialmente motores CP3 como Tracer 900, MT-09, XSR900, así como MT-07, Ténéré 700, TMAX).
            
            El usuario acaba de realizar un escaneo OBD2 en su motocicleta encontrando los siguientes códigos de falla (DTC):
            $dtcListString
            
            Contexto telemétrico actual de la motocicleta:
            $telemetryContext
            
            Por favor, proporciona un informe técnico claro, conciso y estructurado en español:
            1. **Gravedad del Problema**: Indica claramente si es seguro seguir conduciendo o si debe detenerse de inmediato.
            2. **Causa Técnica**: Explica qué significan estos errores y cómo podrían estar relacionados entre sí (ej. caída de tensión de batería que genera errores en cascada en el ABS o acelerador electrónico YCC-T).
            3. **Comprobaciones Recomendadas (Bricolaje)**: Enumera 2 o 3 verificaciones prácticas que el motorista puede hacer de inmediato (bornes de batería, fusibles, limpieza de sensores, conectores sulfatados).
            4. **Intervención en Taller**: Qué deberá hacer el mecánico si las comprobaciones básicas no resuelven el problema.
            """.trimIndent()

            AppLanguage.GERMAN -> """
            Sie sind ein erfahrener Motorrad-Maschinenbauingenieur, spezialisiert auf elektronische Diagnose für Yamaha-Motorräder (insbesondere CP3-Motoren wie Tracer 900, MT-09, XSR900 sowie MT-07, Ténéré 700, TMAX).
            
            Der Benutzer hat gerade einen OBD2-Scan an seinem Motorrad durchgeführt und folgende Fehlercodes (DTC) gefunden:
            $dtcListString
            
            Aktueller Telemetrie-Kontext des Motorrads:
            $telemetryContext
            
            Bitte erstellen Sie einen klaren, prägnanten und strukturierten technischen Bericht auf Deutsch:
            1. **Schweregrad des Problems**: Geben Sie klar an, ob eine Weiterfahrt sicher ist oder ob das Motorrad sofort abgestellt werden muss.
            2. **Technische Ursache**: Erklären Sie, was diese Fehler bedeuten und wie sie zusammenhängen könnten (z. B. Unterspannung der Batterie, die Folgefehler im ABS oder der YCC-T-Drosselklappe auslöst).
            3. **Empfohlene Eigenkontrollen (DIY)**: Nennen Sie 2 bis 3 praktische Prüfungen, die der Fahrer sofort selbst durchführen kann (Batteriepole, Sicherungen, Sensorreinigung, korrodierte Stecker).
            4. **Werkstattmaßnahmen**: Was die Fachwerkstatt tun muss, wenn die Grundprüfungen das Problem nicht lösen.
            """.trimIndent()
        }

        dispatchPrompt(prompt)
    }

    fun evaluateTelemetry(telemetryContext: String, language: AppLanguage = AppLanguage.ITALIAN) {
        if (apiKey.trim().isEmpty()) {
            val msg = when (language) {
                AppLanguage.ITALIAN -> "Errore: Chiave API mancante. Inseriscila nelle Impostazioni per abilitare l'Intelligenza Artificiale."
                AppLanguage.ENGLISH -> "Error: Missing API Key. Please enter it in Settings to enable AI evaluation."
                AppLanguage.FRENCH -> "Erreur: Clé API manquante. Veuillez la saisir dans les Paramètres pour activer l'IA."
                AppLanguage.SPANISH -> "Error: Falta la clave API. Introdúcela en Ajustes para activar la IA."
                AppLanguage.GERMAN -> "Fehler: API-Schlüssel fehlt. Bitte in den Einstellungen eingeben, um die KI zu aktivieren."
            }
            evaluationResult = msg
            return
        }

        isEvaluating = true
        evaluationResult = when (language) {
            AppLanguage.ITALIAN -> "Analisi telemetrica e corpi farfallati in corso con ${selectedProvider.id} ($selectedModel)... Attendere prego."
            AppLanguage.ENGLISH -> "Analyzing telemetry and throttle bodies with ${selectedProvider.id} ($selectedModel)... Please wait."
            AppLanguage.FRENCH -> "Analyse télémétrique et corps de papillon en cours avec ${selectedProvider.id} ($selectedModel)... Veuillez patienter."
            AppLanguage.SPANISH -> "Analizando telemetría y cuerpos de aceleración con ${selectedProvider.id} ($selectedModel)... Por favor espere."
            AppLanguage.GERMAN -> "Telemetrie- und Drosselklappenanalyse läuft mit ${selectedProvider.id} ($selectedModel)... Bitte warten."
        }

        val prompt = when (language) {
            AppLanguage.ITALIAN -> """
            Sei un Ingegnere Meccanico Esperto specializzato in diagnostica elettronica per motociclette Yamaha (in particolare motori CP3 come Tracer 900, MT-09, XSR900, e simili come MT-07, Ténéré 700, TMAX).
            
            L'utente ha richiesto un'analisi preventiva dello stato di salute del motore e dei corpi farfallati basandosi sui seguenti parametri telemetrici e KWP2000 letti in tempo reale dalla centralina:
            $telemetryContext
            
            Nota tecnica importante per motori Yamaha CP3/CP2:
            - Con il tempo, i depositi carboniosi intorno alle farfalle riducono il passaggio d'aria al minimo.
            - La centralina compensa aprendo maggiormente la valvola ISC (Idle Speed Control - Sub-code 0x54). Un valore ISC basso (< 35%) indica corpi farfallati puliti; tra 40% e 60% indica accumulo moderato di sporco; oltre 60-65% indica corpi farfallati molto sporchi che richiedono pulizia fisica e successivo Reset ISC (Codice 67).
            - Il rapporto aria/carburante (AFR / O2 Voltage) e la compensazione O2 (Sub-code 0x52, dove 100% è neutro) indicano se la carburazione sta correggendo anomalie di aspirazione o scarico.
            - La pressione MAP al minimo su un motore sano a caldo si aggira tipicamente tra 30 e 42 kPa. Valori troppo alti possono indicare disallineamento dei corpi farfallati o valvole.
            
            Per favore, fornisci una relazione tecnica chiara, concisa e strutturata in italiano:
            1. **Stato di Salute Generale**: Valuta se i parametri termici, elettrici (Batteria) e di regime (RPM, TPS) sono nella norma.
            2. **Analisi Corpi Farfallati e Minimo (ISC / MAP)**: Interpreta i valori di apertura ISC, stima sporcizia corpi farfallati e depressione MAP per dire all'utente se i corpi farfallati sono puliti, se necessitano di sincronizzazione o di pulizia fisica con Reset ISC (Codice 67).
            3. **Analisi Carburazione e Sonda Lambda (AFR / O2)**: Commenta il valore AFR e la compensazione O2 (se disponibili) indicando se la miscela è corretta, magra o grassa.
            4. **Consigli di Manutenzione**: Suggerisci eventuali azioni preventive.
            """.trimIndent()

            AppLanguage.ENGLISH -> """
            You are an Expert Motorcycle Mechanical Engineer specialized in electronic diagnostics for Yamaha motorcycles (especially CP3 engines like Tracer 900, MT-09, XSR900, as well as MT-07, Ténéré 700, TMAX).
            
            The user requested a preventive health analysis of the engine and throttle bodies based on the following real-time OBD2 and KWP2000 telemetry parameters read from the ECU:
            $telemetryContext
            
            Important technical reference for Yamaha CP3/CP2 engines:
            - Over time, carbon deposits around the throttle plates restrict airflow at idle.
            - The ECU compensates by opening the ISC (Idle Speed Control - Sub-code 0x54) stepper valve further. A low ISC value (< 35%) indicates clean throttle bodies; 40% to 60% indicates moderate carbon buildup; above 60-65% indicates dirty throttle bodies requiring physical cleaning followed by an ISC Reset (Diagnostic Code 67).
            - Air/Fuel Ratio (AFR / O2 Voltage) and O2 fuel trim (Sub-code 0x52, where 100% is neutral) show whether closed-loop fueling is compensating for intake leaks or exhaust anomalies.
            - Idle MAP pressure on a healthy warm engine typically sits between 30 and 42 kPa. Higher values may suggest throttle body sync issues or tight valve clearances.
            
            Please provide a clear, concise, and structured technical report in English:
            1. **Overall Engine Health**: Evaluate whether thermal, electrical (Battery), and engine speed/load (RPM, TPS) parameters are normal.
            2. **Throttle Body & Idle Analysis (ISC / MAP)**: Interpret the ISC opening, estimated throttle body buildup, and MAP vacuum to advise whether the throttle bodies are clean or need cleaning/syncing and an ISC Reset (Code 67).
            3. **Fueling & Lambda Sensor Analysis (AFR / O2)**: Comment on the AFR and O2 trim values (if available), indicating whether the mixture is stoichiometric, lean, or rich.
            4. **Maintenance Recommendations**: Suggest any preventive maintenance actions.
            """.trimIndent()

            AppLanguage.FRENCH -> """
            Vous êtes un Ingénieur Mécanicien Expert spécialisé dans le diagnostic électronique des motos Yamaha (en particulier les moteurs CP3 comme Tracer 900, MT-09, XSR900, ainsi que MT-07, Ténéré 700, TMAX).
            
            L'utilisateur a demandé une analyse préventive de l'état de santé du moteur et des corps de papillon basée sur les paramètres télémétriques OBD2 et KWP2000 suivants :
            $telemetryContext
            
            Référence technique importante pour les moteurs Yamaha CP3/CP2 :
            - Avec le temps, les dépôts de calamine autour des papillons réduisent le passage d'air au ralenti.
            - L'ECU compense en ouvrant davantage la vanne ISC (Idle Speed Control - Sub-code 0x54). Une valeur ISC basse (< 35%) indique des corps propres ; entre 40% et 60% un encrassement modéré ; au-delà de 60-65% des corps très encrassés nécessitant un nettoyage physique suivi d'un Reset ISC (Code 67).
            - Le rapport air/carburant (AFR / Tension O2) et la correction O2 (Sub-code 0x52, où 100% est neutre) indiquent si l'injection corrige des anomalies.
            - La pression MAP au ralenti à chaud se situe généralement entre 30 et 42 kPa.
            
            Veuillez fournir un rapport technique clair, concis et structuré en français :
            1. **État de Santé Général** : Évaluez les paramètres thermiques, électriques (Batterie) et de régime (RPM, TPS).
            2. **Analyse Corps de Papillon et Ralenti (ISC / MAP)** : Interprétez l'ouverture ISC, l'encrassement estimé et la dépression MAP.
            3. **Analyse Carburation et Sonde Lambda (AFR / O2)** : Commentez les valeurs AFR et la correction O2.
            4. **Conseils d'Entretien** : Suggérez des actions préventives.
            """.trimIndent()

            AppLanguage.SPANISH -> """
            Eres un Ingeniero Mecánico Experto especializado en diagnóstico electrónico para motocicletas Yamaha (especialmente motores CP3 como Tracer 900, MT-09, XSR900, así como MT-07, Ténéré 700, TMAX).
            
            El usuario ha solicitado un análisis preventivo del estado de salud del motor y de los cuerpos de aceleración basado en los siguientes parámetros telemétricos OBD2 y KWP2000 leídos en tiempo real:
            $telemetryContext
            
            Referencia técnica importante para motores Yamaha CP3/CP2:
            - Con el tiempo, los depósitos de carbonilla alrededor de las mariposas reducen el paso de aire al ralentí.
            - La ECU compensa abriendo más la válvula ISC (Idle Speed Control - Sub-code 0x54). Un valor ISC bajo (< 35%) indica cuerpos limpios; entre 40% y 60% suciedad moderada; más de 60-65% cuerpos muy sucios que requieren limpieza física y posterior Reset ISC (Código 67).
            - La relación aire/combustible (AFR / Voltaje O2) y la compensación O2 (Sub-code 0x52, donde 100% es neutro) indican si la inyección está corrigiendo anomalías.
            - La presión MAP al ralentí en caliente suele estar entre 30 y 42 kPa.
            
            Por favor, proporciona un informe técnico claro, conciso y estructurado en español:
            1. **Estado de Salud General**: Evalúa los parámetros térmicos, eléctricos (Batería) y de régimen (RPM, TPS).
            2. **Análisis de Cuerpos de Aceleración y Ralentí (ISC / MAP)**: Interpreta la apertura ISC, la suciedad estimada y la presión MAP.
            3. **Análisis de Mezcla y Sonda Lambda (AFR / O2)**: Comenta el valor AFR y la compensación O2.
            4. **Consejos de Mantenimiento**: Sugiere acciones preventivas.
            """.trimIndent()

            AppLanguage.GERMAN -> """
            Sie sind ein erfahrener Motorrad-Maschinenbauingenieur, spezialisiert auf elektronische Diagnose für Yamaha-Motorräder (insbesondere CP3-Motoren wie Tracer 900, MT-09, XSR900 sowie MT-07, Ténéré 700, TMAX).
            
            Der Benutzer hat eine präventive Zustandsanalyse des Motors und der Drosselklappen angefordert, basierend auf den folgenden Echtzeit-OBD2- und KWP2000-Telemetrieparametern:
            $telemetryContext
            
            Wichtiger technischer Hinweis für Yamaha CP3/CP2-Motoren:
            - Mit der Zeit verringern Kohlenstoffablagerungen an den Drosselklappen den Luftstrom im Leerlauf.
            - Das Steuergerät (ECU) gleicht dies durch weiteres Öffnen des ISC-Leerlaufstellers (Sub-code 0x54) aus. Ein niedriger ISC-Wert (< 35%) zeigt saubere Drosselklappen an; 40% bis 60% mäßige Verschmutzung; über 60-65% stark verschmutzte Drosselklappen, die eine physische Reinigung und anschließend einen ISC-Reset (Diagnosecode 67) erfordern.
            - Das Luft-Kraftstoff-Verhältnis (AFR / O2-Spannung) und die O2-Kompensation (Sub-code 0x52, 100% = neutral) zeigen, ob die Gemischregelung Abweichungen korrigiert.
            - Der MAP-Saugrohrdruck im warmen Leerlauf liegt normalerweise zwischen 30 und 42 kPa.
            
            Bitte erstellen Sie einen klaren, prägnanten und strukturierten technischen Bericht auf Deutsch:
            1. **Allgemeiner Motorzustand**: Bewerten Sie thermische, elektrische (Batterie) und Drehzahl-/Lastparameter (RPM, TPS).
            2. **Drosselklappen- & Leerlaufanalyse (ISC / MAP)**: Interpretieren Sie ISC-Öffnung, geschätzte Verschmutzung und MAP-Druck.
            3. **Gemisch- & Lambdasondenanalyse (AFR / O2)**: Kommentieren Sie AFR- und O2-Korrekturwerte.
            4. **Wartungsempfehlungen**: Schlagen Sie vorbeugende Maßnahmen vor.
            """.trimIndent()
        }

        dispatchPrompt(prompt)
    }

    private fun dispatchPrompt(prompt: String) {
        val provider = selectedProvider
        val key = apiKey.trim()
        val model = selectedModel
        val endpoint = customEndpoint

        scope.launch {
            try {
                val reply = withContext(Dispatchers.IO) {
                    when (provider) {
                        AIProvider.GEMINI -> callGemini(prompt, key, model)
                        AIProvider.ANTHROPIC -> callAnthropic(prompt, key, model)
                        AIProvider.OPENAI, AIProvider.DEEPSEEK, AIProvider.GROQ, AIProvider.CUSTOM ->
                            callOpenAICompatible(prompt, key, model, endpoint)
                    }
                }
                isEvaluating = false
                evaluationResult = reply
            } catch (e: Exception) {
                isEvaluating = false
                evaluationResult = "Error (${provider.id}): ${e.localizedMessage ?: "Unknown network error"}"
            }
        }
    }

    private fun callGemini(prompt: String, key: String, model: String): String {
        val url = URL("https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key")
        val payload = JSONObject().apply {
            put("contents", JSONArray().put(
                JSONObject().put("parts", JSONArray().put(
                    JSONObject().put("text", prompt)
                ))
            ))
        }
        return executePost(url, payload.toString(), mapOf("Content-Type" to "application/json")) { responseBody ->
            val json = JSONObject(responseBody)
            val candidates = json.optJSONArray("candidates")
            if (candidates != null && candidates.length() > 0) {
                val content = candidates.getJSONObject(0).optJSONObject("content")
                val parts = content?.optJSONArray("parts")
                if (parts != null && parts.length() > 0) {
                    return@executePost parts.getJSONObject(0).optString("text", "")
                }
            }
            throw Exception("Unexpected Gemini response format")
        }
    }

    private fun callAnthropic(prompt: String, key: String, model: String): String {
        val url = URL("https://api.anthropic.com/v1/messages")
        val payload = JSONObject().apply {
            put("model", model)
            put("max_tokens", 1024)
            put("messages", JSONArray().put(
                JSONObject().apply {
                    put("role", "user")
                    put("content", prompt)
                }
            ))
        }
        val headers = mapOf(
            "Content-Type" to "application/json",
            "x-api-key" to key,
            "anthropic-version" to "2023-06-01"
        )
        return executePost(url, payload.toString(), headers) { responseBody ->
            val json = JSONObject(responseBody)
            val content = json.optJSONArray("content")
            if (content != null && content.length() > 0) {
                return@executePost content.getJSONObject(0).optString("text", "")
            }
            throw Exception("Unexpected Anthropic response format")
        }
    }

    private fun callOpenAICompatible(prompt: String, key: String, model: String, endpoint: String): String {
        val url = URL(endpoint)
        val payload = JSONObject().apply {
            put("model", model)
            put("messages", JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "system")
                    put("content", "You are an expert motorcycle mechanic specialized in Yamaha OBD2 diagnostics.")
                })
                put(JSONObject().apply {
                    put("role", "user")
                    put("content", prompt)
                })
            })
            put("temperature", 0.4)
        }
        val headers = mapOf(
            "Content-Type" to "application/json",
            "Authorization" to "Bearer $key"
        )
        return executePost(url, payload.toString(), headers) { responseBody ->
            val json = JSONObject(responseBody)
            val choices = json.optJSONArray("choices")
            if (choices != null && choices.length() > 0) {
                val message = choices.getJSONObject(0).optJSONObject("message")
                val text = message?.optString("content", "") ?: ""
                if (text.isNotEmpty()) return@executePost text
            }
            throw Exception("Unexpected OpenAI-compatible response format")
        }
    }

    private fun executePost(
        url: URL,
        jsonPayload: String,
        headers: Map<String, String>,
        parser: (String) -> String
    ): String {
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            doOutput = true
            connectTimeout = 25000
            readTimeout = 25000
            for ((k, v) in headers) {
                setRequestProperty(k, v)
            }
        }

        OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { writer ->
            writer.write(jsonPayload)
            writer.flush()
        }

        val code = conn.responseCode
        val body = (if (code in 200..299) conn.inputStream else conn.errorStream)
            ?.bufferedReader()?.use { it.readText() } ?: ""

        if (code !in 200..299) {
            val apiMsg = extractAPIErrorMessage(body)
            if (!apiMsg.isNullOrEmpty()) {
                val hint = if (code == 404 || apiMsg.lowercase().contains("not found") || apiMsg.lowercase().contains("deprecated")) {
                    "\nHint: Open Settings -> tap 'Refresh Models from API' to pick an active model."
                } else ""
                throw Exception("$apiMsg$hint")
            }
            throw Exception("HTTP $code: $body")
        }

        return parser(body)
    }
}
