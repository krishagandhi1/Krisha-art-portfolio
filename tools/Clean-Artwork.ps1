# Straighten and crop a photographed artwork before it goes through Convert-Artwork.ps1.
# Crop bounds are fractions of the straightened image so they can be tuned by eye.
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [double]$Angle = 0,
    [double]$Left = 0,
    [double]$Top = 0,
    [double]$Right = 1,
    [double]$Bottom = 1,
    [int]$Quality = 95
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Image]::FromFile((Resolve-Path $Source))
try {
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

    $rotated = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
    $g = [System.Drawing.Graphics]::FromImage($rotated)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.TranslateTransform($img.Width / 2, $img.Height / 2)
    $g.RotateTransform($Angle)
    $g.TranslateTransform(-$img.Width / 2, -$img.Height / 2)
    $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
    $g.Dispose()

    $x = [int]($rotated.Width * $Left)
    $y = [int]($rotated.Height * $Top)
    $w = [int]($rotated.Width * ($Right - $Left))
    $h = [int]($rotated.Height * ($Bottom - $Top))

    $crop = $rotated.Clone((New-Object System.Drawing.Rectangle($x, $y, $w, $h)), $rotated.PixelFormat)
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [int64]$Quality)
    $crop.Save((Join-Path (Get-Location) $Destination), $codec, $params)

    "$($crop.Width) x $($crop.Height) -> $Destination"
    $params.Dispose(); $crop.Dispose(); $rotated.Dispose()
}
finally {
    $img.Dispose()
}
