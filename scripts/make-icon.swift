// Rendert das App-Icon (👍 auf abgerundetem Hintergrund) in ein .iconset.
// Nutzung: swift scripts/make-icon.swift <ziel.iconset>
import AppKit

let emoji = "👍"
let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "build/AppIcon.iconset")
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(pixels)
    // macOS-Icon-Raster: Inhalt ~80 % der Fläche, abgerundetes Quadrat.
    let inset = size * 0.1
    let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let path = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
    NSGradient(
        starting: NSColor(calibratedRed: 0.36, green: 0.84, blue: 0.47, alpha: 1),
        ending: NSColor(calibratedRed: 0.10, green: 0.62, blue: 0.36, alpha: 1)
    )!.draw(in: path, angle: -90)

    let font = NSFont.systemFont(ofSize: rect.height * 0.62)
    let text = NSAttributedString(string: emoji, attributes: [.font: font])
    let textSize = text.size()
    text.draw(at: NSPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2))

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    try render(pixels: base).write(to: outDir.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(pixels: base * 2).write(to: outDir.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
print("✅ Icon gerendert: \(outDir.path)")
