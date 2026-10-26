
# CarDSP Phase 4E - Step 1
# Add Low Shelf, High Shelf and Notch filters
# Correct the six-filter playback mapping

$ErrorActionPreference = "Stop"

$root = "C:\Users\thetechysasquatch\Documents\GitHub\CarDSP"

$dspPath = Join-Path $root "SharedDSP\include\cardsp\dsp_chain.hpp"
$enginePath = Join-Path $root "UI\Desktop\Audio\AudioPlaybackEngine.cpp"

if (!(Test-Path $dspPath) -or !(Test-Path $enginePath)) {
    throw "Required CarDSP source files were not found."
}

$dsp = Get-Content $dspPath -Raw
$engine = Get-Content $enginePath -Raw

$anchor = "template <std::size_t MaxFilters = 40>"

if (!$dsp.Contains($anchor)) {
    throw "DSP insertion point not found. No files changed."
}

# Match the original switch, including the two old cases.
$pattern = '(?s)switch\s*\(type\)\s*\{.*?default:\s*coefficients\s*=\s*cardsp::makePeakingEQ\(.*?\);\s*break;\s*\}'

if ($engine -notmatch $pattern) {
    if ($engine -notmatch 'case\s+5\s*:') {
        throw "Expected playback switch not found. No files changed."
    }
}

$filters = @'
inline BiquadCoefficients makeNotch(
    float sampleRate, float frequency, float q = 0.70710678f) noexcept
{
    if (!std::isfinite(sampleRate) || sampleRate < 8000 ||
        sampleRate > 384000 || !std::isfinite(frequency) ||
        !std::isfinite(q) || q <= 0)
        return {};

    frequency = std::clamp(frequency, 1.0f, sampleRate * 0.499f);
    q = std::max(q, 0.001f);

    const float w = 2.0f * std::numbers::pi_v<float>
                    * frequency / sampleRate;
    const float c = std::cos(w);
    const float alpha = std::sin(w) / (2.0f * q);
    const float a0 = 1.0f + alpha;

    return {
        1.0f / a0,
        -2.0f * c / a0,
        1.0f / a0,
        -2.0f * c / a0,
        (1.0f - alpha) / a0
    };
}

inline BiquadCoefficients makeLowShelf(
    float sampleRate, float frequency, float gainDB) noexcept
{
    if (!std::isfinite(sampleRate) || sampleRate < 8000 ||
        sampleRate > 384000 || !std::isfinite(frequency) ||
        !std::isfinite(gainDB) || gainDB < -96 || gainDB > 96)
        return {};

    frequency = std::clamp(frequency, 1.0f, sampleRate * 0.499f);

    const float A = std::pow(10.0f, gainDB / 40.0f);
    const float w = 2.0f * std::numbers::pi_v<float>
                    * frequency / sampleRate;
    const float c = std::cos(w);
    const float alpha = std::sin(w) / std::sqrt(2.0f);
    const float beta = 2.0f * std::sqrt(A) * alpha;

    const float a0 = (A + 1.0f) +
                     (A - 1.0f) * c + beta;

    return {
        A * ((A + 1.0f) - (A - 1.0f) * c + beta) / a0,
        2.0f * A * ((A - 1.0f) - (A + 1.0f) * c) / a0,
        A * ((A + 1.0f) - (A - 1.0f) * c - beta) / a0,
        -2.0f * ((A - 1.0f) + (A + 1.0f) * c) / a0,
        ((A + 1.0f) + (A - 1.0f) * c - beta) / a0
    };
}

inline BiquadCoefficients makeHighShelf(
    float sampleRate, float frequency, float gainDB) noexcept
{
    if (!std::isfinite(sampleRate) || sampleRate < 8000 ||
        sampleRate > 384000 || !std::isfinite(frequency) ||
        !std::isfinite(gainDB) || gainDB < -96 || gainDB > 96)
        return {};

    frequency = std::clamp(frequency, 1.0f, sampleRate * 0.499f);

    const float A = std::pow(10.0f, gainDB / 40.0f);
    const float w = 2.0f * std::numbers::pi_v<float>
                    * frequency / sampleRate;
    const float c = std::cos(w);
    const float alpha = std::sin(w) / std::sqrt(2.0f);
    const float beta = 2.0f * std::sqrt(A) * alpha;

    const float a0 = (A + 1.0f) -
                     (A - 1.0f) * c + beta;

    return {
        A * ((A + 1.0f) + (A - 1.0f) * c + beta) / a0,
        -2.0f * A * ((A - 1.0f) + (A + 1.0f) * c) / a0,
        A * ((A + 1.0f) + (A - 1.0f) * c - beta) / a0,
        2.0f * ((A - 1.0f) - (A + 1.0f) * c) / a0,
        ((A + 1.0f) - (A - 1.0f) * c - beta) / a0
    };
}

'@

$newSwitch = @'
switch (type) {
        case 0:
            coefficients = cardsp::makePeakingEQ(
                sampleRate, frequency, q, gain);
            break;
        case 1:
            coefficients = cardsp::makeLowShelf(
                sampleRate, frequency, gain);
            break;
        case 2:
            coefficients = cardsp::makeHighShelf(
                sampleRate, frequency, gain);
            break;
        case 3:
            coefficients = cardsp::makeLowPass(
                sampleRate, frequency, q);
            break;
        case 4:
            coefficients = cardsp::makeHighPass(
                sampleRate, frequency, q);
            break;
        case 5:
            coefficients = cardsp::makeNotch(
                sampleRate, frequency, q);
            break;
        default:
            setError("Unsupported EQ filter type.");
            stop();
            return false;
        }
'@

$needFilters = $dsp -notmatch 'makeLowShelf\s*\('
$needMapping = $engine -notmatch 'case\s+5\s*:'

if ($needFilters) {
    foreach ($name in @("makeLowShelf", "makeHighShelf", "makeNotch")) {
        if ($dsp -match "$name\s*\(") {
            throw "Partial filter installation detected. No files changed."
        }
    }

    $dsp = $dsp.Replace($anchor, $filters + "`r`n" + $anchor)
}

if ($needMapping) {
    $engine = [regex]::Replace(
        $engine,
        $pattern,
        [System.Text.RegularExpressions.MatchEvaluator] {
            param($match)
            return $newSwitch
        }
    )
}

# Backups are created before either file is modified.
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

Copy-Item $dspPath "$dspPath.$stamp.bak"
Copy-Item $enginePath "$enginePath.$stamp.bak"

$utf8 = [System.Text.UTF8Encoding]::new($false)

if ($needFilters) {
    [System.IO.File]::WriteAllText($dspPath, $dsp, $utf8)
}

if ($needMapping) {
    [System.IO.File]::WriteAllText($enginePath, $engine, $utf8)
}

Write-Host "`nVerifying CarDSP filters..." -ForegroundColor Cyan

foreach ($name in @(
    "makePeakingEQ",
    "makeLowShelf",
    "makeHighShelf",
    "makeLowPass",
    "makeHighPass",
    "makeNotch"
)) {
    if ($dsp -match "$name\s*\(") {
        Write-Host "PASS: $name" -ForegroundColor Green
    } else {
        throw "Missing filter: $name"
    }
}

foreach ($number in 0..5) {
    if ($engine -notmatch "case\s+$number\s*:") {
        throw "Missing playback mapping: case $number"
    }
}

Write-Host "PASS: All six playback mappings" -ForegroundColor Green

$qt = "C:\Qt\6.12.0\mingw_64"
$env:Path = "$qt\bin;C:\Qt\Tools\mingw1310_64\bin;$env:Path"
$env:QML_IMPORT_PATH = "$qt\qml"
$env:QT_PLUGIN_PATH = "$qt\plugins"

Set-Location $root

Write-Host "`nBuilding CarDSP..." -ForegroundColor Cyan

cmake --build build/qt-desktop --parallel 4

if ($LASTEXITCODE -ne 0) {
    throw "CarDSP build failed. Check the compiler output above."
}

Write-Host "`nCarDSP Step 1 patch compiled successfully!" -ForegroundColor Green
Write-Host "Backups use timestamp: $stamp"