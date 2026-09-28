param(
    [int]$Port = 8080
)

$baseDir = $PSScriptRoot
if (-not $baseDir) { $baseDir = Get-Location }

# Find an available port if the specified one is in use
while ($true) {
    try {
        $listener = New-Object System.Net.HttpListener
        $prefix = "http://localhost:$Port/"
        $listener.Prefixes.Add($prefix)
        $listener.Start()
        break
    } catch {
        Write-Host "Puerto $Port ocupado, probando $( $Port + 1 )..."
        $Port++
        if ($Port -gt 8100) {
            Write-Error "No se pudo encontrar un puerto libre."
            exit 1
        }
    }
}

Write-Host "============================================="
Write-Host " Servidor local activo en: http://localhost:$Port/"
Write-Host " Presiona Ctrl+C para detener el servidor"
Write-Host "============================================="

# Open default browser
try {
    Start-Process "http://localhost:$Port/"
} catch {
    Write-Warning "No se pudo abrir el navegador automáticamente: $_"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($urlPath)) {
            $urlPath = "index.html"
        }

        # Normalize path separators
        $urlPath = $urlPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $filePath = Join-Path $baseDir $urlPath

        if (-not (Test-Path $filePath -PathType Leaf)) {
            $filePath = Join-Path $baseDir "index.html"
        }

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".htm"  { "text/html; charset=utf-8" }
                ".css"  { "text/css; charset=utf-8" }
                ".js"   { "application/javascript; charset=utf-8" }
                ".json" { "application/json; charset=utf-8" }
                ".png"  { "image/png" }
                ".jpg"  { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".gif"  { "image/gif" }
                ".svg"  { "image/svg+xml" }
                ".webp" { "image/webp" }
                ".ico"  { "image/x-icon" }
                default { "application/octet-stream" }
            }

            try {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentType = $contentType
                $response.ContentLength64 = $bytes.Length
                $response.StatusCode = 200
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } catch {
                $response.StatusCode = 500
            }
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 No Encontrado")
            $response.ContentLength64 = $errBytes.Length
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
