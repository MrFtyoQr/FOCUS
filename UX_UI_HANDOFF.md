# Handoff UX/UI (Hipperapp)

Documento para portar la capa visual a otra rama con otros datos/modelos manteniendo la misma interfaz.

## Contratos

- **Color de proyecto:** guardar `#RRGGBB` desde la paleta light al crear proyecto. En runtime usar `PaletaPasteles.proyectoColorByMode(hex, brightness)` para chips/badges en light y dark.
- **Estados de actividad:** `ActivityStatusColors.forStatus(estado, brightness: Theme.of(context).brightness)` (no colores fijos sin modo).
- **SnackBars:** `AppSnackBar.exito` / `.error` / `.aviso` / `.info` (duración fija para que no queden colgados).
- **Tema:** `main.dart` aplica `themeModeProvider` con override leído en arranque desde `LocalPrefs.getThemeMode()` (sin esperar al primer frame). Primera instalación sin prefs → modo oscuro por defecto.
- **Pendiente global (recordatorio):** al cerrar el ciclo de pantallas, unificar criterio **tema del dispositivo** para toda la app: preferir `ThemeMode.system` como opción por defecto o asegurar que cada pantalla use `Theme.of(context)` / `colorScheme` y no colores fijos; revisar auth y estados vacíos.

## Archivos (estructura actual HiperApp)

| Área | Ruta |
|------|------|
| Tema claro/oscuro | `lib/core/theme/app_theme.dart` |
| Modo de tema + prefs | `lib/core/theme/theme_mode_provider.dart`, `LocalPrefs.getThemeMode` |
| Paleta proyectos | `lib/core/utils/paleta_pasteles.dart` |
| Colores por estado | `lib/core/utils/activity_status_colors.dart` |
| SnackBars | `lib/core/utils/app_snackbar.dart` |
| Tarjeta actividad / badge | `lib/core/widgets/activity_card.dart`, `status_badge.dart` |
| Shell | `lib/core/widgets/main_shell.dart` |
| Entrada app | `lib/main.dart` (`theme`, `darkTheme`, `themeMode`) |

## Pantallas con ajustes puntuales

`capture_screen`, `dashboard_screen` (tablero), `stats_screen`, `projects_screen`, `project_detail_screen`, `activity_detail_screen`, `team_screen`, `profile_screen` (apariencia).

### Captura con adjuntos

- UI: card «Archivos adjuntos», botones Imagen / Archivo, chips con `onDeleted` (igual referencia legacy).
- Flujo: `CaptureNotifier.capture` crea la actividad y luego `ActivityRepository.uploadAttachment` por cada ruta. Fallos de subida no cancelan la actividad: se devuelve `CaptureOutcome.failedFiles` y se muestra `AppSnackBar.aviso`.

Tras cambiar modelos: revisar imports, `brightness` en colores de estado/proyecto, y reemplazar `SnackBar(...)` sueltos por `AppSnackBar.*`.

## Checklist de verificación

1. Cambiar tema claro/oscuro: superficies, cards, inputs legibles.
2. Listas: chip de proyecto y badge de estado coherentes en ambos modos.
3. Captura y validaciones: snackbars con estilo unificado.
4. Productividad / proyectos / equipo: diálogos y métricas legibles; modal de equipo se cierra bien.
5. Slidable / acciones: contraste en light (foreground claro donde aplica).
