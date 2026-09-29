import 'package:flutter/material.dart';

import 'data/local/hive_database.dart';
import 'data/repositories/kirana_repository.dart';
import 'presentation/controllers/app_controller.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await HiveDatabase.open();
  final repository = KiranaRepository(database);
  final controller = await AppController.create(repository);

  runApp(KiranaSmartApp(controller: controller));
}

class KiranaSmartApp extends StatelessWidget {
  const KiranaSmartApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KiranaSmart',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFF7F9F7),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
