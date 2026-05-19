import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dayMonth     = DateFormat('dd/MM');
  static final _dayMonthYear = DateFormat('dd/MM/yyyy');
  static final _full         = DateFormat('EEEE d \'de\' MMMM', 'es');
  static final _iso          = DateFormat('yyyy-MM-dd');

  /// "15/03" — sin año, para tablero compacto
  static String shortDate(DateTime date) => _dayMonth.format(date);

  /// "15/03/2026"
  static String fullDate(DateTime date) => _dayMonthYear.format(date);

  /// "lunes 15 de marzo"
  static String humanDate(DateTime date) => _full.format(date);

  /// "2026-03-15" — para enviar al backend
  static String isoDate(DateTime date) => _iso.format(date);

  /// Relativo: "hoy", "mañana", "ayer", o la fecha completa
  static String relative(DateTime date) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    final diff  = d.difference(today).inDays;

    if (diff == 0) return 'hoy';
    if (diff == 1) return 'mañana';
    if (diff == -1) return 'ayer';
    if (diff > 1 && diff < 7) return 'en $diff días';
    return fullDate(date);
  }

  /// Devuelve true si la fecha ya pasó (vencida)
  static bool isOverdue(DateTime date) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return DateTime(date.year, date.month, date.day).isBefore(today);
  }
}
