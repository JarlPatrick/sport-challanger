// import 'dart:convert';
// import 'package:activity_challenge/home.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';

// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:go_router/go_router.dart';
// import 'package:amplify_flutter/amplify_flutter.dart';

// import 'package:csv/csv.dart';

// import 'secret.dart';

// class StravaAuthPage extends StatefulWidget {
//   @override
//   _StravaAuthPageState createState() => _StravaAuthPageState();
// }

// class _StravaAuthPageState extends State<StravaAuthPage> {
//   final String redirectUri =
//       // 'http://90.190.108.191/home';
//       'https://treenix.ee/home'; // Replace with your redirect URI
//   // 'http://90.191.76.145/home';
//   String? accessToken;
//   Map<String, dynamic>? lastActivity;

//   Future<void> _authenticate() async {
//     // Generate Strava OAuth URL
//     final authUrl = Uri.parse('https://www.strava.com/oauth/mobile/authorize?'
//         'client_id=$CLIENTID&response_type=code&redirect_uri=$redirectUri&approval_prompt=auto&scope=read,activity:read_all');

//     // Open the URL in the browser
//     await launchUrl(authUrl);
//   }

//   bool connected = false;
//   bool loaded = false;

//   @override
//   void initState() {
//     loadinit();
//   }

//   void loadinit() async {
//     bool wtf = await getStravaAccessToken();
//     print(wtf);
//     setState(() {
//       connected = wtf;
//       loaded = true;
//     });
//   }

//   Future<String> getToken() async {
//     final result = await Amplify.Auth.fetchAuthSession();
//     // print(result);
//     // print("");
//     var a = result.toString().split("idToken")[1];
//     var b = a.split('"')[2];
//     var token = b.split('\"')[0];
//     return token;
//   }

//   Future<bool> getStravaAccessToken() async {
//     String lambdaUrl =
//         "https://6iks67rav1.execute-api.eu-north-1.amazonaws.com/default/strava-get-access-token";
//     try {
//       String token = await getToken();
//       // print(token);

//       final response = await http.post(
//         Uri.parse(lambdaUrl),
//         // headers: {"a": "b"},
//         headers: <String, String>{
//           "Authorization": token,
//         },
//         body: jsonEncode({
//           "code": "",
//         }),
//       );
//       print(response.body);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         print(data);
//         return data["access_token"] != null;
//       } else {
//         print("Error: ${response.statusCode} - ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       print("Exception: $e");
//       return false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return loaded
//         ? !connected
//             ? Scaffold(
//                 body: Container(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text('Treenix?', style: TextStyle(fontSize: 30)),
//                         SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: () => _authenticate(),
//                           child: Text(
//                             'START',
//                             style: TextStyle(fontSize: 30),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               )
//             : Home()
//         : Placeholder();
//   }
// }
