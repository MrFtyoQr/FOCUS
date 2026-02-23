import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/estancias_api.dart';
import 'estancia_detail_screen.dart';

/// Lista de estancias del usuario (propias + donde es miembro). Blueprint: GET /estancias.
class EstanciasListScreen extends StatefulWidget {
  const EstanciasListScreen({super.key});

  @override
  State<EstanciasListScreen> createState() => _EstanciasListScreenState();
}

class _EstanciasListScreenState extends State<EstanciasListScreen> {
  final EstanciasApi _api = EstanciasApi();
  bool _loading = true;
  String? _error;
  List<EstanciaResponse> _estancias = [];

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
      final list = await _api.list();
      if (!mounted) return;
      setState(() {
        _estancias = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis estancias'),
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
              : _estancias.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes estancias',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _estancias.length,
                        itemBuilder: (context, index) {
                          final e = _estancias[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.meeting_room),
                              ),
                              title: Text(e.nombre),
                              subtitle: e.descripcion != null && e.descripcion!.isNotEmpty
                                  ? Text(e.descripcion!)
                                  : null,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EstanciaDetailScreen(estanciaId: e.id, nombre: e.nombre),
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
