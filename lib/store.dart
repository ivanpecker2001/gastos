import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constantes.dart';
import 'formato.dart';
import 'modelos.dart';

/// Error con un mensaje pensado para mostrarle al usuario tal cual.
class Aviso implements Exception {
  const Aviso(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Estado de la app: períodos y categorías del usuario, el período elegido y
/// sus gastos y movimientos. Las filas de otros usuarios las filtra RLS en Supabase.
class GastosStore extends ChangeNotifier {
  SupabaseClient get _db => Supabase.instance.client;

  List<Periodo> periodos = [];
  List<Categoria> categorias = [];
  Periodo? periodo;
  List<Gasto> gastos = [];
  List<Movimiento> movimientos = [];

  /// Dólares comprados en todos los períodos.
  double usdHistorico = 0;
  bool cargando = false;
  Object? error;

  /// El período en curso, si hay uno.
  Periodo? get abierto => periodos.where((p) => p.abierto).firstOrNull;

  /// El período más reciente (los períodos están ordenados del más nuevo al más viejo).
  Periodo? get ultimo => periodos.firstOrNull;

  /// Recarga todo. Mantiene el período elegido (o [periodoId]); si no hay,
  /// elige el que contiene la fecha de hoy o, si ninguno, el más reciente.
  Future<void> cargar({int? periodoId}) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final (filas, cats) = await (
        _db.from('periodos').select().order('inicio', ascending: false),
        _cargarCategorias(),
      ).wait;
      periodos = filas.map(Periodo.fromJson).toList();
      categorias = cats;
      final elegido = periodoId ?? periodo?.id;
      final hoy = DateTime.now();
      periodo =
          periodos.where((p) => p.id == elegido).firstOrNull ??
          periodos.where((p) => p.contiene(hoy)).firstOrNull ??
          periodos.firstOrNull;
      await _cargarDelPeriodo();
    } catch (e) {
      error = e is ParallelWaitError ? e.errors : e;
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> elegir(Periodo p) => cargar(periodoId: p.id);

  /// La primera vez que el usuario entra le crea las categorías iniciales.
  Future<List<Categoria>> _cargarCategorias() async {
    var filas = await _db.from('categorias').select().order('nombre');
    if (filas.isEmpty) {
      filas = await _db
          .from('categorias')
          .insert([
            for (final (nombre, icono) in categoriasIniciales)
              {'nombre': nombre, 'icono': icono},
          ])
          .select()
          .order('nombre');
    }
    return filas.map(Categoria.fromJson).toList();
  }

  Future<void> _cargarDelPeriodo() async {
    final p = periodo;
    if (p == null) {
      gastos = [];
      movimientos = [];
      return;
    }
    var consultaGastos = _db
        .from('gastos')
        .select()
        .gte('fecha', fechaIso(p.inicio));
    if (p.fin != null) {
      consultaGastos = consultaGastos.lte('fecha', fechaIso(p.fin!));
    }
    final (filasGastos, filasMovimientos, compras) = await (
      consultaGastos
          .order('fecha', ascending: false)
          .order('id', ascending: false),
      _db
          .from('movimientos')
          .select()
          .eq('periodo_id', p.id!)
          .order('fecha')
          .order('id'),
      _db
          .from('movimientos')
          .select('usd')
          .eq('tipo', TipoMovimiento.dolares.name),
    ).wait;
    gastos = filasGastos.map(Gasto.fromJson).toList();
    movimientos = filasMovimientos.map(Movimiento.fromJson).toList();
    usdHistorico = _suma(compras.map((c) => (c['usd'] as num).toDouble()));
  }

  Future<void> _refrescar() async {
    await _cargarDelPeriodo();
    notifyListeners();
  }

  // Gastos

  Future<void> guardarGasto(Gasto g) async {
    if (g.id == null) {
      await _db.from('gastos').insert(g.toJson());
    } else {
      await _db.from('gastos').update(g.toJson()).eq('id', g.id!);
    }
    await _refrescar();
  }

  Future<void> borrarGasto(Gasto g) async {
    await _db.from('gastos').delete().eq('id', g.id!);
    await _refrescar();
  }

  // Movimientos

  Future<void> guardarMovimiento(Movimiento m) async {
    if (m.id == null) {
      await _db.from('movimientos').insert(m.toJson());
    } else {
      await _db.from('movimientos').update(m.toJson()).eq('id', m.id!);
    }
    await _refrescar();
  }

  Future<void> borrarMovimiento(Movimiento m) async {
    await _db.from('movimientos').delete().eq('id', m.id!);
    await _refrescar();
  }

  // Períodos

  /// Primer día posible para un período nuevo: el día después del último.
  DateTime? get inicioMinimo {
    final u = ultimo;
    return u == null ? null : (u.fin ?? u.inicio).add(const Duration(days: 1));
  }

  /// Abre un período nuevo. Si hay uno abierto, lo cierra el día anterior.
  Future<void> iniciarPeriodo(String nombre, DateTime inicio) async {
    final anterior = abierto;
    if (anterior != null) {
      await _db
          .from('periodos')
          .update({'fin': fechaIso(inicio.subtract(const Duration(days: 1)))})
          .eq('id', anterior.id!);
    }
    final fila = await _db
        .from('periodos')
        .insert(Periodo(nombre: nombre, inicio: inicio).toJson())
        .select()
        .single();
    await cargar(periodoId: fila['id'] as int);
  }

  Future<void> cerrarPeriodo(Periodo p, DateTime fin) async {
    await _db.from('periodos').update({'fin': fechaIso(fin)}).eq('id', p.id!);
    await cargar(periodoId: p.id);
  }

  Future<void> reabrirPeriodo(Periodo p) async {
    await _db.from('periodos').update({'fin': null}).eq('id', p.id!);
    await cargar(periodoId: p.id);
  }

  Future<void> guardarPeriodo(Periodo p) async {
    await _db.from('periodos').update(p.toJson()).eq('id', p.id!);
    await cargar(periodoId: p.id);
  }

  Future<void> borrarPeriodo(Periodo p) async {
    await _db.from('periodos').delete().eq('id', p.id!);
    periodo = null;
    await cargar();
  }

  // Categorías

  Categoria? categoria(int id) =>
      categorias.where((c) => c.id == id).firstOrNull;

  String nombreCategoria(int id) => categoria(id)?.nombre ?? 'Sin categoría';

  Future<void> guardarCategoria(Categoria c) async {
    try {
      if (c.id == null) {
        await _db.from('categorias').insert(c.toJson());
      } else {
        await _db.from('categorias').update(c.toJson()).eq('id', c.id!);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Aviso('Ya existe una categoría «${c.nombre}»');
      }
      rethrow;
    }
    await cargar();
  }

  Future<void> borrarCategoria(Categoria c) async {
    try {
      await _db.from('categorias').delete().eq('id', c.id!);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw Aviso(
          '«${c.nombre}» tiene gastos cargados. '
          'Cambiales la categoría antes de borrarla.',
        );
      }
      rethrow;
    }
    await cargar();
  }

  // Totales del período elegido

  Iterable<Movimiento> get _ingresos =>
      movimientos.where((m) => m.tipo.esIngreso);
  Iterable<Movimiento> get _compras =>
      movimientos.where((m) => m.tipo == TipoMovimiento.dolares);

  double get totalCobrado => _suma(_ingresos.map((m) => m.monto));
  double get totalGastado => _suma(gastos.map((g) => g.monto));

  /// Pesos usados para comprar dólares en el período.
  double get totalDolaresArs => _suma(_compras.map((m) => m.monto));
  double get totalUsd => _suma(_compras.map((m) => m.usd ?? 0));

  double get restanteTotal => totalCobrado - totalGastado - totalDolaresArs;

  double cobrado(Medio medio) =>
      _suma(_ingresos.where((m) => m.medio == medio).map((m) => m.monto));

  /// Lo que entró a cada medio: lo cobrado, más o menos retiros y depósitos,
  /// menos lo usado para comprar dólares.
  double disponible(Medio medio) =>
      _suma(movimientos.map((m) => m.efectoEn(medio)));
  double gastado(Medio m) =>
      _suma(gastos.where((g) => g.medio == m).map((g) => g.monto));
  double restante(Medio m) => disponible(m) - gastado(m);

  /// Total gastado agrupado por [clave], de mayor a menor.
  List<MapEntry<String, double>> totalesPor(String Function(Gasto) clave) {
    final totales = <String, double>{};
    for (final g in gastos) {
      totales.update(clave(g), (v) => v + g.monto, ifAbsent: () => g.monto);
    }
    return totales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  static double _suma(Iterable<double> montos) =>
      montos.fold(0, (s, m) => s + m);
}
