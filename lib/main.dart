import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pantallas/home.dart';
import 'pantallas/login.dart';

// Se pasan al compilar con --dart-define (local) o desde las variables de entorno de Vercel.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    // La sesión queda guardada en el navegador y se renueva sola,
    // así que después del primer ingreso no vuelve a pedir usuario.
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
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: supabaseUrl.isEmpty || supabaseKey.isEmpty
          ? const _FaltaConfig()
          : const _SegunSesion(),
    );
  }
}

/// Muestra el login o la app según haya sesión iniciada.
class _SegunSesion extends StatelessWidget {
  const _SegunSesion();

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final sesion = auth.currentSession;
        return sesion == null
            ? const LoginPage()
            : HomePage(key: ValueKey(sesion.user.id));
      },
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
