import 'package:flutter/material.dart';

import '../formato.dart';
import '../modelos.dart';
import '../store.dart';
import 'formularios.dart';

class GastosTab extends StatelessWidget {
  const GastosTab({super.key, required this.store});

  final GastosStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filas = <Widget>[];
    DateTime? dia;
    for (final g in store.gastos) {
      if (g.fecha != dia) {
        dia = g.fecha;
        filas.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Text(
              '${diaSemana(g.fecha)} ${fechaCorta(g.fecha)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      }
      filas.add(FilaGasto(store: store, gasto: g, conFecha: false));
    }

    return RefreshIndicator(
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Card(
            child: ListTile(
              title: const Text('Total gastado'),
              subtitle: Text(
                store.gastos.isEmpty
                    ? '0 gastos'
                    : '${store.gastos.length} gastos · '
                          'tocá uno para editarlo o borrarlo',
              ),
              trailing: Text(
                plata(store.totalGastado),
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          if (store.gastos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Todavía no cargaste gastos en este período',
                textAlign: TextAlign.center,
              ),
            ),
          ...filas,
        ],
      ),
    );
  }
}

class FilaGasto extends StatelessWidget {
  const FilaGasto({
    super.key,
    required this.store,
    required this.gasto,
    this.conFecha = true,
  });

  final GastosStore store;
  final Gasto gasto;
  final bool conFecha;

  @override
  Widget build(BuildContext context) {
    final categoria = store.categoria(gasto.categoriaId);
    final detalle = [
      if (conFecha) fechaCorta(gasto.fecha),
      categoria?.nombre ?? 'Sin categoría',
      gasto.formaPago,
    ].join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        child: Icon(categoria?.iconData ?? Icons.label, size: 20),
      ),
      title: Text(gasto.descripcion),
      subtitle: Text(detalle),
      trailing: Text(
        plata(gasto.monto),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () => editarGasto(context, store, gasto),
    );
  }
}
