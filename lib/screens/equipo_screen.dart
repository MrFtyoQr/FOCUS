import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/responsive.dart';

/// Lista del equipo con gestión de personas
class EquipoScreen extends StatefulWidget {
  const EquipoScreen({super.key});

  @override
  State<EquipoScreen> createState() => _EquipoScreenState();
}

class _EquipoScreenState extends State<EquipoScreen> {
  List<Persona> _personas = [];
  Map<String, List<Actividad>> _actividadesPorPersona = {};
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
      final personas = await db.getAllPersonas();
      
      // Cargar actividades por persona
      final actividadesPorPersona = <String, List<Actividad>>{};
      for (var persona in personas) {
        // Obtener todas las actividades asignadas a esta persona
        final todasActividades = <Actividad>[];
        for (var estado in EstadoActividad.values) {
          todasActividades.addAll(await db.getActividadesPorEstado(estado));
        }
        
        actividadesPorPersona[persona.id] = todasActividades
            .where((a) => a.personaAsignadaId == persona.id)
            .toList();
      }
      
      setState(() {
        _personas = personas;
        _actividadesPorPersona = actividadesPorPersona;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar equipo: $e')),
        );
      }
    }
  }

  Future<void> _mostrarDialogoCrearPersona() async {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final telefonoController = TextEditingController();
    
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Persona'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
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
    );
    
    if (resultado == true && nombreController.text.trim().isNotEmpty) {
      try {
        final db = DatabaseService().database;
        final ahora = DateTime.now();
        
        final nuevaPersona = Persona(
          id: const Uuid().v4(),
          nombre: nombreController.text.trim(),
          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
          telefono: telefonoController.text.trim().isEmpty ? null : telefonoController.text.trim(),
          createdAt: ahora,
          updatedAt: ahora,
        );
        
        await db.insertarPersona(nuevaPersona);
        _cargarDatos();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Persona creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear persona: $e')),
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
        title: const Text('Equipo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _mostrarDialogoCrearPersona,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _personas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay personas en el equipo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _mostrarDialogoCrearPersona,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar primera persona'),
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
                          itemCount: _personas.length,
                          itemBuilder: (context, index) {
                            return _buildPersonaCard(_personas[index]);
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                          itemCount: _personas.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildPersonaCard(_personas[index]),
                            );
                          },
                        ),
                ),
    );
  }

  Widget _buildPersonaCard(Persona persona) {
    final actividades = _actividadesPorPersona[persona.id] ?? [];
    final contador = _contarActividadesPorEstado(actividades);
    final total = actividades.length;
    final completadas = contador[EstadoActividad.completada] ?? 0;
    final enProgreso = (contador[EstadoActividad.hoy] ?? 0) +
        (contador[EstadoActividad.manana] ?? 0) +
        (contador[EstadoActividad.programado] ?? 0);
    
    return Card(
      child: InkWell(
        onTap: () {
          _mostrarDetallePersona(persona, actividades);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      persona.nombre[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona.nombre,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (persona.email != null)
                          Text(
                            persona.email!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Métricas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniMetrica('Total', total, Icons.list),
                  _buildMiniMetrica('Completadas', completadas, Icons.check_circle, Colors.green),
                  _buildMiniMetrica('En progreso', enProgreso, Icons.play_circle, Colors.blue),
                ],
              ),
              const SizedBox(height: 12),
              // Resumen de actividades
              if (total > 0) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Actividades asignadas: $total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completadas: $completadas | En proceso: $enProgreso',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetrica(String label, int valor, IconData icono, [Color? color]) {
    final metricColor = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Icon(icono, size: 20, color: metricColor),
        const SizedBox(height: 4),
        Text(
          valor.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: metricColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  void _mostrarDetallePersona(Persona persona, List<Actividad> actividades) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      persona.nombre[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          persona.nombre,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (persona.email != null)
                          Text(
                            persona.email!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: actividades.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay actividades asignadas',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: actividades.length,
                      itemBuilder: (context, index) {
                        final actividad = actividades[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(actividad.titulo),
                            subtitle: Text(actividad.estado.nombre),
                            trailing: Chip(
                              label: Text(actividad.estado.nombre),
                              backgroundColor: _getEstadoColor(actividad.estado).withOpacity(0.2),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Navegar a detalle de actividad
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
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
      case EstadoActividad.completada:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
