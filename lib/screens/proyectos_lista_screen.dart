import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/responsive.dart';

/// Listado de proyectos con métricas
class ProyectosListaScreen extends StatefulWidget {
  const ProyectosListaScreen({super.key});

  @override
  State<ProyectosListaScreen> createState() => _ProyectosListaScreenState();
}

class _ProyectosListaScreenState extends State<ProyectosListaScreen> {
  List<Proyecto> _proyectos = [];
  Map<String, List<Actividad>> _actividadesPorProyecto = {};
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
      final proyectos = await db.getAllProyectos();
      
      // Cargar actividades por proyecto
      final actividadesPorProyecto = <String, List<Actividad>>{};
      for (var proyecto in proyectos) {
        // Obtener todas las actividades del proyecto
        final todasActividades = await db.getActividadesPorEstado(EstadoActividad.bandeja);
        todasActividades.addAll(await db.getActividadesPorEstado(EstadoActividad.hoy));
        todasActividades.addAll(await db.getActividadesPorEstado(EstadoActividad.manana));
        todasActividades.addAll(await db.getActividadesPorEstado(EstadoActividad.programado));
        todasActividades.addAll(await db.getActividadesPorEstado(EstadoActividad.pendientes));
        todasActividades.addAll(await db.getActividadesPorEstado(EstadoActividad.completada));
        
        actividadesPorProyecto[proyecto.id] = todasActividades
            .where((a) => a.proyectoId == proyecto.id)
            .toList();
      }
      
      setState(() {
        _proyectos = proyectos;
        _actividadesPorProyecto = actividadesPorProyecto;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar proyectos: $e')),
        );
      }
    }
  }

  Future<void> _mostrarDialogoCrearProyecto() async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    Color? colorSeleccionado = Colors.blue;
    
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Proyecto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.red,
                    Colors.teal,
                    Colors.pink,
                    Colors.indigo,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          colorSeleccionado = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorSeleccionado == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: colorSeleccionado == color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
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
                if (nombreController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    
    if (resultado == true && nombreController.text.trim().isNotEmpty) {
      try {
        final db = DatabaseService().database;
        final ahora = DateTime.now();
        
        final nuevoProyecto = Proyecto(
          id: const Uuid().v4(),
          nombre: nombreController.text.trim(),
          descripcion: descripcionController.text.trim().isEmpty
              ? null
              : descripcionController.text.trim(),
          color: '#${(colorSeleccionado ?? Colors.blue).value.toRadixString(16).substring(2)}',
          createdAt: ahora,
          updatedAt: ahora,
        );
        
        await db.insertarProyecto(nuevoProyecto);
        _cargarDatos();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proyecto creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear proyecto: $e')),
          );
        }
      }
    }
  }

  Map<EstadoActividad, int> _contarActividadesPorEstado(List<Actividad> actividades) {
    final contador = <EstadoActividad, int>{};
    for (var estado in EstadoActividad.values) {
      contador[estado] = actividades.where((a) => a.estado == estado).length;
    }
    return contador;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final columnCount = Responsive.getColumnCount(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarDialogoCrearProyecto,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _proyectos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay proyectos',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _mostrarDialogoCrearProyecto,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear primer proyecto'),
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
                            crossAxisCount: columnCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _proyectos.length,
                          itemBuilder: (context, index) {
                            return _buildProyectoCard(_proyectos[index]);
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                          itemCount: _proyectos.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildProyectoCard(_proyectos[index]),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildProyectoCard(Proyecto proyecto) {
    final actividades = _actividadesPorProyecto[proyecto.id] ?? [];
    final contador = _contarActividadesPorEstado(actividades);
    final total = actividades.length;
    final completadas = contador[EstadoActividad.completada] ?? 0;
    
    Color proyectoColor = Colors.blue;
    if (proyecto.color != null && proyecto.color!.isNotEmpty) {
      try {
        proyectoColor = Color(int.parse(proyecto.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        proyectoColor = Colors.blue;
      }
    }

    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle de proyecto
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: proyectoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.folder, color: proyectoColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proyecto.nombre,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (proyecto.descripcion != null)
                          Text(
                            proyecto.descripcion!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Métricas
              Text(
                '$completadas de $total completadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Barras de estado
              ...EstadoActividad.values
                  .where((e) => e != EstadoActividad.completada && e != EstadoActividad.bandeja)
                  .map((estado) {
                final count = contador[estado] ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          estado.nombre,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: total > 0 ? count / total : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getEstadoColor(estado),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.hoy:
        return Colors.blue;
      case EstadoActividad.manana:
        return Colors.orange;
      case EstadoActividad.programado:
        return Colors.purple;
      case EstadoActividad.pendientes:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
