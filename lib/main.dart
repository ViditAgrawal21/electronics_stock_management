import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/models/materials.dart';
import 'src/models/pcb.dart';
import 'src/models/devices.dart'; // Add this import
import 'src/models/bom.dart'; // Add this import for BOM adapters
import 'src/screens/login_screen.dart';
import 'src/theme/app_theme.dart';
import 'src/constants/app_string.dart';

void main() async {
  // Ensure flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive with custom path on Windows network drive
  Hive.init(r'Z:\Stock Management\DOCUMENTS');

  // Register Hive adapters
  Hive.registerAdapter(MaterialAdapter());
  // Add these lines for device persistence:
  Hive.registerAdapter(SubComponentAdapter());
  Hive.registerAdapter(DeviceAdapter());
  Hive.registerAdapter(ProductionRecordAdapter());
  Hive.registerAdapter(PCBAdapter());
  Hive.registerAdapter(BOMAdapter());
  Hive.registerAdapter(BOMItemAdapter());

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
