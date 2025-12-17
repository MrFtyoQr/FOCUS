import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/mover_actividad_bottom_sheet.dart';
import '../utils/responsive.dart';

/// Pantalla de detalle de actividad
class DetalleActividadScreen extends StatefulWidget {
  final String actividadId;

  const DetalleActividadScreen({
    super.key,
    required this.actividadId,
  });

  @override
  State<DetalleActividadScreen> createState() => _DetalleActividadScreenState();
}

class _DetalleActividadScreenState extends State<DetalleActividadScreen> {
  Actividad? _actividad;
  Proyecto? _proyecto;
  Persona? _persona;
  List<BitacoraEvento> _bitacora = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseService().database;
      final actividad = await db.getActividadPorId(widget.actividadId);
      
      if (actividad == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Actividad no encontrada')),
          );
        }
        return;
      }

      Proyecto? proyecto;
      if (actividad.proyectoId != null) {
        proyecto = await db.getProyectoPorId(actividad.proyectoId!);
      }

      Persona? persona;
      if (actividad.personaAsignadaId != null) {
        final personas = await db.getAllPersonas();
        persona = personas.firstWhere(
          (p) => p.id == actividad.personaAsignadaId,
          orElse: () => personas.first,
        );
      }

      final bitacora = await db.getBitacoraPorActividad(widget.actividadId);

      setState(() {
        _actividad = actividad;
        _proyecto = proyecto;
        _persona = persona;
        _bitacora = bitacora;
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

  Future<void> _actualizarActividad(Actividad actividad) async {
    try {
      final db = DatabaseService().database;
      await db.actualizarActividad(actividad);
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actividad actualizada')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_actividad == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: Text('Actividad no encontrada')),
      );
    }

    final isTablet = Responsive.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Actividad'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Editar actividad
            },
          ),
        ],
      ),
      body: isTablet
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildContenidoPrincipal(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 1,
                  child: _buildSidebar(),
                ),
              ],
            )
          : SingleChildScrollView(
              child: _buildContenidoPrincipal(),
            ),
    );
  }

  Widget _buildContenidoPrincipal() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            _actividad!.titulo,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Estado
          Chip(
            avatar: Icon(
              _getEstadoIcon(_actividad!.estado),
              size: 18,
              color: _getEstadoColor(_actividad!.estado),
            ),
            label: Text(_actividad!.estado.nombre),
            backgroundColor: _getEstadoColor(_actividad!.estado).withOpacity(0.1),
            side: BorderSide(color: _getEstadoColor(_actividad!.estado)),
          ),
          const SizedBox(height: 24),
          // Descripción
          if (_actividad!.descripcion != null) ...[
            Text(
              'Descripción',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _actividad!.descripcion!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ],
          // Información
          _buildInfoSection(),
          const SizedBox(height: 24),
          // Acciones
          _buildAcciones(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
        children: [
          Text(
            'Bitácora',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_bitacora.isEmpty)
            Text(
              'No hay eventos registrados',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            )
          else
            ..._bitacora.map((evento) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(_getTipoEventoIcon(evento.tipo)),
                    title: Text(evento.tipo.nombre),
                    subtitle: Text(
                      '${evento.timestamp.day}/${evento.timestamp.month}/${evento.timestamp.year} ${evento.timestamp.hour}:${evento.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    isThreeLine: evento.descripcion != null,
                    dense: true,
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_proyecto != null)
              _buildInfoRow(Icons.folder, 'Proyecto', _proyecto!.nombre),
            if (_persona != null)
              _buildInfoRow(Icons.person, 'Asignado a', _persona!.nombre),
            if (_actividad!.fechaObjetivo != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Fecha objetivo',
                '${_actividad!.fechaObjetivo!.day}/${_actividad!.fechaObjetivo!.month}/${_actividad!.fechaObjetivo!.year}',
              ),
            _buildInfoRow(
              Icons.access_time,
              'Creada',
              '${_actividad!.createdAt.day}/${_actividad!.createdAt.month}/${_actividad!.createdAt.year}',
            ),
            _buildInfoRow(
              Icons.update,
              'Actualizada',
              '${_actividad!.updatedAt.day}/${_actividad!.updatedAt.month}/${_actividad!.updatedAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () {
            mostrarMoverActividadBottomSheet(
              context,
              _actividad!,
              (nuevoEstado) async {
                await _actualizarActividad(_actividad!.copyWith(estado: nuevoEstado));
              },
            );
          },
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Mover'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _actualizarActividad(
              _actividad!.copyWith(estado: EstadoActividad.completada),
            );
          },
          icon: const Icon(Icons.check),
          label: const Text('Completar'),
        ),
      ],
    );
  }

  Color _getEstadoColor(EstadoActividad estado) {
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

  IconData _getEstadoIcon(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Icons.inbox;
      case EstadoActividad.hoy:
        return Icons.today;
      case EstadoActividad.manana:
        return Icons.event;
      case EstadoActividad.programado:
        return Icons.calendar_today;
      case EstadoActividad.pendientes:
        return Icons.pause_circle;
      case EstadoActividad.completada:
        return Icons.check_circle;
    }
  }

  IconData _getTipoEventoIcon(TipoEvento tipo) {
    switch (tipo) {
      case TipoEvento.create:
        return Icons.add_circle;
      case TipoEvento.move:
        return Icons.swap_horiz;
      case TipoEvento.complete:
        return Icons.check_circle;
      case TipoEvento.assign:
        return Icons.person;
      case TipoEvento.attach:
        return Icons.attach_file;
      case TipoEvento.update:
        return Icons.edit;
      case TipoEvento.delete:
        return Icons.delete;
    }
  }
}

