import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api_client.dart';
import 'services/inventory_api.dart';
import 'state/inventory_store.dart';
import 'ui/inventory_screen.dart';

class AccessoriesApp extends StatefulWidget {
  final String baseUrl;
  final String companyId;

  const AccessoriesApp({
    super.key,
    required this.baseUrl,
    required this.companyId,
  });

  @override
  State<AccessoriesApp> createState() => _AccessoriesAppState();
}

class _AccessoriesAppState extends State<AccessoriesApp> {
  late final InventoryStore _store;

  @override
  void initState() {
    super.initState();
    final api = InventoryApi(ApiClient(baseUrl: widget.baseUrl));
    _store = InventoryStore(api: api, companyId: widget.companyId);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Core Colors from Design Doc
    const bsCharcoal950 = Color(0xFF060D18);
    const bsCharcoal800 = Color(0xFF0F172A);
    const bsCharcoal500 = Color(0xFF475569);
    const bsCharcoal400 = Color(0xFF64748B);
    const bsCharcoal100 = Color(0xFFE2E8F0);
    const bsBlue800 = Color(0xFF0284C7);
    const bsBlue900 = Color(0xFF0369A1);
    const bsBlue400 = Color(0xFFBAE6FD);
    const bsBlue200 = Color(0xFFE0F2FE);
    const bsBlue50 = Color(0xFFF0F9FF);
    const bsBg = Color(0xFFF5F8FA);

    return MaterialApp(
      title: 'BuilderSolve',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bsBlue800,
          primary: bsBlue800,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: bsCharcoal800,
          outline: bsBlue400,
        ),
        scaffoldBackgroundColor: bsBg,
        // Typography - Using Sora as defined in doc
        textTheme: GoogleFonts.soraTextTheme().copyWith(
          displayLarge: GoogleFonts.sora(fontWeight: FontWeight.w800, color: bsCharcoal800),
          titleLarge: GoogleFonts.sora(fontWeight: FontWeight.w700, color: bsCharcoal800, letterSpacing: -0.3),
          titleMedium: GoogleFonts.sora(fontWeight: FontWeight.w600, color: bsCharcoal800),
          bodyLarge: GoogleFonts.sora(fontWeight: FontWeight.w400, color: bsCharcoal500, fontSize: 17),
          bodyMedium: GoogleFonts.sora(fontWeight: FontWeight.w400, color: bsCharcoal500, fontSize: 15),
          bodySmall: GoogleFonts.sora(fontWeight: FontWeight.w400, color: bsCharcoal400, fontSize: 13),
          labelLarge: GoogleFonts.sora(fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 11),
        ),
        // Button Styles - "Tactile clarity" with flat shadows
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(bsBlue800),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            textStyle: WidgetStateProperty.all(GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 13)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), // --r-sm
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return 0;
              return 0; // Handled by custom shadow decoration or simplistic approach
            }),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: bsBlue800,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // --r-sm
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: bsBlue800,
            side: const BorderSide(color: bsBlue400, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        // Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: bsBlue400, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: bsBlue400, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: bsBlue800, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: bsCharcoal500),
          hintStyle: GoogleFonts.sora(color: bsCharcoal400),
        ),
      ),
      home: InventoryScreen(store: _store),
    );
  }
}
