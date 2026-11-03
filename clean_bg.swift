import Cocoa

func removeWhiteBackground(inPath: String, outPath: String) {
    guard let image = NSImage(contentsOfFile: inPath),
          let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData) else {
        print("Cannot load \(inPath)")
        return
    }

    let width = bitmap.pixelsWide
    let height = bitmap.pixelsHigh

    let resultBitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                        pixelsWide: width,
                                        pixelsHigh: height,
                                        bitsPerSample: 8,
                                        samplesPerPixel: 4,
                                        hasAlpha: true,
                                        isPlanar: false,
                                        colorSpaceName: .calibratedRGB,
                                        bytesPerRow: width * 4,
                                        bitsPerPixel: 32)!

    for y in 0..<height {
        for x in 0..<width {
            let color = bitmap.colorAt(x: x, y: y) ?? NSColor.white
            if color.redComponent > 0.95 && color.greenComponent > 0.95 && color.blueComponent > 0.95 {
                resultBitmap.setColor(NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0), atX: x, y: y)
            } else {
                resultBitmap.setColor(color, atX: x, y: y)
            }
        }
    }

    if let pngData = resultBitmap.representation(using: .png, properties: [:]) {
        try! pngData.write(to: URL(fileURLWithPath: outPath))
        print("Saved \(outPath)")
    }
}

removeWhiteBackground(
    inPath: "/Users/jabella78/Documents/OBD2/YamahaOBD2.app/Contents/Resources/tracer_900_gt.jpg",
    outPath: "/Users/jabella78/Documents/OBD2/YamahaOBD2.app/Contents/Resources/tracer_900_gt.png"
)

removeWhiteBackground(
    inPath: "/Users/jabella78/Documents/OBD2/YamahaOBD2.app/Contents/Resources/yamaha_logo_full.png",
    outPath: "/Users/jabella78/Documents/OBD2/YamahaOBD2.app/Contents/Resources/yamaha_logo_full.png"
)
