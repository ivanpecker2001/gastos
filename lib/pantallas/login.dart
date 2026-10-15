import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dominio que se agrega al usuario para formar el email de Supabase Auth
/// (el usuario "iban" es iban@gastos.app).
const _dominio = 'gastos.app';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _entrando = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final usuario = _usuario.text.trim().toLowerCase();
    if (usuario.isEmpty || _clave.text.isEmpty) return;
    setState(() {
      _entrando = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: usuario.contains('@') ? usuario : '$usuario@$_dominio',
        password: _clave.text,
      );
      // Al entrar, la app cambia sola a la pantalla principal.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _entrando = false;
        _error = e.code == 'invalid_credentials'
            ? 'Usuario o contraseña incorrectos'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entrando = false;
        _error = 'No se pudo conectar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    Text(
                      'Mis Gastos',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usuario,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                    ),
                    TextField(
                      controller: _clave,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      autofillHints: const [AutofillHints.password],
                      obscureText: true,
                      onSubmitted: (_) => _entrar(),
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    FilledButton(
                      onPressed: _entrando ? null : _entrar,
                      child: _entrando
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ingresar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
