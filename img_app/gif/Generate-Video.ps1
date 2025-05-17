# Generate-Video.ps1
## Ejecuta el comando: Generate-Video.ps1
<#
.SYNOPSIS
    Convierte "video.mp4" a "tour.gif" en la misma carpeta,
    con 10 fps y ancho 400 px por defecto, usando paleta para mejorar calidad.
#>

param(
    [int]$Fps = 10,
    [int]$Width = 400
)

# 1) comprueba que ffmpeg esté en el PATH
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "ffmpeg no está en el PATH."
    exit 1
}

# rutas fijas
$input = Join-Path $PSScriptRoot 'video.mp4'
$output = Join-Path $PSScriptRoot 'tour.gif'
$palette = Join-Path $PSScriptRoot 'palette.png'

if (-not (Test-Path $input)) {
    Write-Error "No encuentro '$input'."
    exit 1
}

# 2) generamos la paleta optimizada
ffmpeg -y -i $input `
    -vf "fps=$Fps,scale=$($Width):-1:flags=lanczos,palettegen=stats_mode=diff" `
    $palette

# 3) creamos el GIF usando esa paleta (dithering para más detalle)
ffmpeg -y -i $input -i $palette `
    -filter_complex "fps=$Fps,scale=$($Width):-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" `
    -loop 0 $output

# (opcional) eliminar la paleta
Remove-Item $palette -ErrorAction SilentlyContinue

Write-Host "✅ tour.gif generado en '$output' (fps=$Fps, ancho=$Width px) con mayor calidad."
