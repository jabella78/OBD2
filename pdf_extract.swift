import Foundation
import Quartz

let path = "/Users/jabella78/Documents/OBD2/YA_TRACER_GT_900_TRA-H_2017-2020_OM+PC+FSM copia.pdf"
let outPath = "/Users/jabella78/Documents/OBD2/yamaha_manual.txt"

guard let pdf = PDFDocument(url: URL(fileURLWithPath: path)) else {
    print("Could not load PDF")
    exit(1)
}

if let text = pdf.string {
    try? text.write(to: URL(fileURLWithPath: outPath), atomically: true, encoding: .utf8)
    print("Extracted to yamaha_manual.txt")
} else {
    print("No text found")
}
