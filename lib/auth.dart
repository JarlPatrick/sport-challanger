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

import 'package:csv/csv.dart';

import 'secret.dart';

class StravaAuthPage extends StatefulWidget {
  @override
  _StravaAuthPageState createState() => _StravaAuthPageState();
}

class _StravaAuthPageState extends State<StravaAuthPage> {
  final String redirectUri =
      'https://treenix.ee'; // Replace with your redirect URI
  String? accessToken;
  Map<String, dynamic>? lastActivity;

  Future<void> _authenticate() async {
    // Generate Strava OAuth URL
    final authUrl = Uri.parse('https://www.strava.com/oauth/mobile/authorize?'
        'client_id=$CLIENTID&response_type=code&redirect_uri=$redirectUri&approval_prompt=auto&scope=read,activity:read');

    // Open the URL in the browser
    if (await canLaunch(authUrl.toString())) {
      await launch(authUrl.toString());
    } else {
      throw 'Could not launch $authUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Strava Web Auth')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            ],
          ),
        ),
      ),
    );
  }
}
