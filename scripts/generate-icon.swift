import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func drawIcon() {
    let copper = NSColor(srgbRed: 0.70, green: 0.29, blue: 0.17, alpha: 1)
    let cream = NSColor(srgbRed: 0.97, green: 0.95, blue: 0.91, alpha: 1)
    copper.setFill()
    NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 190, yRadius: 190).fill()

    cream.withAlphaComponent(0.25).setStroke()
    let plate = NSBezierPath(ovalIn: NSRect(x: 237, y: 277, width: 550, height: 43))
    plate.lineWidth = 7
    plate.stroke()

    cream.setStroke()
    let handle = NSBezierPath()
    handle.move(to: NSPoint(x: 669, y: 568))
    handle.curve(to: NSPoint(x: 667, y: 411), controlPoint1: NSPoint(x: 846, y: 611), controlPoint2: NSPoint(x: 843, y: 383))
    handle.lineWidth = 30
    handle.lineCapStyle = .round
    handle.stroke()

    let cup = NSBezierPath()
    cup.move(to: NSPoint(x: 312, y: 601))
    cup.line(to: NSPoint(x: 702, y: 601))
    cup.curve(to: NSPoint(x: 619, y: 325), controlPoint1: NSPoint(x: 695, y: 423), controlPoint2: NSPoint(x: 682, y: 325))
    cup.curve(to: NSPoint(x: 393, y: 325), controlPoint1: NSPoint(x: 555, y: 298), controlPoint2: NSPoint(x: 457, y: 298))
    cup.curve(to: NSPoint(x: 312, y: 601), controlPoint1: NSPoint(x: 331, y: 325), controlPoint2: NSPoint(x: 317, y: 423))
    cup.close()
    cream.setFill()
    cup.fill()

    NSColor(srgbRed: 0.83, green: 0.62, blue: 0.48, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 312, y: 575, width: 390, height: 54)).fill()
    NSColor(srgbRed: 0.24, green: 0.17, blue: 0.13, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 337, y: 583, width: 340, height: 28)).fill()

    cream.withAlphaComponent(0.7).setStroke()
    for x in [434.0, 509.0, 584.0] {
        let steam = NSBezierPath()
        steam.move(to: NSPoint(x: x, y: 680))
        steam.curve(to: NSPoint(x: x, y: 798), controlPoint1: NSPoint(x: x + 45, y: 721), controlPoint2: NSPoint(x: x - 40, y: 752))
        steam.lineWidth = 10
        steam.lineCapStyle = .round
        steam.stroke()
    }
}

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            fatalError("Could not create icon bitmap")
        }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()
        drawIcon()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        let file = output.appendingPathComponent("icon_\(points)x\(points)\(suffix).png")
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Could not encode icon")
        }
        try png.write(to: file)
    }
}
