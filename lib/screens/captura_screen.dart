import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/estado_actividad_colors.dart';
import '../utils/responsive.dart';

/// Fondo de cards en Capturar (solo light mode).
const _kCapturaCardBackgroundLight = Color(0xFFF7F7F7);

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
  List<String> _archivosAdjuntos = []; // Lista de rutas de archivos
  final FileService _fileService = FileService();

  Color? _capturaCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _kCapturaCardBackgroundLight
        : null;
  }

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
          AppSnackBar.error('Error al cargar proyectos: $e'),
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
        AppSnackBar.aviso(
          'Las actividades programadas requieren una fecha objetivo',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService().database;
      final ahora = DateTime.now();
      final nuevaActividadId = const Uuid().v4();
      
      // Copiar archivos al directorio de la actividad ANTES de crear la actividad
      for (var archivoRuta in _archivosAdjuntos) {
        await _fileService.copiarArchivoAActividad(nuevaActividadId, archivoRuta);
      }
      
      final nuevaActividad = Actividad(
        id: nuevaActividadId,
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        estado: _estadoDestino,
        proyectoId: _proyectoId,
        fechaObjetivo: _fechaObjetivo,
        createdAt: ahora,
        updatedAt: ahora,
        tieneAdjuntos: _archivosAdjuntos.isNotEmpty,
        orden: 0,
      );

      await db.insertarActividad(nuevaActividad);
      
      // Registrar en bitácora
      final evento = BitacoraEvento(
        id: const Uuid().v4(),
        actividadId: nuevaActividadId,
        tipo: TipoEvento.create,
        descripcion: 'Actividad creada',
        timestamp: ahora,
        usuarioId: null,
      );
      await db.insertarEventoBitacora(evento);
      
      // Registrar archivos adjuntos en bitácora
      for (var archivoRuta in _archivosAdjuntos) {
        final nombreArchivo = archivoRuta.split('/').last;
        final eventoArchivo = BitacoraEvento(
          id: const Uuid().v4(),
          actividadId: nuevaActividadId,
          tipo: TipoEvento.attach,
          descripcion: 'Archivo adjunto: $nombreArchivo',
          timestamp: ahora,
          usuarioId: null,
        );
        await db.insertarEventoBitacora(eventoArchivo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.exito('Actividad creada exitosamente'),
        );
        
        // Limpiar formulario
        _tituloController.clear();
        _descripcionController.clear();
        setState(() {
          _estadoDestino = EstadoActividad.bandeja;
          _proyectoId = null;
          _fechaObjetivo = null;
          _archivosAdjuntos.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al guardar: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
      
      if (imagen != null) {
        setState(() {
          _archivosAdjuntos.add(imagen.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al seleccionar imagen: $e'),
        );
      }
    }
  }

  Future<void> _seleccionarArchivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _archivosAdjuntos.add(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al seleccionar archivo: $e'),
        );
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
                  color: _capturaCardColor(context),
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _buildEstadoButtons(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Proyecto (opcional)
                if (_proyectos.isNotEmpty)
                  Card(
                    color: _capturaCardColor(context),
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
                    color: _capturaCardColor(context),
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
                
                // Archivos adjuntos
                Card(
                  color: _capturaCardColor(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archivos adjuntos',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _seleccionarImagen,
                              icon: const Icon(Icons.image),
                              label: const Text('Imagen'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _seleccionarArchivo,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Archivo'),
                            ),
                          ],
                        ),
                        if (_archivosAdjuntos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ..._archivosAdjuntos.map((archivo) => Chip(
                                label: Text(archivo.split('/').last),
                                onDeleted: () {
                                  setState(() {
                                    _archivosAdjuntos.remove(archivo);
                                  });
                                },
                                deleteIcon: const Icon(Icons.close),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
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
      _buildEstadoChip(EstadoActividad.bandeja, Icons.inbox_outlined),
      _buildEstadoChip(EstadoActividad.hoy, Icons.today_outlined),
      _buildEstadoChip(EstadoActividad.manana, Icons.event_outlined),
      _buildEstadoChip(EstadoActividad.programado, Icons.schedule_outlined),
      _buildEstadoChip(EstadoActividad.pendientes, Icons.pause_circle_outline),
    ];
  }

  Widget _buildEstadoChip(EstadoActividad estado, IconData icon) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final isSelected = _estadoDestino == estado;
    final color = _getEstadoColor(estado);
    // Light: texto/ícono claros al seleccionar. Dark: conserva suavidad legible.
    final selectedForeground = isLight
        ? const Color(0xFFF3F5FA)
        : Color.lerp(color, const Color(0xFF1F2430), 0.82)!;
    
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(estado.nombre),
      labelStyle: TextStyle(
        color: isSelected ? selectedForeground : color,
        fontWeight: FontWeight.w600,
      ),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? selectedForeground : color,
      ),
      selectedColor: color,
      elevation: isLight ? 0 : null,
      pressElevation: isLight ? 0 : null,
      shadowColor: isLight ? Colors.transparent : null,
      selectedShadowColor: isLight ? Colors.transparent : null,
      surfaceTintColor: isLight ? Colors.transparent : null,
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
    return EstadoActividadColors.forEstado(
      estado,
      brightness: Theme.of(context).brightness,
    );
  }
}
