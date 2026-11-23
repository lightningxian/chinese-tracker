# Makes the Android and iOS app icons from the brand mascot (owner
# 2026-11-24: App Store app). The pencil mascot (assets/brand/mascot_pencil.png)
# sits on the brand's soft yellow (#FFF4CC, LandingBrand.yellowSoft); the
# icons have no transparency, as the App Store requires.
#
#   powershell -ExecutionPolicy Bypass -File tool/make_app_icons.ps1
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$mascot = [System.Drawing.Image]::FromFile((Join-Path $root 'assets\brand\mascot_pencil.png'))
$bg = [System.Drawing.Color]::FromArgb(255, 0xFF, 0xF4, 0xCC)

function New-Icon([int]$px, [string]$path) {
  $bmp = New-Object System.Drawing.Bitmap($px, $px, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'HighQuality'
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.PixelOffsetMode = 'HighQuality'
  $g.Clear($bg)
  # The mascot fills 80% of the height, centred.
  $h = [int]($px * 0.80)
  $w = [int]($h * $mascot.Width / $mascot.Height)
  $g.DrawImage($mascot, [int](($px - $w) / 2), [int](($px - $h) / 2), $w, $h)
  $g.Dispose()
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

# iOS: the size is in the file name, e.g. Icon-App-83.5x83.5@2x.png = 167 px.
$ios = Join-Path $root 'ios\Runner\Assets.xcassets\AppIcon.appiconset'
Get-ChildItem $ios -Filter 'Icon-App-*.png' | ForEach-Object {
  if ($_.Name -match 'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png') {
    New-Icon ([int][math]::Round([double]$Matches[1] * [int]$Matches[2])) $_.FullName
  }
}

# Android launcher icons.
$android = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($k in $android.Keys) {
  New-Icon $android[$k] (Join-Path $root "android\app\src\main\res\mipmap-$k\ic_launcher.png")
}
$mascot.Dispose()
'icons written'
