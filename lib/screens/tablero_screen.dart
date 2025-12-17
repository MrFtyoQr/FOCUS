import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/actividad_card.dart';
import '../widgets/mover_actividad_bottom_sheet.dart';
import '../utils/responsive.dart';
import 'detalle_actividad_screen.dart';

/// Pantalla principal del Tablero con segmented control
/// Implementa el modelo mental: Bandeja, Hoy, Mañana, Programado, Pendientes
class TableroScreen extends StatefulWidget {
  const TableroScreen({super.key});

  @override
  State<TableroScreen> createState() => _TableroScreenState();
}

class _TableroScreenState extends State<TableroScreen> {
  EstadoActividad _estadoSeleccionado = EstadoActividad.bandeja;
  List<Actividad> _actividades = [];
  bool _isLoading = true;
  Map<String, Proyecto> _proyectos = {};
  Map<String, Persona> _personas = {};

  final List<EstadoActividad> _estados = [
    EstadoActividad.bandeja,
    EstadoActividad.hoy,
    EstadoActividad.manana,
    EstadoActividad.programado,
    EstadoActividad.pendientes,
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar cuando la pantalla vuelve a ser visible
    // Esto asegura que se vean las actividades recién creadas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cargarDatos();
      }
    });
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseService().database;

      // Cargar actividades del estado seleccionado
      // REGLA: Una actividad solo vive en un estado
      final actividades = await db.getActividadesPorEstado(_estadoSeleccionado);

      // Cargar proyectos y personas para mostrar en las tarjetas
      // REGLA: Proyectos son contenedores transversales, las tareas viven en los estados
      final proyectos = await db.getAllProyectos();
      final personas = await db.getAllPersonas();

      setState(() {
        _actividades = actividades;
        _proyectos = {for (var p in proyectos) p.id: p};
        _personas = {for (var p in personas) p.id: p};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar actividades: $e')),
        );
      }
    }
  }

  void _onEstadoChanged(EstadoActividad nuevoEstado) {
    setState(() {
      _estadoSeleccionado = nuevoEstado;
    });
    _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tablero'), elevation: 0),
      body: Column(
        children: [
          // Segmented Control - Estados del método
          Padding(
            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
            child: SegmentedButton<EstadoActividad>(
              segments: _estados.map((estado) {
                return ButtonSegment<EstadoActividad>(
                  value: estado,
                  label: Text(estado.nombre),
                );
              }).toList(),
              selected: {_estadoSeleccionado},
              onSelectionChanged: (Set<EstadoActividad> newSelection) {
                _onEstadoChanged(newSelection.first);
              },
            ),
          ),
          // Lista de actividades con AnimatedSwitcher
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildListaActividades(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaActividades() {
    if (_isLoading) {
      return Center(
        key: ValueKey('loading_${_estadoSeleccionado.name}'),
        child: const CircularProgressIndicator(),
      );
    }

    if (_actividades.isEmpty) {
      return Center(
        key: ValueKey('empty_${_estadoSeleccionado.name}'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEstadoIcon(_estadoSeleccionado),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay actividades en ${_estadoSeleccionado.nombre}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _estadoSeleccionado.descripcion,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final isTablet = Responsive.isTablet(context);
    final columnCount = Responsive.getColumnCount(context);

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: isTablet
          ? GridView.builder(
              key: ValueKey('grid_${_estadoSeleccionado.name}'),
              padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _actividades.length,
              itemBuilder: (context, index) {
                final actividad = _actividades[index];
                final proyecto = actividad.proyectoId != null
                    ? _proyectos[actividad.proyectoId]
                    : null;
                final persona = actividad.personaAsignadaId != null
                    ? _personas[actividad.personaAsignadaId]
                    : null;

                return ActividadCard(
                  actividad: actividad,
                  proyecto: proyecto,
                  personaAsignada: persona,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetalleActividadScreen(actividadId: actividad.id),
                      ),
                    ).then((_) => _cargarDatos());
                  },
                  onComplete: () => _completarActividad(actividad),
                  onMove: () => _mostrarMoverActividad(actividad),
                  onLongPress: () {
                    // TODO: Selección múltiple
                  },
                );
              },
            )
          : ListView.builder(
              key: ValueKey('list_${_estadoSeleccionado.name}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _actividades.length,
              itemBuilder: (context, index) {
                final actividad = _actividades[index];
                final proyecto = actividad.proyectoId != null
                    ? _proyectos[actividad.proyectoId]
                    : null;
                final persona = actividad.personaAsignadaId != null
                    ? _personas[actividad.personaAsignadaId]
                    : null;

                return ActividadCard(
                  actividad: actividad,
                  proyecto: proyecto,
                  personaAsignada: persona,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetalleActividadScreen(actividadId: actividad.id),
                      ),
                    ).then((_) => _cargarDatos());
                  },
                  onComplete: () => _completarActividad(actividad),
                  onMove: () => _mostrarMoverActividad(actividad),
                  onLongPress: () {
                    // TODO: Selección múltiple
                  },
                );
              },
            ),
    );
  }

  Future<void> _completarActividad(Actividad actividad) async {
    try {
      final db = DatabaseService().database;
      final actividadCompletada = actividad.copyWith(
        estado: EstadoActividad.completada,
        updatedAt: DateTime.now(),
      );

      // REGLA: Mover ≠ duplicar - actualizamos el estado, no creamos nueva
      await db.actualizarActividad(actividadCompletada);

      // TODO: Registrar en bitácora (TipoEvento.complete)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${actividad.titulo} completada'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () async {
                await db.actualizarActividad(actividad);
                _cargarDatos();
              },
            ),
          ),
        );
      }

      _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _mostrarMoverActividad(Actividad actividad) {
    mostrarMoverActividadBottomSheet(
      context,
      actividad,
      (nuevoEstado) => _moverActividad(actividad, nuevoEstado),
    );
  }

  Future<void> _moverActividad(
    Actividad actividad,
    EstadoActividad nuevoEstado,
  ) async {
    try {
      final db = DatabaseService().database;

      // REGLA: Programado siempre requiere fecha
      if (nuevoEstado == EstadoActividad.programado &&
          actividad.fechaObjetivo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Las actividades programadas requieren una fecha objetivo',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final estadoAnterior = actividad.estado;
      final actividadMovida = actividad.copyWith(
        estado: nuevoEstado,
        updatedAt: DateTime.now(),
      );

      // REGLA: Mover ≠ duplicar - actualizamos el estado, no creamos nueva
      await db.actualizarActividad(actividadMovida);

      // TODO: Registrar en bitácora (TipoEvento.move)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Movida a ${nuevoEstado.nombre}'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () async {
                final actividadRestaurada = actividadMovida.copyWith(
                  estado: estadoAnterior,
                  updatedAt: DateTime.now(),
                );
                await db.actualizarActividad(actividadRestaurada);
                _cargarDatos();
              },
            ),
          ),
        );
      }

      _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al mover: $e')));
      }
    }
  }

  IconData _getEstadoIcon(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Icons.inbox_outlined;
      case EstadoActividad.hoy:
        return Icons.today;
      case EstadoActividad.manana:
        return Icons.event;
      case EstadoActividad.programado:
        return Icons.calendar_today;
      case EstadoActividad.pendientes:
        return Icons.pause_circle_outline;
      case EstadoActividad.completada:
        return Icons.check_circle_outline;
    }
  }
}
