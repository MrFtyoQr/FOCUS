import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/auditoria_api.dart';
import '../../core/security/secure_storage.dart';

/// Bitácora (GET /api/v1/auditoria). Solo SUPER_ADMIN (backend y app).
class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final AuditoriaApi _api = AuditoriaApi();
  final SecureStorage _storage = SecureStorage();
  bool _loading = true;
  bool _forbidden = false;
  String? _error;
  List<AuditoriaEntry> _entries = const [];

  int? _filterUsuarioId;
  String _filterAccion = '';
  String _filterEntidad = '';
  DateTime? _filterDesde;
  DateTime? _filterHasta;

  @override
  void initState() {
    super.initState();
    _checkRolAndLoad();
  }

  Future<void> _checkRolAndLoad() async {
    final rol = await _storage.getUserRol();
    if (!mounted) return;
    if ((rol ?? '').trim() != 'SUPER_ADMIN') {
      setState(() {
        _loading = false;
        _forbidden = true;
      });
      return;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final desdeStr = _filterDesde != null
          ? DateTime(_filterDesde!.year, _filterDesde!.month, _filterDesde!.day)
              .toUtc()
              .toIso8601String()
          : null;
      final hastaStr = _filterHasta != null
          ? DateTime(_filterHasta!.year, _filterHasta!.month, _filterHasta!.day, 23, 59, 59)
              .toUtc()
              .toIso8601String()
          : null;
      final entries = await _api.getAuditoria(
        skip: 0,
        limit: 100,
        usuarioId: _filterUsuarioId,
        accion: _filterAccion.isEmpty ? null : _filterAccion,
        entidad: _filterEntidad.isEmpty ? null : _filterEntidad,
        desde: desdeStr,
        hasta: hastaStr,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = (e.response?.data is Map && (e.response!.data as Map)['detail'] != null)
            ? (e.response!.data as Map)['detail'].toString()
            : (e.message ?? 'Error de conexión');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _showFilters() {
    final usuarioController = TextEditingController(
      text: _filterUsuarioId?.toString() ?? '',
    );
    final accionController = TextEditingController(text: _filterAccion);
    final entidadController = TextEditingController(text: _filterEntidad);
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Filtros'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: usuarioController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario ID',
                    hintText: 'Opcional',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: accionController,
                  decoration: const InputDecoration(
                    labelText: 'Acción',
                    hintText: 'Opcional',
                  ),
                ),
                TextField(
                  controller: entidadController,
                  decoration: const InputDecoration(
                    labelText: 'Entidad',
                    hintText: 'Opcional',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    _filterDesde == null
                        ? 'Desde (fecha)'
                        : 'Desde: ${_filterDesde!.day}/${_filterDesde!.month}/${_filterDesde!.year}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _filterDesde ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setDialogState(() => _filterDesde = d);
                    },
                  ),
                ),
                ListTile(
                  title: Text(
                    _filterHasta == null
                        ? 'Hasta (fecha)'
                        : 'Hasta: ${_filterHasta!.day}/${_filterHasta!.month}/${_filterHasta!.year}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _filterHasta ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setDialogState(() => _filterHasta = d);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterUsuarioId = null;
                  _filterAccion = '';
                  _filterEntidad = '';
                  _filterDesde = null;
                  _filterHasta = null;
                });
                Navigator.of(ctx).pop();
                _load();
              },
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final uid = int.tryParse(usuarioController.text.trim());
                setState(() {
                  _filterUsuarioId = uid;
                  _filterAccion = accionController.text.trim();
                  _filterEntidad = entidadController.text.trim();
                });
                Navigator.of(ctx).pop();
                _load();
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_forbidden) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auditoría')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Solo los superadministradores pueden ver la auditoría.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría'),
        actions: [
          IconButton(onPressed: _showFilters, icon: const Icon(Icons.filter_list)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    final subtitle = [
                      if (e.entidad != null) e.entidad,
                      if (e.entidadId != null) '#${e.entidadId}',
                      if (e.usuarioId != null) 'u:${e.usuarioId}',
                      if (e.timestamp != null) e.timestamp,
                    ].whereType<String>().join(' • ');
                    return ListTile(
                      leading: Icon(
                        e.exitoso ? Icons.check_circle_outline : Icons.error_outline,
                        color: e.exitoso ? Colors.green : Colors.red,
                      ),
                      title: Text(e.accion),
                      subtitle: Text(subtitle),
                      trailing: e.nivel != null ? Text(e.nivel!) : null,
                    );
                  },
                ),
    );
  }
}

