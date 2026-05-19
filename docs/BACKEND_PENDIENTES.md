# Pendientes Backend — HiperApp / Focus

**Base URL producción:** `https://focus-backend-u211p.sevalla.app`  
**Última revisión:** 2026-04-07

El frontend Flutter está conectado al backend real. Este documento lista únicamente
los problemas y pendientes detectados en pruebas con la app en dispositivo físico.

---

## Estado general de endpoints

| Endpoint | Método | Estado |
|---|---|---|
| `GET /api/auth/me/` | GET | ✅ OK |
| `POST /api/auth/login/` | POST | ✅ OK |
| `POST /api/auth/logout/` | POST | ✅ OK |
| `POST /api/auth/refresh/` | POST | ✅ OK |
| `GET /api/activities/` | GET | ✅ OK |
| `POST /api/activities/` | POST | ✅ OK |
| `GET/PATCH/DELETE /api/activities/{uuid}/` | — | ✅ OK |
| `POST /api/activities/{uuid}/move/` | POST | ✅ OK |
| `POST /api/activities/{uuid}/assign/` | POST | ✅ OK |
| `POST /api/activities/{uuid}/complete/` | POST | ✅ OK |
| `GET/POST /api/activities/{uuid}/attachments/` | — | ✅ OK |
| `GET /api/areas/` | GET | ✅ OK |
| `GET /api/users/` | GET | ✅ OK |
| `POST /api/users/invite/` | POST | ✅ OK — falta campo `code` (ver §1) |
| `GET /api/users/invite/verify/` | GET | ❌ Pendiente (ver §2) |
| `POST /api/users/accept-invite/` | POST | ⚠️ Parcial — no acepta `code` (ver §3) |
| `GET /api/projects/` | GET | 🔴 Connection timeout (ver §4) |
| Serialización de proyectos + actividades anidadas | — | ⚠️ Ver **§6** (área / AA / lista vacía) |
| `GET /api/users/?role=admin_area` | GET | 🔴 Connection timeout (ver §4) |
| `GET /api/stats/personal/` | GET | ❓ Sin probar |
| `GET /api/stats/global/` | GET | ❓ Sin probar |
| `GET /api/stats/workers/` | GET | ❓ Sin probar |
| `GET /api/stats/area/{uuid}/` | GET | ❓ Sin probar |

---

## 🔴 §4 — `GET /api/projects/` y `GET /api/users/?role=admin_area` no responden

### Síntoma (progresión observada)
```
# Día 1: respondía con HTML de error
[API] ✗ 500 GET /api/projects/ | <!doctype html>...<title>Server Error (500)</title>...

# Día 2: ya ni acepta la conexión
[API] ✗ -- GET /api/projects/       | connection timeout (15s)
[API] ✗ -- GET /api/users/?role=admin_area | connection timeout (15s)
```
Mientras tanto `GET /api/activities/` sigue respondiendo 200 con normalidad.

### Diagnóstico probable
El worker/proceso de Django que atiende estos endpoints se quedó bloqueado o murió
(deadlock de DB, query sin índice que agota el connection pool, memoria, etc.).
Los demás endpoints siguen vivos porque usan diferentes queries o tablas.

### Impacto
- Pantalla **Proyectos** → no carga nada
- Dropdown de proyectos en **Capturar** → aparece vacío
- Pantalla **Equipo** (vista SA) → aparece vacía (los admins de área no cargan)
- El tablero y la captura de actividades **sí funcionan** (ya tienen `catchError`)

### Acción requerida en backend
1. Revisar logs de Gunicorn/uwsgi para ver el traceback real
2. Verificar si hay queries colgadas en PostgreSQL (`SELECT * FROM pg_stat_activity WHERE state = 'active'`)
3. Reiniciar el worker como medida temporal
4. Agregar índices si la query de proyectos hace full scan

---

## ❌ §2 — `GET /api/users/invite/verify/` no existe

### Contrato esperado por el frontend
```
GET /api/users/invite/verify/?code=IZJC5DB3
(sin Authorization header — endpoint público)
```

### Respuesta 200 — código válido:
```json
{
  "role":       "trabajador",
  "area_name":  "Test Area",
  "expires_at": "2026-04-07T18:00:00Z"
}
```

### Respuestas de error 400:
```json
{ "code": "Código inválido" }
{ "code": "Esta invitación ya fue utilizada" }
{ "code": "Esta invitación ha expirado" }
```

### Comportamiento
- **No consume** la invitación. Se puede llamar N veces.
- El frontend lo llama antes de mostrar el formulario de registro.

---

## ⚠️ §3 — `POST /api/users/accept-invite/` no acepta campo `code`

### Qué manda el frontend
```json
{
  "code":       "IZJC5DB3",
  "email":      "nuevo@example.com",
  "first_name": "Ana",
  "last_name":  "García",
  "password":   "MiPassword1!"
}
```

### Solución sugerida
Aceptar tanto `code` como `token` (compatibilidad hacia atrás):
```python
identifier = request.data.get('code') or request.data.get('token')
invitation  = Invitation.objects.get(code=identifier)
```

### Respuesta 201 esperada:
```json
{
  "id":         "uuid",
  "email":      "nuevo@example.com",
  "first_name": "Ana",
  "last_name":  "García",
  "role":       "trabajador",
  "area_id":    "uuid"
}
```

---

## ✅ §1 — `POST /api/users/invite/` — agregar campo `code` en respuesta

El endpoint ya funciona pero devuelve solo `token` (JWT largo, difícil de compartir).

### Agregar `code` a la respuesta:
```json
{
  "code":       "IZJC5DB3",
  "token":      "eyJhbGci...",
  "expires_at": "2026-04-07T18:00:00Z",
  "role":       "trabajador",
  "area_id":    "uuid"
}
```

El `code` debe ser único (8 chars A-Z0-9), válido 24 horas, un solo uso.  
El frontend ya hace `map['code'] ?? map['token']` como fallback mientras no exista.

---

## Flujo de invitación completo (referencia)

```
SA/AA                         Backend                      Invitado (Flutter)
─────                         ───────                      ──────────────────
POST /users/invite/   ──►    genera code + token
{ area, role }        ◄──    { code: "IZJC5DB3", ... }
Copia "IZJC5DB3"
Lo comparte (WhatsApp, etc.)
                                                 Abre app → "Tengo código"
                                                 Escribe: IZJC5DB3
                              GET /users/invite/verify/?code=IZJC5DB3  ──►
                                                 ◄──  { role, area_name }
                                                 Ve: "Trabajador · Test Area ✓"
                                                 Llena: nombre, email, password
                              POST /users/accept-invite/  ──►
                              { code, email, first_name, last_name, password }
                                                 ◄──  { id, email, role }
                                                 → Redirige a Login
```

---

## §6 — Proyectos: área, administrador de área y `GET /api/projects/{id}/activities/`

### Contrato esperado (alineado con la doc Focus / uso en Flutter)

1. **`GET /api/projects/` y `GET /api/projects/{id}/`**  
   Deben incluir de forma estable, cuando existan:
   - `area`: UUID **o** objeto anidado `{ id, name }`
   - `area_name` (opcional pero recomendado)
   - `area_admin_name` o relación equivalente al AA responsable del área (para mostrar “Administrador de área”)

   Si `POST /api/projects/` guarda `area` pero el listado/detalle **no** devuelve `area` / `area_id`, el cliente trata el proyecto como “personal” (sin área): la pestaña **Para AA** queda vacía y las tarjetas no muestran vínculo.

2. **`GET /api/projects/{uuid}/activities/`**  
   Debe devolver las mismas actividades que tendrían `project_id` / `project` apuntando a ese UUID en **`GET /api/activities/`**.  
   Si el listado global muestra actividades con `project_id` correcto pero este endpoint devuelve `count: 0`, hay inconsistencia en backend (filtro, permisos o FK).

### Mitigación en frontend (2026-04-06)

- Detalle de proyecto (SA): si el endpoint anidado viene vacío, se usa **fallback** filtrando `GET /api/activities/` por `project_id`, y se muestra un aviso en pantalla.
- Nombres de área: si faltan en el proyecto, se intenta resolver con `GET /api/areas/`.

### Acción requerida en backend

- Revisar serializers de `Project` (list + retrieve) y la vista de `ProjectActivities` para coherencia con el listado global y con el payload de creación (`area`).

---

## §7 — Hallazgos por logs (2026-04-07): clasificación Back vs Front

Fuente: trazas con prefijos `[API]`, `[FILTER]`, `[PROJECTS][API]`, `[PROJECTS][PARSED]`, `[PROJECTS][SCREEN]`.

### 7.1 TA no ve actividad asignada (aunque SA sí la ve)

**Evidencia de logs**
- `GET /api/activities/` responde `200` con actividad:
  - `assigned_to_id = 5ac7bb77-...` (usuario TA logueado)
  - `project_id != null`
  - `area_id = null`
- Luego el filtro local imprime:
  - `[FILTER] X "Danger" ...`
  - `[FILTER] √ 0/1 actividades visibles`

**Diagnóstico**
- **FRONTEND (regla de filtrado)**: la función `isTeamActivityForUser(...)` no contempla explícitamente "si está asignada a mí, mostrarla". Para TA/AA usa principalmente `areaId` de proyecto/actividad o propiedad (`ownerId`), por eso descarta una actividad asignada al TA cuando `area_id` viene nulo.
- **BACKEND (consistencia de datos)**: al devolver actividad de proyecto con `area_id = null`, también rompe la heurística de equipo en cliente.

**Clasificación**
- Principal: **FRONTEND**
- Contribuyente: **BACKEND**

### 7.2 En Proyectos, "Equipo/Para AA" queda vacío y aparecen en "Personales"

**Evidencia de logs**
- Al crear proyecto con `POST /api/projects/` enviando `area: <uuid>`, backend responde `201`.
- Al recargar `GET /api/projects/`, todos los ítems llegan con:
  - `area = null`
  - `area_name = null`
  - `area_admin_name = null`
- Parseo del cliente:
  - `areaId = null` en todos.
- Filtro de pantalla:
  - `tab=team ... visible=0`
  - `tab=personal ... visible>0`

**Diagnóstico**
- **BACKEND**: el listado/detalle de proyectos no está serializando/persistiendo `area` correctamente. El frontend clasifica "equipo" por `areaId != null`; si todo llega null, todo cae en personales.

**Clasificación**
- Principal: **BACKEND**

### 7.3 En SA tablero no cargó hasta refresh

**Evidencia de logs**
- No hay timeout ni 500 en esas trazas.
- Se observan `200` en `/api/projects/` y `/api/activities/`.
- Después llega `[FILTER] √ 4/4 actividades visibles`.

**Diagnóstico**
- **No apunta a conectividad backend** en ese evento (las respuestas llegan OK).
- Indicio de **FRONTEND/estado asincrónico** (timing de providers/caché/invalidación al navegar o cambiar sesión), porque los datos sí existen y terminan apareciendo tras refrescar.

**Clasificación**
- Principal: **FRONTEND (manejo de estado/refresh)**
- No reproducible aquí como falla de red/backend en los logs compartidos.

---

## §8 — Incidente AA al crear actividad en proyecto: `POST 201` seguido de `GET detalle 404`

### Evidencia observada en logs (2026-04-07)

Secuencia real capturada en dispositivo:

1. `POST /api/activities/` responde **201**  
   - Se crea la actividad con `id=88b9f4cf-63d7-482b-b8bb-282906b623be`
   - Payload/response muestran `project=5e8ec807-061b-40ce-a3e5-7fecd1842da7`
   - La actividad queda con `area=null`

2. Inmediatamente después, el cliente intenta abrir detalle:
   - `GET /api/activities/88b9f4cf-63d7-482b-b8bb-282906b623be/`
   - Respuesta: **404 No encontrado**

3. El cliente luego consulta listados:
   - `GET /api/activities/` responde **200**, pero no incluye la actividad recién creada para ese usuario/flujo
   - `GET /api/projects/{id}/activities/` responde **200** con la actividad, también con `area_id=null`

### Diagnóstico técnico

Esto **no es crash de Flutter** en este bloque: es una inconsistencia de visibilidad/consulta en backend.

- Si un recurso se crea con `201` y acto seguido su `GET /api/activities/{id}/` devuelve `404`, el problema apunta a:
  - reglas de permisos/filtros por rol en `retrieve`, o
  - queryset distinto entre `create`, `list` y `retrieve`, o
  - política que oculta registros con `area_id=null` para ciertos roles.

La evidencia refuerza ese punto:
- el proyecto y la actividad aparecen con `area=null`/`area_id=null`,
- y para AA eso puede excluirlos en rutas que dependan de área para autorización/visibilidad.

### Clasificación

- Principal: **BACKEND** (consistencia entre create/list/retrieve + reglas de permisos)
- Contribuyente: **BACKEND data shape** (`area_id` nulo en registros nuevos/históricos)
- Mitigación UX: **FRONTEND** (manejar 404 post-creación sin romper flujo visual)

### Impacto funcional

- Usuario AA percibe que “tronó” al crear actividad dentro de proyecto.
- El alta sí sucede, pero la app no puede abrir el detalle inmediato (404), generando sensación de falla.
- Se degrada la confianza del flujo de creación y post-navegación.

### Acción requerida en backend (checklist)

1. Alinear el `queryset` de `ActivityListCreateView` y `ActivityDetailView` para que un item recién creado por usuario autorizado sea recuperable por ese mismo usuario.
2. Verificar que reglas AA incluyan al menos:
   - `owner=user` **o**
   - `assigned_to=user` **o**
   - pertenencia por `area_id`/`project__area_id` según contrato de negocio.
3. Confirmar normalización en serializer:
   - `area_id -> area`
   - `project_id -> project`
4. Mantener auto-herencia de área desde proyecto al crear actividad (si `project.area` existe y `area` no llega).
5. Validar en entorno real con la misma secuencia:
   - crear actividad (AA) -> abrir detalle inmediato -> debe responder **200**.

### Mitigación temporal en frontend (ya recomendada)

Si `GET /api/activities/{id}/` devuelve 404 justo después de crear:
- no mostrar pantalla de error fatal,
- regresar a lista/detalle de proyecto y mostrar aviso no bloqueante,
- reintentar fetch o refrescar colección.

### Estado post-fix backend (2026-04-07)

Se corrigió `_get_activity_for_user` para AA con `_can_aa_access_activity` (área, proyecto del área, owner).  
En pruebas recientes, `GET /api/activities/{id}/` pasa a **200** tras crear la actividad. El §8 queda **cerrado en detalle** si ese comportamiento se mantiene en producción.

---

## §9 — Asignar actividad (AA → TA): `POST /api/activities/{id}/assign/`

### Regla de negocio (producto)

Un **Administrador de área** (`admin_area`) solo debe poder **asignar trabajo a personas de su misma área** (usuarios cuyo `area_id` coincide con el del AA). No aplica asignar a usuarios de otra área salvo excepción explícita del producto (p. ej. solo SuperAdmin).

- **SuperAdmin:** puede asignar a cualquier usuario.
- **Admin de área:** solo a usuarios con `assignee.area_id == user.area_id`.
- Si el destino no es elegible: **400** con mensaje claro en el campo `assigned_to`, no **404** por política de asignación.

### Causa raíz (histórica — 2026-04-07)

`AssignActivityView` **no** usaba `_get_activity_for_user`; hacía un check manual:

```text
if user.role == 'admin_area' and activity.area_id != user.area_id:
    raise NotFound()   # None != <uuid> → True → 404
```

Mismo patrón que §8: con `activity.area_id = null`, el AA recibía **404** al asignar aunque el detalle ya fuera accesible tras el fix de `_get_activity_for_user`.

### Evidencia en logs (antes del fix de assign)

- `GET /api/activities/{id}/` → **200** (detalle OK).
- `POST /api/activities/{id}/assign/` → **404** `No encontrado.`

### Fix aplicado en backend (`apps/activities/views.py` — `AssignActivityView`)

1. **Resolución de actividad:** dejar de usar `get_object_or_404(Activity, pk=pk)` + check manual; usar `_get_activity_for_user(pk, request.user)` y mapear `Activity.DoesNotExist` → `NotFound()`. Así **assign** queda alineado con detail/list (`_can_aa_access_activity`).
2. **Validación del asignatario:** si `user.role == 'admin_area'` y `assignee` no es `None`, exigir `assignee.area_id == user.area_id`. Si falla, responder **400** con cuerpo del estilo:
   ```json
   { "assigned_to": "Solo puedes asignar actividades a miembros de tu área." }
   ```

**Otras vistas:** `MoveActivityView` y `CompleteActivityView` deben seguir usando `_get_activity_for_user` (coherente con §8). Las vistas de **attachments** pueden tener control propio; revisar solo si aparece el mismo patrón `area_id !=` a ciegas.

### Estado

- **Repositorio backend (verificado por equipo):** `AssignActivityView` usa `_get_activity_for_user` (~línea 206); validación **400** en `assigned_to` si el TA no es del área del AA; una sola ruta `/assign/`; `GET /api/users/?role=trabajador` aplica `area_id` del usuario para **AA** además del filtro por rol.
- **Deploy Sevalla:** verificado en app (2026-04-07): `POST .../assign/` como **AA** → **200**; bitácora con `event_type: assigned`. El síntoma “detail 200 + assign 404” quedó resuelto en producción.
- **Regresión:** si vuelve 404 en assign con detalle 200, revisar de nuevo deploy o rutas duplicadas.
- **Frontend:** listo; el filtro local por área para AA es **redundante** si el API ya acota la lista, pero no rompe nada (doble filtro coherente).

---

### Briefing para backend — verificación, respuestas y alineación con Flutter

Copiar o adjuntar este bloque al ticket / chat del equipo servidor.

#### 1. Objetivo

Un **admin_area** debe poder **asignar** actividades que ya puede **ver** en detalle (mismas reglas que `_get_activity_for_user` / `_can_aa_access_activity`), y solo a trabajadores de **su** `area_id`. El **super_admin** sigue sin restricción de área en asignación.

#### 2. Comportamiento HTTP esperado

| Situación | Código | Cuerpo (ejemplo) |
|-----------|--------|------------------|
| Actividad no existe o el solicitante **no** tiene acceso (misma regla que GET detail) | **404** | `{ "detail": "No encontrado." }` (o equivalente DRF) |
| Actividad accesible pero `assigned_to` no pertenece al área del AA | **400** | `{ "assigned_to": "Solo puedes asignar actividades a miembros de tu área." }` |
| Asignación correcta | **200** | Actividad serializada (o el contrato actual del endpoint) |

**Importante:** rechazo por “TA de otra área” debe ser **400** en el campo `assigned_to`, **no 404**, para que el cliente muestre el mensaje correcto y no se confunda con “actividad inexistente”.

#### 3. Pruebas que deben pasar (mismo token JWT)

Reemplazar `{ACCESS}`, `{ACTIVITY_ID}`, `{TA_EN_MI_AREA}` por valores reales.

1. **Quién:** usuario con `role=admin_area` y `area_id` definido.  
2. `GET /api/auth/me/` → anotar `area_id`.  
3. `GET /api/activities/{ACTIVITY_ID}/` → debe ser **200** si el AA debe poder gestionar esa actividad.  
4. `POST /api/activities/{ACTIVITY_ID}/assign/`  
   - Header: `Authorization: Bearer {ACCESS}`  
   - Body JSON: `{ "assigned_to": "{TA_EN_MI_AREA}" }`  
   - Esperado: **200** (o el éxito que definan). Si aquí sale **404** pero el paso 3 fue **200**, la vista **assign** **no** está usando la misma resolución de actividad que **retrieve**.  
5. Opcional negativo: mismo AA, `assigned_to` = UUID de trabajador de **otra** área → **400** con `assigned_to` en el JSON, no 404.

#### 4. Checklist de implementación (código)

- [x] `AssignActivityView` obtiene la actividad con **`_get_activity_for_user`** — OK en repo.  
- [x] Validación **400** / campo **`assigned_to`** si el asignatario no es del área del AA — OK en repo.  
- [x] Una sola URL `.../assign/` — OK en `urls.py`.  
- [x] `GET /api/users/?role=trabajador` con token **AA** acota por `area_id` en servidor — OK en repo.  
- [x] **Deploy** al entorno que usa la app — verificado (assign **200** para AA en Sevalla).

#### 5. Qué hace el cliente Flutter (alineado)

- Lista: `GET /api/users/?role=trabajador` (el backend ya devuelve solo TA del área cuando el token es **AA**).  
- Filtro extra en cliente (`workersForAssignmentPicker`) para AA: opcional/redundante; se puede quitar después si se prefiere una sola fuente de verdad.  
- **400** con `assigned_to` → SnackBar con ese mensaje.

#### 6. Evidencia reciente (log app)

```
GET .../api/users/?role=trabajador → 200
POST .../api/activities/88b9f4cf-63d7-482b-b8bb-282906b623be/assign/
  body: { assigned_to: 46f3350a-d3e7-4830-a3eb-69e241358246 }
→ 404 { detail: No encontrado. }
```

Con **SA** el mismo tipo de `POST assign` **sí** funciona → refuerza que el fallo está en la rama **admin_area** de la vista de assign o en deploy incompleto.

---

### Checklist frontend (implementado en app)

1. **`workersListProvider`** → `GET /api/users/?role=trabajador` vía `TeamRepository.getWorkers()`.
2. **`workersForAssignmentPicker`:** SA ve todos los items de la respuesta; AA aplica además `areaId == currentUser.areaId` (redundante si el API ya filtra — se puede simplificar después del deploy).
3. **Detalle de actividad** y **pantalla Asignar** usan esa lista.
4. **`messageFromAssignApiError`:** en **400** prioriza el campo **`assigned_to`**.

---

## Credenciales de prueba actuales

| Usuario | Email | Password | Rol |
|---|---|---|---|
| Super Admin | admin@focus.com | Admin123! | super_admin |
| Invitado (ya creado) | nuevo@focus.com | Pass1234! | trabajador |
