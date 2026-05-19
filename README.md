# HiperApp (Focus) - README

Aplicación Flutter para gestión de productividad personal y por equipos, con roles organizacionales y conexión a backend REST.

## Tabla de contenido

- Descripción general
- Stack y lenguajes
- Estructura del proyecto
- Configuración y variables de entorno
- Comandos de ejecución y desarrollo
- Rutas de la app (GoRouter)
- Endpoints REST y repositorios
- Reglas de negocio por rol
- Productividad / Stats (definiciones actuales)
- Flujo de invitaciones (áreas + alta de usuarios)
- Cambios aplicados recientemente
- Migraciones backend (Django) recomendadas
- Estado backend y pendientes
- Credenciales de prueba

## Descripción general

HiperApp implementa:

- Autenticación JWT, biometría y onboarding.
- Gestión de actividades (crear, mover, completar, asignar, adjuntos, logs).
- Proyectos personales y de equipo (por área).
- Productividad por rol (personal, equipo, rendimiento por trabajadores/áreas).
- Gestión de equipo (SA/AA/TA) e invitaciones con código.

Frontend: Flutter + Riverpod + GoRouter.  
Backend esperado: API REST (actualmente en Sevalla).

## Stack y lenguajes

- Lenguaje principal: `Dart`
- Framework: `Flutter`
- Estado: `flutter_riverpod`
- Navegación: `go_router`
- HTTP: `dio`
- Entorno: `flutter_dotenv`
- Almacenamiento:
  - `flutter_secure_storage` (tokens)
  - `shared_preferences` (flags/tema)
- UI extra: `google_fonts`, `flutter_slidable`
- Archivos/media: `file_picker`, `image_picker`, `video_player`, `audioplayers`, `share_plus`
- Notificaciones locales: `flutter_local_notifications`, `timezone`
- Legacy/local DB (en transición): `sqflite`

Dependencias completas en `pubspec.yaml`.

## Estructura del proyecto

Estructura principal:

- `lib/main.dart`: bootstrap de la app.
- `lib/core/`
  - `api/`: cliente HTTP, interceptores, endpoints.
  - `router/`: rutas y guards.
  - `storage/`: persistencia local segura/preferencias.
  - `theme/`: tema light/dark.
  - `utils/`: reglas de filtrado/alcance de actividades y proyectos.
  - `widgets/`: shell y componentes compartidos.
- `lib/features/`
  - `auth/`: login, registro, onboarding, invitaciones, biometría.
  - `dashboard/`: tablero y detalle de actividad.
  - `capture/`: creación rápida de actividades.
  - `projects/`: listado y detalle de proyectos.
  - `stats/`: productividad personal/equipo.
  - `team/`: equipo, invitaciones, asignación.
  - `profile/`: perfil y seguridad.
- `lib/shared/`
  - `models/`: `UserModel`, `ActivityModel`, `ProjectModel`.
  - `enums/`: `UserRole`, `ActivityStatus`.
- `docs/`
  - `BACKEND_PENDIENTES.md`
  - `ROLES_VISIBILIDAD_Y_BACKEND.md`
  - `AREAS_AND_INVITE_FLOW.md`

## Configuración y variables de entorno

Archivo usado por la app:

- `app.env`

Variables actuales:

- `API_BASE_URL=https://focus-backend-u211p.sevalla.app`

También existe `.env` con la misma clave como respaldo local.

## Comandos de ejecución y desarrollo

En raíz del proyecto (`hipperapp`):

```bash
flutter pub get
flutter run
```

Análisis estático:

```bash
dart analyze
```

Formato:

```bash
dart format .
```

Tests (si aplica):

```bash
flutter test
```

Build APK debug/release:

```bash
flutter build apk --debug
flutter build apk --release
```

Generación de código (Riverpod generator / build_runner):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Rutas de la app (GoRouter)

Definidas en `lib/core/router/app_router.dart`.

Rutas principales:

- `/splash`
- `/loading`
- `/login`
- `/register`
- `/onboarding`
- `/biometric`
- `/join` (flujo de código manual)
- `/invite/:token` (deep link de invitación)

Shell principal (`MainShell`) con:

- `/` (dashboard)
  - `/activity/:id`
- `/capture`
- `/historial`
- `/projects`
  - `/projects/:id`
- `/stats`
- `/team`
  - `/team/assign/:activityId`
- `/profile`
  - `/profile/security`

Reglas de redirección:

- Si auth está cargando: se mantiene splash/loading.
- Invitación (`/join`, `/invite/:token`) se permite sin auth.
- Si no autenticado: solo login/register/splash.
- Si autenticado: respeta onboarding antes de entrar al home.

## Endpoints REST y repositorios

### Endpoints (`lib/core/api/api_endpoints.dart`)

Auth:

- `POST /api/auth/login/`
- `POST /api/auth/logout/`
- `POST /api/auth/refresh/`
- `GET /api/auth/me/`
- `POST /api/auth/biometric/enable/`
- `POST /api/auth/biometric/disable/`
- `POST /api/auth/biometric/login/`
- `POST /api/auth/onboarding/complete/`

Users / Invite:

- `GET /api/users/`
- `POST /api/users/invite/`
- `GET /api/users/invite/verify/`
- `POST /api/users/accept-invite/`
- `GET/PATCH /api/users/{id}/`

Areas:

- `GET/POST /api/areas/`
- `GET /api/areas/{id}/`
- `GET /api/areas/{id}/members/`

Activities:

- `GET/POST /api/activities/`
- `GET/PATCH/DELETE /api/activities/{id}/`
- `POST /api/activities/{id}/move/`
- `POST /api/activities/{id}/complete/`
- `POST /api/activities/{id}/assign/`
- `GET /api/activities/{id}/logs/`
- `GET/POST /api/activities/{id}/attachments/`
- `DELETE /api/activities/{id}/attachments/{attId}/`

Projects:

- `GET/POST /api/projects/`
- `GET/PATCH/DELETE /api/projects/{id}/`
- `GET /api/projects/{id}/activities/`
- `GET /api/projects/{id}/progress/`

Stats:

- `GET /api/stats/personal/`
- `GET /api/stats/global/`
- `GET /api/stats/workers/`
- `GET /api/stats/drilldown/`
- `GET /api/stats/area/{areaId}/`

### Repositorios principales

- `AuthRepository`
  - `login`, `logout`, `getMe`, `verifyInviteCode`, `acceptInvitation`, biometría.
- `ActivityRepository`
  - `getActivities`, `getActivity`, `createActivity`, `updateActivity`, `moveActivity`, `completeActivity`, `assignActivity`, `unassignActivity`, adjuntos/logs.
- `ProjectRepository`
  - `getProjects`, `getProject`, `getProjectActivities`, `getProjectProgress`, `createProject`, `updateProject`, `deleteProject`.
- `TeamRepository`
  - `getTeamMembers`, `getWorkers`, `getAreaAdmins`, `getAreaMembers`, `getAreas`, `createArea`, `generateInvite`, `updateUser`.
- `StatsRepository`
  - `getPersonalStats`, `getMyStats`, `getAreaStats`, `getDrilldown`, `getWorkerStats`, `getAllAreasStats`.

## Reglas de negocio por rol

Referencia funcional detallada: `docs/ROLES_VISIBILIDAD_Y_BACKEND.md`.

Roles:

- `superAdmin`
- `adminArea`
- `trabajador`
- `personal`

Resumen:

- SA: visibilidad global organizacional y comparación por áreas.
- AA: visión personal + equipo de su área; puede invitar TA.
- TA: visión personal + equipo (según reglas de área/asignación).
- personal: experiencia solo personal, sin bloques de organización.

## Productividad / Stats (definiciones actuales)

Archivo principal: `lib/features/stats/screens/stats_screen.dart`.

### Lógica actual importante

- Separación personal/equipo mediante:
  - `personalActivitiesForStats(...)`
  - `teamActivitiesForStats(...)`
  en `lib/core/utils/activity_scope.dart`.
- Cálculo de `%` robusto para barras de rendimiento:
  - usa `completed/total` cuando hay datos;
  - fallback a `completion_rate`, tolerando formatos `0..1` o `0..100`.
- Normalización de campos backend para stats:
  - `overdue`, `overdue_count`, etc.
  - `by_user` con fallback a `results/users`.
- En distribución de actividades:
  - las completadas se reatribuyen a su bucket lógico (Hoy/Mañana/Programado/Pendientes/Bandeja) para no perder señal en “Hoy”.

## Flujo de invitaciones (áreas + alta de usuarios)

Referencia funcional detallada: `docs/AREAS_AND_INVITE_FLOW.md`.

Contrato esperado:

1. SA/AA genera invitación: `POST /api/users/invite/`
2. Invitado valida código: `GET /api/users/invite/verify/?code=...`
3. Invitado acepta invitación: `POST /api/users/accept-invite/` con `code`

Campos clave:

- `code` (código corto)
- `role`
- `area_id` / `area_name`
- `expires_at`

## Cambios aplicados recientemente

### Frontend (este repositorio)

- Stats:
  - robustecimiento de parsing de `completion_rate` y métricas nulas.
  - normalización de `overdue` para evitar mostrar `null`.
  - barra de progreso con clamp `0..1`.
  - separación reforzada personal vs equipo en filtros de stats.
  - mejora de distribución para que “Hoy” refleje actividades completadas del flujo.
- Proyectos/parseo:
  - parsing más robusto para `area` y `created_by`.
- Startup animation:
  - fix de crash por `Padding` negativo en `startup_animation_screen.dart` (`rowLeft` clamped a `>= 0`).
- UI:
  - retiro de opción “Agregar nota” en detalle de actividad (según ajuste solicitado).

### Backend (estado documentado y validado por pruebas)

Ver `docs/BACKEND_PENDIENTES.md` para historial completo de incidentes y estado por endpoint.

## Migraciones backend (Django) recomendadas

Este repositorio es frontend; las migraciones se aplican en el repositorio backend.  
Se deja checklist para alinear contrato con la app:

1. Invitaciones:
   - asegurar campo `code` (único, corto) en modelo de invitación;
   - exponer `code` en respuesta de `POST /users/invite/`;
   - permitir `accept-invite` con `code` (y opcional fallback `token`).
2. Actividades:
   - coherencia de permisos entre list/retrieve/assign;
   - evitar casos `POST 201` seguido de `GET detail 404` para el mismo actor autorizado.
3. Asignación AA:
   - validar `assigned_to` dentro de su área;
   - responder `400` con mensaje de campo (`assigned_to`) cuando aplique.
4. Proyectos:
   - serializar/persistir consistentemente `area`, `area_name`, `area_admin_name`, `created_by`.
5. Stats:
   - consistencia de llaves en drilldown (`by_user`, `by_area`, `completion_rate`, `total`, `completed`, `overdue`).

Comandos típicos en backend Django (referencia):

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py showmigrations
python manage.py createsuperuser
python manage.py runserver
```

## Estado backend y pendientes

Documento fuente: `docs/BACKEND_PENDIENTES.md`.

Incluye:

- matriz de endpoints y estado;
- incidentes históricos (timeouts, 404 post-create, assign 404 AA, etc.);
- clasificación Front vs Back;
- acciones requeridas en servidor;
- evidencia de logs y verificación en producción.

## Credenciales de prueba

Según `docs/BACKEND_PENDIENTES.md`:

- Super Admin:
  - email: `admin@focus.com`
  - password: `Admin123!`
- Invitado creado:
  - email: `nuevo@focus.com`
  - password: `Pass1234!`

## Referencias rápidas

- Arquitectura de roles y visibilidad:
  - `docs/ROLES_VISIBILIDAD_Y_BACKEND.md`
- Flujo áreas + invitaciones:
  - `docs/AREAS_AND_INVITE_FLOW.md`
- Pendientes/incidentes backend:
  - `docs/BACKEND_PENDIENTES.md`

---

README consolidado para uso en GitHub.  
Si quieres, en el siguiente paso te lo puedo dividir en badges + tabla de features + roadmap para que quede más “open-source style”.
