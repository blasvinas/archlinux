#!/usr/bin/env python3
"""
Extract a coherent theme palette from an image using only ffmpeg + the Python
standard library (no PIL / ImageMagick / external color tools).

Usage:  wallpaper-colors.py <image-path>
Output: a JSON palette object on stdout, compatible with Theme.qml's schema:
        base, mantle, crust, surface0, surface1, surface2,
        text, subtext, blue (accent), red, green, yellow, onAccent, dark

The approach:
  1. ffmpeg decodes/downscales the image to raw RGB pixels.
  2. k-means finds the dominant colors.
  3. We pick a dark (or light) background from the palette, derive layered
     surfaces from it, choose a readable foreground, and select the most
     vivid cluster as the accent. red/green/yellow are nudged toward their
     hues from the accent so semantic colors stay on-brand but recognizable.
"""
import sys, json, subprocess, random, colorsys

random.seed(42)

# ---------------------------------------------------------------- decode
def decode(path, size=80):
    cmd = ["ffmpeg", "-v", "quiet", "-i", path, "-vf",
           f"scale={size}:{size}:force_original_aspect_ratio=decrease",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
    raw = subprocess.run(cmd, capture_output=True).stdout
    return [(raw[i], raw[i + 1], raw[i + 2]) for i in range(0, len(raw) - 2, 3)]

# ---------------------------------------------------------------- helpers
def lum(c):  # perceived luminance 0..255
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]

def hexs(c):
    return "#%02x%02x%02x" % (max(0, min(255, int(c[0]))),
                              max(0, min(255, int(c[1]))),
                              max(0, min(255, int(c[2]))))

def rgb_hsv(c):
    return colorsys.rgb_to_hsv(c[0] / 255, c[1] / 255, c[2] / 255)

def hsv_rgb(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return (r * 255, g * 255, b * 255)

def mix(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)

def clampv(c, lo, hi):  # clamp a color's value/brightness into [lo,hi]
    h, s, v = rgb_hsv(c)
    return hsv_rgb(h, s, max(lo, min(hi, v)))

# ---------------------------------------------------------------- k-means
def kmeans(px, k=8, iters=12):
    pts = random.sample(px, min(len(px), 2000))
    cents = random.sample(pts, k)
    for _ in range(iters):
        buckets = [[] for _ in range(k)]
        for p in pts:
            bi = min(range(k), key=lambda i: (p[0] - cents[i][0]) ** 2 +
                     (p[1] - cents[i][1]) ** 2 + (p[2] - cents[i][2]) ** 2)
            buckets[bi].append(p)
        for i, b in enumerate(buckets):
            if b:
                cents[i] = (sum(p[0] for p in b) / len(b),
                            sum(p[1] for p in b) / len(b),
                            sum(p[2] for p in b) / len(b))
    weights = [len(b) for b in buckets]
    return list(zip(cents, weights))

# ---------------------------------------------------------------- palette
def build(path):
    px = decode(path)
    if not px:
        raise SystemExit("no pixels decoded")
    clusters = kmeans(px)                       # [(color, weight), ...]
    clusters.sort(key=lambda cw: cw[1], reverse=True)
    colors = [c for c, w in clusters]

    avg = (sum(p[0] for p in px) / len(px),
           sum(p[1] for p in px) / len(px),
           sum(p[2] for p in px) / len(px))
    dark = lum(avg) < 128

    # Accent = most colorful (saturated & reasonably bright) cluster.
    def vivid(c):
        h, s, v = rgb_hsv(c)
        return s * (0.5 + 0.5 * v)
    accent = max(colors, key=vivid)
    ah, a_s, av = rgb_hsv(accent)
    # Ensure the accent is punchy and readable on the background.
    accent = hsv_rgb(ah, max(0.55, a_s), 0.80 if dark else 0.65)

    # Background: pull the dominant color toward dark (or light) and desaturate.
    dom = colors[0]
    dh, ds, dv = rgb_hsv(dom)
    if dark:
        base    = hsv_rgb(dh, min(ds, 0.35), 0.13)
        mantle  = hsv_rgb(dh, min(ds, 0.35), 0.10)
        crust   = hsv_rgb(dh, min(ds, 0.35), 0.07)
        surface0 = hsv_rgb(dh, min(ds, 0.30), 0.22)
        surface1 = hsv_rgb(dh, min(ds, 0.28), 0.30)
        surface2 = hsv_rgb(dh, min(ds, 0.26), 0.40)
        text    = hsv_rgb(dh, 0.08, 0.93)
        subtext = hsv_rgb(dh, 0.12, 0.72)
        on_accent = "#111111"
    else:
        base    = hsv_rgb(dh, min(ds, 0.18), 0.95)
        mantle  = hsv_rgb(dh, min(ds, 0.18), 0.90)
        crust   = hsv_rgb(dh, min(ds, 0.18), 0.85)
        surface0 = hsv_rgb(dh, min(ds, 0.20), 0.82)
        surface1 = hsv_rgb(dh, min(ds, 0.22), 0.74)
        surface2 = hsv_rgb(dh, min(ds, 0.24), 0.66)
        text    = hsv_rgb(dh, 0.30, 0.25)
        subtext = hsv_rgb(dh, 0.25, 0.40)
        on_accent = "#ffffff"

    # Semantic colors: fixed target hues, saturation/brightness tuned to theme.
    sv = (0.65, 0.85) if dark else (0.70, 0.70)
    def sem(hue):
        return hsv_rgb(hue / 360.0, sv[0], sv[1])
    red    = sem(0)
    green  = sem(140)
    yellow = sem(45)

    return {
        "dark": dark,
        "base": hexs(base), "mantle": hexs(mantle), "crust": hexs(crust),
        "surface0": hexs(surface0), "surface1": hexs(surface1), "surface2": hexs(surface2),
        "text": hexs(text), "subtext": hexs(subtext),
        "blue": hexs(accent),
        "red": hexs(red), "green": hexs(green), "yellow": hexs(yellow),
        "onAccent": on_accent,
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("usage: wallpaper-colors.py <image>")
    print(json.dumps(build(sys.argv[1])))
