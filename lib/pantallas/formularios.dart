import 'package:flutter/material.dart';

import '../constantes.dart';
import '../formato.dart';
import '../modelos.dart';
import '../store.dart';

Future<void> editarGasto(
  BuildContext context,
  GastosStore store, [
  Gasto? gasto,
]) => showDialog(context: context, builder: (_) => _GastoDialog(store, gasto));

/// Carga un movimiento nuevo de [tipo], o edita [movimiento].
Future<void> editarMovimiento(
  BuildContext context,
  GastosStore store, {
  TipoMovimiento tipo = TipoMovimiento.blanco,
  Movimiento? movimiento,
}) => showDialog(
  context: context,
  builder: (_) =>
      _MovimientoDialog(store, movimiento?.tipo ?? tipo, movimiento),
);

Future<void> iniciarPeriodo(BuildContext context, GastosStore store) =>
    showDialog(context: context, builder: (_) => _NuevoPeriodoDialog(store));

Future<void> editarPeriodo(
  BuildContext context,
  GastosStore store,
  Periodo periodo,
) => showDialog(
  context: context,
  builder: (_) => _EditarPeriodoDialog(store, periodo),
);

Future<void> cerrarPeriodo(
  BuildContext context,
  GastosStore store,
  Periodo periodo,
) => showDialog(
  context: context,
  builder: (_) => _CerrarPeriodoDialog(store, periodo),
);

Future<void> editarCategoria(
  BuildContext context,
  GastosStore store, [
  Categoria? categoria,
]) => showDialog(
  context: context,
  builder: (_) => _CategoriaDialog(store, categoria),
);

Future<bool> confirmar(
  BuildContext context,
  String pregunta, [
  String accion = 'Borrar',
]) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(pregunta),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _GastoDialog extends StatefulWidget {
  const _GastoDialog(this.store, this.gasto);

  final GastosStore store;
  final Gasto? gasto;

  @override
  State<_GastoDialog> createState() => _GastoDialogState();
}

class _GastoDialogState extends State<_GastoDialog> {
  late final _descripcion = TextEditingController(
    text: widget.gasto?.descripcion,
  );
  late final _monto = TextEditingController(
    text: widget.gasto == null ? '' : montoEditable(widget.gasto!.monto),
  );
  late DateTime _fecha =
      widget.gasto?.fecha ?? DateUtils.dateOnly(DateTime.now());
  late String _formaPago = formasPago.containsKey(widget.gasto?.formaPago)
      ? widget.gasto!.formaPago
      : formasPago.keys.first;
  late int? _categoriaId = widget.gasto == null
      ? null
      : widget.store.categoria(widget.gasto!.categoriaId)?.id;

  @override
  void dispose() {
    _descripcion.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<String?> _guardar() async {
    await widget.store.guardarGasto(
      Gasto(
        id: widget.gasto?.id,
        fecha: _fecha,
        descripcion: _descripcion.text.trim(),
        monto: parseMonto(_monto.text)!,
        formaPago: _formaPago,
        categoriaId: _categoriaId!,
      ),
    );
    final p = widget.store.periodo;
    return p != null && !p.contiene(_fecha)
        ? 'Guardado, pero su fecha no entra en «${p.nombre}», '
              'así que no aparece en este período.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final gasto = widget.gasto;
    return _FormDialog(
      titulo: gasto == null ? 'Nuevo gasto' : 'Editar gasto',
      guardar: _guardar,
      borrar: gasto == null ? null : () => widget.store.borrarGasto(gasto),
      preguntaBorrar: '¿Borrar «${gasto?.descripcion}»?',
      campos: [
        CampoFecha(
          label: 'Fecha',
          fecha: _fecha,
          onChanged: (d) => setState(() => _fecha = d),
        ),
        TextFormField(
          controller: _descripcion,
          decoration: const InputDecoration(labelText: 'Descripción'),
          textCapitalization: TextCapitalization.sentences,
          validator: _obligatorio,
        ),
        _CampoMonto(_monto),
        const _Etiqueta('Forma de pago'),
        _Opciones(
          opciones: {for (final f in formasPago.keys) f: f},
          valor: _formaPago,
          onChanged: (v) => setState(() => _formaPago = v),
        ),
        DropdownButtonFormField<int>(
          initialValue: _categoriaId,
          decoration: const InputDecoration(labelText: 'Categoría'),
          items: [
            for (final c in widget.store.categorias)
              DropdownMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Icon(c.iconData, size: 20),
                    const SizedBox(width: 8),
                    Text(c.nombre),
                  ],
                ),
              ),
          ],
          onChanged: (v) => setState(() => _categoriaId = v),
          validator: (v) => v != null
              ? null
              : widget.store.categorias.isEmpty
              ? 'Creá una categoría en la solapa Categorías'
              : 'Elegí una categoría',
        ),
      ],
    );
  }
}

class _MovimientoDialog extends StatefulWidget {
  const _MovimientoDialog(this.store, this.tipo, this.movimiento);

  final GastosStore store;
  final TipoMovimiento tipo;
  final Movimiento? movimiento;

  @override
  State<_MovimientoDialog> createState() => _MovimientoDialogState();
}

class _MovimientoDialogState extends State<_MovimientoDialog> {
  late final Movimiento? _m = widget.movimiento;
  late TipoMovimiento _tipo = widget.tipo;
  late DateTime _fecha = _m?.fecha ?? DateUtils.dateOnly(DateTime.now());
  late Medio _medio = _m?.medio ?? Medio.cuenta;
  late final _monto = TextEditingController(
    text: _m == null ? '' : montoEditable(_m.monto),
  );
  late final _usd = TextEditingController(
    text: _m?.usd == null ? '' : montoEditable(_m!.usd!),
  );
  late final _cotizacion = TextEditingController(
    text: _m?.usd == null ? '' : montoEditable(_m!.monto / _m.usd!),
  );
  late final _nota = TextEditingController(text: _m?.nota);

  bool get _esDolares => _tipo == TipoMovimiento.dolares;

  /// En una compra de dólares los pesos salen de dólares × cotización.
  double? get _pesos => _esDolares
      ? switch ((parseMonto(_usd.text), parseMonto(_cotizacion.text))) {
          (final u?, final c?) => (u * c).roundToDouble(),
          _ => null,
        }
      : parseMonto(_monto.text);

  @override
  void dispose() {
    _monto.dispose();
    _usd.dispose();
    _cotizacion.dispose();
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    final pesos = _pesos;
    final medioFijo = switch (_tipo) {
      TipoMovimiento.retiro => Medio.efectivo,
      TipoMovimiento.deposito => Medio.cuenta,
      _ => null,
    };
    final titulo = _tipo.esIngreso ? 'ingreso' : _tipo.label.toLowerCase();
    return _FormDialog(
      titulo: m == null ? 'Nuevo $titulo' : 'Editar $titulo',
      guardar: () async {
        final nota = _nota.text.trim();
        await widget.store.guardarMovimiento(
          Movimiento(
            id: m?.id,
            periodoId: m?.periodoId ?? widget.store.periodo!.id!,
            fecha: _fecha,
            tipo: _tipo,
            medio: medioFijo ?? _medio,
            monto: _pesos!,
            usd: _esDolares ? parseMonto(_usd.text) : null,
            nota: nota.isEmpty ? null : nota,
          ),
        );
        return null;
      },
      borrar: m == null ? null : () => widget.store.borrarMovimiento(m),
      preguntaBorrar: '¿Borrar este movimiento?',
      campos: [
        CampoFecha(
          label: 'Fecha',
          fecha: _fecha,
          onChanged: (d) => setState(() => _fecha = d),
        ),
        if (_tipo.esIngreso)
          _Opciones(
            opciones: {
              for (final t in TipoMovimiento.values.where((t) => t.esIngreso))
                t.name: t.label,
            },
            valor: _tipo.name,
            onChanged: (v) => setState(() => _tipo = TipoMovimiento.desde(v)),
          ),
        if (medioFijo == null) ...[
          _Etiqueta(_esDolares ? 'Pagaste con' : 'Dónde entró'),
          SegmentedButton<Medio>(
            segments: [
              for (final x in Medio.values)
                ButtonSegment(
                  value: x,
                  label: Text(x.label),
                  icon: Icon(x.icono),
                ),
            ],
            selected: {_medio},
            onSelectionChanged: (s) => setState(() => _medio = s.first),
          ),
        ] else
          Text(
            _tipo.detalleTransferencia,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (_esDolares) ...[
          TextFormField(
            controller: _usd,
            decoration: const InputDecoration(
              labelText: 'Dólares',
              prefixText: r'US$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: _positivo,
          ),
          TextFormField(
            controller: _cotizacion,
            decoration: const InputDecoration(
              labelText: 'Cotización (pesos por dólar)',
              prefixText: r'$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: _positivo,
          ),
          Text(
            pesos == null
                ? 'Total en pesos: —'
                : 'Total en pesos: ${plata(pesos)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ] else
          _CampoMonto(_monto),
        TextFormField(
          controller: _nota,
          decoration: InputDecoration(
            labelText: 'Observación (opcional)',
            hintText: _tipo == TipoMovimiento.extra
                ? 'Ej.: regalo de cumpleaños'
                : null,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

class _NuevoPeriodoDialog extends StatefulWidget {
  const _NuevoPeriodoDialog(this.store);

  final GastosStore store;

  @override
  State<_NuevoPeriodoDialog> createState() => _NuevoPeriodoDialogState();
}

class _NuevoPeriodoDialogState extends State<_NuevoPeriodoDialog> {
  late final DateTime? _minimo = widget.store.inicioMinimo;
  late DateTime _inicio = _inicioPorDefecto();
  late final _nombre = TextEditingController(text: nombreSugerido(_inicio));

  /// Mientras no se escriba un nombre a mano, se sugiere según el inicio.
  bool _nombreAMano = false;

  /// Hoy, salvo que el último período se haya cerrado antes: entonces el
  /// día siguiente a su cierre, para que no queden días sin período.
  DateTime _inicioPorDefecto() {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final minimo = _minimo;
    if (minimo == null) return hoy;
    if (widget.store.abierto == null || hoy.isBefore(minimo)) return minimo;
    return hoy;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final abierto = widget.store.abierto;
    final minimo = _minimo;
    final inicioOk = minimo == null || !_inicio.isBefore(minimo);
    return _FormDialog(
      titulo: 'Nuevo período',
      textoGuardar: 'Iniciar',
      puedeGuardar: inicioOk,
      guardar: () async {
        await widget.store.iniciarPeriodo(_nombre.text.trim(), _inicio);
        return null;
      },
      campos: [
        CampoFecha(
          label: 'Empieza',
          fecha: _inicio,
          error: inicioOk
              ? null
              : 'Tiene que ser desde el ${fechaLarga(minimo)}',
          onChanged: (d) => setState(() {
            _inicio = d;
            if (!_nombreAMano) _nombre.text = nombreSugerido(d);
          }),
        ),
        TextFormField(
          controller: _nombre,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _nombreAMano = true,
          validator: _obligatorio,
        ),
        if (abierto != null && inicioOk)
          Text(
            '«${abierto.nombre}» se va a cerrar el '
            '${fechaLarga(_inicio.subtract(const Duration(days: 1)))}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _EditarPeriodoDialog extends StatefulWidget {
  const _EditarPeriodoDialog(this.store, this.periodo);

  final GastosStore store;
  final Periodo periodo;

  @override
  State<_EditarPeriodoDialog> createState() => _EditarPeriodoDialogState();
}

class _EditarPeriodoDialogState extends State<_EditarPeriodoDialog> {
  late final _nombre = TextEditingController(text: widget.periodo.nombre);
  late DateTime _inicio = widget.periodo.inicio;
  late DateTime? _fin = widget.periodo.fin;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.periodo;
    final fin = _fin;
    final fechasOk = fin == null || !fin.isBefore(_inicio);
    return _FormDialog(
      titulo: 'Editar período',
      puedeGuardar: fechasOk,
      guardar: () async {
        await widget.store.guardarPeriodo(
          Periodo(
            id: p.id,
            nombre: _nombre.text.trim(),
            inicio: _inicio,
            fin: _fin,
          ),
        );
        return null;
      },
      borrar: () => widget.store.borrarPeriodo(p),
      preguntaBorrar:
          '¿Borrar el período «${p.nombre}»? '
          'También se borran sus cobros. Los gastos no se borran.',
      campos: [
        TextFormField(
          controller: _nombre,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.sentences,
          validator: _obligatorio,
        ),
        CampoFecha(
          label: 'Empieza',
          fecha: _inicio,
          onChanged: (d) => setState(() => _inicio = d),
        ),
        if (fin != null)
          CampoFecha(
            label: 'Termina',
            fecha: fin,
            error: fechasOk ? null : 'Tiene que ser después del inicio',
            onChanged: (d) => setState(() => _fin = d),
          ),
      ],
    );
  }
}

class _CerrarPeriodoDialog extends StatefulWidget {
  const _CerrarPeriodoDialog(this.store, this.periodo);

  final GastosStore store;
  final Periodo periodo;

  @override
  State<_CerrarPeriodoDialog> createState() => _CerrarPeriodoDialogState();
}

class _CerrarPeriodoDialogState extends State<_CerrarPeriodoDialog> {
  late DateTime _fin = () {
    final hoy = DateUtils.dateOnly(DateTime.now());
    return hoy.isBefore(widget.periodo.inicio) ? widget.periodo.inicio : hoy;
  }();

  @override
  Widget build(BuildContext context) {
    final finOk = !_fin.isBefore(widget.periodo.inicio);
    return _FormDialog(
      titulo: 'Cerrar «${widget.periodo.nombre}»',
      textoGuardar: 'Cerrar período',
      puedeGuardar: finOk,
      guardar: () async {
        await widget.store.cerrarPeriodo(widget.periodo, _fin);
        return null;
      },
      campos: [
        CampoFecha(
          label: 'Último día',
          fecha: _fin,
          error: finOk ? null : 'Tiene que ser después del inicio',
          onChanged: (d) => setState(() => _fin = d),
        ),
        Text(
          'Los gastos con fecha posterior van a quedar para el próximo '
          'período. Si cobrás y querés arrancar uno nuevo, usá «Nuevo período»: '
          'cierra este solo.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CategoriaDialog extends StatefulWidget {
  const _CategoriaDialog(this.store, this.categoria);

  final GastosStore store;
  final Categoria? categoria;

  @override
  State<_CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends State<_CategoriaDialog> {
  late final _nombre = TextEditingController(text: widget.categoria?.nombre);
  late String _icono = widget.categoria?.icono ?? 'label';

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.categoria;
    return _FormDialog(
      titulo: c == null ? 'Nueva categoría' : 'Editar categoría',
      guardar: () async {
        await widget.store.guardarCategoria(
          Categoria(id: c?.id, nombre: _nombre.text.trim(), icono: _icono),
        );
        return null;
      },
      borrar: c == null ? null : () => widget.store.borrarCategoria(c),
      preguntaBorrar: '¿Borrar la categoría «${c?.nombre}»?',
      campos: [
        TextFormField(
          controller: _nombre,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.sentences,
          validator: _obligatorio,
        ),
        const _Etiqueta('Ícono'),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final i in iconosCategoria.entries)
              i.key == _icono
                  ? IconButton.filled(
                      onPressed: () {},
                      icon: Icon(i.value),
                      tooltip: i.key,
                    )
                  : IconButton(
                      onPressed: () => setState(() => _icono = i.key),
                      icon: Icon(i.value),
                    ),
          ],
        ),
      ],
    );
  }
}

/// Diálogo con formulario: valida, muestra el estado de guardado y los errores.
class _FormDialog extends StatefulWidget {
  const _FormDialog({
    required this.titulo,
    required this.campos,
    required this.guardar,
    this.borrar,
    this.preguntaBorrar = '¿Borrar?',
    this.puedeGuardar = true,
    this.textoGuardar = 'Guardar',
  });

  final String titulo;
  final List<Widget> campos;

  /// Guarda y devuelve, si hace falta, un aviso para mostrar al cerrar.
  final Future<String?> Function() guardar;
  final Future<void> Function()? borrar;
  final String preguntaBorrar;
  final bool puedeGuardar;
  final String textoGuardar;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _form = GlobalKey<FormState>();
  bool _ocupado = false;

  Future<void> _correr(Future<String?> Function() accion) async {
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _ocupado = true);
    try {
      final aviso = await accion();
      if (!mounted) return;
      Navigator.pop(context);
      if (aviso != null) avisos.showSnackBar(SnackBar(content: Text(aviso)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      avisos.showSnackBar(
        SnackBar(
          content: Text(e is Aviso ? e.mensaje : 'No se pudo guardar: $e'),
        ),
      );
    }
  }

  Future<void> _borrar() async {
    if (!await confirmar(context, widget.preguntaBorrar)) return;
    await _correr(() async {
      await widget.borrar!();
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Row(
        children: [
          Expanded(child: Text(widget.titulo)),
          if (widget.borrar != null)
            IconButton(
              tooltip: 'Borrar',
              icon: const Icon(Icons.delete_outline),
              onPressed: _ocupado ? null : _borrar,
            ),
        ],
      ),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: widget.campos,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _ocupado ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _ocupado || !widget.puedeGuardar
              ? null
              : () {
                  if (_form.currentState!.validate()) _correr(widget.guardar);
                },
          child: Text(widget.textoGuardar),
        ),
      ],
    );
  }
}

class CampoFecha extends StatelessWidget {
  const CampoFecha({
    super.key,
    required this.label,
    required this.fecha,
    required this.onChanged,
    this.error,
  });

  final String label;
  final DateTime fecha;
  final ValueChanged<DateTime> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text('${diaSemana(fecha)} ${fechaLarga(fecha)}'),
      ),
    );
  }
}

/// Título de sección con un botón para agregar a la derecha.
class Encabezado extends StatelessWidget {
  const Encabezado(
    this.titulo, {
    super.key,
    required this.boton,
    required this.onPressed,
  });

  final String titulo;
  final String boton;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: Text(boton),
        ),
      ],
    );
  }
}

class _CampoMonto extends StatelessWidget {
  const _CampoMonto(this.controller);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Monto', prefixText: r'$ '),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        final monto = parseMonto(v ?? '');
        return monto == null || monto <= 0 ? 'Ingresá un monto válido' : null;
      },
    );
  }
}

/// Elección de una opción entre varias, con chips que pasan de línea si no entran.
class _Opciones extends StatelessWidget {
  const _Opciones({
    required this.opciones,
    required this.valor,
    required this.onChanged,
  });

  /// Valor → texto.
  final Map<String, String> opciones;
  final String valor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final o in opciones.entries)
          ChoiceChip(
            label: Text(o.value),
            selected: o.key == valor,
            onSelected: (_) => onChanged(o.key),
          ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(texto, style: Theme.of(context).textTheme.labelLarge),
  );
}

String? _positivo(String? v) {
  final n = parseMonto(v ?? '');
  return n == null || n <= 0 ? 'Ingresá un número válido' : null;
}

String? _obligatorio(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;
