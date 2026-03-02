# Configuración de Keycloak para el proyecto Biblioteca

## Configuración automática (recomendada)

Si usas **Docker Compose** desde la raíz del proyecto (`docker-compose up -d`), el realm **biblioteca** se importa automáticamente con:

- Roles: ADMIN, BIBLIOTECARIO, LECTOR  
- Cliente **biblioteca-app** (Direct Access Grants) para obtener token con usuario/contraseña  
- Usuarios: admin / admin, bibliotecario / bibliotecario, lector / lector  

No es necesario seguir los pasos manuales de abajo salvo que quieras cambiar algo o no uses Docker.

---

## ¿Qué es un Realm en Keycloak?

Un **realm** en Keycloak es un espacio de administración que agrupa:

- **Usuarios**: las cuentas que pueden autenticarse.
- **Credenciales**: contraseñas, tokens, etc.
- **Roles**: permisos y agrupaciones (ej. `ADMIN`, `BIBLIOTECARIO`, `LECTOR`).
- **Clientes**: aplicaciones o servicios que usan Keycloak para autenticación (tus microservicios, frontends, etc.).
- **Configuraciones de sesión y tokens**: tiempo de vida del JWT, claims, etc.

Puedes imaginarlo como **un “tenant” o “proyecto” dentro del mismo servidor Keycloak**. Cada realm es independiente: sus usuarios y roles no se mezclan con otros realms. Así puedes tener, por ejemplo:

- Un realm `biblioteca` para este proyecto.
- Otro realm `gimnasio` para otro proyecto.
- Un realm `master` (por defecto) para administrar el propio Keycloak.

Para este proyecto usaremos un realm llamado **`biblioteca`** (el enunciado menciona “gimnasio” como ejemplo; aquí aplicamos la misma idea al proyecto de biblioteca).

---

## 1. Crear el realm "biblioteca"

1. Inicia Keycloak (Docker o instalación local).
2. Accede al **Admin Console** (ej. `http://localhost:8080`).
3. Inicia sesión con el usuario admin del realm `master`.
4. En el desplegable superior izquierdo donde dice **master**, haz clic en **Create realm**.
5. **Realm name**: `biblioteca`.
6. Clic en **Create**.

---

## 2. Configurar un cliente por cada microservicio

Cada microservicio actuará como **cliente** que valida JWTs emitidos por Keycloak. Crea un cliente por servicio.

### Cliente: catalogoservice

1. En el realm **biblioteca**: **Clients** → **Create client**.
2. **Client type**: OpenID Connect.
3. **Client ID**: `catalogoservice`.
4. **Next**.
5. **Client authentication**: ON (es un servicio confidencial que validará tokens).
6. **Authorization**: OFF (salvo que uses fine-grained auth).
7. **Next**.
8. **Authentication flow**: marcar **Standard flow** y **Direct access grants** si vas a obtener tokens con usuario/contraseña desde Postman.
9. **Next**.
10. **Valid redirect URIs**: por ejemplo `http://localhost:8082/*` (puerto del catálogo).
11. **Web origins**: `http://localhost:8082` o `+` para permitir todos en desarrollo.
12. **Save**.
13. En la pestaña **Credentials** copia el **Secret** y úsalo en `application.properties` del microservicio catálogo como `spring.security.oauth2.resourceserver.jwt.issuer-uri` no, el secret va en otro lado. En realidad para **validar JWT** no hace falta el client secret en el resource server; el secret se usa si el microservicio obtuviera tokens (client credentials). Para solo validar, basta el **issuer-uri** y opcionalmente **jwk-set-uri**. El **Client ID** del cliente en Keycloak puede ser el mismo que el `audience` si lo exiges.
14. Anota: **Client ID** = `catalogoservice`. Si activas "Service accounts" podrías usar client credentials para pruebas.

Repite el mismo proceso para:

- **usuarioservice** (puerto 8081 típico).
- **circulacionservice** (puerto 8083).
- **notificacionservice** (puerto 8084).

Cada uno con su **Client ID** igual al nombre del servicio y su puerto en redirect URIs si aplica.

---

## 3. Definir roles relevantes

1. En el realm **biblioteca**: **Realm roles** → **Create role**.
2. Crear por ejemplo:
   - **ADMIN**: administrador del sistema.
   - **BIBLIOTECARIO**: gestiona préstamos, catálogo y notificaciones.
   - **LECTOR**: solo consulta y hace préstamos como usuario final.

Puedes asignar estos roles a **realm roles** (a nivel de realm) para que aparezcan en el JWT.

---

## 4. Crear usuarios de prueba

1. **Users** → **Add user**.
2. Ejemplos:
   - **admin**  
     - Username: `admin`  
     - Email: `admin@biblioteca.com`  
     - Asignar rol **ADMIN** en **Role mapping**.
   - **bibliotecario**  
     - Username: `bibliotecario`  
     - Asignar rol **BIBLIOTECARIO**.
   - **lector**  
     - Username: `lector`  
     - Asignar rol **LECTOR**.
3. Para cada usuario, en **Credentials** establece una **Password** (temporal o permanente) y desactiva **Temporary** si no quieres forzar cambio en el primer login.

---

## 5. Obtener un token JWT para pruebas

Desde **Keycloak** puedes usar:

- **Clients** → tu cliente (ej. `catalogoservice`) → **Client scopes** / o bien usar el cliente estándar **account** o un cliente con "Direct access grants" habilitado.

En desarrollo suele crearse un cliente tipo **public** o **confidencial** con "Direct access grants" para obtener token con usuario y contraseña:

- **Token Endpoint**:  
  `http://localhost:8080/realms/biblioteca/protocol/openid-connect/token`
- **Método**: POST, body `x-www-form-urlencoded`:
  - `grant_type`: `password`
  - `client_id`: `<tu-client-id>`
  - `client_secret`: `<secret del cliente>` (si es confidencial)
  - `username`: `admin`
  - `password`: `<contraseña del usuario>`

La respuesta incluye `access_token` (JWT). Ese token se envía en el header:

```http
Authorization: Bearer <access_token>
```

---

## Resumen

| Concepto   | Descripción breve                                                                 |
|-----------|-------------------------------------------------------------------------------------|
| **Realm** | Espacio aislado en Keycloak: usuarios, roles, clientes y configuración del proyecto. |
| **Cliente** | Aplicación o microservicio que usa Keycloak (cada uno con su Client ID).           |
| **Roles** | Permisos (ADMIN, BIBLIOTECARIO, LECTOR) que se incluyen en el JWT.                  |
| **Usuario** | Cuenta en el realm; al autenticarse recibe un JWT con sus roles.                   |

Con esto puedes seguir con la implementación de Spring Security + JWT y la documentación Swagger en cada microservicio.
