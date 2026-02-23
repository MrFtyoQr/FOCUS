import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/estancias_api.dart';

/// Detalle de una estancia: miembros, proyectos (enlace). Blueprint: GET /estancias/{id}, GET /estancias/{id}/miembros.
class EstanciaDetailScreen extends StatelessWidget {
  const EstanciaDetailScreen({
    super.key,
    required this.estanciaId,
    required this.nombre,
  });

  final int estanciaId;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
      ),
      body: FutureBuilder<List<MiembroEstanciaResponse>>(
        future: EstanciasApi().listarMiembros(estanciaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      snapshot.error is DioException
                          ? (snapshot.error as DioException).message ?? 'Error'
                          : snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final miembros = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Miembros (${miembros.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (miembros.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No hay miembros en esta estancia')),
                )
              else
                ...miembros.map(
                  (m) {
                    final nombreCompleto =
                        (m.apellido != null ? '${m.nombre} ${m.apellido}' : m.nombre).trim();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (nombreCompleto.isNotEmpty ? nombreCompleto[0] : m.email[0]).toUpperCase(),
                          ),
                        ),
                        title: Text(nombreCompleto.isEmpty ? m.email : nombreCompleto),
                        subtitle: Text('${m.email} • ${m.rolEnEstancia}'),
                        trailing: Chip(
                          label: Text(m.rolEnEstancia),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
