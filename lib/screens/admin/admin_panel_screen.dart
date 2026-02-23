import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/estancias_api.dart';
import '../../data/api/kpis_api.dart';
import '../../data/api/retroalimentacion_api.dart';

/// Panel para ADMIN y SUPER_ADMIN: KPIs y retroalimentación por estancia (conectado al backend).
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final EstanciasApi _estanciasApi = EstanciasApi();
  final KpisApi _kpisApi = KpisApi();
  final RetroalimentacionApi _retroApi = RetroalimentacionApi();

  bool _loadingEstancias = true;
  String? _errorEstancias;
  List<EstanciaResponse> _estancias = [];
  int? _estanciaIdSeleccionada;

  bool _loadingDatos = false;
  String? _errorDatos;
  KpiEstanciaResponse? _kpis;
  List<RetroalimentacionResponse> _retroalimentaciones = [];

  @override
  void initState() {
    super.initState();
    _loadEstancias();
  }

  Future<void> _loadEstancias() async {
    setState(() {
      _loadingEstancias = true;
      _errorEstancias = null;
    });
    try {
      final list = await _estanciasApi.list();
      if (!mounted) return;
      setState(() {
        _estancias = list;
        _loadingEstancias = false;
        if (list.isNotEmpty && _estanciaIdSeleccionada == null) {
          _estanciaIdSeleccionada = list.first.id;
          _loadKpisYRetroalimentacion();
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEstancias = false;
        _errorEstancias = e.response?.data is Map && (e.response!.data as Map)['detail'] != null
            ? (e.response!.data as Map)['detail'].toString()
            : (e.message ?? 'Error de conexión');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEstancias = false;
        _errorEstancias = e.toString();
      });
    }
  }

  Future<void> _loadKpisYRetroalimentacion() async {
    final id = _estanciaIdSeleccionada;
    if (id == null) return;
    setState(() {
      _loadingDatos = true;
      _errorDatos = null;
      _kpis = null;
      _retroalimentaciones = [];
    });
    try {
      final kpis = await _kpisApi.getKpisEstancia(id);
      final retro = await _retroApi.listByEstancia(estanciaId: id);
      if (!mounted) return;
      setState(() {
        _kpis = kpis;
        _retroalimentaciones = retro;
        _loadingDatos = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDatos = false;
        _errorDatos = e.response?.data is Map && (e.response!.data as Map)['detail'] != null
            ? (e.response!.data as Map)['detail'].toString()
            : (e.message ?? 'Error de conexión');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDatos = false;
        _errorDatos = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadEstancias();
              if (_estanciaIdSeleccionada != null) _loadKpisYRetroalimentacion();
            },
          ),
        ],
      ),
      body: _loadingEstancias
          ? const Center(child: CircularProgressIndicator())
          : _errorEstancias != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorEstancias!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadEstancias,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _estancias.isEmpty
                  ? Center(
                      child: Text(
                        'No tienes estancias asignadas. Crea una o únete a una para ver KPIs y retroalimentación.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadEstancias();
                        if (_estanciaIdSeleccionada != null) await _loadKpisYRetroalimentacion();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Selector de estancia
                            DropdownButtonFormField<int>(
                              value: _estanciaIdSeleccionada,
                              decoration: const InputDecoration(
                                labelText: 'Estancia',
                                border: OutlineInputBorder(),
                              ),
                              items: _estancias
                                  .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre)))
                                  .toList(),
                              onChanged: (id) {
                                setState(() => _estanciaIdSeleccionada = id);
                                if (id != null) _loadKpisYRetroalimentacion();
                              },
                            ),
                            const SizedBox(height: 24),
                            if (_loadingDatos)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (_errorDatos != null)
                              Card(
                                color: theme.colorScheme.errorContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(_errorDatos!),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: _loadKpisYRetroalimentacion,
                                        child: const Text('Reintentar'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              // KPIs de la estancia
                              if (_kpis != null) _buildKpiCard(theme, _kpis!),
                              const SizedBox(height: 16),
                              // Retroalimentación
                              Text(
                                'Retroalimentación',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (_retroalimentaciones.isEmpty)
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No hay retroalimentación en esta estancia.',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                )
                              else
                                ..._retroalimentaciones.map((r) => _buildRetroTile(theme, r)),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildKpiCard(ThemeData theme, KpiEstanciaResponse kpi) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'KPIs Estancia',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            if (kpi.resumen != null && kpi.resumen!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(kpi.resumen!, style: theme.textTheme.bodyMedium),
            ],
            if (kpi.metricas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kpi.metricas.entries.map((e) {
                  final v = e.value;
                  final str = v is num ? v.toStringAsFixed(v is double ? 1 : 0) : v.toString();
                  return Chip(
                    label: Text('${e.key}: $str'),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRetroTile(ThemeData theme, RetroalimentacionResponse r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          r.tipo == 'jefe_a_equipo' ? Icons.thumb_up_outlined : Icons.chat_bubble_outline,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          r.anonima ? 'Anónima' : 'Retroalimentación',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.contenido, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (r.fechaCreacion != null)
              Text(
                r.fechaCreacion!,
                style: theme.textTheme.bodySmall,
              ),
            if (r.calificacion != null)
              Text('Calificación: ${r.calificacion}', style: theme.textTheme.bodySmall),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
