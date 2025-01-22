import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import 'calendar_view.dart';
import 'j-index.dart';
import 'totals.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  State<Upload> createState() => _UploadState();
}

int YEAR = 2025;

class _UploadState extends State<Upload> {
  Map<DateTime, bool> _activityDurations = {};
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _allactivities = [];

  bool _dragging = false;
  Future<void> printFiles(List<DropItem> files, [int depth = 0]) async {
    for (final file in files) {
      String content = await file.readAsString();

      List<List<dynamic>> rowsAsListOfValues =
          const CsvToListConverter(eol: "\n").convert(content);

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

        allActivities.add(activity);
      }

      // print(allActivities[0]);
      // print(allActivities.last);

      setState(() {
        _allactivities = allActivities;
      });

      LoadData();
    }
  }

  Future<void> LoadData() async {
    Map<DateTime, bool> activityDurations = {};
    List<Map<String, dynamic>> activities = [];

    for (var activity in _allactivities) {
      final parsedDate = DateTime.parse(activity['start_date']);
      final normalizedDate =
          DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final durationSeconds = activity['moving_time'];
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
              child: DropTarget(
                onDragDone: (detail) async {
                  await printFiles(detail.files);
                },
                onDragUpdated: (details) {},
                onDragEntered: (detail) {
                  setState(() {
                    _dragging = true;
                  });
                },
                onDragExited: (detail) {
                  setState(() {
                    _dragging = false;
                  });
                },
                child: Container(
                  height: 200,
                  width: 200,
                  color:
                      _dragging ? Colors.blue.withOpacity(0.4) : Colors.black26,
                  child: Stack(
                    children: [
                      Center(child: Text("Drop here (activities.csv)")),
                    ],
                  ),
                ),
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
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(height: 20),
                      for (int i = 2019; i <= 2025; i++) ...[
                        ElevatedButton(
                            onPressed: () {
                              YEAR = i;
                              LoadData();
                            },
                            child: Text(
                              i.toString(),
                              style: TextStyle(fontSize: 15),
                            )),
                        SizedBox(height: 5),
                      ],
                      // SizedBox(height: 30),
                      // ElevatedButton(
                      //     onPressed: () {
                      //       YEAR = 2024;
                      //       LoadData();
                      //     },
                      //     child: Text("2024", style: TextStyle(fontSize: 30))),
                      // SizedBox(height: 30),
                      // ElevatedButton(
                      //     onPressed: () {
                      //       YEAR = 2025;
                      //       LoadData();
                      //     },
                      //     child: Text("2025", style: TextStyle(fontSize: 30))),
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
