# Gestión de Biblioteca - Microservicios

Proyecto de microservicios para la gestión de una biblioteca, con seguridad JWT (Keycloak) y documentación OpenAPI/Swagger.

**¿Primera vez ejecutando?** → Sigue la guía paso a paso: [scripts/EJECUTAR-PROYECTO.md](scripts/EJECUTAR-PROYECTO.md)

## Microservicios

| Microservicio | Puerto | Descripción |
|---------------|--------|-------------|
| **microservicio-usuarios** | 8081 | Gestión de usuarios |
| **microservicio-catalogo** | 8082 | Catálogo de libros |
| **microservicio-circulacion** | 8083 | Préstamos y devoluciones |
| **microservicio-notificacion** | 8084 | Envío de notificaciones |

## Requisitos previos

- **Java 17**
- **Maven 3.8+**
- **Keycloak** (solo si usas la seguridad JWT): puedes ejecutarlo con Docker o instalado en tu máquina; ver opciones abajo.

Los **microservicios se ejecutan como siempre** con `mvn spring-boot:run`; no hace falta Docker para ellos. Docker Compose es **opcional** y solo sirve para levantar Keycloak de forma rápida si no lo tienes instalado.

## 1. Iniciar Keycloak (solo para validar seguridad JWT)

Keycloak debe estar en marcha en **http://localhost:8080** para que los microservicios puedan validar los JWT. Puedes hacerlo de dos formas:

### Opción A – Con Docker (opcional)

Si tienes Docker instalado y quieres evitar instalar Keycloak a mano:

```bash
# En la raíz del proyecto
docker-compose up -d

# Esperar unos 30-60 segundos. Admin Console: http://localhost:8080 (admin / admin)
```

El realm **biblioteca** se importa automáticamente (roles, cliente `biblioteca-app`, usuarios admin/bibliotecario/lector). Si no se importa, configura el realm a mano según [docs/KEYCLOAK-SETUP.md](docs/KEYCLOAK-SETUP.md).

### Opción B – Sin Docker (Keycloak instalado)

1. Descarga Keycloak desde [keycloak.org](https://www.keycloak.org/downloads) y descomprímelo.
2. En una terminal, desde el directorio de Keycloak:  
   **Linux/Mac:** `bin/kc.sh start-dev`  
   **Windows:** `bin\kc.bat start-dev`
3. Abre http://localhost:8080, inicia sesión (admin / admin) y crea el realm **biblioteca** siguiendo [docs/KEYCLOAK-SETUP.md](docs/KEYCLOAK-SETUP.md) (realm, cliente, roles, usuarios).

En ambos casos, los microservicios se ejecutan igual con Maven.

## 2. Ejecutar los microservicios

Abre **cuatro terminales** (o usa tu IDE para lanzar cada aplicación) y ejecuta uno por uno. El orden no es crítico, pero Keycloak debe estar ya levantado.

```bash
# Terminal 1 - Usuarios
cd microservicio-usuarios
mvn spring-boot:run

# Terminal 2 - Catálogo
cd microservicio-catalogo
mvn spring-boot:run

# Terminal 3 - Circulación
cd microservicio-circulacion
mvn spring-boot:run

# Terminal 4 - Notificación
cd microservicio-notificacion
mvn spring-boot:run
```

Alternativamente, desde la raíz:

```bash
mvn -f microservicio-usuarios/pom.xml spring-boot:run
mvn -f microservicio-catalogo/pom.xml spring-boot:run
mvn -f microservicio-circulacion/pom.xml spring-boot:run
mvn -f microservicio-notificacion/pom.xml spring-boot:run
```

**Windows (PowerShell):** puedes lanzar los cuatro a la vez en ventanas separadas:

```powershell
.\scripts\ejecutar-microservicios.ps1
```

Cada servicio expone:

- **API REST** en el puerto indicado.
- **Swagger UI** en `http://localhost:<puerto>/swagger-ui.html`.

## 3. Obtener un token JWT

Para llamar a los endpoints protegidos necesitas un token de Keycloak.

**Opción A – Postman / Insomnia / curl**

- **URL:** `POST http://localhost:8080/realms/biblioteca/protocol/openid-connect/token`
- **Headers:** `Content-Type: application/x-www-form-urlencoded`
- **Body (x-www-form-urlencoded):**

  | Clave        | Valor        |
  |-------------|--------------|
  | grant_type  | password     |
  | client_id   | biblioteca-app |
  | username    | admin        |
  | password    | admin        |

En la respuesta JSON copia el valor de **`access_token`**.

**Opción B – curl**

```bash
curl -X POST "http://localhost:8080/realms/biblioteca/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=biblioteca-app" \
  -d "username=admin" \
  -d "password=admin"
```

## 4. Validar la implementación

### 4.1 Swagger UI con JWT

1. Abre, por ejemplo, http://localhost:8082/swagger-ui.html (Catálogo).
2. Clic en **Authorize**.
3. Pega solo el valor del `access_token` (sin la palabra "Bearer") y confirma.
4. Ejecuta cualquier operación; las peticiones irán con `Authorization: Bearer <token>`.

Repite en los otros puertos (8081, 8083, 8084) para los demás microservicios.

### 4.2 Llamada con curl

```bash
# Sustituye TOKEN por el access_token obtenido en el paso 3.

# Catálogo - buscar libros (cualquier usuario autenticado)
curl -H "Authorization: Bearer TOKEN" "http://localhost:8082/libros/buscar?criterio=java"

# Usuarios - obtener usuario (cualquier usuario autenticado)
curl -H "Authorization: Bearer TOKEN" "http://localhost:8081/usuarios/u1"
```

### 4.3 Comportamiento esperado

| Prueba                    | Resultado esperado |
|---------------------------|--------------------|
| Petición **sin** token    | **401** Unauthorized |
| Token inválido o expirado | **401** Unauthorized |
| Usuario **lector** en PUT /libros/.../disponibilidad | **403** Forbidden |
| Usuario **admin** o **bibliotecario** en ese endpoint | **200** (si el recurso existe) |

Más casos en [docs/PRUEBAS-SEGURIDAD.md](docs/PRUEBAS-SEGURIDAD.md).

## 5. Documentación adicional

- [docs/KEYCLOAK-SETUP.md](docs/KEYCLOAK-SETUP.md) – Explicación del realm y configuración manual de Keycloak.
- [docs/PRUEBAS-SEGURIDAD.md](docs/PRUEBAS-SEGURIDAD.md) – Pruebas de seguridad (token válido, inválido, roles).

## 6. Detener todo

- **Keycloak con Docker:** `docker-compose down`
- **Keycloak sin Docker:** Ctrl+C en la terminal donde ejecutaste `kc.sh start-dev` (o cierra el proceso).
- **Microservicios:** Ctrl+C en cada terminal donde corre `mvn spring-boot:run`.

## Resumen de URLs útiles

| Recurso              | URL |
|----------------------|-----|
| Keycloak Admin       | http://localhost:8080 |
| Swagger Catálogo     | http://localhost:8082/swagger-ui.html |
| Swagger Usuarios     | http://localhost:8081/swagger-ui.html |
| Swagger Circulación  | http://localhost:8083/swagger-ui.html |
| Swagger Notificación| http://localhost:8084/swagger-ui.html |
