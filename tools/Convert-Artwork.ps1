# Resize a source photo into the portfolio's full + thumb sizes.
# Re-encoding onto a fresh bitmap also drops EXIF (including any GPS data).
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Name,
    [int]$FullMax = 1600,
    [int]$ThumbMax = 800,
    [int]$FullQuality = 82,
    [int]$ThumbQuality = 80
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

function Save-Resized {
    param([System.Drawing.Image]$Image, [int]$Width, [int]$Height, [string]$Path, [int]$Quality)

    $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
    $bmp.SetResolution(72, 72)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($Image, (New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)))
    $g.Dispose()

    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object { $_.MimeType -eq 'image/jpeg' }
    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
        [System.Drawing.Imaging.Encoder]::Quality, [int64]$Quality)

    $bmp.Save($Path, $codec, $params)
    $params.Dispose()
    $bmp.Dispose()
}

$img = [System.Drawing.Image]::FromFile((Resolve-Path $Source))
try {
    # EXIF orientation tag: cameras store the photo unrotated plus a "turn it this way" flag.
    if ($img.PropertyIdList -contains 0x0112) {
        switch ($img.GetPropertyItem(0x0112).Value[0]) {
            2 { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
            3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
            4 { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipY) }
            5 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
            6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
            7 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
            8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
        }
    }

    $scaleFull = [Math]::Min($FullMax / $img.Width, $FullMax / $img.Height)
    $scaleThumb = [Math]::Min($ThumbMax / $img.Width, $ThumbMax / $img.Height)

    $fullPath = Join-Path $root "images\full\$Name.jpg"
    $thumbPath = Join-Path $root "images\thumbs\$Name.jpg"

    Save-Resized $img ([int][Math]::Round($img.Width * $scaleFull)) ([int][Math]::Round($img.Height * $scaleFull)) $fullPath $FullQuality
    Save-Resized $img ([int][Math]::Round($img.Width * $scaleThumb)) ([int][Math]::Round($img.Height * $scaleThumb)) $thumbPath $ThumbQuality
}
finally {
    $img.Dispose()
}

Get-ChildItem $fullPath, $thumbPath | ForEach-Object {
    $i = [System.Drawing.Image]::FromFile($_.FullName)
    [PSCustomObject]@{ File = $_.Name; Folder = Split-Path (Split-Path $_.FullName -Parent) -Leaf; KB = [math]::Round($_.Length / 1KB); W = $i.Width; H = $i.Height }
    $i.Dispose()
} | Format-Table -AutoSize
