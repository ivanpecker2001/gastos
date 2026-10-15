import 'package:flutter/material.dart';

import '../formato.dart';
import '../store.dart';
import 'formularios.dart';

class CategoriasTab extends StatelessWidget {
  const CategoriasTab({super.key, required this.store});

  final GastosStore store;

  @override
  Widget build(BuildContext context) {
    final gastado = {
      for (final e in store.totalesPor(
        (g) => store.nombreCategoria(g.categoriaId),
      ))
        e.key: e.value,
    };
    return RefreshIndicator(
      onRefresh: store.cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Encabezado(
            'Categorías',
            boton: 'Categoría',
            onPressed: () => editarCategoria(context, store),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              'Tocá una para cambiarle el nombre o el ícono. '
              'Los gastos ya cargados toman el cambio.',
            ),
          ),
          for (final c in store.categorias)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: CircleAvatar(child: Icon(c.iconData, size: 20)),
              title: Text(c.nombre),
              subtitle: store.periodo == null
                  ? null
                  : Text(
                      '${plata(gastado[c.nombre] ?? 0)} '
                      'en ${store.periodo!.nombre}',
                    ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => editarCategoria(context, store, c),
            ),
        ],
      ),
    );
  }
}
