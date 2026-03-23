import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/api_client.dart';
import 'services/inventory_api.dart';
import 'state/inventory_store.dart';
import 'ui/inventory_screen.dart';

class AccessoriesApp extends StatelessWidget {
  final String baseUrl;
  final String companyId;

  const AccessoriesApp({
    super.key,
    required this.baseUrl,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final api = InventoryApi(ApiClient(baseUrl: baseUrl));

    const brandPrimary = Color(0xFF0284C7);
    const surfaceTint = Color(0xFFF0F9FF);
    const border = Color(0xFFE2E8F0);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryStore(api: api, companyId: companyId)),
      ],
      child: MaterialApp(
        title: 'Accessories',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: brandPrimary).copyWith(
            primary: brandPrimary,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: surfaceTint,
          textTheme: GoogleFonts.nunitoSansTextTheme().copyWith(
            titleLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            titleMedium: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            labelLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            labelMedium: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: brandPrimary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
              elevation: 4,
              shadowColor: const Color(0xFF023E6B),
            ).copyWith(
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) return 1;
                return 4;
              }),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: border, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: Color(0xFFD0EDFB), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: brandPrimary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        home: const InventoryScreen(),
      ),
    );
  }
}
