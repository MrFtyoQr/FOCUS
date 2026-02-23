import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/invitaciones_api.dart';
import 'estancia_detail_screen.dart';

/// Invitaciones pendientes (estancias a las que fue invitado). Blueprint: GET /invitaciones/pendientes.
class InvitacionesPendientesScreen extends StatefulWidget {
  const InvitacionesPendientesScreen({super.key});

  @override
  State<InvitacionesPendientesScreen> createState() => _InvitacionesPendientesScreenState();
}

class _InvitacionesPendientesScreenState extends State<InvitacionesPendientesScreen> {
  final InvitacionesApi _api = InvitacionesApi();
  bool _loading = true;
  String? _error;
  List<InvitacionConDetalle> _invitaciones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.listarPendientes();
      if (!mounted) return;
      setState(() {
        _invitaciones = list;
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

  Future<void> _aceptar(int id) async {
    try {
      await _api.aceptar(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitación aceptada')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rechazar(int id) async {
    try {
      await _api.rechazar(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitación rechazada')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitaciones pendientes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _invitaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes invitaciones pendientes',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _invitaciones.length,
                        itemBuilder: (context, index) {
                          final inv = _invitaciones[index];
                          final estanciaNombre = inv.estanciaNombre ?? 'Estancia #${inv.estanciaId}';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.mail),
                              ),
                              title: Text(estanciaNombre),
                              subtitle: Text(
                                inv.invitadoPor != null
                                    ? 'Invitado por: ${inv.invitadoPor!.displayName}'
                                    : 'Rol: ${inv.rolAsignado}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _rechazar(inv.id),
                                    child: const Text('Rechazar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => _aceptar(inv.id),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EstanciaDetailScreen(
                                      estanciaId: inv.estanciaId,
                                      nombre: estanciaNombre,
                                    ),
                                  ),
                                ).then((_) => _load());
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
