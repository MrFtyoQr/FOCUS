import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../models/models.dart';

/// Servicio para gestionar notificaciones programadas
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos en Android 13+
    if (await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>() != null) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Procesar según el ID de la notificación
    final id = response.id;
    if (id == 1) {
      // Notificación 8 AM - se procesa automáticamente al dispararse
      procesarNotificacion8AM();
    } else if (id == 2) {
      // Notificación 1 PM - solo mostrar info
      procesarNotificacion1PM();
    } else if (id == 3) {
      // Notificación 9 PM - solo mostrar info
      procesarNotificacion9PM();
    }
  }

  /// Programar notificaciones diarias
  Future<void> programarNotificacionesDiarias() async {
    try {
      await initialize();

      // Cancelar notificaciones anteriores
      await _notifications.cancelAll();

      // 8:00 AM - Actividades de Mañana no completadas → mover a Hoy
      await _programarNotificacion8AM();

      // 1:00 PM - Actividades pendientes en Hoy
      await _programarNotificacion1PM();

      // 9:00 PM - Actividades pendientes en Hoy para ajustar
      await _programarNotificacion9PM();
    } catch (e) {
      // Si falla la programación, no bloquear la app
      print('Error al programar notificaciones: $e');
    }
  }

  /// Notificación 8 AM: Mover actividades de Mañana no completadas a Hoy
  Future<void> _programarNotificacion8AM() async {
    final ahora = DateTime.now();
    final hora8AM = DateTime(ahora.year, ahora.month, ahora.day, 8, 0);
    
    // Si ya pasaron las 8 AM hoy, programar para mañana
    final fechaNotificacion = hora8AM.isBefore(ahora) 
        ? hora8AM.add(const Duration(days: 1))
        : hora8AM;

    await _notifications.zonedSchedule(
      1,
      'Revisión Matutina',
      'Revisando actividades de ayer...',
      tz.TZDateTime.from(fechaNotificacion, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'revision_matutina',
          'Revisión Matutina',
          channelDescription: 'Notificaciones de revisión matutina de actividades',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Notificación 1 PM: Actividades pendientes en Hoy
  Future<void> _programarNotificacion1PM() async {
    final ahora = DateTime.now();
    final hora1PM = DateTime(ahora.year, ahora.month, ahora.day, 13, 0);
    
    final fechaNotificacion = hora1PM.isBefore(ahora) 
        ? hora1PM.add(const Duration(days: 1))
        : hora1PM;

    await _notifications.zonedSchedule(
      2,
      'Revisión de Mediodía',
      'Tienes actividades pendientes en Hoy',
      tz.TZDateTime.from(fechaNotificacion, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'revision_mediodia',
          'Revisión de Mediodía',
          channelDescription: 'Notificaciones de revisión de mediodía',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Notificación 9 PM: Actividades pendientes en Hoy para ajustar
  Future<void> _programarNotificacion9PM() async {
    final ahora = DateTime.now();
    final hora9PM = DateTime(ahora.year, ahora.month, ahora.day, 21, 0);
    
    final fechaNotificacion = hora9PM.isBefore(ahora) 
        ? hora9PM.add(const Duration(days: 1))
        : hora9PM;

    await _notifications.zonedSchedule(
      3,
      'Revisión Nocturna',
      'Ajusta las actividades pendientes de hoy',
      tz.TZDateTime.from(fechaNotificacion, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'revision_nocturna',
          'Revisión Nocturna',
          channelDescription: 'Notificaciones de revisión nocturna',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Procesar notificación 8 AM: Mover actividades de Mañana a Hoy
  Future<void> procesarNotificacion8AM() async {
    try {
      final db = DatabaseService().database;
      
      // Obtener actividades de "Mañana" que no se completaron
      final actividadesManana = await db.getActividadesPorEstado(EstadoActividad.manana);
      
      if (actividadesManana.isEmpty) {
        // No hay actividades para mover
        await _mostrarNotificacion(
          'Revisión Matutina',
          'No hay actividades pendientes de ayer',
        );
        return;
      }

      int movidas = 0;
      for (var actividad in actividadesManana) {
        // Mover a Hoy
        final actividadActualizada = Actividad(
          id: actividad.id,
          titulo: actividad.titulo,
          descripcion: actividad.descripcion,
          estado: EstadoActividad.hoy,
          proyectoId: actividad.proyectoId,
          personaAsignadaId: actividad.personaAsignadaId,
          fechaObjetivo: actividad.fechaObjetivo,
          createdAt: actividad.createdAt,
          updatedAt: DateTime.now(),
          tieneAdjuntos: actividad.tieneAdjuntos,
          orden: actividad.orden,
        );
        
        await db.actualizarActividad(actividadActualizada);
        
        // Registrar en bitácora
        final evento = BitacoraEvento(
          id: const Uuid().v4(),
          actividadId: actividad.id,
          tipo: TipoEvento.move,
          descripcion: 'Movida automáticamente de Mañana a Hoy',
          timestamp: DateTime.now(),
          usuarioId: null,
        );
        await db.insertarEventoBitacora(evento);
        
        movidas++;
      }

      await _mostrarNotificacion(
        'Revisión Matutina',
        movidas > 0 
            ? '$movidas actividad${movidas > 1 ? 'es' : ''} movida${movidas > 1 ? 's' : ''} a Hoy'
            : 'No hay actividades pendientes',
      );
    } catch (e) {
      await _mostrarNotificacion(
        'Error en Revisión Matutina',
        'Error al procesar actividades: $e',
      );
    }
  }

  /// Procesar notificación 1 PM: Mostrar actividades pendientes en Hoy
  Future<void> procesarNotificacion1PM() async {
    try {
      final db = DatabaseService().database;
      final actividadesHoy = await db.getActividadesPorEstado(EstadoActividad.hoy);
      
      if (actividadesHoy.isEmpty) {
        await _mostrarNotificacion(
          'Revisión de Mediodía',
          '¡Excelente! No tienes actividades pendientes',
        );
      } else {
        await _mostrarNotificacion(
          'Revisión de Mediodía',
          'Tienes ${actividadesHoy.length} actividad${actividadesHoy.length > 1 ? 'es' : ''} pendiente${actividadesHoy.length > 1 ? 's' : ''} en Hoy',
        );
      }
    } catch (e) {
      await _mostrarNotificacion(
        'Error en Revisión de Mediodía',
        'Error al revisar actividades: $e',
      );
    }
  }

  /// Procesar notificación 9 PM: Mostrar actividades pendientes para ajustar
  Future<void> procesarNotificacion9PM() async {
    try {
      final db = DatabaseService().database;
      final actividadesHoy = await db.getActividadesPorEstado(EstadoActividad.hoy);
      
      if (actividadesHoy.isEmpty) {
        await _mostrarNotificacion(
          'Revisión Nocturna',
          '¡Perfecto! Completaste todas las actividades de hoy',
        );
      } else {
        await _mostrarNotificacion(
          'Revisión Nocturna',
          'Aún tienes ${actividadesHoy.length} actividad${actividadesHoy.length > 1 ? 'es' : ''} pendiente${actividadesHoy.length > 1 ? 's' : ''}. ¿Las mueves a Mañana?',
        );
      }
    } catch (e) {
      await _mostrarNotificacion(
        'Error en Revisión Nocturna',
        'Error al revisar actividades: $e',
      );
    }
  }

  /// Mostrar una notificación inmediata
  Future<void> _mostrarNotificacion(String titulo, String cuerpo) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      titulo,
      cuerpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'notificaciones_generales',
          'Notificaciones Generales',
          channelDescription: 'Notificaciones generales de la app',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Probar notificaciones inmediatamente (para testing)
  Future<void> probarNotificacion8AM() async {
    await procesarNotificacion8AM();
  }

  Future<void> probarNotificacion1PM() async {
    await procesarNotificacion1PM();
  }

  Future<void> probarNotificacion9PM() async {
    await procesarNotificacion9PM();
  }

  /// Mostrar notificación de prueba inmediata
  Future<void> mostrarNotificacionPrueba(String tipo) async {
    String titulo = '';
    String cuerpo = '';
    
    switch (tipo) {
      case '8am':
        titulo = 'Revisión Matutina (Prueba)';
        cuerpo = 'Esta es una notificación de prueba para las 8 AM';
        break;
      case '1pm':
        titulo = 'Revisión de Mediodía (Prueba)';
        cuerpo = 'Esta es una notificación de prueba para la 1 PM';
        break;
      case '9pm':
        titulo = 'Revisión Nocturna (Prueba)';
        cuerpo = 'Esta es una notificación de prueba para las 9 PM';
        break;
    }
    
    await _mostrarNotificacion(titulo, cuerpo);
  }

}

