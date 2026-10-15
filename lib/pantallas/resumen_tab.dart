import 'package:flutter/material.dart';

import '../constantes.dart';
import '../formato.dart';
import '../store.dart';

class ResumenTab extends StatelessWidget {
  const ResumenTab({super.key, required this.store});

  final GastosStore store;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Seccion(
            titulo: 'Por categoría',
            total: store.totalGastado,
            filas: store.totalesPor(
              (g) => store.nombreCategoria(g.categoriaId),
            ),
            icono: (nombre) =>
                store.categorias
                    .where((c) => c.nombre == nombre)
                    .firstOrNull
                    ?.iconData ??
                Icons.label,
          ),
          const SizedBox(height: 8),
          _Seccion(
            titulo: 'Por forma de pago',
            total: store.totalGastado,
            filas: store.totalesPor((g) => g.formaPago),
            icono: (f) => (formasPago[f] ?? Medio.cuenta).icono,
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.total,
    required this.filas,
    required this.icono,
  });

  final String titulo;
  final double total;
  final List<MapEntry<String, double>> filas;
  final IconData Function(String) icono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(titulo, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(plata(total), style: theme.textTheme.titleMedium),
              ],
            ),
            if (filas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Sin gastos en este período'),
              ),
            for (final f in filas)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  spacing: 6,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Icon(
                          icono(f.key),
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        Expanded(child: Text(f.key)),
                        Text(
                          '${(f.value / total * 100).round()}%',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          plata(f.value),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    LinearProgressIndicator(
                      value: f.value / total,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
