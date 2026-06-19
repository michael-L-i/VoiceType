#!/usr/bin/env swift
//
// make-dmg-background.swift — render the VoiceType install-window background.
//
// This is the artwork behind the "drag to install" DMG window: a warm near-black
// plum gradient (so the coral app icon pops), the wordmark and tagline up top in
// warm tones, and a coral arrow pointing from the app toward the Applications
// folder. Finder draws the two real icons on top at the positions baked into the
// DMG's .DS_Store (see Scripts/make-dmg.sh) — this image only paints the canvas
// and the hint between them.
//
// Like make-icon.swift, rendering is pure Core Graphics + Core Text into an RGBA
// bitmap, so it runs headlessly (no window server) and is deterministic in CI.
// The window is laid out in points; we render at 1× and 2× so Finder gets a crisp
// Retina background (the two PNGs are combined into a HiDPI TIFF by make-dmg.sh).
//
// Usage:  swift Scripts/make-dmg-background.swift
// Output: Resources/dmg-background.png  (1×, 660×440)
//         Resources/dmg-background@2x.png  (2×, 1320×880)
//
import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

// MARK: - Window geometry (points). Must match Scripts/make-dmg.sh layout.

let winW: CGFloat = 660
let winH: CGFloat = 440

// Icon centres as Finder sees them (top-left origin). Kept here so the artwork and
// the .DS_Store positions can't drift apart — make-dmg.sh reads the same numbers.
let iconY: CGFloat = 215          // vertical centre of both icons (from top)
let appX: CGFloat = 175           // VoiceType.app column
let applicationsX: CGFloat = 485  // Applications symlink column

// MARK: - Colour helpers (sRGB)

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: srgb, components: [CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a)])!
}

// MARK: - Text

/// Draws a horizontally-centred line of text with its baseline at `y` (CG space,
/// bottom-left origin). Tracking gives the wordmark a touch of air.
func drawCenteredText(_ ctx: CGContext, _ string: String, font: CTFont,
                      color: CGColor, y: CGFloat, tracking: CGFloat = 0) {
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: color,
        kCTKernAttributeName: tracking,
    ]
    let attributed = CFAttributedStringCreate(nil, string as CFString, attrs as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    let x = (winW - bounds.width) / 2 - bounds.minX
    ctx.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, ctx)
}

// MARK: - Renderer

func renderBackground(scale: CGFloat) -> CGImage {
    let pxW = Int(winW * scale)
    let pxH = Int(winH * scale)
    guard let ctx = CGContext(
        data: nil, width: pxW, height: pxH,
        bitsPerComponent: 8, bytesPerRow: pxW * 4,
        space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create CGContext at scale \(scale)")
    }

    // Work in points; the scale transform handles Retina.
    ctx.scaleBy(x: scale, y: scale)
    ctx.setShouldAntialias(true)
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    // --- Background: warm near-black plum gradient (lets the coral icon pop) ---
    let bgColors = [
        rgb(0.22, 0.14, 0.12),   // warm espresso (top)
        rgb(0.16, 0.10, 0.09),   // mid
        rgb(0.10, 0.07, 0.06),   // deep warm black (bottom)
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: srgb, colors: bgColors,
                                locations: [0.0, 0.55, 1.0])!
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: winW / 2, y: winH),
                           end: CGPoint(x: winW / 2, y: 0),
                           options: [])

    // --- Gentle top highlight for depth ---
    let hiColors = [rgb(1, 1, 1, 0.10), rgb(1, 1, 1, 0.0)] as CFArray
    let hiGradient = CGGradient(colorsSpace: srgb, colors: hiColors, locations: [0, 1])!
    ctx.drawRadialGradient(hiGradient,
                           startCenter: CGPoint(x: winW / 2, y: winH - 30),
                           startRadius: 0,
                           endCenter: CGPoint(x: winW / 2, y: winH - 30),
                           endRadius: winW * 0.7,
                           options: [.drawsAfterEndLocation])

    // ===================================================================
    //  Wordmark + tagline (top)
    // ===================================================================
    let title = CTFontCreateWithName("SF Pro Display" as CFString, 38, nil)
    let titleFallback = CTFontCreateUIFontForLanguage(.emphasizedSystem, 38, nil) ?? title
    drawCenteredText(ctx, "VoiceType",
                     font: CTFontGetSize(title) > 0 ? title : titleFallback,
                     color: rgb(1.0, 0.97, 0.94), y: winH - 78, tracking: 0.5)

    let tagFont = CTFontCreateUIFontForLanguage(.system, 14, nil)!
    drawCenteredText(ctx, "Speak anywhere. Get clean text instantly.",
                     font: tagFont, color: rgb(0.97, 0.82, 0.72, 0.9), y: winH - 104)

    // ===================================================================
    //  Arrow from the app toward Applications (centre, at icon height)
    // ===================================================================
    // Convert the Finder (top-left) icon row to CG (bottom-left) space.
    let arrowCY = winH - iconY
    let arrowStartX = appX + 90        // just right of the app icon
    let arrowEndX = applicationsX - 90 // just left of the Applications folder
    let shaftEndX = arrowEndX - 14     // leave room for the head

    ctx.saveGState()
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setStrokeColor(rgb(1.0, 0.66, 0.45, 0.95))
    ctx.setFillColor(rgb(1.0, 0.66, 0.45, 0.95))
    ctx.setShadow(offset: .zero, blur: 10, color: rgb(1.0, 0.45, 0.30, 0.55))

    // Shaft
    ctx.setLineWidth(6)
    ctx.move(to: CGPoint(x: arrowStartX, y: arrowCY))
    ctx.addLine(to: CGPoint(x: shaftEndX, y: arrowCY))
    ctx.strokePath()

    // Head (filled triangle)
    let headH: CGFloat = 22
    ctx.move(to: CGPoint(x: arrowEndX + 6, y: arrowCY))
    ctx.addLine(to: CGPoint(x: shaftEndX - 6, y: arrowCY + headH / 2))
    ctx.addLine(to: CGPoint(x: shaftEndX - 6, y: arrowCY - headH / 2))
    ctx.closePath()
    ctx.fillPath()
    ctx.restoreGState()

    // ===================================================================
    //  Footer hint (bottom)
    // ===================================================================
    let hintFont = CTFontCreateUIFontForLanguage(.system, 13, nil)!
    drawCenteredText(ctx, "Drag VoiceType into your Applications folder",
                     font: hintFont, color: rgb(0.90, 0.78, 0.70, 0.85), y: 34)

    guard let image = ctx.makeImage() else {
        fatalError("Could not produce CGImage at scale \(scale)")
    }
    return image
}

// MARK: - PNG writing

func writePNG(_ image: CGImage, to url: URL) {
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("Could not create PNG destination at \(url.path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        fatalError("Could not write PNG at \(url.path)")
    }
}

// MARK: - Drive

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let repoRoot = scriptDir.deletingLastPathComponent()
let resources = repoRoot.appendingPathComponent("Resources")
try? FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

print("▸ Rendering DMG background…")
writePNG(renderBackground(scale: 1), to: resources.appendingPathComponent("dmg-background.png"))
print("  • dmg-background.png (\(Int(winW))×\(Int(winH)))")
writePNG(renderBackground(scale: 2), to: resources.appendingPathComponent("dmg-background@2x.png"))
print("  • dmg-background@2x.png (\(Int(winW * 2))×\(Int(winH * 2)))")
print("✓ DMG background written to \(resources.path)")
