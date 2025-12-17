import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/actividad_card.dart';
import '../utils/responsive.dart';
import 'detalle_actividad_screen.dart';

/// Pantalla de historial con todas las actividades
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Actividad> _todasActividades = [];
  List<Actividad> _actividadesFiltradas = [];
  Map<String, Proyecto> _proyectos = {};
  Map<String, Persona> _personas = {};
  bool _isLoading = true;
  
  EstadoActividad? _filtroEstado;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseService().database;
      final todasActividades = await db.getAllActividades();
      final proyectos = await db.getAllProyectos();
      final personas = await db.getAllPersonas();
      
      setState(() {
        _todasActividades = todasActividades;
        _proyectos = {for (var p in proyectos) p.id: p};
        _personas = {for (var p in personas) p.id: p};
        _aplicarFiltros();
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

  void _aplicarFiltros() {
    var filtradas = List<Actividad>.from(_todasActividades);
    
    // Filtro por estado
    if (_filtroEstado != null) {
      filtradas = filtradas.where((a) => a.estado == _filtroEstado).toList();
    }
    
    // Filtro por fecha desde
    if (_fechaDesde != null) {
      filtradas = filtradas.where((a) {
        return a.createdAt.isAfter(_fechaDesde!) || 
               a.createdAt.isAtSameMomentAs(_fechaDesde!);
      }).toList();
    }
    
    // Filtro por fecha hasta
    if (_fechaHasta != null) {
      filtradas = filtradas.where((a) {
        return a.createdAt.isBefore(_fechaHasta!.add(const Duration(days: 1))) ||
               a.createdAt.isAtSameMomentAs(_fechaHasta!);
      }).toList();
    }
    
    setState(() {
      _actividadesFiltradas = filtradas;
    });
  }

  Future<void> _seleccionarFechaDesde() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaDesde ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaDesde = fecha;
        _aplicarFiltros();
      });
    }
  }

  Future<void> _seleccionarFechaHasta() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHasta ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaHasta = fecha;
        _aplicarFiltros();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros activos
                if (_filtroEstado != null || _fechaDesde != null || _fechaHasta != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_filtroEstado != null)
                          Chip(
                            label: Text(_filtroEstado!.nombre),
                            onDeleted: () {
                              setState(() {
                                _filtroEstado = null;
                                _aplicarFiltros();
                              });
                            },
                          ),
                        if (_fechaDesde != null)
                          Chip(
                            label: Text('Desde: ${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}'),
                            onDeleted: () {
                              setState(() {
                                _fechaDesde = null;
                                _aplicarFiltros();
                              });
                            },
                          ),
                        if (_fechaHasta != null)
                          Chip(
                            label: Text('Hasta: ${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}'),
                            onDeleted: () {
                              setState(() {
                                _fechaHasta = null;
                                _aplicarFiltros();
                              });
                            },
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
                              Icon(Icons.history, size: 64, color: Colors.grey[400]),
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
                                    return _buildActividadCard(actividad);
                                  },
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                                  itemCount: _actividadesFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final actividad = _actividadesFiltradas[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _buildActividadCard(actividad),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildActividadCard(Actividad actividad) {
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
            builder: (context) => DetalleActividadScreen(actividadId: actividad.id),
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
      onMove: () {},
      onLongPress: () {},
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            // Filtro por estado
            Text(
              'Estado',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<EstadoActividad?>(
              segments: [
                const ButtonSegment<EstadoActividad?>(
                  value: null,
                  label: Text('Todos'),
                ),
                ...EstadoActividad.values.map((estado) => ButtonSegment<EstadoActividad?>(
                      value: estado,
                      label: Text(estado.nombre),
                    )),
              ],
              selected: {_filtroEstado},
              onSelectionChanged: (Set<EstadoActividad?> newSelection) {
                setState(() {
                  _filtroEstado = newSelection.first;
                  _aplicarFiltros();
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            
            // Filtros de fecha
            Text(
              'Fechas',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarFechaDesde,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_fechaDesde != null
                        ? '${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}'
                        : 'Desde'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarFechaHasta,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_fechaHasta != null
                        ? '${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}'
                        : 'Hasta'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Botón limpiar
            FilledButton(
              onPressed: () {
                setState(() {
                  _filtroEstado = null;
                  _fechaDesde = null;
                  _fechaHasta = null;
                  _aplicarFiltros();
                });
                Navigator.pop(context);
              },
              child: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

