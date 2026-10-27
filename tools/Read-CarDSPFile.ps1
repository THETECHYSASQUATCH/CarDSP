param(
    [Parameter(Mandatory)]
    [string]$File,

    [int]$StartLine = 1,

    [int]$LineCount = 100
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$rootFull = [IO.Path]::GetFullPath($root)
$target = [IO.Path]::GetFullPath((Join-Path $rootFull $File))
$prefix = $rootFull.TrimEnd('\') + '\'

if (-not $target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "File must be inside the CarDSP repository."
}

if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    throw "File not found: $target"
}

$lines = [IO.File]::ReadAllLines($target)

$start = [Math]::Max(1, $StartLine)
$end = [Math]::Min($lines.Length, $start + $LineCount - 1)

for ($i = $start; $i -le $end; $i++) {
    "{0,5}: {1}" -f $i, $lines[$i - 1]
}
