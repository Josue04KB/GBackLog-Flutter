# Original vector artwork; generates all launcher assets without extra packages.
# Run from Windows: powershell -ExecutionPolicy Bypass -File tool/generate_app_icons.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$brandDirectory = Join-Path $projectRoot 'assets/branding'
[void][IO.Directory]::CreateDirectory($brandDirectory)
$background = '#6949DB'
$shapes = @(
    @{ Color = '#B6A5FF'; Path = 'M 40 30 L 68 30 C 70 30 71 31 71 33 L 71 34 L 37 34 L 37 33 C 37 31 38 30 40 30 Z' },
    @{ Color = '#DFD6FF'; Path = 'M 35 36 L 73 36 C 76 36 77 38 77 40 L 31 40 C 31 38 32 36 35 36 Z' },
    @{ Color = '#FFFFFF'; Path = 'M 37 43 L 71 43 C 76 43 78 47 79 53 L 83 70 C 85 78 77 82 72 76 L 65 69 L 43 69 L 36 76 C 31 82 23 78 25 70 L 29 53 C 30 47 32 43 37 43 Z' },
    @{ Color = '#6949DB'; Path = 'M 37 51 L 41 51 L 41 55 L 45 55 L 45 59 L 41 59 L 41 63 L 37 63 L 37 59 L 33 59 L 33 55 L 37 55 Z' },
    @{ Color = '#6949DB'; Path = 'M 72 53 C 72 54.657 70.657 56 69 56 C 67.343 56 66 54.657 66 53 C 66 51.343 67.343 50 69 50 C 70.657 50 72 51.343 72 53 Z' },
    @{ Color = '#6949DB'; Path = 'M 65 60 C 65 61.657 63.657 63 62 63 C 60.343 63 59 61.657 59 60 C 59 58.343 60.343 57 62 57 C 63.657 57 65 58.343 65 60 Z' }
)

function Write-ProjectText([string]$RelativePath, [string]$Content) {
    $destination = Join-Path $projectRoot $RelativePath
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
    [IO.File]::WriteAllText($destination, $Content, [Text.UTF8Encoding]::new($false))
}

# Only absolute M, L, C, Z commands are needed for this original artwork.
function New-ArtPath([string]$PathData) {
    $parts = [regex]::Matches($PathData, '[MLCZ]|-?\d+(?:\.\d+)?') | ForEach-Object { $_.Value }
    $path = [Drawing.Drawing2D.GraphicsPath]::new()
    $point = [Drawing.PointF]::new(0, 0)
    $i = 0
    while ($i -lt $parts.Count) {
        $command = $parts[$i++]
        if ($command -eq 'Z') { $path.CloseFigure(); continue }
        $count = if ($command -eq 'C') { 6 } else { 2 }
        $coords = @()
        for ($j = 0; $j -lt $count; $j++) {
            $coords += [single]::Parse($parts[$i++], [Globalization.CultureInfo]::InvariantCulture)
        }
        $target = [Drawing.PointF]::new($coords[$count - 2], $coords[$count - 1])
        switch ($command) {
            'M' { $path.StartFigure() }
            'L' { $path.AddLine($point, $target) }
            'C' { $path.AddBezier($point, [Drawing.PointF]::new($coords[0], $coords[1]), [Drawing.PointF]::new($coords[2], $coords[3]), $target) }
        }
        $point = $target
    }
    return ,$path
}

function New-IconBitmap([int]$Size, [single]$ArtScale = 1.16) {
    $renderSize = [Math]::Max(432, $Size * 2)
    $large = [Drawing.Bitmap]::new($renderSize, $renderSize)
    $canvas = [Drawing.Graphics]::FromImage($large)
    $canvas.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $canvas.Clear([Drawing.ColorTranslator]::FromHtml($background))
    $canvas.ScaleTransform($renderSize / 108.0, $renderSize / 108.0)
    $canvas.TranslateTransform(54, 54)
    $canvas.ScaleTransform($ArtScale, $ArtScale)
    $canvas.TranslateTransform(-54, -54)
    foreach ($shape in $shapes) {
        $path = New-ArtPath $shape.Path
        $brush = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($shape.Color))
        $canvas.FillPath($brush, $path)
        $brush.Dispose()
        $path.Dispose()
    }
    $canvas.Dispose()
    $small = [Drawing.Bitmap]::new($Size, $Size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $resize = [Drawing.Graphics]::FromImage($small)
    $resize.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $resize.DrawImage($large, 0, 0, $Size, $Size)
    $resize.Dispose()
    $large.Dispose()
    return ,$small
}

function Save-Icon([string]$RelativePath, [int]$Size, [single]$ArtScale = 1.16) {
    $destination = Join-Path $projectRoot $RelativePath
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
    $bitmap = New-IconBitmap $Size $ArtScale
    $bitmap.Save($destination, [Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

$svgPaths = ($shapes | ForEach-Object { '<path fill="' + $_.Color + '" d="' + $_.Path + '"/>' }) -join "`n"
Write-ProjectText 'assets/branding/gamebacklog.svg' ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><title>GameBacklog</title><rect width="108" height="108" fill="' + $background + '"/><g transform="translate(54 54) scale(1.16) translate(-54 -54)">' + $svgPaths + '</g></svg>')
Save-Icon 'assets/branding/gamebacklog.png' 1024
Save-Icon 'assets/branding/preview.png' 256

$densities = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
foreach ($density in $densities.GetEnumerator()) {
    Save-Icon "android/app/src/main/res/mipmap-$($density.Key)/ic_launcher.png" $density.Value
}

$vectorPaths = ($shapes | ForEach-Object { '<path android:fillColor="' + $_.Color + '" android:pathData="' + $_.Path + '"/>' }) -join "`n"
$vectorStart = '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><group android:pivotX="54" android:pivotY="54" android:scaleX="0.92" android:scaleY="0.92">'
Write-ProjectText 'android/app/src/main/res/drawable/ic_launcher_foreground.xml' ($vectorStart + $vectorPaths + '</group></vector>')
$mono = '<path android:fillColor="#FFFFFF" android:pathData="' + $shapes[0].Path + ' ' + $shapes[1].Path + '"/>'
$cutout = ($shapes[2..5] | ForEach-Object { $_.Path }) -join ' '
$mono += '<path android:fillColor="#FFFFFF" android:fillType="evenOdd" android:pathData="' + $cutout + '"/>'
Write-ProjectText 'android/app/src/main/res/drawable/ic_launcher_monochrome.xml' ($vectorStart + $mono + '</group></vector>')
Write-ProjectText 'android/app/src/main/res/values/ic_launcher_background.xml' ('<resources><color name="ic_launcher_background">' + $background + '</color></resources>')
$adaptive = '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/ic_launcher_background"/><foreground android:drawable="@drawable/ic_launcher_foreground"/>'
Write-ProjectText 'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml' ($adaptive + '</adaptive-icon>')
Write-ProjectText 'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml' ($adaptive + '<monochrome android:drawable="@drawable/ic_launcher_monochrome"/></adaptive-icon>')

foreach ($folder in @('ios/Runner/Assets.xcassets/AppIcon.appiconset', 'macos/Runner/Assets.xcassets/AppIcon.appiconset')) {
    $catalog = Get-Content -LiteralPath (Join-Path $projectRoot "$folder/Contents.json") -Raw | ConvertFrom-Json
    foreach ($item in $catalog.images) {
        $baseSize = [double]::Parse($item.size.Split('x')[0], [Globalization.CultureInfo]::InvariantCulture)
        $scale = [double]::Parse($item.scale.TrimEnd('x'), [Globalization.CultureInfo]::InvariantCulture)
        Save-Icon "$folder/$($item.filename)" ([int]($baseSize * $scale))
    }
}
foreach ($size in @(192, 512)) {
    Save-Icon "web/icons/Icon-$size.png" $size
    Save-Icon "web/icons/Icon-maskable-$size.png" $size 0.92
}
Save-Icon 'web/favicon.png' 32

# ICO directory with PNG images for Windows at common taskbar/menu sizes.
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$images = @()
foreach ($size in $sizes) {
    $bitmap = New-IconBitmap $size
    $stream = [IO.MemoryStream]::new()
    $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
    $images += ,$stream.ToArray()
    $stream.Dispose()
    $bitmap.Dispose()
}
$output = [IO.File]::Create((Join-Path $projectRoot 'windows/runner/resources/app_icon.ico'))
$writer = [IO.BinaryWriter]::new($output)
$writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $dimension = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
    $writer.Write([byte]$dimension); $writer.Write([byte]$dimension)
    $writer.Write([byte]0); $writer.Write([byte]0)
    $writer.Write([uint16]1); $writer.Write([uint16]24)
    $writer.Write([uint32]$images[$i].Length); $writer.Write([uint32]$offset)
    $offset += $images[$i].Length
}
foreach ($bytes in $images) { $writer.Write([byte[]]$bytes) }
$writer.Dispose()
Write-Output 'GameBacklog: SVG, PNG, Android adaptive/monochrome, Apple, web and Windows icons generated.'
