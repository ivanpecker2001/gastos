import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Se pasan al compilar con --dart-define (local) o desde las variables de entorno de Vercel.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  runApp(const GastosApp());
}

class GastosApp extends StatelessWidget {
  const GastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: supabaseUrl.isEmpty || supabaseKey.isEmpty
          ? const _FaltaConfig()
          : const GastosPage(),
    );
  }
}

class _FaltaConfig extends StatelessWidget {
  const _FaltaConfig();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Faltan SUPABASE_URL y SUPABASE_KEY.\n'
            'Pasalas con --dart-define o configuralas en Vercel.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class GastosPage extends StatefulWidget {
  const GastosPage({super.key});

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  final _db = Supabase.instance.client;
  final _moneda = NumberFormat.currency(locale: 'es_AR', symbol: r'$');
  late Future<List<Map<String, dynamic>>> _gastos;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _gastos = _db
        .from('gastos')
        .select()
        .order('fecha', ascending: false)
        .order('id', ascending: false);
  }

  Future<void> _nuevoGasto() async {
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => const _NuevoGastoDialog(),
    );
    if (guardado == true) setState(_cargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Gastos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoGasto,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gastos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final gastos = snap.data!;
          final total = gastos.fold<double>(
              0, (s, g) => s + (g['monto'] as num).toDouble());
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  title: const Text('Total'),
                  trailing: Text(
                    _moneda.format(total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              Expanded(
                child: gastos.isEmpty
                    ? const Center(child: Text('Todavía no cargaste gastos'))
                    : ListView.builder(
                        itemCount: gastos.length,
                        itemBuilder: (_, i) {
                          final g = gastos[i];
                          return ListTile(
                            title: Text(g['descripcion'] as String),
                            subtitle: Text(g['fecha'] as String),
                            trailing: Text(
                                _moneda.format((g['monto'] as num).toDouble())),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NuevoGastoDialog extends StatefulWidget {
  const _NuevoGastoDialog();

  @override
  State<_NuevoGastoDialog> createState() => _NuevoGastoDialogState();
}

class _NuevoGastoDialogState extends State<_NuevoGastoDialog> {
  final _form = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  final _monto = TextEditingController();
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await Supabase.instance.client.from('gastos').insert({
        'descripcion': _descripcion.text.trim(),
        'monto': double.parse(_monto.text.replaceAll(',', '.')),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo gasto'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _descripcion,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            ),
            TextFormField(
              controller: _monto,
              decoration: const InputDecoration(labelText: 'Monto'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse((v ?? '').replaceAll(',', '.')) == null
                      ? 'Número inválido'
                      : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
