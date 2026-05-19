# Flujo: Crear Área + Invitar usuarios (con código de verificación)

Este documento describe los endpoints y contratos exactos para el flujo completo
de invitación en HiperApp. El frontend **no genera ni calcula ningún código** —
todo lo genera el backend. El frontend solo es visual y consume estas APIs.

---

## Resumen del flujo de invitación

```
SA / AA                     Flutter App                    Backend
────────                    ───────────                    ───────
Genera invitación ──────►  POST /api/users/invite/  ────► genera código corto
                  ◄──────  { code, expires_at, ... }  ◄──
Copia el código
y lo comparte
                            (invitado abre la app)
                            Pantalla: "Tengo un código"
                            Ingresa el código ──────────►  POST /api/users/invite/verify/
                            Código verificado ◄──────────  { role, area_name, expires_at }
                            Muestra: "Vas a unirte         (muestra info antes de continuar)
                                      como AA en Marketing"
                            Llena nombre/email/pass
                            Envía ──────────────────────►  POST /api/users/accept-invite/
                            Cuenta creada ◄──────────────  { id, email, role, ... }
                            → va al login
```

---

## Endpoints involucrados

| Paso | Método | URL                             | Auth requerida                |
|------|--------|---------------------------------|-------------------------------|
| 1    | `GET`  | `/api/areas/`                   | Bearer JWT (SA ve todas, AA/TA solo la suya) |
| 2    | `POST` | `/api/areas/`                   | Bearer JWT — solo **SA**      |
| 3    | `POST` | `/api/users/invite/`            | Bearer JWT — SA o AA          |
| 4    | `POST` | `/api/users/invite/verify/`     | **Público** (sin JWT)         |
| 5    | `POST` | `/api/users/accept-invite/`     | **Público** (sin JWT)         |

---

## Paso 1 — Listar áreas

```
GET /api/areas/
Authorization: Bearer <access_token>
```

**Respuesta 200:**
```json
[
  {
    "id": "ca17493b-fcd9-4dd8-b0ca-a323b3995aa1",
    "name": "Desarrollo",
    "description": "Equipo de dev",
    "created_by": {
      "id": "uuid",
      "email": "admin@focus.com",
      "full_name": "Super Admin"
    },
    "created_at": "2026-04-03T...",
    "updated_at": "2026-04-03T..."
  }
]
```

> SA ve todas las áreas. AA y TA solo ven la suya (lista de 1 elemento).

---

## Paso 2 — Crear área (solo SA)

```
POST /api/areas/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "Marketing",
  "description": "Equipo de marketing"   ← opcional
}
```

**Respuesta 201:** mismo formato que GET individual arriba.

**Errores:**
- `403` si el rol no es `super_admin`
- `400` si `name` está vacío

---

## Paso 3 — Generar invitación ⚠️ CAMPO `code` REQUERIDO

```
POST /api/users/invite/
Authorization: Bearer <access_token>
Content-Type: application/json
```

### SA invitando AA o TA (requiere area):
```json
{
  "area": "ca17493b-fcd9-4dd8-b0ca-a323b3995aa1",
  "role": "admin_area"
}
```

### SA invitando otro SA (sin area):
```json
{
  "role": "super_admin"
}
```

### AA invitando TA (solo puede usar su propia area):
```json
{
  "area": "<el area_id del AA>",
  "role": "trabajador"
}
```

**Respuesta 201 — ⚠️ El backend DEBE incluir el campo `code`:**
```json
{
  "code":       "XK92BLP3",
  "expires_at": "2026-04-04T18:36:49.123456Z",
  "role":       "admin_area",
  "area_id":    "ca17493b-fcd9-4dd8-b0ca-a323b3995aa1"
}
```

> **`code`** es un identificador **corto, alfanumérico y legible** (recomendado:
> 8–16 chars, ej. `XK92BLP3`) que el SA/AA copia y comparte con el invitado.
> El `token` interno largo puede seguir existiendo en la BD, pero lo que llega
> al Flutter es `code`. Si el backend aún devuelve `token`, el app lo usa
> como fallback mientras no se migre.
>
> `area_id` es `null` para invitaciones de tipo `super_admin`.

**Errores de jerarquía:**
- `403` si AA intenta `role=admin_area` o `role=super_admin`
- `403` si AA usa un `area` distinto al suyo
- `429` si se superan 10 invitaciones/hora

---

## Paso 4 — Verificar código ⚠️ ENDPOINT NUEVO REQUERIDO

El frontend verifica el código **antes** de mostrar el formulario de registro.
Así el usuario sabe de inmediato si el código es inválido, sin tener que llenar
todos sus datos primero.

```
POST /api/users/invite/verify/
(sin JWT — endpoint público)
Content-Type: application/json

{
  "code": "XK92BLP3"
}
```

**Respuesta 200 — código válido:**
```json
{
  "role":       "admin_area",
  "area_name":  "Marketing",
  "expires_at": "2026-04-04T18:36:49.123456Z"
}
```

> El frontend usa `role` y `area_name` para mostrarle al invitado un banner:
> **"Vas a unirte como Administrador de Área · Marketing"**
> antes de pedirle que llene sus datos.

**Errores 400 — código inválido:**
```json
{ "code": "Código inválido" }
```
```json
{ "code": "Esta invitación ya fue utilizada" }
```
```json
{ "code": "Esta invitación ha expirado" }
```

> Los errores se muestran directamente en el campo del código, el usuario
> puede corregirlo sin salir de la pantalla.

---

## Paso 5 — Aceptar invitación (registro del usuario) ⚠️ USA `code`

```
POST /api/users/accept-invite/
(sin JWT — endpoint público)
Content-Type: application/json

{
  "code":       "XK92BLP3",
  "email":      "nuevo@example.com",
  "first_name": "Carlos",
  "last_name":  "López",
  "password":   "minimo8chars"
}
```

> Se usa `code` en lugar de `token`. El backend valida nuevamente el código
> al registrar (para evitar race conditions si el código expiró entre
> el verify y el submit).

**Respuesta 201:**
```json
{
  "id":         "uuid",
  "email":      "nuevo@example.com",
  "first_name": "Carlos",
  "last_name":  "López",
  "role":       "admin_area"
}
```

**Errores:**
- `400 code: Código inválido`
- `400 code: Esta invitación ya fue utilizada`
- `400 code: Esta invitación ha expirado`
- `400 email: Ya existe un usuario con este correo`

---

## Flujo Flutter — qué hace cada pantalla

### SA/AA genera la invitación (TeamScreen)

```
TeamScreen
  └── botón "Invitar al equipo"
        └── Dialog: {área (dropdown), rol}
              └── POST /api/users/invite/
                    └── éxito → dialog con código copiable
                          ┌─────────────────────────────────┐
                          │  Código de invitación           │
                          │  ┌───────────────────────────┐  │
                          │  │  XK92BLP3                 │  │
                          │  └───────────────────────────┘  │
                          │  [Copiar código]     [Listo]    │
                          └─────────────────────────────────┘
```

### Invitado crea su cuenta (InviteScreen / JoinScreen)

```
LoginScreen
  └── botón "Tengo un código de invitación"
        └── /join  →  InviteScreen (token vacío)

RegisterScreen
  └── botón "Tengo un código de invitación"
        └── /join  →  InviteScreen (token vacío)

InviteScreen — Paso 1: ingresa código
  ├── TextField (pegar código)
  ├── botón "Continuar" → POST /api/users/invite/verify/
  │     ├── error → muestra error en el campo (se queda en paso 1)
  │     └── éxito → avanza a paso 2 (con info del rol/área)
  │
  └── Paso 2: completa tu perfil
        ├── Banner: "Código verificado — Admin de Área · Marketing"
        ├── Formulario: email, nombre, apellido, contraseña
        └── botón "Activar cuenta" → POST /api/users/accept-invite/
              ├── error → muestra error bajo el formulario
              └── éxito → snackbar + redirige a /login
```

---

## Flujo Flutter (AA)

```
TeamScreen (AA)
  └── botón "Invitar trabajador" (area fija = la suya)
        └── POST /api/users/invite/ {area: user.area_id, role: "trabajador"}
              └── éxito → dialog con código copiable (igual que SA)
```

---

## Contrato de datos — modelo InviteInfo (Flutter)

El Flutter mapea la respuesta del endpoint `/verify/` a:

```dart
class InviteInfo {
  final String  role;       // 'super_admin' | 'admin_area' | 'trabajador'
  final String? areaName;   // null para super_admin
  final String? expiresAt;  // ISO 8601
}
```

---

## Notas de implementación para el backend

1. **Generar `code` corto**: Al crear la invitación, generar un código
   alfanumérico de 8–16 chars (ej. usando `secrets.token_urlsafe(8)` o
   similar). Puede coexistir con el `token` interno largo.

2. **Endpoint `/verify/` es idempotente**: Solo verifica, no consume la
   invitación. El código sigue siendo válido después de verificar.

3. **`/accept-invite/` valida el `code` nuevamente**: Aunque ya pasó por
   `/verify/`, al registrar se revalida para evitar que el código expire
   entre el verify y el submit.

4. **Backwards compatibility**: Mientras el campo `code` no esté en
   producción, el Flutter acepta `token` como fallback
   (`map['code'] ?? map['token']`).

5. **Los endpoints `/verify/` y `/accept-invite/` son públicos**: No
   requieren JWT. El frontend los llama sin interceptor de autenticación.
