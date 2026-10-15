import 'package:flutter/material.dart';

import '../constantes.dart';
import '../formato.dart';
import '../store.dart';
import 'formularios.dart';

class PeriodoTab extends StatelessWidget {
  const PeriodoTab({super.key, required this.store});

  final GastosStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = store.periodo;
    // Se puede reabrir el último período si se cerró y no hay otro abierto.
    final reabrible =
        p != null &&
        !p.abierto &&
        store.abierto == null &&
        p.id == store.ultimo?.id;

    return RefreshIndicator(
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (p != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nombre, style: theme.textTheme.titleLarge),
                              Text(p.rango),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar período',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => editarPeriodo(context, store, p),
                        ),
                      ],
                    ),
                    if (p.abierto || reabrible) const SizedBox(height: 8),
                    if (p.abierto)
                      OutlinedButton.icon(
                        onPressed: () => cerrarPeriodo(context, store, p),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Cerrar período'),
                      ),
                    if (reabrible)
                      OutlinedButton.icon(
                        onPressed: () => store.reabrirPeriodo(p),
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Reabrir'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Movimientos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (tipo, texto) in [
                  (TipoMovimiento.blanco, 'Ingreso'),
                  (TipoMovimiento.retiro, 'Retirar'),
                  (TipoMovimiento.deposito, 'Depositar'),
                  (TipoMovimiento.dolares, 'Dólares'),
                ])
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        editarMovimiento(context, store, tipo: tipo),
                    icon: Icon(tipo.icono),
                    label: Text(texto),
                  ),
              ],
            ),
            if (store.movimientos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Todavía no cargaste movimientos en este período: el '
                  'sueldo (en blanco o en negro), ingresos extra, el '
                  'efectivo con el que arrancás, retiros, depósitos y '
                  'compras de dólares.',
                ),
              ),
            for (final m in store.movimientos)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: CircleAvatar(child: Icon(m.tipo.icono, size: 20)),
                title: Text(m.tipo.label),
                subtitle: Text(
                  [
                    fechaCorta(m.fecha),
                    m.detalle,
                    if (m.nota != null) m.nota!,
                  ].join(' · '),
                ),
                trailing: Text(
                  // Lo que sale del total (dólares) se muestra en negativo.
                  plata(m.tipo == TipoMovimiento.dolares ? -m.monto : m.monto),
                  style: theme.textTheme.titleMedium,
                ),
                onTap: () => editarMovimiento(context, store, movimiento: m),
              ),
            if (store.movimientos.isNotEmpty) ...[
              const Divider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Total cobrado'),
                subtitle: Text(
                  [
                    for (final m in Medio.values)
                      '${m.label} ${plata(store.cobrado(m))}',
                  ].join(' · '),
                ),
                trailing: Text(
                  plata(store.totalCobrado),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (store.totalUsd > 0 || store.usdHistorico > 0)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text(
                    'Compraste ${dolares(store.totalUsd)} en este período',
                  ),
                  subtitle: Text(
                    'Por ${plata(store.totalDolaresArs)} · '
                    'En total, ${dolares(store.usdHistorico)} comprados',
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
          Encabezado(
            'Todos los períodos',
            boton: 'Nuevo',
            onPressed: () => iniciarPeriodo(context, store),
          ),
          if (store.periodos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Todavía no tenés períodos. Iniciá uno cuando '
                'cobres y cerralo cuando quieras; al iniciar el siguiente, '
                'el anterior se cierra solo.',
              ),
            ),
          for (final x in store.periodos)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(x.nombre),
              subtitle: Text(x.rango),
              selected: x.id == p?.id,
              trailing: x.id == p?.id ? const Icon(Icons.check) : null,
              onTap: () => store.elegir(x),
            ),
        ],
      ),
    );
  }
}
