/// Tipos de eventos que se registran en la bitácora
enum TipoEvento {
  create,
  move,
  complete,
  assign,
  attach,
  update,
  delete,
}

extension TipoEventoExtension on TipoEvento {
  String get nombre {
    switch (this) {
      case TipoEvento.create:
        return 'Creada';
      case TipoEvento.move:
        return 'Movida';
      case TipoEvento.complete:
        return 'Completada';
      case TipoEvento.assign:
        return 'Asignada';
      case TipoEvento.attach:
        return 'Adjunto agregado';
      case TipoEvento.update:
        return 'Actualizada';
      case TipoEvento.delete:
        return 'Eliminada';
    }
  }
  
  String get icono {
    switch (this) {
      case TipoEvento.create:
        return 'add_circle';
      case TipoEvento.move:
        return 'swap_horiz';
      case TipoEvento.complete:
        return 'check_circle';
      case TipoEvento.assign:
        return 'person';
      case TipoEvento.attach:
        return 'attach_file';
      case TipoEvento.update:
        return 'edit';
      case TipoEvento.delete:
        return 'delete';
    }
  }
}

