# Generate-Collage.ps1
# Ejecución: .\Generate-Collage.ps1 -columns 4

param(
    [int]$columns = 3       # por defecto 3 columnas
)

Add-Type -AssemblyName System.Drawing

$bgColor = 'Black'
$outFile = Join-Path -Path (Get-Location) -ChildPath 'collage.png'

# Carga imágenes (excluye el propio collage.png)
$imgs = Get-ChildItem -File |
Where-Object {
        ($_.Extension -in '.jpg', '.jpeg', '.png') -and
        ($_.Name -ne 'collage.png')
} |
Sort-Object Name

if (-not $imgs) {
    Write-Error "No encontré imágenes (.jpg/.png) aquí."
    exit
}

# Tamaño base
$first = [System.Drawing.Image]::FromFile($imgs[0].FullName)
$w = $first.Width; $h = $first.Height
$first.Dispose()

# Cálculos de lienzo
$count = $imgs.Count
$rows = [math]::Ceiling($count / $columns)
$canvasW = $columns * $w
$canvasH = $rows * $h

# Crear lienzo
$bmp = New-Object System.Drawing.Bitmap $canvasW, $canvasH
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::$bgColor)

# Dibuja cada imagen
for ($i = 0; $i -lt $count; $i++) {
    $img = [System.Drawing.Image]::FromFile($imgs[$i].FullName)
    $x = ($i % $columns) * $w
    $y = [math]::Floor($i / $columns) * $h
    $g.DrawImage($img, $x, $y, $w, $h)
    $img.Dispose()
}

# Guardar como PNG
$g.Dispose()
$bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "👍 Collage listo: $outFile con $columns columnas."
