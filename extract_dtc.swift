import Foundation

let path = "/Users/jabella78/Documents/OBD2/yamaha_manual.txt"
let outPath = "/Users/jabella78/Documents/OBD2/YamahaOBD2.swiftpm/dtc_database.json"

guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
    print("Could not read file")
    exit(1)
}

let lines = text.components(separatedBy: .newlines)
var database: [String: String] = [:]

let regexBrackets = try! NSRegularExpression(pattern: "\\[(P[0-9A-Z]{4})\\]\\s+(.*)")

var pendingCode: String? = nil

for line in lines {
    let range = NSRange(location: 0, length: line.utf16.count)
    
    // Check [P1234] format
    if let match = regexBrackets.firstMatch(in: line, options: [], range: range) {
        if let codeRange = Range(match.range(at: 1), in: line),
           let descRange = Range(match.range(at: 2), in: line) {
            let code = String(line[codeRange])
            let desc = String(line[descRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            database[code] = desc
        }
        continue
    }
    
    // Check "Fault code No. P1234" format
    if line.hasPrefix("Fault code No. P") {
        let code = line.replacingOccurrences(of: "Fault code No. ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        if code.count == 5 { // e.g. P0030
            pendingCode = code
        } else {
            pendingCode = nil
        }
    } else if let code = pendingCode, line.hasPrefix("Item ") {
        let desc = line.replacingOccurrences(of: "Item ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        database[code] = desc
        pendingCode = nil
    }
}

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
if let data = try? encoder.encode(database) {
    try? data.write(to: URL(fileURLWithPath: outPath))
    print("Extracted \(database.count) DTC codes to dtc_database.json")
}
