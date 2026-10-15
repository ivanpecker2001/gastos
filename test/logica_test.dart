import 'package:flutter_test/flutter_test.dart';
import 'package:gastos/constantes.dart';
import 'package:gastos/formato.dart';
import 'package:gastos/modelos.dart';
import 'package:gastos/store.dart';

void main() {
  test('parseMonto entiende el formato argentino', () {
    expect(parseMonto('6.500'), 6500);
    expect(parseMonto(r'$ 10.000'), 10000);
    expect(parseMonto('1.234,5'), 1234.5);
    expect(parseMonto('800'), 800);
    expect(parseMonto('abc'), isNull);
  });

  test('montoEditable y plata', () {
    expect(montoEditable(6500), '6500');
    expect(montoEditable(12.5), '12,5');
    expect(plata(1610942), '\$ 1.610.942');
  });

  test('nombre sugerido según el mes donde cae la mayor parte', () {
    expect(nombreSugerido(DateTime(2026, 10, 4)), 'Octubre');
    expect(nombreSugerido(DateTime(2026, 10, 28)), 'Noviembre');
    expect(nombreSugerido(DateTime(2026, 12, 20)), 'Enero');
  });

  test(
    'Periodo.contiene: cerrado incluye los extremos, abierto no tiene fin',
    () {
      final cerrado = Periodo(
        nombre: 'Octubre',
        inicio: DateTime(2026, 10, 4),
        fin: DateTime(2026, 11, 3),
      );
      expect(cerrado.contiene(DateTime(2026, 10, 4, 23, 59)), isTrue);
      expect(cerrado.contiene(DateTime(2026, 11, 3, 10)), isTrue);
      expect(cerrado.contiene(DateTime(2026, 10, 3)), isFalse);
      expect(cerrado.contiene(DateTime(2026, 11, 4)), isFalse);

      final abierto = Periodo(
        nombre: 'Noviembre',
        inicio: DateTime(2026, 11, 4),
      );
      expect(abierto.abierto, isTrue);
      expect(abierto.contiene(DateTime(2027, 3, 1)), isTrue);
      expect(abierto.contiene(DateTime(2026, 11, 3)), isFalse);
      expect(abierto.toJson()['fin'], isNull);
    },
  );

  test('inicioMinimo es el día después del último período', () {
    final s = GastosStore();
    expect(s.inicioMinimo, isNull);
    s.periodos = [
      Periodo(id: 1, nombre: 'Octubre', inicio: DateTime(2026, 10, 4)),
    ];
    expect(s.abierto?.id, 1);
    expect(s.inicioMinimo, DateTime(2026, 10, 5));
    s.periodos = [
      Periodo(
        id: 1,
        nombre: 'Octubre',
        inicio: DateTime(2026, 10, 4),
        fin: DateTime(2026, 11, 3),
      ),
    ];
    expect(s.abierto, isNull);
    expect(s.inicioMinimo, DateTime(2026, 11, 4));
  });

  test('lo que queda: ingresos, retiros, depósitos y dólares por medio', () {
    final hoy = DateTime(2026, 10, 15);
    Gasto gasto(double monto, String forma, int cat) => Gasto(
      fecha: hoy,
      descripcion: 'x',
      monto: monto,
      formaPago: forma,
      categoriaId: cat,
    );
    Movimiento mov(
      TipoMovimiento tipo,
      double monto, {
      Medio medio = Medio.cuenta,
      double? usd,
    }) => Movimiento(
      periodoId: 1,
      fecha: hoy,
      tipo: tipo,
      medio: medio,
      monto: monto,
      usd: usd,
    );
    final s = GastosStore()
      ..categorias = const [
        Categoria(id: 1, nombre: 'Deporte', icono: 'sports_tennis'),
        Categoria(id: 2, nombre: 'Salidas a comer', icono: 'restaurant'),
      ]
      ..movimientos = [
        mov(TipoMovimiento.blanco, 1000000),
        mov(TipoMovimiento.negro, 200000, medio: Medio.efectivo),
        mov(TipoMovimiento.extra, 50000, medio: Medio.efectivo),
        mov(TipoMovimiento.retiro, 100000, medio: Medio.efectivo),
        mov(TipoMovimiento.deposito, 30000, medio: Medio.cuenta),
        mov(TipoMovimiento.dolares, 153000, usd: 100),
      ]
      ..gastos = [
        gasto(6500, 'Efectivo', 1),
        gasto(9500, 'Mercado Pago', 2),
        gasto(500, 'BNA', 1),
        gasto(100, 'Mercado Pago', 99),
      ];

    expect(s.totalCobrado, 1250000);
    expect(s.totalGastado, 16600);
    expect(s.totalDolaresArs, 153000);
    expect(s.totalUsd, 100);
    expect(s.restanteTotal, 1250000 - 16600 - 153000);
    // Cuenta: 1.000.000 - 100.000 retiro + 30.000 depósito - 153.000 dólares - 10.100 gastos
    expect(s.restante(Medio.cuenta), 766900);
    // Efectivo: 250.000 + 100.000 retiro - 30.000 depósito - 6.500 gastos
    expect(s.restante(Medio.efectivo), 313500);
    expect(
      s.restante(Medio.cuenta) + s.restante(Medio.efectivo),
      s.restanteTotal,
    );
    final porCategoria = s.totalesPor((g) => s.nombreCategoria(g.categoriaId));
    expect(porCategoria.map((e) => e.key), [
      'Salidas a comer',
      'Deporte',
      'Sin categoría',
    ]);
    expect(porCategoria[1].value, 7000);
  });

  test('detalle de una compra de dólares', () {
    final m = Movimiento(
      periodoId: 1,
      fecha: DateTime(2026, 10, 5),
      tipo: TipoMovimiento.dolares,
      medio: Medio.cuenta,
      monto: 612000,
      usd: 400,
    );
    expect(m.detalle, r'US$ 400 a $ 1.530 · Cuenta');
  });
}
