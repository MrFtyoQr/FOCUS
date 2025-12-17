import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/responsive.dart';

/// Pantalla de captura rápida de actividades
class CapturaScreen extends StatefulWidget {
  const CapturaScreen({super.key});

  @override
  State<CapturaScreen> createState() => _CapturaScreenState();
}

class _CapturaScreenState extends State<CapturaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  EstadoActividad _estadoDestino = EstadoActividad.bandeja;
  String? _proyectoId;
  DateTime? _fechaObjetivo;
  List<Proyecto> _proyectos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarProyectos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarProyectos() async {
    try {
      final db = DatabaseService().database;
      final proyectos = await db.getAllProyectos();
      setState(() {
        _proyectos = proyectos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar proyectos: $e')),
        );
      }
    }
  }

  Future<void> _guardarActividad() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Si es Programado, debe tener fecha
    if (_estadoDestino == EstadoActividad.programado && _fechaObjetivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las actividades programadas requieren una fecha objetivo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService().database;
      final ahora = DateTime.now();
      
      final nuevaActividad = Actividad(
        id: const Uuid().v4(),
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        estado: _estadoDestino,
        proyectoId: _proyectoId,
        fechaObjetivo: _fechaObjetivo,
        createdAt: ahora,
        updatedAt: ahora,
        tieneAdjuntos: false,
        orden: 0,
      );

      await db.insertarActividad(nuevaActividad);
      
      // TODO: Registrar en bitácora

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _tituloController.clear();
        _descripcionController.clear();
        setState(() {
          _estadoDestino = EstadoActividad.bandeja;
          _proyectoId = null;
          _fechaObjetivo = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaObjetivo ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      final hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (hora != null) {
        setState(() {
          _fechaObjetivo = DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            hora.hour,
            hora.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final maxWidth = Responsive.getMaxContentWidth(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar Actividad'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
              children: [
                // Título (requerido)
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: '¿Qué necesitas hacer?',
                    prefixIcon: Icon(Icons.title),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Descripción (opcional)
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Detalles adicionales (opcional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                
                // Estado destino
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destino inicial',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        isTablet
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _buildEstadoButtons(),
                              )
                            : SegmentedButton<EstadoActividad>(
                                segments: [
                                  ButtonSegment(
                                    value: EstadoActividad.bandeja,
                                    label: const Text('Bandeja'),
                                    icon: const Icon(Icons.inbox, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: EstadoActividad.hoy,
                                    label: const Text('Hoy'),
                                    icon: const Icon(Icons.today, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: EstadoActividad.manana,
                                    label: const Text('Mañana'),
                                    icon: const Icon(Icons.event, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: EstadoActividad.programado,
                                    label: const Text('Programado'),
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: EstadoActividad.pendientes,
                                    label: const Text('Pendientes'),
                                    icon: const Icon(Icons.pause_circle, size: 18),
                                  ),
                                ],
                                selected: {_estadoDestino},
                                onSelectionChanged: (Set<EstadoActividad> newSelection) {
                                  setState(() {
                                    _estadoDestino = newSelection.first;
                                    if (_estadoDestino != EstadoActividad.programado) {
                                      _fechaObjetivo = null;
                                    }
                                  });
                                },
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Proyecto (opcional)
                if (_proyectos.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proyecto (opcional)',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _proyectoId,
                            decoration: const InputDecoration(
                              hintText: 'Seleccionar proyecto',
                              prefixIcon: Icon(Icons.folder),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Sin proyecto'),
                              ),
                              ..._proyectos.map((proyecto) {
                                return DropdownMenuItem<String>(
                                  value: proyecto.id,
                                  child: Text(proyecto.nombre),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _proyectoId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Fecha objetivo (si es Programado)
                if (_estadoDestino == EstadoActividad.programado) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha objetivo *',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(
                              _fechaObjetivo != null
                                  ? '${_fechaObjetivo!.day}/${_fechaObjetivo!.month}/${_fechaObjetivo!.year} ${_fechaObjetivo!.hour.toString().padLeft(2, '0')}:${_fechaObjetivo!.minute.toString().padLeft(2, '0')}'
                                  : 'Seleccionar fecha y hora',
                            ),
                            trailing: _fechaObjetivo != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _fechaObjetivo = null;
                                      });
                                    },
                                  )
                                : null,
                            onTap: _seleccionarFecha,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Botón guardar
                FilledButton.icon(
                  onPressed: _isLoading ? null : _guardarActividad,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Guardando...' : 'Guardar Actividad'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEstadoButtons() {
    return [
      _buildEstadoChip(EstadoActividad.bandeja, Icons.inbox),
      _buildEstadoChip(EstadoActividad.hoy, Icons.today),
      _buildEstadoChip(EstadoActividad.manana, Icons.event),
      _buildEstadoChip(EstadoActividad.programado, Icons.calendar_today),
      _buildEstadoChip(EstadoActividad.pendientes, Icons.pause_circle),
    ];
  }

  Widget _buildEstadoChip(EstadoActividad estado, IconData icon) {
    final isSelected = _estadoDestino == estado;
    final color = _getEstadoColor(estado);
    
    return FilterChip(
      selected: isSelected,
      label: Text(estado.nombre),
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : color),
      selectedColor: color,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        setState(() {
          _estadoDestino = estado;
          if (_estadoDestino != EstadoActividad.programado) {
            _fechaObjetivo = null;
          }
        });
      },
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
}
