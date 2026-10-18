# Genere l'icone (mipmap) et la banniere Android TV (320x180) dans app/res a partir de logo.png.
Add-Type -AssemblyName System.Drawing
$res = Join-Path $PSScriptRoot "app\res"
$logo = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot "logo.png"))

function New-Canvas($w, $h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    return $bmp, $g
}

function Save($bmp, $g, $path) {
    New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# Icones : le logo redimensionne.
foreach ($d in @(@("mdpi", 48), @("hdpi", 72), @("xhdpi", 96), @("xxhdpi", 144), @("xxxhdpi", 192))) {
    $bmp, $g = New-Canvas $d[1] $d[1]
    $g.DrawImage($logo, 0, 0, $d[1], $d[1])
    Save $bmp $g "$res\mipmap-$($d[0])\ic_launcher.png"
}

# Banniere : le logo (texte sur fond uni) agrandi a toute la largeur, centre verticalement.
$bmp, $g = New-Canvas 320 180
$g.Clear((New-Object System.Drawing.Bitmap $logo).GetPixel(0, 0))
$g.DrawImage($logo, 0, -70, 320, 320)
Save $bmp $g "$res\drawable-xhdpi\banner.png"

$logo.Dispose()
Write-Host "Icones generees."
