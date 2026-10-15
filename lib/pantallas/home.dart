import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../store.dart';
import 'categorias_tab.dart';
import 'formularios.dart';
import 'gastos_tab.dart';
import 'inicio_tab.dart';
import 'periodo_tab.dart';
import 'resumen_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _store = GastosStore();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _store.cargar();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _salir() async {
    if (await confirmar(context, '¿Cerrar sesión?', 'Salir')) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final s = _store;
        return Scaffold(
          appBar: AppBar(
            title: _SelectorPeriodo(store: s),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: _salir,
              ),
            ],
            bottom: s.cargando
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : null,
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _cuerpo(s),
            ),
          ),
          floatingActionButton: _tab <= 1 && s.periodo != null
              ? FloatingActionButton.extended(
                  onPressed: () => editarGasto(context, s),
                  icon: const Icon(Icons.add),
                  label: const Text('Gasto'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Gastos',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: 'Resumen',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Plata',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'Categorías',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cuerpo(GastosStore s) {
    if (s.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Text('No se pudieron cargar los datos'),
              Text(
                '${s.error}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              FilledButton(
                onPressed: s.cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (s.cargando && s.periodos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tab == 3) return PeriodoTab(store: s);
    if (_tab == 4) return CategoriasTab(store: s);
    if (s.periodo == null) return _SinPeriodo(store: s);
    return switch (_tab) {
      0 => InicioTab(store: s, verGastos: () => setState(() => _tab = 1)),
      1 => GastosTab(store: s),
      _ => ResumenTab(store: s),
    };
  }
}

class _SelectorPeriodo extends StatelessWidget {
  const _SelectorPeriodo({required this.store});

  final GastosStore store;

  @override
  Widget build(BuildContext context) {
    final actual = store.periodo;
    if (actual == null) return const Text('Mis Gastos');
    return PopupMenuButton(
      tooltip: 'Cambiar período',
      onSelected: store.elegir,
      itemBuilder: (_) => [
        for (final p in store.periodos)
          PopupMenuItem(
            value: p,
            child: Text('${p.nombre}  ·  ${p.rangoCorto}'),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(actual.nombre, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _SinPeriodo extends StatelessWidget {
  const _SinPeriodo({required this.store});

  final GastosStore store;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Icon(
              Icons.date_range,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            Text(
              'Todavía no tenés períodos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Iniciá uno cuando cobres (por ejemplo «Octubre», desde el 4/10) '
              'y cerralo cuando quieras. Al iniciar el siguiente, el anterior '
              'se cierra solo.',
              textAlign: TextAlign.center,
            ),
            FilledButton.icon(
              onPressed: () => iniciarPeriodo(context, store),
              icon: const Icon(Icons.add),
              label: const Text('Iniciar período'),
            ),
          ],
        ),
      ),
    );
  }
}
