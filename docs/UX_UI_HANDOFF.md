# Handoff UX/UI (Hipperapp)

Documento para portar la capa visual a otra rama con otros datos/modelos manteniendo la misma interfaz.

## Contratos

- **Color de proyecto:** guardar `#RRGGBB` desde la paleta light al crear proyecto. En runtime usar `PaletaPasteles.proyectoColorByMode(hex, brightness)` para chips/badges en light y dark.
- **Estados de actividad:** `EstadoActividadColors.forEstado(estado, brightness: Theme.of(context).brightness)` (no colores fijos sin modo).
- **SnackBars:** `AppSnackBar.exito` / `.error` / `.aviso` / `.info` (duración fija para que no queden colgados).

## Archivos a traer (o fusionar)

| Área | Ruta |
|------|------|
| Tema | `lib/utils/app_theme.dart` |
| Paleta y helpers | `lib/utils/paleta_pasteles.dart` |
| Colores por estado | `lib/utils/estado_actividad_colors.dart` |
| SnackBars | `lib/utils/app_snackbar.dart` |
| Cards / listas | `lib/widgets/actividad_card.dart` |
| Mover actividad | `lib/widgets/mover_actividad_bottom_sheet.dart` |
| Entrada app | `lib/main.dart` (`theme` / `darkTheme` / `themeMode`) |

## Pantallas con ajustes puntuales

`captura_screen`, `tablero_screen`, `productividad_screen`, `proyectos_lista_screen`, `detalle_proyecto_screen`, `detalle_actividad_screen`, `equipo_screen`, `historial_screen`, `main_navigation`.

Tras cambiar modelos: revisar imports, `brightness` en colores de estado/proyecto, y reemplazar `SnackBar(...)` sueltos por `AppSnackBar.*`.

## Checklist de verificación

1. Cambiar tema claro/oscuro: superficies, cards, inputs legibles.
2. Listas: chip de proyecto y badge de estado coherentes en ambos modos.
3. Captura y validaciones: snackbars con estilo unificado.
4. Productividad / proyectos / equipo: diálogos y métricas legibles; modal de equipo se cierra bien.
5. Slidable / acciones: contraste en light (foreground claro donde aplica).
