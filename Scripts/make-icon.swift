#!/usr/bin/env swift
//
// make-icon.swift — render the VoiceType macOS app icon.
//
// Design language: "warm & distinctive". A Big Sur+ rounded-rect (squircle) app
// tile with a warm coral→amber gradient, a soft inner highlight for depth, and a
// single ownable glyph: the "utterance wave" — vertical rounded bars whose
// envelope traces a horizontal pointed oval (a lens), tall in the centre and
// tapering to points at each end. It's the silhouette of a single spoken sound:
// recognizable as voice without the stock microphone.
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
    ctx.setFillColor(rgb(0.18, 0.09, 0.07))
    ctx.fillPath()
    ctx.restoreGState()

    // --- Tile background: warm amber → coral diagonal gradient ---
    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    let bgColors = [
        rgb(1.00, 0.72, 0.44),   // warm amber (top-left)
        rgb(0.99, 0.52, 0.36),   // coral (mid)
        rgb(0.90, 0.39, 0.27),   // burnt coral (bottom-right)
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: srgb, colors: bgColors,
                                locations: [0.0, 0.55, 1.0])!
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: tileRect.minX, y: tileRect.maxY),
                           end: CGPoint(x: tileRect.maxX, y: tileRect.minY),
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
    //  GLYPH — "utterance wave": vertical rounded bars whose envelope traces
    //  a horizontal pointed oval (a lens). Tall in the centre, tapering to
    //  points at each end — the silhouette of a single spoken sound.
    // ===================================================================
    let cx = dim / 2.0
    let cy = dim / 2.0

    let barCount = 9
    let lensW = 660.0 * u                 // overall width of the mark
    let pitch = lensW / Double(barCount)  // per-bar cell width
    let barW = pitch * 0.52               // bar thickness (rest is the gap)
    let maxHalf = 178.0 * u               // half-height of the centre bar
    let minHalf = barW / 2.0              // end bars collapse to round dots (the tips)

    // Build every bar into one path so the warm glow underneath reads as a
    // single unified mark rather than a halo per bar.
    let group = CGMutablePath()
    for i in 0..<barCount {
        let t = Double(i) / Double(barCount - 1) * 2.0 - 1.0   // -1 … 1 across the width
        let f = 1.0 - t * t                                    // pointed-oval envelope
        let half = max(minHalf, maxHalf * f)
        // Bars are centred in their cell, leaving a small margin past the tips.
        let x = cx - lensW / 2.0 + pitch * (Double(i) + 0.5)
        let r = CGRect(x: x - barW / 2, y: cy - half, width: barW, height: half * 2)
        group.addPath(CGPath(roundedRect: r, cornerWidth: barW / 2, cornerHeight: barW / 2, transform: nil))
    }

    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 38 * u, color: rgb(1.0, 0.82, 0.64, 0.50))
    ctx.addPath(group)
    ctx.setFillColor(rgb(1.0, 0.98, 0.96))   // near-white, faint warm tint
    ctx.fillPath()
    ctx.restoreGState()

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
