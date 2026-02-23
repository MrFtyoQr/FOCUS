import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/api/users_api.dart';
import '../../core/security/secure_storage.dart';

/// Lista de usuarios (GET /api/v1/users). Solo SUPER_ADMIN (backend y app).
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsersApi _api = UsersApi();
  final SecureStorage _storage = SecureStorage();
  bool _loading = true;
  bool _forbidden = false;
  String? _error;
  List<dynamic> _users = const [];

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
      final users = await _api.getUsers(skip: 0, limit: 100);
      if (!mounted) return;
      setState(() {
        _users = users;
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
    if (_forbidden) {
      return Scaffold(
        appBar: AppBar(title: const Text('Usuarios')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Solo los superadministradores pueden ver la lista de usuarios.',
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
        title: const Text('Usuarios'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    final title = '${u.nombre} ${u.apellido ?? ''}'.trim();
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(title.isEmpty ? u.email : title),
                      subtitle: Text('${u.email} • ${u.rol ?? ''}'.trim()),
                    );
                  },
                ),
    );
  }
}

