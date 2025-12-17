import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Servicio para gestionar archivos de la aplicación
class FileService {
  static final FileService _instance = FileService._internal();
  
  factory FileService() {
    return _instance;
  }
  
  FileService._internal();

  /// Obtiene el directorio base para archivos de la app
  Future<Directory> getAppFilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filesDir = Directory(p.join(appDir.path, 'hipperapp_files'));
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    return filesDir;
  }

  /// Obtiene el directorio para una actividad específica
  Future<Directory> getActividadDirectory(String actividadId) async {
    final filesDir = await getAppFilesDirectory();
    final actividadDir = Directory(p.join(filesDir.path, 'actividades', actividadId));
    if (!await actividadDir.exists()) {
      await actividadDir.create(recursive: true);
    }
    return actividadDir;
  }

  /// Copia un archivo al directorio de la actividad
  Future<String> copiarArchivoAActividad(String actividadId, String archivoOrigen) async {
    final actividadDir = await getActividadDirectory(actividadId);
    final archivo = File(archivoOrigen);
    final nombreArchivo = p.basename(archivo.path);
    final archivoDestino = File(p.join(actividadDir.path, nombreArchivo));
    
    // Si el archivo ya existe, agregar timestamp
    if (await archivoDestino.exists()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreSinExtension = p.basenameWithoutExtension(archivo.path);
      final extension = p.extension(archivo.path);
      final nuevoNombre = '$nombreSinExtension\_$timestamp$extension';
      final nuevoArchivoDestino = File(p.join(actividadDir.path, nuevoNombre));
      await archivo.copy(nuevoArchivoDestino.path);
      return nuevoArchivoDestino.path;
    } else {
      await archivo.copy(archivoDestino.path);
      return archivoDestino.path;
    }
  }

  /// Obtiene todos los archivos de una actividad
  Future<List<File>> getArchivosDeActividad(String actividadId) async {
    try {
      final actividadDir = await getActividadDirectory(actividadId);
      if (!await actividadDir.exists()) {
        return [];
      }
      final archivos = actividadDir.listSync()
          .where((item) => item is File)
          .cast<File>()
          .toList();
      return archivos;
    } catch (e) {
      return [];
    }
  }

  /// Elimina un archivo de una actividad
  Future<bool> eliminarArchivo(String rutaArchivo) async {
    try {
      final archivo = File(rutaArchivo);
      if (await archivo.exists()) {
        await archivo.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Selecciona una imagen de la galería
  Future<String?> seleccionarImagen() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
      return imagen?.path;
    } catch (e) {
      return null;
    }
  }

  /// Selecciona un archivo
  Future<String?> seleccionarArchivo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

