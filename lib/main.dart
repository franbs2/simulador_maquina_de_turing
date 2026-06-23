import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/maquina_model.dart';
import 'screens/editor_screen.dart';

void main() {
  runApp(const SimuladorTuringApp());
}

class SimuladorTuringApp extends StatelessWidget {
  const SimuladorTuringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MaquinaModel.exemploIncrementoBinario(),
      child: MaterialApp(
        title: 'Simulador de Máquina de Turing',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.dark),
        home: const EditorScreen(),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seed = Color(0xFF6C63FF);
    const surface = Color(0xFF0F1117);
    const surfaceContainer = Color(0xFF1A1D2E);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: surface,
      surfaceContainerHighest: surfaceContainer,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.secondary,
        thumbColor: colorScheme.secondary,
        overlayColor: colorScheme.secondary.withValues(alpha: 0.2),
      ),
    );
  }
}
