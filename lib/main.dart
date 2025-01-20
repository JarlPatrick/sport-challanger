import 'dart:ui_web';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'auth.dart';
import 'home.dart';

void main() {
  usePathUrlStrategy();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Challanger",
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => StravaAuthPage(),
          ),
          GoRoute(
            path: "/home",
            builder: (context, state) => Home(
                // activityId: state.uri.queryParameters["activityId"]),
                ),
          ),
        ],
      ),
      // theme: ThemeData(
      //   useMaterial3: true,
      //   // Define the default brightness and colors.
      //   colorScheme: ColorScheme.fromSeed(
      //     seedColor: const Color.fromARGB(255, 0, 255, 255),
      //     brightness: Brightness.dark,
      //   ),

      //   textTheme: TextTheme(
      //     displayLarge: const TextStyle(
      //       fontSize: 72,
      //       fontWeight: FontWeight.bold,
      //     ),
      //     // ···
      //     titleLarge: GoogleFonts.oswald(
      //       fontSize: 30,
      //       fontStyle: FontStyle.italic,
      //     ),
      //     bodyMedium: GoogleFonts.merriweather(),
      //     displaySmall: GoogleFonts.pacifico(),
      //   ),
      // ),
    );
  }
}
