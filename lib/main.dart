import 'dart:ui_web';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'auth.dart';
import 'home.dart';
import 'upload.dart';

void main() {
  // usePathUrlStrategy();

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
    // String? authCode = Uri.base.queryParameters['code'];

    // if (authCode != null) {
    //   return MaterialApp(home: Home());
    // } else {
    //   return MaterialApp(home: StravaAuthPage());
    // }

    return MaterialApp.router(
      title: "Challanger",
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            // builder: (context, state) => StravaAuthPage(),
            builder: (context, state) => Upload(),
          ),
          // GoRoute(
          //   path: "/home",
          //   builder: (context, state) => Home(),
          // ),
          // GoRoute(
          //   path: "/upload",
          //   builder: (context, state) => Upload(),
          // ),
        ],
      ),
    );
  }
}
