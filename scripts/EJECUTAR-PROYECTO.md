# Cómo ejecutar el proyecto - Paso a paso

Sigue estos pasos **en tu PC**, en PowerShell o CMD.

---

## Paso 1: Keycloak (necesario para que los endpoints acepten JWT)

Elige **una** opción.

### Si tienes Docker

En la **raíz del proyecto** (donde está `docker-compose.yml`):

```powershell
cd "c:\Users\firer\OneDrive\Escritorio\UNIVERSIDAD\ICESI\noveno semestre\Microservicios\Gestion de biblioteca"
docker-compose up -d
```

Espera 1–2 minutos. Comprueba en el navegador: http://localhost:8080 (usuario: **admin**, contraseña: **admin**).

### Si no tienes Docker

1. Descarga Keycloak: https://www.keycloak.org/downloads (opción "Keycloak 25.x").
2. Descomprime y en una terminal, desde la carpeta de Keycloak:
   ```powershell
   bin\kc.bat start-dev
   ```
3. Abre http://localhost:8080, inicia sesión (admin / admin) y configura el realm **biblioteca** según [docs/KEYCLOAK-SETUP.md](../docs/KEYCLOAK-SETUP.md).

---

## Paso 2: Ejecutar los 4 microservicios

Abre **4 terminales** (PowerShell o CMD). En cada una, ejecuta **uno** de estos bloques (sustituye la ruta si tu proyecto está en otra carpeta).

**Terminal 1 – Usuarios (puerto 8081):**
```powershell
cd "c:\Users\firer\OneDrive\Escritorio\UNIVERSIDAD\ICESI\noveno semestre\Microservicios\Gestion de biblioteca\microservicio-usuarios"
.\mvnw.cmd spring-boot:run
```

**Terminal 2 – Catálogo (puerto 8082):**
```powershell
cd "c:\Users\firer\OneDrive\Escritorio\UNIVERSIDAD\ICESI\noveno semestre\Microservicios\Gestion de biblioteca\microservicio-catalogo"
.\mvnw.cmd spring-boot:run
```

**Terminal 3 – Circulación (puerto 8083):**
```powershell
cd "c:\Users\firer\OneDrive\Escritorio\UNIVERSIDAD\ICESI\noveno semestre\Microservicios\Gestion de biblioteca\microservicio-circulacion"
.\mvnw.cmd spring-boot:run
```

**Terminal 4 – Notificación (puerto 8084):**
```powershell
cd "c:\Users\firer\OneDrive\Escritorio\UNIVERSIDAD\ICESI\noveno semestre\Microservicios\Gestion de biblioteca\microservicio-notificacion"
.\mvnw.cmd spring-boot:run
```

> Si tienes Maven en el PATH puedes usar `mvn spring-boot:run` en lugar de `.\mvnw.cmd spring-boot:run`.

Espera en cada terminal a ver algo como: `Started ...Application in X seconds`.

---

## Paso 3: Comprobar que está todo arriba

- Keycloak: http://localhost:8080  
- Swagger Usuarios: http://localhost:8081/swagger-ui.html  
- Swagger Catálogo: http://localhost:8082/swagger-ui.html  
- Swagger Circulación: http://localhost:8083/swagger-ui.html  
- Swagger Notificación: http://localhost:8084/swagger-ui.html  

---

## Paso 4: Probar con token JWT (si Keycloak está corriendo)

1. Obtén un token (Postman o PowerShell):

   **Postman:**  
   - POST `http://localhost:8080/realms/biblioteca/protocol/openid-connect/token`  
   - Body: x-www-form-urlencoded  
   - `grant_type` = password  
   - `client_id` = biblioteca-app  
   - `username` = admin  
   - `password` = admin  

   **PowerShell:**
   ```powershell
   $body = @{
     grant_type = "password"
     client_id  = "biblioteca-app"
     username   = "admin"
     password   = "admin"
   }
   $r = Invoke-RestMethod -Uri "http://localhost:8080/realms/biblioteca/protocol/openid-connect/token" -Method Post -Body $body
   $r.access_token
   ```
   Copia el token que se imprime.

2. En Swagger (por ejemplo http://localhost:8082/swagger-ui.html): clic en **Authorize**, pega el token y prueba cualquier endpoint.

---

## Resumen rápido

| Orden | Qué hacer |
|-------|------------|
| 1 | Keycloak: `docker-compose up -d` **o** Keycloak instalado con realm `biblioteca` |
| 2 | 4 terminales → en cada una: `cd microservicio-XXX` y `mvn spring-boot:run` |
| 3 | Abrir Swagger en 8081, 8082, 8083, 8084 |
| 4 | (Opcional) Obtener token y usar Authorize en Swagger |

Para detener: Ctrl+C en cada terminal de microservicio; si usaste Docker: `docker-compose down`.
