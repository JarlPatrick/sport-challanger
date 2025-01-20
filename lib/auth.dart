import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class StravaAuthPage extends StatefulWidget {
  @override
  _StravaAuthPageState createState() => _StravaAuthPageState();
}

class _StravaAuthPageState extends State<StravaAuthPage> {
  final String clientId = '111297'; // Replace with your client ID
  final String clientSecret =
      '9165c87e1af5ed7f4d8d5a89c564ae63af97cbc7'; // Replace with your client secret
  final String redirectUri =
      'http://90.191.76.145/home'; // Replace with your redirect URI
  String? accessToken;
  Map<String, dynamic>? lastActivity;

  Future<void> _authenticate() async {
    // Generate Strava OAuth URL
    final authUrl = Uri.parse('https://www.strava.com/oauth/mobile/authorize?'
        'client_id=$clientId&response_type=code&redirect_uri=$redirectUri&approval_prompt=auto&scope=read,activity:read');

    // Open the URL in the browser
    if (await canLaunch(authUrl.toString())) {
      await launch(authUrl.toString());
    } else {
      throw 'Could not launch $authUrl';
    }
  }

  Future<void> _handleAuthCode() async {
    // final tokenUrl = Uri.parse('https://www.strava.com/oauth/token');
    // String? authCode = Uri.base.queryParameters['code'];

    // // Exchange auth code for access token
    // final response = await http.post(
    //   tokenUrl,
    //   body: {
    //     'client_id': clientId,
    //     'client_secret': clientSecret,
    //     'code': authCode,
    //     'grant_type': 'authorization_code',
    //   },
    // );

    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   setState(() {
    //     accessToken = data['access_token'];
    //   });

    //   print('Access Token: $accessToken');
    // } else {
    //   print('Failed to get access token: ${response.body}');
    // }
  }

  Future<void> _getAthlete() async {
    String? code = Uri.base.queryParameters['code'];

    // final url = Uri.parse('https://www.strava.com/api/v3/athlete/activities');
    final url = Uri.parse('https://www.strava.com/api/v3/athlete');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $code'},
    );

    if (response.statusCode == 200) {
      final activities = jsonDecode(response.body);
      if (activities.isNotEmpty) {
        setState(() {
          lastActivity = activities[0];
        });
      }
    } else {
      print('Failed to fetch activities: ${response.body}');
    }
  }

  Future<void> _getLastActivity() async {
    if (accessToken == null) {
      print('Authenticate first.');
      return;
    }

    final url = Uri.parse('https://www.strava.com/api/v3/athlete/activities');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final activities = jsonDecode(response.body);
      if (activities.isNotEmpty) {
        setState(() {
          lastActivity = activities[0];
        });
        print(activities.length);
      }
    } else {
      print('Failed to fetch activities: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Strava Web Auth')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lastActivity != null)
              Column(
                children: [
                  Text('Last Activity:', style: TextStyle(fontSize: 20)),
                  Text('Name: ${lastActivity!['name']}'),
                  Text('Distance: ${lastActivity!['distance']} meters'),
                ],
              )
            else
              Text('No activity loaded.'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _authenticate(),
              child: Text('Authenticate'),
            ),
            ElevatedButton(
              onPressed: () {
                // Replace with your actual auth code for local testing
                _handleAuthCode();
              },
              child: Text('Fetch Access Token'),
            ),
            ElevatedButton(
              onPressed: () {
                _getAthlete();
              },
              child: Text('Get Athlete'),
            ),
            ElevatedButton(
              onPressed: _getLastActivity,
              child: Text('Get Last Activity'),
            ),
          ],
        ),
      ),
    );
  }
}
