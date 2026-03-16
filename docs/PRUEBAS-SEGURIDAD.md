# Pruebas de seguridad JWT - Biblioteca

## 1. Obtener un token JWT válido (Keycloak)

Con Keycloak en marcha y el realm `gimnasio` configurado (ver [KEYCLOAK-SETUP.md](KEYCLOAK-SETUP.md)):

### Opción A: Cliente con Direct access grants (usuario/contraseña)

**Request (Postman o curl):**

- **URL:** `POST http://localhost:8080/realms/biblioteca/protocol/openid-connect/token`
- **Headers:** `Content-Type: application/x-www-form-urlencoded`
- **Body (x-www-form-urlencoded):**
  - `grant_type` = `password`
  - `client_id` = `<id del cliente>` (ej. `catalogoservice` o un cliente tipo `biblioteca-app`)
  - `client_secret` = `<secret del cliente>` (si el cliente es confidencial)
  - `username` = `admin` (o `bibliotecario`, `lector`)
  - `password` = `<contraseña del usuario>`

**Respuesta:** JSON con `access_token` (JWT). Copia ese valor para usarlo como Bearer.

### Opción B: Desde la consola de Keycloak

En **Clients** → tu cliente → **Client scopes** / **Credentials** puedes usar la pestaña **OpenID Endpoint Configuration** para ver la URL del token. Luego desde un cliente de pruebas (Postman, etc.) realiza la petición anterior.

---

## 2. Acceso a endpoints protegidos con token válido

1. Obtén un token con un usuario que tenga el rol necesario (ej. `ADMIN` o `BIBLIOTECARIO`).
2. En Postman (o similar):
   - Método y URL del microservicio, ej. `GET http://localhost:8082/libros/buscar?criterio=java`
   - Pestaña **Authorization** → Type: **Bearer Token** → Pegar el `access_token`.
3. Envía la petición. Debe responder **200** (o el código esperado) y el cuerpo de la respuesta.

**Ejemplos por microservicio:**

| Servicio   | Puerto | Ejemplo de endpoint                          | Rol requerido (donde aplica)     |
|-----------|--------|----------------------------------------------|-----------------------------------|
| Catálogo  | 8082   | GET /libros/buscar?criterio=java              | Cualquier autenticado            |
| Catálogo  | 8082   | PUT /libros/1/disponibilidad body: true       | ADMIN o BIBLIOTECARIO            |
| Usuarios  | 8081   | GET /usuarios/u1                             | Cualquier autenticado            |
| Usuarios  | 8081   | PUT /usuarios/u1/email body: "nuevo@mail.com"| ADMIN o BIBLIOTECARIO            |
| Circulación | 8083 | POST /circulacion/prestar?usuarioId=u1&libroId=l1 | ADMIN o BIBLIOTECARIO        |
| Circulación | 8083 | GET /circulacion/prestamos                    | ADMIN o BIBLIOTECARIO            |
| Notificación | 8084 | POST /notificar body: {"usuarioId":"u1","mensaje":"..."} | ADMIN o BIBLIOTECARIO   |

---

## 3. Token inválido o expirado

- **Sin header Authorization:** La petición debe devolver **401 Unauthorized**.
- **Header incorrecto:** Ej. `Authorization: Bearer token_invalido`. Debe devolver **401**.
- **Token expirado:** Usa un `access_token` antiguo (Keycloak suele dar 5 min por defecto). Debe devolver **401**.

Ejemplo curl sin token:

```bash
curl -i http://localhost:8082/libros/buscar?criterio=java
# Esperado: 401
```

---

## 4. Diferentes roles de usuario

Crear en Keycloak (realm `gimnasio`) al menos:

- Usuario **admin** con rol **ADMIN**
- Usuario **bibliotecario** con rol **BIBLIOTECARIO**
- Usuario **lector** con rol **LECTOR**

Pruebas sugeridas:

1. **LECTOR**
   - Debe poder: GET /libros/{id}, GET /libros/buscar, GET /libros/{id}/disponible, GET /usuarios/{id}.
   - No debe poder: PUT /libros/{id}/disponibilidad, PUT /usuarios/{id}/email, POST /circulacion/prestar, POST /circulacion/devolver, GET /circulacion/prestamos, POST /notificar → esperado **403 Forbidden**.

2. **BIBLIOTECARIO** y **ADMIN**
   - Deben poder acceder a todos los endpoints anteriores (incluidos los que requieren ADMIN o BIBLIOTECARIO).

Obtén un token para `lector` y otro para `bibliotecario` y repite las mismas URLs; donde el rol no sea suficiente debe aparecer **403**.

---

## 5. Swagger UI con JWT

Cada microservicio expone Swagger sin autenticación en:

- Catálogo: http://localhost:8082/swagger-ui.html
- Usuarios: http://localhost:8081/swagger-ui.html
- Circulación: http://localhost:8083/swagger-ui.html
- Notificación: http://localhost:8084/swagger-ui.html

Para probar endpoints protegidos desde Swagger:

1. Obtén un token (paso 1).
2. En Swagger UI, clic en **Authorize**.
3. Pega el token en el campo Bearer (solo el valor del token, sin la palabra "Bearer").
4. Ejecuta las operaciones; las peticiones irán con el header `Authorization: Bearer <token>`.

Así puedes demostrar acceso correcto con token válido y, si quitas el token o usas uno inválido, ver **401** en las respuestas.

---

## 6. Pruebas automatizadas con Newman (Postman CLI)

Además de probar a mano con curl o Swagger, puedes ejecutar un **conjunto de pruebas automatizadas** con [Newman](https://github.com/postmanlabs/newman), la CLI de Postman.

### 6.1. Preparar entorno

- Tener **Keycloak** levantado con el realm `gimnasio` y usuarios `admin`, `bibliotecario`, `lector`.
- Tener los **cuatro microservicios** en marcha (puertos 8081–8084).
- Tener **Node.js** instalado.

Instalar Newman globalmente:

```bash
npm install -g newman
```

### 6.2. Ejecutar la colección

En la raíz del proyecto:

```bash
newman run docs/newman-biblioteca.postman_collection.json
```

La colección hace lo siguiente:

- Llama al endpoint de **token** de Keycloak para obtener:
  - `token_admin`
  - `token_bibliotecario`
  - `token_lector`
- Ejecuta peticiones contra cada microservicio:
  - Catálogo: comprobar que el **lector** puede buscar libros pero no cambiar disponibilidad.
  - Usuarios: comprobar que el **lector** no puede cambiar el email.
  - Circulación: comprobar que el endpoint `/circulacion/public/status` es público y que el **lector** no puede listar todos los préstamos.
  - Notificación: comprobar que el **bibliotecario** puede enviar notificaciones.

Newman mostrará un resumen de tests pasados/fallados en consola; así puedes validar rápidamente que la configuración de seguridad y roles funciona en todos los microservicios.
