import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html'; // For web-specific functionality.
import 'dart:typed_data';

import 'calendar_view.dart';
import 'j-index.dart';
import 'totals.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  State<Upload> createState() => _UploadState();
}

int YEAR = 2025;
List<int> possibleYears = [];

class _UploadState extends State<Upload> {
  Map<DateTime, bool> _activityDurations = {};
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _allactivities = [];

  Future<void> pickAndReadFile() async {
    // Create an invisible file input element
    FileUploadInputElement uploadInput = FileUploadInputElement();
    uploadInput.accept = '.txt,.json,.csv'; // Specify allowed file types
    uploadInput.click(); // Programmatically trigger the file picker dialog

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files; // Get the selected files
      if (files != null && files.isNotEmpty) {
        final file = files.first; // Take the first file
        final reader = FileReader();

        // Read file content as text
        reader.readAsText(file);

        // Wait for the file to load
        reader.onLoadEnd.listen((event) {
          String fileContent = reader.result as String;
          List<List<dynamic>> rowsAsListOfValues =
              const CsvToListConverter(eol: "\n").convert(fileContent);

          rowsAsListOfValues.removeAt(0);

          List<Map<String, dynamic>> allActivities = [];

          DateFormat format = DateFormat("MMM d, y, h:mm:ss a");
          // List<Map<String, dynamic>> allActivities = [];
          for (final row in rowsAsListOfValues) {
            Map<String, dynamic> activity = {};
            activity["id"] = row[0];
            String dateString = row[1];
            activity["start_date"] = format.parse(dateString).toString();
            activity["name"] = row[2];
            activity["type"] = row[3];
            activity["elapsed_time"] = row[5];
            activity["distance"] = row[6];
            activity["moving_time"] = row[16];

            int year = format.parse(dateString).year;
            if (!possibleYears.contains(year)) {
              possibleYears.add(year);
            }

            allActivities.add(activity);
          }

          setState(() {
            _allactivities = allActivities;
          });

          LoadData(); // Do something with the file content
        });
      }
    });
  }

  Future<void> LoadData() async {
    Map<DateTime, bool> activityDurations = {};
    List<Map<String, dynamic>> activities = [];

    for (var activity in _allactivities) {
      final parsedDate = DateTime.parse(activity['start_date']);
      final normalizedDate =
          DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final durationSeconds = activity['moving_time'];
      // print(durationSeconds);
      final isLongActivity = durationSeconds > 20 * 60; // 20 minutes

      if (activityDurations.containsKey(normalizedDate)) {
        activityDurations[normalizedDate] =
            activityDurations[normalizedDate]! || isLongActivity;
      } else {
        activityDurations[normalizedDate] = isLongActivity;
      }

      if (parsedDate.year == YEAR) {
        activities.add(activity);
      }
    }

    setState(() {
      _activityDurations = activityDurations;
      _activities = activities;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text('Treenix?', style: TextStyle(fontSize: 30)),
                  SizedBox(height: 30),
                  Text(
                      "1. Log into the account on Strava.com from which you wish to bulk export data."),
                  SizedBox(height: 10),
                  Text(
                      '2. Hover over your name in the upper right-hand corner of the Strava page.\n Choose "Settings," then find the "My Account" tab from the menu listed on the Left.'),
                  SizedBox(height: 10),
                  Text(
                      '3. Select “Get Started” under “Download or Delete Your Account.”'),
                  SizedBox(height: 10),
                  Text("4. Select “Request your archive” on the next page."),
                  SizedBox(height: 10),
                  Text(
                      "5. You will receive an email with a link to download your data (this may take a few hours.) \n For this reason, it’s important that you have access to the email account attached to your Strava profile."),
                  SizedBox(height: 10),
                  Text("6. Download and unzip your data"),
                  SizedBox(height: 10),
                  Text(
                      '7. Press the button bellow and file named "activities.csv"'),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: pickAndReadFile,
                    child: Text('Select "activities.csv"',
                        style: TextStyle(fontSize: 30)),
                  ),
                ],
              ),
            )
          : Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  CalendarView(
                    activityDurations: _activityDurations,
                    allActivities: _activities,
                    YEAR: YEAR,
                    columns: true,
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(height: 20),
                      for (int year in possibleYears) ...[
                        ElevatedButton(
                            onPressed: () {
                              YEAR = year;
                              LoadData();
                            },
                            child: Text(
                              year.toString(),
                              style: TextStyle(fontSize: 15),
                            )),
                        SizedBox(height: 5),
                      ],
                      SizedBox(height: 15),
                      JarlsNumber(allActivities: _activities),
                      SizedBox(height: 30),
                      Totals(allActivities: _activities),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
