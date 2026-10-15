import 'package:flutter/material.dart' show DateUtils, IconData;

import 'constantes.dart';
import 'formato.dart';

class Periodo {
  const Periodo({
    this.id,
    required this.nombre,
    required this.inicio,
    this.fin,
  });

  factory Periodo.fromJson(Map<String, dynamic> j) => Periodo(
    id: j['id'] as int,
    nombre: j['nombre'] as String,
    inicio: DateTime.parse(j['inicio'] as String),
    fin: j['fin'] == null ? null : DateTime.parse(j['fin'] as String),
  );

  final int? id;
  final String nombre;
  final DateTime inicio;

  /// null mientras el período sigue abierto.
  final DateTime? fin;

  bool get abierto => fin == null;

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'inicio': fechaIso(inicio),
    'fin': fin == null ? null : fechaIso(fin!),
  };

  bool contiene(DateTime fecha) {
    final d = DateUtils.dateOnly(fecha);
    return !d.isBefore(inicio) && (fin == null || !d.isAfter(fin!));
  }

  /// `Desde 04/10/2026 · en curso` o `04/10/2026 al 03/11/2026`.
  String get rango => fin == null
      ? 'Desde ${fechaLarga(inicio)} · en curso'
      : '${fechaLarga(inicio)} al ${fechaLarga(fin!)}';

  /// `04/10 – en curso` o `04/10 – 03/11`.
  String get rangoCorto =>
      '${fechaCorta(inicio)} – ${fin == null ? 'en curso' : fechaCorta(fin!)}';
}

class Categoria {
  const Categoria({this.id, required this.nombre, required this.icono});

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
    id: j['id'] as int,
    nombre: j['nombre'] as String,
    icono: j['icono'] as String,
  );

  final int? id;
  final String nombre;

  /// Clave de [iconosCategoria].
  final String icono;

  IconData get iconData => iconoCategoria(icono);

  Map<String, dynamic> toJson() => {'nombre': nombre, 'icono': icono};
}

class Gasto {
  const Gasto({
    this.id,
    required this.fecha,
    required this.descripcion,
    required this.monto,
    required this.formaPago,
    required this.categoriaId,
  });

  factory Gasto.fromJson(Map<String, dynamic> j) => Gasto(
    id: j['id'] as int,
    fecha: DateTime.parse(j['fecha'] as String),
    descripcion: j['descripcion'] as String,
    monto: (j['monto'] as num).toDouble(),
    formaPago: j['forma_pago'] as String,
    categoriaId: j['categoria_id'] as int,
  );

  final int? id;
  final DateTime fecha;
  final String descripcion;
  final double monto;
  final String formaPago;
  final int categoriaId;

  Medio get medio => formasPago[formaPago] ?? Medio.cuenta;

  Map<String, dynamic> toJson() => {
    'fecha': fechaIso(fecha),
    'descripcion': descripcion,
    'monto': monto,
    'forma_pago': formaPago,
    'categoria_id': categoriaId,
  };
}

/// Movimiento de plata de un período: un ingreso, un retiro o depósito entre
/// la cuenta y el efectivo, o una compra de dólares.
class Movimiento {
  const Movimiento({
    this.id,
    required this.periodoId,
    required this.fecha,
    required this.tipo,
    required this.medio,
    required this.monto,
    this.usd,
    this.nota,
  });

  factory Movimiento.fromJson(Map<String, dynamic> j) => Movimiento(
    id: j['id'] as int,
    periodoId: j['periodo_id'] as int,
    fecha: DateTime.parse(j['fecha'] as String),
    tipo: TipoMovimiento.desde(j['tipo'] as String),
    medio: Medio.desde(j['medio'] as String),
    monto: (j['monto'] as num).toDouble(),
    usd: (j['usd'] as num?)?.toDouble(),
    nota: j['nota'] as String?,
  );

  final int? id;
  final int periodoId;
  final DateTime fecha;
  final TipoMovimiento tipo;

  /// Dónde entró un ingreso, o con qué se pagaron los dólares.
  /// En retiros y depósitos lo define el tipo.
  final Medio medio;

  /// En pesos.
  final double monto;

  /// Dólares comprados (solo en [TipoMovimiento.dolares]).
  final double? usd;
  final String? nota;

  /// Cuánto suma (o resta) este movimiento a la plata disponible en [m].
  double efectoEn(Medio m) => switch (tipo) {
    TipoMovimiento.retiro => m == Medio.efectivo ? monto : -monto,
    TipoMovimiento.deposito => m == Medio.cuenta ? monto : -monto,
    TipoMovimiento.dolares => m == medio ? -monto : 0,
    _ => m == medio ? monto : 0,
  };

  /// `Cuenta → Efectivo`, `US$ 400 a $ 1.530 · Cuenta`, `Efectivo`…
  String get detalle => switch (tipo) {
    TipoMovimiento.retiro => 'Cuenta → Efectivo',
    TipoMovimiento.deposito => 'Efectivo → Cuenta',
    TipoMovimiento.dolares =>
      '${dolares(usd ?? 0)} a ${plata(monto / (usd ?? 1))} · ${medio.label}',
    _ => medio.label,
  };

  Map<String, dynamic> toJson() => {
    'periodo_id': periodoId,
    'fecha': fechaIso(fecha),
    'tipo': tipo.name,
    'medio': medio.name,
    'monto': monto,
    'usd': usd,
    'nota': nota,
  };
}
