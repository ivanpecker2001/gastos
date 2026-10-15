import 'package:intl/intl.dart';

final _plata = NumberFormat.currency(
  locale: 'es_AR',
  symbol: r'$',
  customPattern: '¤ #,##0',
  decimalDigits: 0,
);
final _iso = DateFormat('yyyy-MM-dd');
final _corta = DateFormat('dd/MM');
final _larga = DateFormat('dd/MM/yyyy');

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', //
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];
const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

/// `$ 6.500`
String plata(double v) => _plata.format(v);

String fechaIso(DateTime d) => _iso.format(d);
String fechaCorta(DateTime d) => _corta.format(d);
String fechaLarga(DateTime d) => _larga.format(d);
String diaSemana(DateTime d) => _dias[d.weekday - 1];

/// Interpreta montos escritos como en Argentina: `6.500`, `1.234,50`, `$ 800`.
double? parseMonto(String texto) {
  final limpio = texto
      .replaceAll(RegExp(r'[\s$]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(limpio);
}

/// Monto listo para editar en un campo de texto (`6500`, `12,5`).
String montoEditable(double v) => v == v.roundToDouble()
    ? v.toInt().toString()
    : v.toString().replaceAll('.', ',');

/// Nombre sugerido para un período que arranca en [inicio]: el mes en el que
/// cae la mayor parte de un mes de duración (del 4/10 → Octubre, del 28/10 → Noviembre).
String nombreSugerido(DateTime inicio) =>
    _meses[inicio.add(const Duration(days: 15)).month - 1];

final _dolares = NumberFormat('#,##0.##', 'es_AR');

/// `US$ 1.250,5`
String dolares(double v) => 'US\$ ${_dolares.format(v)}';
