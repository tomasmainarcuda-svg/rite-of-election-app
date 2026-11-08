#!/usr/bin/env python3
"""
Downloads the app's 3 fonts ONCE, at build time, so they ship INSIDE the app
(Tomás, Nov 8: no font requests to Google when someone opens the app; also works
in the stadium with no signal).

Source: the official Google Fonts service (static .ttf per weight) + each font's
license (SIL Open Font License) from github.com/google/fonts.

Run by the build (GitHub Actions / Codemagic) before `flutter build`:
    python3 tool/fetch_fonts.py
Writes:  assets/fonts/<Family>-<weight>[Italic].ttf   (names used in pubspec.yaml)
         assets/licenses/<family>-OFL.txt            (registered in the app)
Fails loudly if any file is missing.
"""
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS_DIR = os.path.join(ROOT, "assets", "fonts")
LIC_DIR = os.path.join(ROOT, "assets", "licenses")

# family name on Google Fonts -> (file prefix, google/fonts repo folder, wanted variants)
FAMILIES = {
    "Roboto Condensed": ("RobotoCondensed", "robotocondensed", [("normal", 400), ("normal", 600), ("normal", 700), ("normal", 800)]),
    "Gelasio": ("Gelasio", "gelasio", [("normal", 400), ("normal", 700), ("italic", 400), ("italic", 700)]),
    "Poppins": ("Poppins", "poppins", [("normal", 400), ("normal", 600), ("normal", 700)]),
}

# A plain user agent makes Google Fonts answer with .ttf files (not woff2), which iOS/Android need.
UA = {"User-Agent": "Mozilla/4.0"}


def get(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def css_url():
    parts = []
    for fam, (_, _, variants) in FAMILIES.items():
        name = fam.replace(" ", "+")
        has_italic = any(st == "italic" for st, _ in variants)
        if has_italic:
            axes = sorted("%d,%d" % (1 if st == "italic" else 0, w) for st, w in variants)
            parts.append("family=%s:ital,wght@%s" % (name, ";".join(axes)))
        else:
            parts.append("family=%s:wght@%s" % (name, ";".join(str(w) for _, w in sorted(variants, key=lambda v: v[1]))))
    return "https://fonts.googleapis.com/css2?" + "&".join(parts)


def main():
    os.makedirs(FONTS_DIR, exist_ok=True)
    os.makedirs(LIC_DIR, exist_ok=True)

    css = get(css_url()).decode("utf-8")
    blocks = re.findall(r"@font-face\s*{([^}]*)}", css)
    got = set()
    for b in blocks:
        fam = re.search(r"font-family:\s*'([^']+)'", b).group(1)
        style = re.search(r"font-style:\s*(\w+)", b).group(1)
        weight = int(re.search(r"font-weight:\s*(\d+)", b).group(1))
        m = re.search(r"src:\s*url\(([^)]+)\)\s*format\('truetype'\)", b)
        if fam not in FAMILIES or not m:
            continue
        prefix = FAMILIES[fam][0]
        name = "%s-%d%s.ttf" % (prefix, weight, "Italic" if style == "italic" else "")
        data = get(m.group(1))
        with open(os.path.join(FONTS_DIR, name), "wb") as f:
            f.write(data)
        got.add((fam, style, weight))
        print("font  ", name, len(data), "bytes")

    missing = [(fam, st, w) for fam, (_, _, vs) in FAMILIES.items() for st, w in vs if (fam, st, w) not in got]
    if missing:
        sys.exit("Missing fonts (Google Fonts did not return .ttf for): %s" % missing)

    for fam, (_, folder, _) in FAMILIES.items():
        lic = get("https://raw.githubusercontent.com/google/fonts/main/ofl/%s/OFL.txt" % folder)
        path = os.path.join(LIC_DIR, "%s-OFL.txt" % folder)
        with open(path, "wb") as f:
            f.write(lic)
        print("license", os.path.basename(path), len(lic), "bytes")

    print("OK: fonts are bundled inside the app.")


if __name__ == "__main__":
    main()
