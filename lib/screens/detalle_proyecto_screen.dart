import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../widgets/actividad_card.dart';
import '../utils/responsive.dart';
import 'detalle_actividad_screen.dart';

/// Pantalla de detalle de proyecto con sus actividades
class DetalleProyectoScreen extends StatefulWidget {
  final String proyectoId;

  const DetalleProyectoScreen({
    super.key,
    required this.proyectoId,
  });

  @override
  State<DetalleProyectoScreen> createState() => _DetalleProyectoScreenState();
}

class _DetalleProyectoScreenState extends State<DetalleProyectoScreen> {
  Proyecto? _proyecto;
  List<Actividad> _actividades = [];
  Map<String, Persona> _personas = {};
  EstadoActividad? _filtroEstado;
  bool _isLoading = true;
  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseService().database;
      final proyecto = await db.getProyectoPorId(widget.proyectoId);
      final actividades = await db.getActividadesPorProyecto(widget.proyectoId);
      final personas = await db.getAllPersonas();
      
      setState(() {
        _proyecto = proyecto;
        _actividades = actividades;
        _personas = {for (var p in personas) p.id: p};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<Actividad> get _actividadesFiltradas {
    if (_filtroEstado == null) return _actividades;
    return _actividades.where((a) => a.estado == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proyecto')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_proyecto == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proyecto')),
        body: const Center(child: Text('Proyecto no encontrado')),
      );
    }

    final isTablet = Responsive.isTablet(context);
    Color proyectoColor = Colors.blue;
    if (_proyecto!.color != null && _proyecto!.color!.isNotEmpty) {
      try {
        proyectoColor = Color(int.parse(_proyecto!.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        proyectoColor = Colors.blue;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_proyecto!.nombre),
        elevation: 0,
        backgroundColor: proyectoColor.withOpacity(0.1),
      ),
      body: Column(
        children: [
          // Información del proyecto
          Container(
            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
            color: proyectoColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text('${_actividades.length} actividades'),
                      avatar: const Icon(Icons.list, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${_actividades.where((a) => a.estado == EstadoActividad.completada).length} completadas',
                      ),
                      avatar: const Icon(Icons.check_circle, size: 18),
                    ),
                  ],
                ),
                if (_proyecto!.descripcion != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _proyecto!.descripcion!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Filtro por estado y botón crear
          Padding(
            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
            child: isTablet && MediaQuery.of(context).size.width > 700
                ? Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<EstadoActividad?>(
                          segments: [
                            const ButtonSegment<EstadoActividad?>(
                              value: null,
                              label: Text('Todas'),
                            ),
                            ...EstadoActividad.values
                                .where((e) => e != EstadoActividad.completada)
                                .map((estado) => ButtonSegment<EstadoActividad?>(
                                      value: estado,
                                      label: Text(estado.nombre),
                                    )),
                          ],
                          selected: {_filtroEstado},
                          onSelectionChanged: (Set<EstadoActividad?> newSelection) {
                            setState(() {
                              _filtroEstado = newSelection.first;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _mostrarDialogoCrearActividad(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: EstadoActividad.values
                                  .where((e) => e != EstadoActividad.completada)
                                  .length +
                              1,
                          itemBuilder: (context, index) {
                            EstadoActividad? estado;
                            if (index == 0) {
                              estado = null;
                            } else {
                              estado = EstadoActividad.values
                                  .where((e) => e != EstadoActividad.completada)
                                  .elementAt(index - 1);
                            }
                            final isSelected = estado == _filtroEstado;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                selected: isSelected,
                                label: Text(estado == null ? 'Todas' : estado.nombre),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _filtroEstado = estado;
                                    });
                                  }
                                },
                                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _mostrarDialogoCrearActividad(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva'),
                      ),
                    ],
                  ),
          ),
          
          // Lista de actividades
          Expanded(
            child: _actividadesFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay actividades',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: isTablet
                        ? GridView.builder(
                            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: Responsive.getColumnCount(context),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: _actividadesFiltradas.length,
                            itemBuilder: (context, index) {
                              final actividad = _actividadesFiltradas[index];
                              final persona = actividad.personaAsignadaId != null
                                  ? _personas[actividad.personaAsignadaId]
                                  : null;
                              
                              return ActividadCard(
                                actividad: actividad,
                                proyecto: _proyecto,
                                personaAsignada: persona,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetalleActividadScreen(
                                        actividadId: actividad.id,
                                      ),
                                    ),
                                  ).then((_) => _cargarDatos());
                                },
                                onComplete: () async {
                                  final db = DatabaseService().database;
                                  await db.actualizarActividad(
                                    actividad.copyWith(
                                      estado: EstadoActividad.completada,
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                                  _cargarDatos();
                                },
                                onMove: () {
                                  // TODO: Implementar mover
                                },
                                onLongPress: () {},
                              );
                            },
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                            itemCount: _actividadesFiltradas.length,
                            itemBuilder: (context, index) {
                              final actividad = _actividadesFiltradas[index];
                              final persona = actividad.personaAsignadaId != null
                                  ? _personas[actividad.personaAsignadaId]
                                  : null;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ActividadCard(
                                  actividad: actividad,
                                  proyecto: _proyecto,
                                  personaAsignada: persona,
                                  numeroActividadProyecto: index + 1,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetalleActividadScreen(
                                          actividadId: actividad.id,
                                        ),
                                      ),
                                    ).then((_) => _cargarDatos());
                                  },
                                  onComplete: () async {
                                    final db = DatabaseService().database;
                                    await db.actualizarActividad(
                                      actividad.copyWith(
                                        estado: EstadoActividad.completada,
                                        updatedAt: DateTime.now(),
                                      ),
                                    );
                                    _cargarDatos();
                                  },
                                  onMove: () {
                                    // TODO: Implementar mover
                                  },
                                  onLongPress: () {},
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoCrearActividad(BuildContext context) async {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    EstadoActividad estadoSeleccionado = EstadoActividad.bandeja;
    DateTime? fechaObjetivo;
    List<String> archivosAdjuntos = [];

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Variable local para el diálogo
          DateTime? fechaObjetivoDialog = fechaObjetivo;
          
          return AlertDialog(
          title: const Text('Nueva Actividad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: '¿Qué necesitas hacer?',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalles adicionales (opcional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Estado
                Text(
                  'Estado inicial',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildEstadoChip(
                      context,
                      setDialogState,
                      EstadoActividad.bandeja,
                      estadoSeleccionado,
                      (estado) => estadoSeleccionado = estado,
                    ),
                    _buildEstadoChip(
                      context,
                      setDialogState,
                      EstadoActividad.hoy,
                      estadoSeleccionado,
                      (estado) => estadoSeleccionado = estado,
                    ),
                    _buildEstadoChip(
                      context,
                      setDialogState,
                      EstadoActividad.manana,
                      estadoSeleccionado,
                      (estado) => estadoSeleccionado = estado,
                    ),
                    _buildEstadoChip(
                      context,
                      setDialogState,
                      EstadoActividad.programado,
                      estadoSeleccionado,
                      (estado) {
                        estadoSeleccionado = estado;
                      },
                    ),
                    _buildEstadoChip(
                      context,
                      setDialogState,
                      EstadoActividad.pendientes,
                      estadoSeleccionado,
                      (estado) => estadoSeleccionado = estado,
                    ),
                  ],
                ),
                // Fecha objetivo (si es Programado)
                if (estadoSeleccionado == EstadoActividad.programado) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Fecha objetivo *',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      fechaObjetivoDialog != null
                          ? '${fechaObjetivoDialog.day}/${fechaObjetivoDialog.month}/${fechaObjetivoDialog.year} ${fechaObjetivoDialog.hour.toString().padLeft(2, '0')}:${fechaObjetivoDialog.minute.toString().padLeft(2, '0')}'
                          : 'Seleccionar fecha y hora',
                    ),
                    trailing: fechaObjetivoDialog != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setDialogState(() {
                                fechaObjetivoDialog = null;
                                fechaObjetivo = null;
                              });
                            },
                          )
                        : null,
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: fechaObjetivoDialog ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (fecha != null) {
                        final hora = await showTimePicker(
                          context: context,
                          initialTime: fechaObjetivoDialog != null
                              ? TimeOfDay.fromDateTime(fechaObjetivoDialog!)
                              : TimeOfDay.now(),
                        );
                        if (hora != null) {
                          setDialogState(() {
                            fechaObjetivoDialog = DateTime(
                              fecha.year,
                              fecha.month,
                              fecha.day,
                              hora.hour,
                              hora.minute,
                            );
                            fechaObjetivo = fechaObjetivoDialog;
                          });
                        }
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Archivos
                Text(
                  'Archivos adjuntos',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ruta = await _fileService.seleccionarImagen();
                        if (ruta != null) {
                          setDialogState(() {
                            archivosAdjuntos.add(ruta);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Imagen'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ruta = await _fileService.seleccionarArchivo();
                        if (ruta != null) {
                          setDialogState(() {
                            archivosAdjuntos.add(ruta);
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Archivo'),
                    ),
                  ],
                ),
                if (archivosAdjuntos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...archivosAdjuntos.map((archivo) => Chip(
                        label: Text(archivo.split('/').last),
                        onDeleted: () {
                          setDialogState(() {
                            archivosAdjuntos.remove(archivo);
                          });
                        },
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (tituloController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
        },
      ),
    );

    if (resultado == true && tituloController.text.trim().isNotEmpty) {
      // Validar que Programado tenga fecha (fechaObjetivo se actualiza en el diálogo)
      if (estadoSeleccionado == EstadoActividad.programado && fechaObjetivo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Las actividades programadas requieren una fecha objetivo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      try {
        final db = DatabaseService().database;
        final ahora = DateTime.now();
        final nuevaActividadId = const Uuid().v4();

        // Copiar archivos al directorio de la actividad
        for (var archivo in archivosAdjuntos) {
          await _fileService.copiarArchivoAActividad(nuevaActividadId, archivo);
        }

        final nuevaActividad = Actividad(
          id: nuevaActividadId,
          titulo: tituloController.text.trim(),
          descripcion: descripcionController.text.trim().isEmpty
              ? null
              : descripcionController.text.trim(),
          estado: estadoSeleccionado,
          proyectoId: widget.proyectoId,
          fechaObjetivo: fechaObjetivo,
          createdAt: ahora,
          updatedAt: ahora,
          tieneAdjuntos: archivosAdjuntos.isNotEmpty,
          orden: 0,
        );

        await db.insertarActividad(nuevaActividad);

        // Registrar en bitácora
        final evento = BitacoraEvento(
          id: const Uuid().v4(),
          actividadId: nuevaActividadId,
          tipo: TipoEvento.create,
          descripcion: 'Actividad creada en proyecto ${_proyecto!.nombre}',
          timestamp: ahora,
          usuarioId: null,
        );
        await db.insertarEventoBitacora(evento);

        _cargarDatos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Actividad creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Widget _buildEstadoChip(
    BuildContext context,
    StateSetter setDialogState,
    EstadoActividad estado,
    EstadoActividad estadoSeleccionado,
    Function(EstadoActividad) onSelected,
  ) {
    final isSelected = estadoSeleccionado == estado;
    final color = _getEstadoColorChip(estado);
    
    return FilterChip(
      selected: isSelected,
      label: Text(estado.nombre),
      selectedColor: color,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        setDialogState(() {
          onSelected(estado);
        });
      },
    );
  }

  Color _getEstadoColorChip(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Colors.grey;
      case EstadoActividad.hoy:
        return Colors.blue;
      case EstadoActividad.manana:
        return Colors.orange;
      case EstadoActividad.programado:
        return Colors.purple;
      case EstadoActividad.pendientes:
        return Colors.red;
      case EstadoActividad.completada:
        return Colors.green;
    }
  }
}

