import 'package:flutter/material.dart';
import '../models/models.dart';

/// Bottom sheet para mover una actividad entre estados
class MoverActividadBottomSheet extends StatelessWidget {
  final Actividad actividad;
  final Function(EstadoActividad nuevoEstado) onMover;

  const MoverActividadBottomSheet({
    super.key,
    required this.actividad,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    final estadosDisponibles = [
      EstadoActividad.bandeja,
      EstadoActividad.hoy,
      EstadoActividad.manana,
      EstadoActividad.programado,
      EstadoActividad.pendientes,
    ].where((estado) => estado != actividad.estado).toList();

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Título
          Text(
            'Mover actividad',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            actividad.titulo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          // Estados disponibles
          Text(
            'Mover a:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          ...estadosDisponibles.map((estado) {
            return _buildOpcionEstado(context, estado);
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOpcionEstado(BuildContext context, EstadoActividad estado) {
    final color = _getEstadoColor(estado);
    final icon = _getEstadoIcon(estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          estado.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          estado.descripcion,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () {
          Navigator.pop(context);
          onMover(estado);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getEstadoColor(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Colors.grey;
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
    }
  }

  IconData _getEstadoIcon(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Icons.inbox;
      case EstadoActividad.hoy:
        return Icons.today;
      case EstadoActividad.manana:
        return Icons.event;
      case EstadoActividad.programado:
        return Icons.calendar_today;
      case EstadoActividad.pendientes:
        return Icons.pause_circle;
      case EstadoActividad.completada:
        return Icons.check_circle;
    }
  }
}

/// Función helper para mostrar el bottom sheet
Future<void> mostrarMoverActividadBottomSheet(
  BuildContext context,
  Actividad actividad,
  Function(EstadoActividad nuevoEstado) onMover,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MoverActividadBottomSheet(
      actividad: actividad,
      onMover: onMover,
    ),
  );
}

