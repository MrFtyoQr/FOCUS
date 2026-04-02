import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Valor inicial; en runtime `main.dart` lo sobrescribe con prefs (override).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
