class AppStringUtils {
  AppStringUtils._();

  /// "john doe" → "John Doe"
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Iniciales: "Juan Pérez" → "JP"
  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Trunca con "…" si supera [maxLength]
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 1)}…';
  }

  /// Elimina espacios extras y normaliza
  static String normalize(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Valida email básico
  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}
