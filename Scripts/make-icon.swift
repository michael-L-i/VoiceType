#!/usr/bin/env swift
//
// make-icon.swift — render the VoiceType macOS app icon.
//
// Design language: "calm & native". A Big Sur+ rounded-rect (squircle) app tile
// with a quiet indigo→graphite gradient, a soft inner highlight for depth, and a
// clean centered glyph: a minimalist microphone over a gentle, symmetric
// soundwave. Restrained, premium, system-native — not loud or cartoonish.
//
// Rendering is done entirely with Core Graphics into an RGBA bitmap context, so
// it works headlessly (no window server / NSGraphicsContext required). The 1024
// master proportions are re-rendered at each iconset size for crispness.
//
// Usage:  swift Scripts/make-icon.swift
// Output: Resources/AppIcon.iconset/*.png  +  Resources/AppIcon.icns
//
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - Colour helpers (sRGB)

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: srgb, components: [CGFloat(r), CGFloat(g), CGFloat(b), CGFloat(a)])!
}

// MARK: - Squircle (Apple-style continuous rounded rect)

/// Approximates the macOS "squircle" continuous-corner rounded rectangle.
func squirclePath(in rect: CGRect, cornerRadius r: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
    // "smoothing" factor controls how far the curve control points reach.
    let s: CGFloat = 1.28195   // empirical value matching iOS/macOS continuous corners
    let c = r * s
    let m = c                  // control-point distance from corner along edge

    p.move(to: CGPoint(x: x + r, y: y))
    // top edge → top-right corner
    p.addLine(to: CGPoint(x: x + w - r, y: y))
    p.addCurve(to: CGPoint(x: x + w, y: y + r),
               control1: CGPoint(x: x + w - r + m * 0.45, y: y),
               control2: CGPoint(x: x + w, y: y + r - m * 0.45))
    // right edge → bottom-right corner
    p.addLine(to: CGPoint(x: x + w, y: y + h - r))
    p.addCurve(to: CGPoint(x: x + w - r, y: y + h),
               control1: CGPoint(x: x + w, y: y + h - r + m * 0.45),
               control2: CGPoint(x: x + w - r + m * 0.45, y: y + h))
    // bottom edge → bottom-left corner
    p.addLine(to: CGPoint(x: x + r, y: y + h))
    p.addCurve(to: CGPoint(x: x, y: y + h - r),
               control1: CGPoint(x: x + r - m * 0.45, y: y + h),
               control2: CGPoint(x: x, y: y + h - r + m * 0.45))
    // left edge → top-left corner
    p.addLine(to: CGPoint(x: x, y: y + r))
    p.addCurve(to: CGPoint(x: x + r, y: y),
               control1: CGPoint(x: x, y: y + r - m * 0.45),
               control2: CGPoint(x: x + r - m * 0.45, y: y))
    p.closeSubpath()
    return p
}

// MARK: - Icon renderer

/// Renders the icon at `size`×`size` into a fresh RGBA bitmap and returns a CGImage.
func renderIcon(size: Int) -> CGImage {
    let dim = CGFloat(size)
    let bytesPerRow = size * 4
    guard let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: srgb,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create CGContext at size \(size)")
    }

    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    // Everything is expressed as a fraction of the canvas so it re-renders crisply
    // at every size. All math in a unit 0…dim space.
    let u = dim / 1024.0   // unit scale relative to the 1024 master

    // --- Tile geometry: standard macOS content inset (~10% padding each side) ---
    let inset = 100.0 * u
    let tileRect = CGRect(x: inset, y: inset, width: dim - inset * 2, height: dim - inset * 2)
    let cornerRadius = tileRect.width * 0.2237   // Big Sur squircle ratio (~185/824)
    let tilePath = squirclePath(in: tileRect, cornerRadius: cornerRadius)

    // --- Soft ambient drop shadow under the tile ---
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * u),
                  blur: 32 * u,
                  color: rgb(0, 0, 0, 0.28))
    ctx.addPath(tilePath)
    ctx.setFillColor(rgb(0.10, 0.12, 0.18))
    ctx.fillPath()
    ctx.restoreGState()

    // --- Tile background: calm indigo → graphite vertical gradient ---
    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    let bgColors = [
        rgb(0.34, 0.42, 0.72),   // soft indigo (top)
        rgb(0.24, 0.30, 0.55),   // mid indigo
        rgb(0.16, 0.19, 0.33),   // graphite (bottom)
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: srgb, colors: bgColors,
                                locations: [0.0, 0.55, 1.0])!
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: tileRect.midX, y: tileRect.maxY),
                           end: CGPoint(x: tileRect.midX, y: tileRect.minY),
                           options: [])

    // --- Gentle top inner highlight for soft depth (radial, upper area) ---
    let hiColors = [rgb(1, 1, 1, 0.20), rgb(1, 1, 1, 0.0)] as CFArray
    let hiGradient = CGGradient(colorsSpace: srgb, colors: hiColors, locations: [0, 1])!
    ctx.drawRadialGradient(hiGradient,
                           startCenter: CGPoint(x: tileRect.midX, y: tileRect.maxY - tileRect.height * 0.08),
                           startRadius: 0,
                           endCenter: CGPoint(x: tileRect.midX, y: tileRect.maxY - tileRect.height * 0.08),
                           endRadius: tileRect.width * 0.85,
                           options: [.drawsAfterEndLocation])
    ctx.restoreGState()

    // --- Crisp 1px-ish inner stroke to define the tile edge (premium feel) ---
    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.setLineWidth(max(1, 2 * u))
    ctx.setStrokeColor(rgb(1, 1, 1, 0.12))
    ctx.strokePath()
    ctx.restoreGState()

    // ===================================================================
    //  GLYPH — minimalist microphone over a soft symmetric soundwave
    // ===================================================================
    let cx = dim / 2.0
    // Visual centre nudged slightly up so mic + wave read as balanced.
    let cy = dim / 2.0 + 40.0 * u

    let glyphColor = rgb(0.96, 0.97, 1.0)             // near-white, faint cool tint
    let glyphSoft  = rgb(0.96, 0.97, 1.0, 0.55)

    // --- Microphone capsule ---
    let micW = 180.0 * u
    let micH = 300.0 * u
    let micTop = cy - 250.0 * u
    let micRect = CGRect(x: cx - micW / 2, y: micTop, width: micW, height: micH)
    let micRadius = micW / 2.0

    ctx.saveGState()
    // subtle glow behind the glyph
    ctx.setShadow(offset: .zero, blur: 26 * u, color: rgb(0.55, 0.65, 1.0, 0.30))
    let micPath = CGPath(roundedRect: micRect, cornerWidth: micRadius, cornerHeight: micRadius, transform: nil)
    ctx.addPath(micPath)
    ctx.setFillColor(glyphColor)
    ctx.fillPath()
    ctx.restoreGState()

    // tiny vertical gradient sheen on the capsule for soft depth
    ctx.saveGState()
    ctx.addPath(micPath)
    ctx.clip()
    let sheen = CGGradient(colorsSpace: srgb,
                           colors: [rgb(1, 1, 1, 0.25), rgb(1, 1, 1, 0.0)] as CFArray,
                           locations: [0, 1])!
    ctx.drawLinearGradient(sheen,
                           start: CGPoint(x: cx, y: micRect.maxY),
                           end: CGPoint(x: cx, y: micRect.minY),
                           options: [])
    ctx.restoreGState()

    // --- Mic cradle (the U-shaped arc) ---
    let cradleR = 150.0 * u
    let cradleCy = cy - 110.0 * u
    let cradleLineW = 32.0 * u
    ctx.saveGState()
    ctx.setLineWidth(cradleLineW)
    ctx.setStrokeColor(glyphColor)
    ctx.setLineCap(.round)
    // semicircle opening upward (from ~200° to ~340° in CG's coord space)
    ctx.addArc(center: CGPoint(x: cx, y: cradleCy),
               radius: cradleR,
               startAngle: CGFloat.pi,           // 180°  (left)
               endAngle: 2 * CGFloat.pi,         // 360°  (right) — bottom half
               clockwise: false)
    ctx.strokePath()
    ctx.restoreGState()

    // --- Mic stem + base ---
    let stemTop = cradleCy - cradleR
    let stemBottom = stemTop - 60.0 * u
    ctx.saveGState()
    ctx.setLineWidth(cradleLineW)
    ctx.setStrokeColor(glyphColor)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: cx, y: stemTop))
    ctx.addLine(to: CGPoint(x: cx, y: stemBottom))
    ctx.strokePath()
    // base bar
    let baseHalf = 88.0 * u
    ctx.move(to: CGPoint(x: cx - baseHalf, y: stemBottom))
    ctx.addLine(to: CGPoint(x: cx + baseHalf, y: stemBottom))
    ctx.strokePath()
    ctx.restoreGState()

    // --- Soft symmetric soundwave bars beneath, flanking the base ---
    // A calm, decaying set of vertical rounded bars on each side, suggesting voice.
    let waveY = stemBottom - 78.0 * u          // baseline for wave centre
    let barW = 24.0 * u
    let gap = 44.0 * u
    // heights decay outward (tallest nearest centre)
    let heights: [CGFloat] = [128, 88, 54].map { CGFloat($0) * u }
    let alphas: [CGFloat]  = [0.85, 0.62, 0.42]

    func drawBar(centerX: CGFloat, height: CGFloat, alpha: CGFloat) {
        let r = CGRect(x: centerX - barW / 2, y: waveY - height / 2, width: barW, height: height)
        let path = CGPath(roundedRect: r, cornerWidth: barW / 2, cornerHeight: barW / 2, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(rgb(0.96, 0.97, 1.0, Double(alpha)))
        ctx.fillPath()
    }

    for (i, h) in heights.enumerated() {
        let offset = CGFloat(i + 1) * (barW + gap)
        drawBar(centerX: cx - offset, height: h, alpha: alphas[i])
        drawBar(centerX: cx + offset, height: h, alpha: alphas[i])
    }
    _ = glyphSoft  // (kept for clarity; bars use explicit alphas)

    guard let image = ctx.makeImage() else {
        fatalError("Could not produce CGImage at size \(size)")
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

// MARK: - Drive: build the iconset

let fm = FileManager.default
let scriptPath = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
// Resolve repo root: script lives in Scripts/, so root is its parent.
let repoRoot = scriptPath.deletingLastPathComponent()
let resources = repoRoot.appendingPathComponent("Resources")
let iconset = resources.appendingPathComponent("AppIcon.iconset")

try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)

// (filename, pixel size)
let entries: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

print("▸ Rendering iconset…")
for (name, px) in entries {
    let img = renderIcon(size: px)
    writePNG(img, to: iconset.appendingPathComponent(name))
    print("  • \(name) (\(px)px)")
}

print("✓ iconset written to \(iconset.path)")
print("  Run: iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns")
