import Foundation

let defaults = UserDefaults(suiteName: "jabella78.OBD2") ?? UserDefaults.standard
if let apiKey = defaults.string(forKey: "GeminiAPIKey") {
    print("Found API Key starting with \(apiKey.prefix(5))...")
    
    let urlStr = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
    guard let url = URL(string: urlStr) else {
        fatalError("Invalid URL")
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            print(String(data: data, encoding: .utf8) ?? "No data")
        }
        semaphore.signal()
    }.resume()
    
    semaphore.wait()
} else {
    print("No API key found in UserDefaults")
}
