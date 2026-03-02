# Ejecuta cada microservicio en una nueva ventana de PowerShell.
# Ejecutar desde la raíz del proyecto. Keycloak debe estar ya levantado (docker-compose up -d).

# Raíz del proyecto = carpeta que contiene "scripts"
$root = Split-Path -Parent $PSScriptRoot
$services = @(
    @{ Name = "usuarios";     Port = 8081; Path = "microservicio-usuarios" },
    @{ Name = "catalogo";     Port = 8082; Path = "microservicio-catalogo" },
    @{ Name = "circulacion";  Port = 8083; Path = "microservicio-circulacion" },
    @{ Name = "notificacion"; Port = 8084; Path = "microservicio-notificacion" }
)

foreach ($svc in $services) {
    $dir = Join-Path $root $svc.Path
    if (-not (Test-Path $dir)) {
        Write-Warning "No existe: $dir"
        continue
    }
    Write-Host "Iniciando $($svc.Name) en puerto $($svc.Port)..."
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$dir'; .\mvnw.cmd spring-boot:run"
    Start-Sleep -Seconds 3
}

Write-Host "`nMicroservicios lanzados. Cierra cada ventana para detener el servicio."
Write-Host "Swagger: http://localhost:8081/swagger-ui.html (usuarios), 8082 (catalogo), 8083 (circulacion), 8084 (notificacion)"
