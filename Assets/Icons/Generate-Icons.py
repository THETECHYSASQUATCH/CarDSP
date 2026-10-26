from PIL import Image, ImageOps
from pathlib import Path
import json

root = Path.cwd()
icons = root / "Assets" / "Icons"
source = Image.open(root / "CarDSP-Icon-Sheet.png").convert("RGB")

# Main icon is in the upper-left portion of the generated presentation sheet.
# Coordinates are proportional to the original image.
w, h = source.size
crop = source.crop((
    int(w * 0.02),
    int(h * 0.03),
    int(w * 0.41),
    int(h * 0.65)
))

# Center and resize to square.
master = ImageOps.fit(
    crop,
    (1024, 1024),
    method=Image.Resampling.LANCZOS
).convert("RGBA")

master.save(icons / "Source" / "CarDSP-1024.png")

# Windows multi-resolution ICO
master.save(
    icons / "Windows" / "CarDSP.ico",
    format="ICO",
    sizes=[
        (16, 16), (24, 24), (32, 32),
        (48, 48), (64, 64), (128, 128),
        (256, 256)
    ]
)

# Standard PNG sizes for desktop platforms
for size in [16, 24, 32, 48, 64, 128, 256, 512, 1024]:
    resized = master.resize(
        (size, size),
        Image.Resampling.LANCZOS
    )
    resized.save(
        icons / "Windows" / f"CarDSP-{size}.png"
    )

    linux_dir = icons / "Linux" / "hicolor" / f"{size}x{size}" / "apps"
    linux_dir.mkdir(parents=True, exist_ok=True)
    resized.save(linux_dir / "cardsp.png")

# macOS PNG source and ICNS
master.save(icons / "macOS" / "CarDSP-1024.png")

mac_sizes = [16, 32, 64, 128, 256, 512, 1024]
for size in mac_sizes:
    master.resize((size, size), Image.Resampling.LANCZOS).save(
        icons / "macOS" / f"CarDSP-{size}.png"
    )

try:
    master.save(
        icons / "macOS" / "CarDSP.icns",
        format="ICNS"
    )
    print("macOS ICNS created")
except Exception as exc:
    print("ICNS creation unavailable:", exc)

# Android legacy launcher icons
densities = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192
}

for density, size in densities.items():
    folder = icons / "Android" / "res" / f"mipmap-{density}"
    folder.mkdir(parents=True, exist_ok=True)

    master.resize(
        (size, size),
        Image.Resampling.LANCZOS
    ).save(folder / "ic_launcher.png")

# Android adaptive-icon resources
# These are placeholder compatible layers derived from the composite image.
foreground_dir = icons / "Android" / "res" / "drawable-nodpi"
foreground_dir.mkdir(parents=True, exist_ok=True)
master.save(foreground_dir / "ic_launcher_foreground.png")

values_dir = icons / "Android" / "res" / "values"
values_dir.mkdir(parents=True, exist_ok=True)
(values_dir / "colors.xml").write_text(
    '<resources><color name="ic_launcher_background">#101820</color></resources>',
    encoding="utf-8"
)

adaptive_dir = icons / "Android" / "res" / "mipmap-anydpi-v26"
adaptive_dir.mkdir(parents=True, exist_ok=True)
(adaptive_dir / "ic_launcher.xml").write_text(
    '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
''',
    encoding="utf-8"
)

# iOS universal 1024px icon
ios = icons / "iOS" / "AppIcon.appiconset"
master.convert("RGB").save(ios / "AppIcon-1024.png")

contents = {
    "images": [{
        "filename": "AppIcon-1024.png",
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024"
    }],
    "info": {
        "author": "xcode",
        "version": 1
    }
}

(ios / "Contents.json").write_text(
    json.dumps(contents, indent=2),
    encoding="utf-8"
)

print("CarDSP platform icons generated successfully.")
print("Location:", icons)