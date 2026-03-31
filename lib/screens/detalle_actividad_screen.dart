import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io' show Platform;
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart' show AudioPlayer, PlayerState;
import 'package:audioplayers/audioplayers.dart' as audio;
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../widgets/mover_actividad_bottom_sheet.dart';
import '../utils/app_snackbar.dart';
import '../utils/estado_actividad_colors.dart';
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
  List<File> _archivos = [];
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
      final actividad = await db.getActividadPorId(widget.actividadId);
      
      if (actividad == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.aviso('Actividad no encontrada'),
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
        try {
          persona = personas.firstWhere(
            (p) => p.id == actividad.personaAsignadaId,
          );
        } catch (e) {
          // Si no se encuentra la persona, se deja como null
          persona = null;
        }
      }

      final bitacora = await db.getBitacoraPorActividad(widget.actividadId);
      final archivos = await _fileService.getArchivosDeActividad(widget.actividadId);

      setState(() {
        _actividad = actividad;
        _proyecto = proyecto;
        _persona = persona;
        _bitacora = bitacora;
        _archivos = archivos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error: $e'),
        );
      }
    }
  }

  Future<void> _actualizarActividad(Actividad actividad) async {
    try {
      final db = DatabaseService().database;
      await db.actualizarActividad(actividad);
      // Esperar a que la actualización se complete antes de recargar
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.exito('Actividad actualizada'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error: $e'),
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
            onPressed: _mostrarDialogoEditarActividad,
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
          // Asignar persona
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Asignar a',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: _mostrarDialogoAsignarPersona,
                      ),
                    ],
                  ),
                  if (_persona != null)
                    Chip(
                      avatar: CircleAvatar(
                        child: Text(_persona!.nombre[0].toUpperCase()),
                      ),
                      label: Text(_persona!.nombre),
                      onDeleted: () async {
                        try {
                          // Crear nueva actividad con personaAsignadaId explícitamente null
                          final actividadActualizada = Actividad(
                            id: _actividad!.id,
                            titulo: _actividad!.titulo,
                            descripcion: _actividad!.descripcion,
                            estado: _actividad!.estado,
                            proyectoId: _actividad!.proyectoId,
                            personaAsignadaId: null, // Explícitamente null
                            fechaObjetivo: _actividad!.fechaObjetivo,
                            createdAt: _actividad!.createdAt,
                            updatedAt: DateTime.now(),
                            tieneAdjuntos: _actividad!.tieneAdjuntos,
                            orden: _actividad!.orden,
                          );
                          await _actualizarActividad(actividadActualizada);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar.error('Error al eliminar asignación: $e'),
                            );
                          }
                        }
                      },
                    )
                  else
                    Text(
                      'Sin asignar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Agregar nota
          Card(
            child: ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Agregar nota'),
              onTap: _mostrarDialogoAgregarNota,
            ),
          ),
          const SizedBox(height: 8),
          
          // Agregar archivo
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Agregar archivo'),
              onTap: _mostrarDialogoAgregarArchivo,
            ),
          ),
          const SizedBox(height: 8),
          
          // Lista de archivos adjuntos
          if (_archivos.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Archivos adjuntos (${_archivos.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _archivos.map((archivo) {
                        final esImagen = _esImagen(archivo.path);
                        return _buildArchivoChip(archivo, esImagen);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          const SizedBox(height: 16),
          
          // Bitácora
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bitácora',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Historial de cambios y eventos de esta actividad',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_bitacora.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No hay eventos registrados',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._bitacora.map((evento) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getTipoEventoIcon(evento.tipo),
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        evento.tipo.nombre,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '${evento.timestamp.day}/${evento.timestamp.month}/${evento.timestamp.year} ${evento.timestamp.hour.toString().padLeft(2, '0')}:${evento.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                                if (evento.descripcion != null && evento.descripcion!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      evento.descripcion!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoAsignarPersona() async {
    try {
      final db = DatabaseService().database;
      final personas = await db.getAllPersonas();
      
      if (personas.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.aviso('No hay personas en el equipo'),
          );
        }
        return;
      }
      
      final personaSeleccionada = await showDialog<Persona>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Asignar persona'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: personas.length,
              itemBuilder: (context, index) {
                final persona = personas[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(persona.nombre[0].toUpperCase()),
                  ),
                  title: Text(persona.nombre),
                  subtitle: persona.email != null ? Text(persona.email!) : null,
                  onTap: () => Navigator.pop(context, persona),
                );
              },
            ),
          ),
        ),
      );
      
      if (personaSeleccionada != null) {
        await _actualizarActividad(
          _actividad!.copyWith(personaAsignadaId: personaSeleccionada.id),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error: $e'),
        );
      }
    }
  }

  Future<void> _mostrarDialogoAgregarNota() async {
    final notaController = TextEditingController();
    
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nota'),
        content: TextField(
          controller: notaController,
          decoration: const InputDecoration(
            hintText: 'Escribe una nota...',
          ),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (notaController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    
    if (resultado == true && notaController.text.trim().isNotEmpty) {
      try {
        final db = DatabaseService().database;
        final ahora = DateTime.now();
        
        // Registrar en bitácora
        final evento = BitacoraEvento(
          id: const Uuid().v4(),
          actividadId: _actividad!.id,
          tipo: TipoEvento.update,
          descripcion: notaController.text.trim(),
          timestamp: ahora,
          usuarioId: null,
        );
        
        await db.insertarEventoBitacora(evento);
        _cargarDatos();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.exito('Nota agregada'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.error('Error: $e'),
          );
        }
      }
    }
  }

  Future<void> _mostrarDialogoAgregarArchivo() async {
    // Mostrar opciones: imagen o archivo
    final opcion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar archivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Seleccionar imagen'),
              onTap: () => Navigator.pop(context, 'imagen'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Seleccionar archivo'),
              onTap: () => Navigator.pop(context, 'archivo'),
            ),
          ],
        ),
      ),
    );
    
    if (opcion == 'imagen') {
      await _agregarImagen();
    } else if (opcion == 'archivo') {
      await _agregarArchivo();
    }
  }

  Future<void> _agregarImagen() async {
    try {
      final rutaImagen = await _fileService.seleccionarImagen();
      if (rutaImagen != null) {
        // Copiar imagen al directorio de la actividad
        final rutaFinal = await _fileService.copiarArchivoAActividad(
          _actividad!.id,
          rutaImagen,
        );
        
        // Actualizar actividad para marcar que tiene adjuntos
        final actividadActualizada = Actividad(
          id: _actividad!.id,
          titulo: _actividad!.titulo,
          descripcion: _actividad!.descripcion,
          estado: _actividad!.estado,
          proyectoId: _actividad!.proyectoId,
          personaAsignadaId: _actividad!.personaAsignadaId,
          fechaObjetivo: _actividad!.fechaObjetivo,
          createdAt: _actividad!.createdAt,
          updatedAt: DateTime.now(),
          tieneAdjuntos: true,
          orden: _actividad!.orden,
        );
        
        await _actualizarActividad(actividadActualizada);
        
        // Registrar en bitácora
        final db = DatabaseService().database;
        final evento = BitacoraEvento(
          id: const Uuid().v4(),
          actividadId: _actividad!.id,
          tipo: TipoEvento.attach,
          descripcion: 'Imagen agregada: ${p.basename(rutaFinal)}',
          timestamp: DateTime.now(),
          usuarioId: null,
        );
        await db.insertarEventoBitacora(evento);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.exito('Imagen agregada exitosamente'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al agregar imagen: $e'),
        );
      }
    }
  }

  Future<void> _agregarArchivo() async {
    try {
      final rutaArchivo = await _fileService.seleccionarArchivo();
      if (rutaArchivo != null) {
        // Copiar archivo al directorio de la actividad
        final rutaFinal = await _fileService.copiarArchivoAActividad(
          _actividad!.id,
          rutaArchivo,
        );
        
        // Actualizar actividad para marcar que tiene adjuntos
        final actividadActualizada = Actividad(
          id: _actividad!.id,
          titulo: _actividad!.titulo,
          descripcion: _actividad!.descripcion,
          estado: _actividad!.estado,
          proyectoId: _actividad!.proyectoId,
          personaAsignadaId: _actividad!.personaAsignadaId,
          fechaObjetivo: _actividad!.fechaObjetivo,
          createdAt: _actividad!.createdAt,
          updatedAt: DateTime.now(),
          tieneAdjuntos: true,
          orden: _actividad!.orden,
        );
        
        await _actualizarActividad(actividadActualizada);
        
        // Registrar en bitácora
        final db = DatabaseService().database;
        final evento = BitacoraEvento(
          id: const Uuid().v4(),
          actividadId: _actividad!.id,
          tipo: TipoEvento.attach,
          descripcion: 'Archivo agregado: ${p.basename(rutaFinal)}',
          timestamp: DateTime.now(),
          usuarioId: null,
        );
        await db.insertarEventoBitacora(evento);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.exito('Archivo agregado exitosamente'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al agregar archivo: $e'),
        );
      }
    }
  }

  bool _esImagen(String ruta) {
    final extension = p.extension(ruta).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  Widget _obtenerIconoArchivo(String ruta) {
    final extension = p.extension(ruta).toLowerCase();
    IconData icono;
    Color color = Theme.of(context).colorScheme.primary;
    
    if (_esPdf(ruta)) {
      icono = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (_esVideo(ruta)) {
      icono = Icons.videocam;
      color = Colors.purple;
    } else if (_esAudio(ruta)) {
      icono = Icons.audiotrack;
      color = Colors.orange;
    } else if (['.doc', '.docx'].contains(extension)) {
      icono = Icons.description;
      color = Colors.blue;
    } else if (['.xls', '.xlsx'].contains(extension)) {
      icono = Icons.table_chart;
      color = Colors.green;
    } else if (['.zip', '.rar', '.7z'].contains(extension)) {
      icono = Icons.folder_zip;
      color = Colors.amber;
    } else {
      icono = Icons.insert_drive_file;
    }
    
    return Center(
      child: Icon(
        icono,
        size: 48,
        color: color,
      ),
    );
  }

  Widget _buildArchivoChip(File archivo, bool esImagen) {
    final nombreArchivo = p.basename(archivo.path);
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vista previa de imagen o icono
            GestureDetector(
              onTap: () => _mostrarArchivo(archivo, esImagen),
              child: Container(
                width: double.infinity,
                height: esImagen ? 150 : 80,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: esImagen
                    ? Image.file(
                        archivo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          );
                        },
                      )
                    : _obtenerIconoArchivo(archivo.path),
              ),
            ),
            // Nombre y botón eliminar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nombreArchivo,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Eliminar archivo'),
                          content: Text('¿Estás seguro de eliminar "$nombreArchivo"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmar == true) {
                        final eliminado = await _fileService.eliminarArchivo(archivo.path);
                        if (eliminado) {
                          // Actualizar actividad si no quedan archivos
                          final archivosRestantes = await _fileService.getArchivosDeActividad(_actividad!.id);
                          final actividadActualizada = Actividad(
                            id: _actividad!.id,
                            titulo: _actividad!.titulo,
                            descripcion: _actividad!.descripcion,
                            estado: _actividad!.estado,
                            proyectoId: _actividad!.proyectoId,
                            personaAsignadaId: _actividad!.personaAsignadaId,
                            fechaObjetivo: _actividad!.fechaObjetivo,
                            createdAt: _actividad!.createdAt,
                            updatedAt: DateTime.now(),
                            tieneAdjuntos: archivosRestantes.isNotEmpty,
                            orden: _actividad!.orden,
                          );
                          await _actualizarActividad(actividadActualizada);
                          
                          // Registrar en bitácora
                          final db = DatabaseService().database;
                          final evento = BitacoraEvento(
                            id: const Uuid().v4(),
                            actividadId: _actividad!.id,
                            tipo: TipoEvento.update,
                            descripcion: 'Archivo eliminado: $nombreArchivo',
                            timestamp: DateTime.now(),
                            usuarioId: null,
                          );
                          await db.insertarEventoBitacora(evento);
                          
                          _cargarDatos();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              AppSnackBar.exito('Archivo eliminado'),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _esVideo(String ruta) {
    final extension = p.extension(ruta).toLowerCase();
    return ['.mp4', '.avi', '.mov', '.mkv', '.webm', '.flv', '.wmv'].contains(extension);
  }

  bool _esAudio(String ruta) {
    final extension = p.extension(ruta).toLowerCase();
    return ['.mp3', '.wav', '.aac', '.ogg', '.m4a', '.flac', '.wma'].contains(extension);
  }

  bool _esPdf(String ruta) {
    final extension = p.extension(ruta).toLowerCase();
    return extension == '.pdf';
  }

  Future<void> _mostrarArchivo(File archivo, bool esImagen) async {
    if (esImagen) {
      // Mostrar imagen en pantalla completa
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.file(archivo),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_esVideo(archivo.path)) {
      // Mostrar reproductor de video
      _mostrarVideo(archivo);
    } else if (_esAudio(archivo.path)) {
      // Mostrar reproductor de audio
      _mostrarAudio(archivo);
    } else if (_esPdf(archivo.path)) {
      // Abrir PDF con app del sistema usando url_launcher
      await _abrirArchivoConSistema(archivo);
    } else {
      // Para otros archivos, intentar abrir con app del sistema
      await _abrirArchivoConSistema(archivo);
    }
  }

  Future<void> _abrirArchivoConSistema(File archivo) async {
    try {
      if (Platform.isAndroid) {
        // En Android, usar share_plus que maneja FileProvider automáticamente
        // Esto evita el FileUriExposedException
        final xFile = XFile(archivo.path);
        await Share.shareXFiles(
          [xFile],
          text: 'Abrir archivo: ${p.basename(archivo.path)}',
        );
      } else {
        // Para iOS y otras plataformas, usar url_launcher
        final uri = Uri.file(archivo.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppSnackBar.aviso(
                'No se encontró una aplicación para abrir este archivo',
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al abrir archivo: $e'),
        );
      }
    }
  }

  void _mostrarVideo(File archivo) {
    final controller = VideoPlayerController.file(archivo);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.black,
            child: FutureBuilder(
              future: controller.initialize(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.blue,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            controller.dispose();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 48,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (controller.value.isPlaying) {
                                    controller.pause();
                                  } else {
                                    controller.play();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          );
        },
      ),
    ).then((_) {
      controller.dispose();
    });
  }

  void _mostrarAudio(File archivo) {
    final player = AudioPlayer();
    bool isPlaying = false;
    Duration duration = Duration.zero;
    Duration position = Duration.zero;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Inicializar reproductor
          player.onDurationChanged.listen((newDuration) {
            setState(() {
              duration = newDuration;
            });
          });
          
          player.onPositionChanged.listen((newPosition) {
            setState(() {
              position = newPosition;
            });
          });
          
          player.onPlayerStateChanged.listen((state) {
            setState(() {
              isPlaying = state == PlayerState.playing;
            });
          });
          
          return AlertDialog(
            title: Text(
              p.basename(archivo.path),
              overflow: TextOverflow.ellipsis,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de progreso
                if (duration.inSeconds > 0)
                  Slider(
                    value: position.inSeconds.toDouble(),
                    max: duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      player.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                // Tiempo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (duration.inSeconds > 0)
                      Text(
                        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Controles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 48,
                      onPressed: () async {
                        if (isPlaying) {
                          await player.pause();
                        } else {
                          if (position.inSeconds == 0) {
                            await player.play(audio.DeviceFileSource(archivo.path));
                          } else {
                            await player.resume();
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () async {
                        await player.stop();
                        setState(() {
                          position = Duration.zero;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  player.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      player.dispose();
    });
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
    return EstadoActividadColors.forEstado(
      estado,
      brightness: Theme.of(context).brightness,
    );
  }

  IconData _getEstadoIcon(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Icons.inbox_outlined;
      case EstadoActividad.hoy:
        return Icons.today_outlined;
      case EstadoActividad.manana:
        return Icons.event_outlined;
      case EstadoActividad.programado:
        return Icons.schedule_outlined;
      case EstadoActividad.pendientes:
        return Icons.pause_circle_outline;
      case EstadoActividad.completada:
        return Icons.star_outline;
    }
  }

  IconData _getTipoEventoIcon(TipoEvento tipo) {
    switch (tipo) {
      case TipoEvento.create:
        return Icons.add_circle_outline;
      case TipoEvento.move:
        return Icons.swap_horiz;
      case TipoEvento.complete:
        return Icons.star_outline;
      case TipoEvento.assign:
        return Icons.person_outline;
      case TipoEvento.attach:
        return Icons.attach_file_outlined;
      case TipoEvento.update:
        return Icons.edit_outlined;
      case TipoEvento.delete:
        return Icons.delete_outline;
    }
  }

  Future<void> _mostrarDialogoEditarActividad() async {
    if (_actividad == null) return;

    final tituloController = TextEditingController(text: _actividad!.titulo);
    final descripcionController = TextEditingController(text: _actividad!.descripcion ?? '');
    EstadoActividad estadoSeleccionado = _actividad!.estado;
    String? proyectoIdSeleccionado = _actividad!.proyectoId;
    DateTime? fechaObjetivo = _actividad!.fechaObjetivo;
    List<Proyecto> proyectos = [];

    // Cargar proyectos
    try {
      final db = DatabaseService().database;
      proyectos = await db.getAllProyectos();
    } catch (e) {
      // Ignorar error
    }

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Actividad'),
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
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                // Estado
                Text(
                  'Estado',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Responsive.isTablet(context) && MediaQuery.of(context).size.width > 700
                    ? SegmentedButton<EstadoActividad>(
                        segments: [
                          ButtonSegment(
                            value: EstadoActividad.bandeja,
                            label: const Text('Bandeja'),
                          ),
                          ButtonSegment(
                            value: EstadoActividad.hoy,
                            label: const Text('Hoy'),
                          ),
                          ButtonSegment(
                            value: EstadoActividad.manana,
                            label: const Text('Mañana'),
                          ),
                          ButtonSegment(
                            value: EstadoActividad.programado,
                            label: const Text('Programado'),
                          ),
                          ButtonSegment(
                            value: EstadoActividad.pendientes,
                            label: const Text('Pendientes'),
                          ),
                        ],
                        selected: {estadoSeleccionado},
                        onSelectionChanged: (Set<EstadoActividad> newSelection) {
                          setDialogState(() {
                            estadoSeleccionado = newSelection.first;
                            if (estadoSeleccionado != EstadoActividad.programado) {
                              fechaObjetivo = null;
                            }
                          });
                        },
                      )
                    : SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: EstadoActividad.values.length,
                          itemBuilder: (context, index) {
                            final estado = EstadoActividad.values[index];
                            final isSelected = estado == estadoSeleccionado;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                selected: isSelected,
                                label: Text(estado.nombre),
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(() {
                                      estadoSeleccionado = estado;
                                      if (estadoSeleccionado != EstadoActividad.programado) {
                                        fechaObjetivo = null;
                                      }
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
                const SizedBox(height: 16),
                // Proyecto
                if (proyectos.isNotEmpty) ...[
                  Text(
                    'Proyecto',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: proyectoIdSeleccionado,
                    decoration: const InputDecoration(
                      hintText: 'Seleccionar proyecto',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Sin proyecto'),
                      ),
                      ...proyectos.map((proyecto) {
                        return DropdownMenuItem<String>(
                          value: proyecto.id,
                          child: Text(proyecto.nombre),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        proyectoIdSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Fecha objetivo (si es Programado)
                if (estadoSeleccionado == EstadoActividad.programado) ...[
                  Text(
                    'Fecha objetivo',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      fechaObjetivo != null
                          ? '${fechaObjetivo!.day}/${fechaObjetivo!.month}/${fechaObjetivo!.year} ${fechaObjetivo!.hour.toString().padLeft(2, '0')}:${fechaObjetivo!.minute.toString().padLeft(2, '0')}'
                          : 'Seleccionar fecha y hora',
                    ),
                    trailing: fechaObjetivo != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setDialogState(() {
                                fechaObjetivo = null;
                              });
                            },
                          )
                        : null,
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: fechaObjetivo ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (fecha != null) {
                        final hora = await showTimePicker(
                          context: context,
                          initialTime: fechaObjetivo != null
                              ? TimeOfDay.fromDateTime(fechaObjetivo!)
                              : TimeOfDay.now(),
                        );
                        if (hora != null) {
                          setDialogState(() {
                            fechaObjetivo = DateTime(
                              fecha.year,
                              fecha.month,
                              fecha.day,
                              hora.hour,
                              hora.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
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
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (resultado == true && tituloController.text.trim().isNotEmpty) {
      try {
        final db = DatabaseService().database;
        final ahora = DateTime.now();

        // Validar que Programado tenga fecha
        if (estadoSeleccionado == EstadoActividad.programado && fechaObjetivo == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppSnackBar.aviso(
                'Las actividades programadas requieren una fecha objetivo',
              ),
            );
          }
          return;
        }

        final actividadActualizada = _actividad!.copyWith(
          titulo: tituloController.text.trim(),
          descripcion: descripcionController.text.trim().isEmpty
              ? null
              : descripcionController.text.trim(),
          estado: estadoSeleccionado,
          proyectoId: proyectoIdSeleccionado,
          fechaObjetivo: fechaObjetivo,
          updatedAt: ahora,
        );

        await db.actualizarActividad(actividadActualizada);

        // Registrar en bitácora
        final evento = BitacoraEvento(
          id: const Uuid().v4(),
          actividadId: _actividad!.id,
          tipo: TipoEvento.update,
          descripcion: 'Actividad actualizada',
          timestamp: ahora,
          usuarioId: null,
        );
        await db.insertarEventoBitacora(evento);

        _cargarDatos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.exito('Actividad actualizada exitosamente'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.error('Error: $e'),
          );
        }
      }
    }
  }
}

