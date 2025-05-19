import 'dart:ui_web';

import 'package:Treenix/mapTerraX.dart';
import 'package:Treenix/mapheatmap.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import 'amplifyconfiguration.dart';

// import 'auth.dart';
import 'home.dart';
import 'privacyPolicy.dart';

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
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      await Amplify.addPlugin(AmplifyAuthCognito());
      await Amplify.configure(amplifyconfig);
      safePrint('Successfully configured');
    } on Exception catch (e) {
      safePrint('Error configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Treenix",
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Authenticator(
              child: MaterialApp(
                builder: Authenticator.builder(),
                home: Home(),
              ),
            ),
          ),
          GoRoute(
            path: '/terrax',
            builder: (context, state) => Authenticator(
              child: MaterialApp(
                builder: Authenticator.builder(),
                home: MapTerraX(),
              ),
            ),
          ),
          GoRoute(
            path: '/heatmap',
            // builder: (context, state) => MapHeatmap(),
            builder: (context, state) => Authenticator(
              child: MaterialApp(
                builder: Authenticator.builder(),
                home: MapHeatmap(),
              ),
            ),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (context, state) => PrivacyPolicyScreen(),
          ),
        ],
      ),
    );
    // return Authenticator(
    //   child: MaterialApp.router(
    //     title: "Treenix",
    //     builder: Authenticator.builder(),
    //     // color: Color(0x2E2E2E),
    //     routerConfig: GoRouter(
    //       routes: [
    //         GoRoute(
    //           path: '/',
    //           // builder: (context, state) => StravaAuthPage(),
    //           builder: (context, state) => Home(),
    //         ),
    //         GoRoute(
    //           path: '/terrax',
    //           // builder: (context, state) => StravaAuthPage(),
    //           builder: (context, state) => MapTerraX(),
    //         ),
    //         GoRoute(
    //           path: '/heatmap',
    //           // builder: (context, state) => StravaAuthPage(),
    //           builder: (context, state) => MapHeatmap(),
    //         ),
    //         // GoRoute(
    //         //   path: "/home",
    //         //   builder: (context, state) => Home(),
    //         // ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
