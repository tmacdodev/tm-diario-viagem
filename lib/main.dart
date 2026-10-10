import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'screens/lista_viagens_screen.dart';

// Ponto de entrada do app
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((_) {
        initializeDateFormatting('pt_BR').then((_) {
          runApp(const DiarioViagemApp());
        });
      });
}

class DiarioViagemApp extends StatelessWidget {
  const DiarioViagemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TM Diário de Viagem',
      debugShowCheckedModeBanner: false,
      // Garante que os widgets nativos (DatePicker, etc.) também apareçam
      // em português, no padrão brasileiro.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
      ),
      home: const ListaViagensScreen(),
    );
  }
}
