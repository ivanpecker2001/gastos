import 'package:flutter/material.dart';

import '../constantes.dart';
import '../formato.dart';
import '../store.dart';
import 'formularios.dart';
import 'gastos_tab.dart';

class InicioTab extends StatelessWidget {
  const InicioTab({super.key, required this.store, required this.verGastos});

  final GastosStore store;
  final VoidCallback verGastos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colores = theme.colorScheme;
    final p = store.periodo!;
    final hoy = DateTime.now();
    final dia =
        (DateUtils.dateOnly(hoy).difference(p.inicio).inHours / 24).round() + 1;
    final estado = !p.abierto
        ? 'cerrado'
        : dia >= 1
        ? 'día $dia'
        : 'todavía no empezó';
    // Si se cerró el último período y no hay otro abierto, se ofrece iniciar uno.
    final ofrecerNuevo = store.abierto == null && p.id == store.ultimo?.id;
    final restante = store.restanteTotal;

    return RefreshIndicator(
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            '${p.rango} · $estado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colores.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (ofrecerNuevo)
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Este período está cerrado'),
                subtitle: const Text('¿Cobraste? Iniciá el próximo.'),
                trailing: FilledButton(
                  onPressed: () => iniciarPeriodo(context, store),
                  child: const Text('Iniciar'),
                ),
              ),
            ),
          Card(
            color: colores.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Te queda',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colores.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    plata(restante),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: restante < 0
                          ? colores.error
                          : colores.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      'Cobraste ${plata(store.totalCobrado)}',
                      'Gastaste ${plata(store.totalGastado)}',
                      if (store.totalUsd > 0)
                        'Dólares ${plata(store.totalDolaresArs)}',
                    ].join(' · '),
                    style: TextStyle(color: colores.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            spacing: 4,
            children: [
              for (final m in Medio.values)
                Expanded(
                  child: _TarjetaMedio(store: store, medio: m),
                ),
            ],
          ),
          if (store.totalCobrado == 0)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Todavía no cargaste lo que cobraste'),
                subtitle: Text(
                  'Cargalo en la pestaña Plata para ver cuánto te queda.',
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Últimos gastos', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton(onPressed: verGastos, child: const Text('Ver todos')),
            ],
          ),
          if (store.gastos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin gastos en este período'),
            ),
          for (final g in store.gastos.take(5))
            FilaGasto(store: store, gasto: g),
        ],
      ),
    );
  }
}

class _TarjetaMedio extends StatelessWidget {
  const _TarjetaMedio({required this.store, required this.medio});

  final GastosStore store;
  final Medio medio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restante = store.restante(medio);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              spacing: 6,
              children: [
                Icon(medio.icono, size: 18, color: theme.colorScheme.primary),
                Text(medio.label, style: theme.textTheme.labelLarge),
              ],
            ),
            Text(
              plata(restante),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: restante < 0 ? theme.colorScheme.error : null,
              ),
            ),
            Text(
              'de ${plata(store.disponible(medio))}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
