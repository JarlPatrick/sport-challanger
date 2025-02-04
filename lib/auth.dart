import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:csv/csv.dart';

import 'secret.dart';

class StravaAuthPage extends StatefulWidget {
  @override
  _StravaAuthPageState createState() => _StravaAuthPageState();
}

class _StravaAuthPageState extends State<StravaAuthPage> {
  final String redirectUri = 'http://90.190.108.191/home';
  // 'https://treenix.ee/home'; // Replace with your redirect URI
  // 'http://90.191.76.145/home';
  String? accessToken;
  Map<String, dynamic>? lastActivity;

  Future<void> _authenticate() async {
    // Generate Strava OAuth URL
    final authUrl = Uri.parse('https://www.strava.com/oauth/mobile/authorize?'
        'client_id=$CLIENTID&response_type=code&redirect_uri=$redirectUri&approval_prompt=auto&scope=read,activity:read_all');

    // Open the URL in the browser
    await launchUrl(authUrl);
    // if (await launchUrl(authUrl)) {
    // } else {
    //   throw 'Could not launch $authUrl';
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Color(0x2E2E2E),
      // appBar: AppBar(title: Text('Strava Web Auth')),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        // color: Color(0xFF2E2E2E),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Treenix?', style: TextStyle(fontSize: 30)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _authenticate(),
                child: Text(
                  'START',
                  style: TextStyle(fontSize: 30),
                ),
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     context.go(Uri(path: '/upload').toString());
              //   },
              //   child: Text(
              //     'GO TO UPLOAD',
              //     style: TextStyle(fontSize: 30),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
