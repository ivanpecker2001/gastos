import 'package:flutter/material.dart';

/// Dónde está la plata. En Inicio, lo que queda en la cuenta se muestra
/// separado de lo que queda en efectivo.
enum Medio {
  cuenta('Cuenta', Icons.account_balance),
  efectivo('Efectivo', Icons.payments);

  const Medio(this.label, this.icono);
  final String label;
  final IconData icono;

  static Medio desde(String nombre) =>
      Medio.values.firstWhere((m) => m.name == nombre, orElse: () => cuenta);
}

/// Formas de pago de un gasto y de qué medio descuentan.
const formasPago = {
  'Mercado Pago': Medio.cuenta,
  'Efectivo': Medio.efectivo,
  'BNA': Medio.cuenta,
  'Galicia': Medio.cuenta,
  'Cuenta DNI': Medio.cuenta,
  'Otro': Medio.cuenta,
};

/// Movimientos de plata de un período, además de los gastos.
enum TipoMovimiento {
  blanco('Sueldo en blanco', Icons.work),
  negro('Sueldo en negro', Icons.work_outline),
  extra('Ingreso extra', Icons.redeem),
  retiro('Retiro de efectivo', Icons.local_atm),
  deposito('Depósito', Icons.savings),
  dolares('Compra de dólares', Icons.attach_money);

  const TipoMovimiento(this.label, this.icono);
  final String label;
  final IconData icono;

  /// Los ingresos suman a lo cobrado; retiros y depósitos solo mueven plata
  /// entre la cuenta y el efectivo; comprar dólares descuenta pesos.
  bool get esIngreso => this == blanco || this == negro || this == extra;

  /// Explicación para retiros y depósitos.
  String get detalleTransferencia => switch (this) {
    retiro => 'Pasa plata de la cuenta al efectivo: no cambia el total.',
    deposito => 'Pasa plata del efectivo a la cuenta: no cambia el total.',
    _ => '',
  };

  static TipoMovimiento desde(String nombre) => TipoMovimiento.values
      .firstWhere((t) => t.name == nombre, orElse: () => extra);
}

/// Íconos que se pueden elegir para una categoría (clave guardada en la base).
const iconosCategoria = <String, IconData>{
  'restaurant': Icons.restaurant,
  'shopping_cart': Icons.shopping_cart,
  'shopping_bag': Icons.shopping_bag,
  'sports_tennis': Icons.sports_tennis,
  'fitness_center': Icons.fitness_center,
  'psychology': Icons.psychology,
  'local_hospital': Icons.local_hospital,
  'card_giftcard': Icons.card_giftcard,
  'celebration': Icons.celebration,
  'local_bar': Icons.local_bar,
  'directions_car': Icons.directions_car,
  'local_gas_station': Icons.local_gas_station,
  'directions_bus': Icons.directions_bus,
  'flight': Icons.flight,
  'subscriptions': Icons.subscriptions,
  'phone_iphone': Icons.phone_iphone,
  'home': Icons.home,
  'bolt': Icons.bolt,
  'checkroom': Icons.checkroom,
  'content_cut': Icons.content_cut,
  'school': Icons.school,
  'pets': Icons.pets,
  'credit_card': Icons.credit_card,
  'savings': Icons.savings,
  'more_horiz': Icons.more_horiz,
  'label': Icons.label,
};

IconData iconoCategoria(String clave) => iconosCategoria[clave] ?? Icons.label;

/// Categorías que se crean la primera vez que un usuario entra.
const categoriasIniciales = [
  ('Salidas a comer', 'restaurant'),
  ('Gastos comida', 'shopping_cart'),
  ('Compras mias', 'shopping_bag'),
  ('Deporte', 'sports_tennis'),
  ('Psicóloga', 'psychology'),
  ('Regalos', 'card_giftcard'),
  ('Auto', 'directions_car'),
  ('Suscripciones', 'subscriptions'),
  ('Otro', 'more_horiz'),
];
