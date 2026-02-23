# 📱 HiperApp - Sistema de Hiperproductividad

> **Aplicación móvil Flutter + Backend FastAPI** para gestión de productividad personal y colaborativa en entornos de alta seguridad.

---

## 📑 Tabla de Contenidos

1. [Visión General](#-visión-general)
2. [Arquitectura del Backend](#-arquitectura-del-backend)
3. [Roles y Estancias](#-roles-y-estancias)
4. [Documentación del Proyecto](#-documentación-del-proyecto)
5. [Manual de Usuario](#-manual-de-usuario)
6. [Arquitectura Móvil](#-arquitectura-móvil)
7. [Correcciones QA Aplicadas](#-correcciones-qa-aplicadas)
8. [Errores QA Detallados](#-errores-qa-detallados)
9. [Instrucciones QA](#-instrucciones-qa)
10. [Flujos y Roles de Estancias](#-flujos-y-roles-de-estancias)
11. [Configuración de Firebase (SHA-1)](#-configuración-de-firebase-sha-1)
12. [Inicio Rápido](#-inicio-rápido)
13. [Control Documental GxP](#-control-documental-gxp)
    - [Marco de Referencia GxP](#marco-de-referencia-gxp)
    - [Registro Completo de Documentos](#registro-completo-de-documentos)
    - [Matriz de Trazabilidad](#matriz-de-trazabilidad-requisitos--diseño--qa)
    - [Criterios de Aceptación QA](#criterios-de-aceptación-qa-verificación-recurrente)
    - [Referencias Rápidas](#referencias-rápidas)
14. [Soporte](#-soporte)

---

## 🎯 Visión General

HiperApp es un sistema completo de gestión de productividad diseñado para **entornos de máxima seguridad y gubernamentales**. Combina:

- **App Móvil (Flutter/Dart)**: Interfaz intuitiva con soporte offline
- **Backend (Python/FastAPI)**: API RESTful robusta y segura
- **Seguridad de nivel gubernamental**: OWASP, ISO 27001, una sesión por dispositivo

### Características Principales

| Característica | Descripción |
|----------------|-------------|
| **Estancias** | Áreas de trabajo tipo "classroom" con propietarios y miembros |
| **Gestión de Tareas** | Estados: Bandeja, Hoy, Mañana, Programado, Pendientes |
| **Roles RBAC** | SUPER_ADMIN, ADMIN, PROPIETARIO, MIEMBRO, INVITADO |
| **Offline First** | SQLite local con sincronización inteligente |
| **Seguridad** | Biometría/PIN, tokens JWT, device fingerprint |
| **KPIs e IA** | Métricas de progreso y predicción de riesgos |

---

## 🏗️ Arquitectura del Backend

> **Documento fuente**: `BACKEND_ARCHITECTURE_BOCETO.md` (DOC-BE-001)

### Estructura por Capas

```
backend/
├── app/
│   ├── api/v1/              # Capa de Rutas (solo endpoints)
│   │   ├── auth_routes.py
│   │   ├── users_routes.py
│   │   ├── estancias_routes.py
│   │   ├── proyectos_routes.py
│   │   ├── tareas_routes.py
│   │   ├── documentos_routes.py
│   │   ├── retroalimentacion_routes.py
│   │   └── kpis_routes.py
│   │
│   ├── services/            # Capa de Lógica de Negocio
│   ├── repositories/        # Capa de Acceso a Datos
│   ├── schemas/             # Validación Pydantic
│   ├── database/models/     # Modelos ORM SQLAlchemy
│   ├── core/                # Configuración y Seguridad
│   └── middleware/          # Headers, Auditoría, Rate Limit
```

### Principio de Separación

| Capa | Responsabilidad | ❌ NO hacer |
|------|-----------------|-------------|
| **Rutas** | Declarar endpoints, delegar a servicios | Lógica de negocio |
| **Servicios** | Toda la lógica de negocio | Acceso directo a BD |
| **Repositorios** | Abstracción de acceso a datos | Lógica de negocio |
| **Schemas** | Validación entrada/salida | Lógica de negocio |

### Endpoints Principales

```
POST   /api/v1/auth/login          # Login con device_fingerprint
POST   /api/v1/auth/register       # Registro de usuario
POST   /api/v1/auth/refresh        # Renovar token
GET    /api/v1/users/me            # Usuario actual (incluye rol)
GET    /api/v1/estancias           # Listar estancias
POST   /api/v1/estancias/{id}/invitar
GET    /api/v1/kpis/estancia/{id}  # KPIs por estancia
GET    /api/v1/auditoria           # Solo SUPER_ADMIN
```

### Seguridad Implementada

- **Una sesión por dispositivo**: Token JWT con `jti` + `device_fingerprint`
- **Bitácora de auditoría**: Registro de todas las acciones (ISO 27001)
- **Headers de seguridad**: X-Frame-Options, CSP, HSTS, etc.
- **Rate limiting**: Protección contra DDoS/fuerza bruta
- **Validación OWASP**: Contraseñas de 12+ caracteres con complejidad

---

## 👥 Roles y Estancias

> **Documento fuente**: `BACKEND_ROLES_Y_ESTANCIAS.md` (DOC-BR-002)

### Tabla de Roles Globales

| ID | Rol | Nivel | Permisos Clave |
|----|-----|-------|----------------|
| 1 | **SUPER_ADMIN** | 100 | Todo: usuarios, auditoría, roles |
| 2 | **ADMIN** | 90 | KPIs, retroalimentación (sin auditoría) |
| 3 | **PROPIETARIO** | 70 | Crear/gestionar estancias |
| 4 | **MIEMBRO** | 50 | Bandeja propia, estancias como miembro |
| 5 | **INVITADO** | 20 | Solo lectura en estancias invitadas |

### Flujo de Acceso a Estancias

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   PROPIETARIO   │────▶│  Invita/Código   │────▶│    MIEMBRO      │
│  Crea estancia  │     │  o Solicitud     │     │  Acepta/Entra   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

### Cómo Asignar Roles (Solo BD)

```sql
-- Después de registrarse, cambiar rol en la base de datos:
UPDATE usuarios SET rol_id = 1 WHERE email = 'admin@ejemplo.com';  -- SUPER_ADMIN
UPDATE usuarios SET rol_id = 2 WHERE email = 'jefe@ejemplo.com';   -- ADMIN
UPDATE usuarios SET rol_id = 3 WHERE email = 'prof@ejemplo.com';   -- PROPIETARIO
```

> ⚠️ **Importante**: Después de cambiar el rol, cerrar sesión y volver a iniciar para que la app refleje los cambios.

---

## 📄 Documentación del Proyecto

> **Documento fuente**: `documentacion.md` (DOC-DOC-003)

### Estado del Proyecto

| Métrica | Valor |
|---------|-------|
| **Progreso** | 55% (11/20 tareas) |
| **Estado** | ✅ App funcional, lista para pruebas |
| **Responsividad** | Tablets soportadas |

### Dependencias Principales (Flutter)

```yaml
dependencies:
  drift: ^2.14.1              # Base de datos SQLite
  flutter_local_notifications: ^16.3.0
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.1.8          # Biometría/PIN
  dio: ^5.4.0                 # Cliente HTTP
  connectivity_plus: ^5.0.2   # Detección de conexión
```

### Modelos de Datos Locales

- **Actividad**: Tarea con estado (Bandeja, Hoy, Mañana, etc.)
- **Proyecto**: Contenedor transversal de actividades
- **Persona**: Colaboradores del equipo (local)
- **BitacoraEvento**: Historial de cambios
- **Configuracion**: Preferencias del usuario

---

## 📖 Manual de Usuario

> **Documento fuente**: `manual_usuario.md` (DOC-MAN-006)

### Navegación Principal

| Pestaña | Función |
|---------|---------|
| 📋 **Tablero** | Vista de actividades por estado |
| ➕ **Captura** | Crear nuevas actividades rápidamente |
| 📁 **Proyectos** | Gestión de proyectos |
| 📊 **Productividad** | Métricas y estadísticas |
| 👥 **Equipo** | Colaboradores y asignaciones |

### Estados de Actividades

```
📥 Bandeja      → Captura inicial, sin ejecutar
📅 Hoy          → Ejecución directa del día
⏰ Mañana       → Planificación próximo día
📆 Programado   → Fecha específica futura (requiere fecha)
⏳ Pendientes   → Bloqueadas por terceros
✅ Completada   → Finalizadas
```

### Gestos Rápidos

- **Deslizar izquierda**: Marcar como completada
- **Mantener presionado**: Mover a otro estado
- **Tocar**: Ver detalles completos

### Flujo de Trabajo Recomendado

1. **Captura Rápida**: Agregar actividades sin pensar mucho
2. **Revisión Diaria**: Cada mañana, mover de Bandeja a "Hoy"
3. **Organización**: Agrupar en Proyectos
4. **Asignación**: Delegar con función de Equipo
5. **Seguimiento**: Revisar Productividad regularmente

---

## 📱 Arquitectura Móvil

> **Documento fuente**: `MOBILE_ARCHITECTURE_INSTRUCCIONES.md` (DOC-MOB-005)

### Estructura de la App

```
hipperapp/lib/
├── core/
│   ├── config.dart              # Base URL, timeouts
│   └── security/
│       ├── secure_storage.dart  # Tokens, fingerprint
│       ├── device_fingerprint.dart
│       ├── local_auth.dart      # Biometría/PIN
│       ├── ssl_pinning.dart     # Certificate pinning
│       └── screen_protection.dart
│
├── data/
│   ├── api/                     # Clientes HTTP
│   │   ├── api_client.dart      # Interceptor Bearer + Fingerprint
│   │   ├── auth_api.dart
│   │   ├── estancias_api.dart
│   │   ├── proyectos_api.dart
│   │   └── tareas_api.dart
│   ├── local/                   # SQLite (Drift)
│   └── repositories/            # Orquestan API + local
│
├── services/                    # Lógica de negocio
│   ├── auth_service.dart
│   ├── sync_service.dart
│   └── inactivity_service.dart
│
└── screens/                     # Solo UI
    ├── auth/
    ├── home/
    ├── actividades/
    ├── estancias/
    ├── admin/                   # Solo ADMIN/SUPER_ADMIN
    └── super_admin/
```

### Seguridad Móvil (Crítica)

| Control | Implementación |
|---------|----------------|
| **Certificate Pinning** | SSL pinning contra MitM |
| **Jailbreak/Root Detection** | Bloqueo en dispositivos comprometidos |
| **Screen Protection** | FLAG_SECURE en pantallas sensibles |
| **Timeout Inactividad** | 5 min → pantalla de desbloqueo |
| **Device Fingerprint** | SHA-256 de datos del dispositivo |
| **Auditoría Local** | Logs sincronizados con backend |

### Flujo de Autenticación

```
┌─────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────┐
│  Login  │───▶│ Guardar JWT  │───▶│ Desbloqueo  │───▶│   Home   │
│ + FP    │    │ + Refresh    │    │ Biometría   │    │ por Rol  │
└─────────┘    └──────────────┘    └─────────────┘    └──────────┘
                                          │
                                          ▼
                                   Al salir/volver
                                   se pide de nuevo
```

### Sincronización Offline

1. **Sin conexión**: Guardar en cola local (SQLite)
2. **Al recuperar conexión**: Subir cola priorizada
3. **Estrategias de conflicto**:
   - **Server wins**: Datos críticos (roles, eliminaciones)
   - **Last write wins**: Tareas, proyectos
   - **User decides**: Conflictos en documentos

---

## ✅ Correcciones QA Aplicadas

> **Documento fuente**: `QA_CORRECCIONES_APLICADAS.md` (DOC-QA-007)

### Resumen de Correcciones

| Prioridad | Tema | Estado |
|-----------|------|--------|
| **P1** | Refresh token (401) | ✅ Resuelto |
| **P2** | SECRET_KEY en producción | ✅ Resuelto |
| **P3** | /health/detailed expuesto | ✅ Resuelto |
| **P4** | Navegación por rol | ✅ Cumplido |
| **P5** | Capa API móvil | ✅ Resuelto |
| **P6** | Endpoints tareas/proyectos | ✅ Resuelto |

### Detalles de Correcciones

#### P1: Refresh Token
- **Problema**: No existía `POST /auth/refresh`
- **Solución**: Backend genera `refresh_token` en login; app lo usa para renovar sin cerrar sesión

#### P2: SECRET_KEY
- **Problema**: Clave por defecto en producción
- **Solución**: Validador que exige SECRET_KEY segura en `ENVIRONMENT=production`

#### P3: Health Detallado
- **Problema**: Telemetría expuesta sin auth
- **Solución**: Requiere `X-Health-Key` en producción

#### P5: Capa API Móvil
- **Problema**: Faltaban clientes para estancias, invitaciones, proyectos, tareas
- **Solución**: Creados `estancias_api.dart`, `invitaciones_api.dart`, `proyectos_api.dart`, `tareas_api.dart`

---

## ⚠️ Errores QA Detallados

> **Documento fuente**: `QA_ERRORES_DETALLADOS.txt` (DOC-QA-008)

### Errores Identificados y Estado

| Error | Descripción | Estado |
|-------|-------------|--------|
| **1** | Rol de usuario en API | ✅ Resuelto (contrato), UI pendiente |
| **2** | POST /auth/refresh inexistente | ✅ Resuelto |
| **3** | Capa API móvil incompleta | ✅ Resuelto |
| **4** | Endpoints tareas/proyectos | ✅ Resuelto |
| **5** | Health detallado expuesto | ✅ Resuelto |
| **6** | SECRET_KEY por defecto | ✅ Resuelto |
| **7** | Navegación por rol | ✅ Resuelto |
| **8** | WebSocket sin eventos | ⏳ Parcial |
| **9** | Orden de rutas estancias | ✅ Correcto |
| **10** | Invitación por token | ✅ Revisado |
| **11** | Endpoints aceptar/rechazar | 📝 Recomendación |

### Tipos de Errores

- **Desconexión de contrato**: Backend no expone lo esperado
- **Funcionalidad faltante**: Capas no implementadas
- **Vulnerabilidad**: Riesgos de seguridad
- **Lógica no cumplida**: Requisitos de negocio

---

## 📋 Instrucciones QA

> **Documento fuente**: `QA_REPORT_INSTRUCCIONES.md` (DOC-QA-009)

### Checklist de Verificación

```
[ ] Login y registro envían device_fingerprint y reciben rol
[ ] Todas las peticiones llevan Authorization: Bearer + X-Device-Fingerprint
[ ] En 401, la app intenta refresh; si falla, cierra sesión
[ ] La app muestra/oculta Panel Admin según rol
[ ] Existen y funcionan: estancias_api, invitaciones_api, proyectos_api, tareas_api
[ ] /health/detailed no es accesible sin auth en producción
[ ] Producción no arranca con SECRET_KEY por defecto
[ ] WebSocket conecta con token y recibe eventos
```

### Recomendación: Unificar Endpoints de Acciones

**En lugar de**:
```
POST /solicitudes/{id}/aceptar
POST /solicitudes/{id}/rechazar
```

**Usar**:
```
PATCH /solicitudes/{id}
Body: { "accion": "aceptar" | "rechazar" | "on_hold" }
```

> Esto escala mejor si aparecen nuevas acciones.

---

## 🔄 Flujos y Roles de Estancias

> **Documento fuente**: `ROLES_ESTANCIAS_Y_FLUJOS.md` (DOC-ROL-010)

### Desbloqueo de la App

| Evento | Comportamiento |
|--------|----------------|
| Primera vez tras login | Pide biometría/PIN |
| Sales de la app y vuelves | Pide biometría/PIN de nuevo |
| Token válido | No pide login, solo desbloqueo |

### Flujo de Actividades

```
┌─────────┐    ┌─────────┐    ┌───────────┐    ┌───────────┐
│ Bandeja │───▶│   Hoy   │───▶│  Mañana   │───▶│Completada │
│ Captura │    │Ejecución│    │  Ajuste   │    │           │
└─────────┘    └─────────┘    └───────────┘    └───────────┘
                    │
                    ▼
              ┌───────────┐
              │Programado │ (requiere fecha)
              └───────────┘
```

### Rollover Automático del Día

El backend expone `POST /api/v1/tareas/rollover-dia`:
- Tareas en "Hoy" con fecha vencida → "Retrasada"
- Tareas en "Hoy" sin vencer → "Mañana"
- La app debe llamar al detectar cambio de día

---

## 🔑 Configuración de Firebase (SHA-1)

> **Documento fuente**: `SHA1_ENCONTRADO.md`

### Huellas Digitales para Debug

```
SHA-1:   B2:8E:2E:3F:02:0C:AB:F8:94:1E:5F:24:0A:6D:E7:60:81:25:DE:32
SHA-256: 2D:9A:90:A1:17:DD:BD:19:D3:9D:78:B3:0F:BB:17:9F:DC:CC:BD:84:DA:8A:39:2F:F6:18:0C:10:10:CA:4A:7E
```

### Keystore

| Atributo | Valor |
|----------|-------|
| **Ubicación** | `C:\Users\josep\.android\debug.keystore` |
| **Alias** | AndroidDebugKey |
| **Válido hasta** | May 14, 2055 |

### Pasos para Firebase Console

1. Ir a Firebase Console → Configuración del proyecto
2. En "Tus aplicaciones" → App Android
3. "Agregar huella digital" → Pegar SHA-1
4. Guardar y esperar 2-5 minutos
5. `flutter clean && flutter pub get && flutter run`

---

## 🚀 Inicio Rápido

### Requisitos

- Flutter 3.x
- Dart 3.x
- Python 3.11+
- PostgreSQL (backend)

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Configurar .env (copiar de .env.example)
# Ejecutar migraciones
alembic upgrade head

# Seed de roles
mysql -u root -p hiperapp_db < scripts/seed_roles.sql

# Iniciar servidor
uvicorn app.main:app --reload
```

### App Móvil

```bash
cd hipperapp
flutter pub get
flutter run
```

### Variables de Entorno (Backend)

```env
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/hiperapp_db
SECRET_KEY=tu-clave-super-segura-de-32-caracteres-minimo
ENVIRONMENT=development
HEALTH_DETAILED_KEY=tu-clave-para-health
```

---

## 📚 Control Documental GxP

> **Documento índice**: `00_INDICE_DOCUMENTACION_GXP.md` (DOC-INDICE-001)

### Marco de Referencia GxP

Este proyecto sigue el marco **GxP (Good Practice)** para asegurar:

| Principio | Descripción | Aplicación |
|-----------|-------------|------------|
| **Control Documental** | Versión, fecha efectiva, estado, responsable | Cada documento tiene cabecera GxP |
| **Trazabilidad** | Relación requisitos → diseño → implementación → pruebas | Matriz de trazabilidad en índice |
| **Auditoría** | Historial de cambios y referencias cruzadas | Bitácora en backend + logs locales |
| **Cumplimiento** | Alineación a OWASP, ISO 27001 | Verificación QA recurrente |

---

### Registro Completo de Documentos

| ID | Documento | Propósito | Versión | Próxima Revisión | Referencias Cruzadas |
|----|-----------|-----------|---------|------------------|----------------------|
| **DOC-INDICE-001** | `00_INDICE_DOCUMENTACION_GXP.md` | Índice maestro de control documental | 1.0 | 2026-08 | Todos los documentos |
| **DOC-BE-001** | `BACKEND_ARCHITECTURE_BOCETO.md` | Arquitectura backend: capas, endpoints, seguridad, modelo de datos | 3.0 | 2026-08 | MOB-005, BR-002, QA-009 |
| **DOC-BR-002** | `BACKEND_ROLES_Y_ESTANCIAS.md` | Roles globales, reglas de estancias (solicitudes, invitaciones, miembros) | 1.0 | 2026-08 | BE-001, ROL-010, MOB-005 |
| **DOC-DOC-003** | `documentacion.md` | Estado del proyecto móvil, modelos, BD local, reglas de negocio | 1.0 | 2026-05 | MOB-005, MAN-006 |
| **DOC-INS-004** | `Instrucciones.md` | Instrucciones generales (placeholder bajo control GxP) | 1.0 | 2026-08 | — |
| **DOC-MOB-005** | `MOBILE_ARCHITECTURE_INSTRUCCIONES.md` | Arquitectura móvil, seguridad, vinculación backend, flujos, checklist | 1.1 | 2026-08 | BE-001, BR-002, QA-009, ROL-010 |
| **DOC-MAN-006** | `manual_usuario.md` | Manual de usuario: funcionalidad, pantallas, privacidad | 1.0 | 2026-05 | DOC-003, MOB-005 |
| **DOC-QA-007** | `QA_CORRECCIONES_APLICADAS.md` | Resumen de correcciones QA aplicadas | 1.0 | 2026-05 | QA-009, QA-008 |
| **DOC-QA-008** | `QA_ERRORES_DETALLADOS.txt` | Detalle técnico de cada error/recomendación | 1.0 | 2026-05 | QA-009, QA-007 |
| **DOC-QA-009** | `QA_REPORT_INSTRUCCIONES.md` | Instrucciones de resolución para cada punto QA | 1.0 | 2026-05 | QA-008, MOB-005, BE-001 |
| **DOC-ROL-010** | `ROLES_ESTANCIAS_Y_FLUJOS.md` | Roles, desbloqueo, vinculación usuarios-estancias, flujo Hoy/Mañana | 1.0 | 2026-05 | BR-002, MOB-005, DOC-003 |

---

### Matriz de Trazabilidad (Requisitos → Diseño → QA)

| Necesidad / Requisito | Documento(s) de Diseño | Documento(s) de Verificación |
|------------------------|------------------------|------------------------------|
| Backend seguro (una sesión por dispositivo, bitácora, roles) | `BACKEND_ARCHITECTURE_BOCETO.md`, `BACKEND_ROLES_Y_ESTANCIAS.md` | `QA_REPORT_INSTRUCCIONES.md`, `QA_ERRORES_DETALLADOS.txt`, `QA_CORRECCIONES_APLICADAS.md` |
| App móvil segura (fingerprint, tokens, biometría, capas) | `MOBILE_ARCHITECTURE_INSTRUCCIONES.md` | `QA_REPORT_INSTRUCCIONES.md`, `QA_ERRORES_DETALLADOS.txt` |
| Roles y permisos (SUPER_ADMIN a INVITADO) | `BACKEND_ROLES_Y_ESTANCIAS.md`, `ROLES_ESTANCIAS_Y_FLUJOS.md` | `QA_REPORT_INSTRUCCIONES.md` (§1, §7), `MOBILE_ARCHITECTURE` |
| Estancias, solicitudes, invitaciones | `BACKEND_ARCHITECTURE_BOCETO.md`, `BACKEND_ROLES_Y_ESTANCIAS.md`, `MOBILE_ARCHITECTURE` | `QA_REPORT_INSTRUCCIONES.md` (§3, §11), `QA_CORRECCIONES_APLICADAS.md` |
| Usuario final (funcionalidad, pantallas, privacidad) | `documentacion.md`, `manual_usuario.md` | Manual como referencia para UAT; documentacion para estado de implementación |

---

### Criterios de Aceptación QA (Verificación Recurrente)

| # | Criterio | Dónde Verificar | Referencia |
|---|----------|-----------------|------------|
| 1 | Todas las peticiones autenticadas llevan `Authorization: Bearer` y `X-Device-Fingerprint` | `api_client.dart` (app), `dependencies.py` (backend) | MOB-005, BE-001 |
| 2 | En producción no se usa `SECRET_KEY` por defecto; arranque falla si es así | `backend/app/core/config.py` | QA-009 §6, QA-007 |
| 3 | `/health/detailed` en producción exige clave o auth | `backend/app/main.py` | QA-009 §5 |
| 4 | Login devuelve `user.rol`; app guarda rol y condiciona navegación | `auth_service.py`, `auth_repository.dart`, `main_navigation.dart` | QA-009 §1, §7; ROL-010 |
| 5 | Refresh token: backend expone `POST /auth/refresh`; app lo usa en 401 | `auth_routes.py`, `api_client.dart` | QA-009 §2, QA-007 |
| 6 | Capa API móvil: estancias, invitaciones, proyectos, tareas consumen backend | `*_api.dart` en `lib/data/api/` | QA-009 §3, QA-007 |
| 7 | Bitácora/auditoría: acciones críticas registradas | `bitacora_repository.py`, audit middleware | BE-001 |
| 8 | Sin URLs/claves en claro en código; variables de entorno en producción | `config.py`, `config.dart` | MOB-005, BE-001 |

---

### Historial de Cambios del Índice

| Versión | Fecha | Descripción | Autor |
|---------|-------|-------------|-------|
| 1.0 | 2026-02-05 | Creación del índice GxP; registro de todos los documentos; trazabilidad y criterios QA | QA |

---

### Referencias Rápidas

| Recurso | Ubicación |
|---------|-----------|
| **Backend API Base** | `http(s)://<host>/api/v1` |
| **Autenticación** | Bearer token + header `X-Device-Fingerprint` |
| **Documentación API** | Swagger: `/docs` • ReDoc: `/redoc` |
| **Roles Disponibles** | SUPER_ADMIN, ADMIN, PROPIETARIO, MIEMBRO, INVITADO |
| **Carpeta de Documentos** | `/Markdown/` |

---

### Convenciones de Versionado

- **Versión doc**: La indicada en la cabecera de cada archivo Markdown
- **Próxima revisión**: Revisión programada (cada 6 meses o tras cambio mayor)
- **Estado**: Vigente, Borrador, Obsoleto, Reservado
- **Cambios sustanciales**: Deben reflejarse en la versión y en el historial del documento afectado

---

## 📞 Soporte

Para reportar problemas o sugerencias:

1. **Revisar documentación**: Este README y los archivos en `/Markdown`
2. **Verificar versión**: Asegurar que se usa la última versión de la app
3. **Documentar el problema**: Incluir capturas de pantalla si es posible
4. **Consultar índice GxP**: `00_INDICE_DOCUMENTACION_GXP.md` para referencias cruzadas

### Contacto

- **Desarrollo Backend**: Consultar `BACKEND_ARCHITECTURE_BOCETO.md`
- **Desarrollo Móvil**: Consultar `MOBILE_ARCHITECTURE_INSTRUCCIONES.md`
- **QA/Testing**: Consultar `QA_REPORT_INSTRUCCIONES.md`

---

**HiperApp** - Sistema de Hiperproductividad  
© 2025-2026 - Todos los derechos reservados

| Atributo | Valor |
|----------|-------|
| **Versión README** | 2.0 |
| **Última actualización** | Febrero 2026 |
| **Marco de referencia** | GxP (Good Practice) |
| **Estándares de seguridad** | OWASP, ISO 27001 |
