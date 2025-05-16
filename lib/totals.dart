import 'package:Treenix/_colors.dart';
import 'package:flutter/material.dart';

class Totals extends StatelessWidget {
  final List<Map<String, dynamic>>
      allActivities; // List of all activities with detailed info
  Totals({
    required this.allActivities,
  });

  Map<String, Map<String, dynamic>> allTypes = {
    'Ride': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.directions_bike,
    },
    'VirtualRide': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.directions_bike,
    },
    'Run': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.directions_run,
    },
    'Swim': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.pool,
    },
    'NordicSki': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.downhill_skiing,
    },
    'Walk': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.directions_walk,
    },
    'Hike': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.hiking_rounded,
    },
    'Rowing': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.rowing,
    },
    'Kayaking': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.kayaking,
    },
    // 'WeightTraining': {
    //   'minutes': 0,
    //   'meters': 0.0,
    // },
    'Other': {
      'minutes': 0,
      'meters': 0.0,
      'icon': Icons.question_mark,
    },
  };

  // Map<String, IconData> ikoonid = {
  //   'cycling': Icons.directions_bike,
  //   'running': Icons.directions_run,
  //   'swimming': Icons.pool,
  //   'skiing': Icons.downhill_skiing,
  //   'others': Icons.question_mark,
  //   'walking': Icons.directions_walk,
  //   'hiking': Icons.hiking_rounded,
  // };

  Map<String, Map<String, dynamic>> _calculateAllStats() {
    // Initialize stats for the week
    // int cyclingMinutes = 0;
    // int runningMinutes = 0;
    // int swimmingMinutes = 0;
    // int skiingMinutes = 0;
    // int walkingMinutes = 0;
    // int hikinggMinutes = 0;
    // int othersMinutes = 0;
    for (var activity in allActivities) {
      final activityDate = DateTime.parse(activity['start_date']);
      final String type = activity['type'];
      int duration =
          activity['moving_time'] ~/ 60; // Convert seconds to minutes
      int distance = activity['distance'] ~/ 1;
      if (allTypes.keys.contains(type)) {
        allTypes[type]!["minutes"] += duration;
        allTypes[type]!["meters"] += distance;
      } else {
        allTypes["Other"]!["minutes"] += duration;
        // allTypes["Other"]!["meters"] +=
        //     double.parse(activity['distance'] / 1000);
      }
      // switch (type) {
      //   case 'Ride':
      //     cyclingMinutes += duration;
      //     break;
      //   case 'VirtualRide':
      //     cyclingMinutes += duration;
      //     break;
      //   case 'Run':
      //     runningMinutes += duration;
      //     break;
      //   case 'Swim':
      //     swimmingMinutes += duration;
      //     break;
      //   case 'NordicSki':
      //     skiingMinutes += duration;
      //     break;
      //   case 'Walk':
      //     walkingMinutes += duration;
      //     break;
      //   case 'Hike':
      //     hikinggMinutes += duration;
      //     break;
      //   default:
      //     othersMinutes += duration;
      //     break;
      // }
    }

    return allTypes;
  }

  String _formatTime(int minutes) {
    int hours = minutes ~/ 60; // Calculate hours
    int remainingMinutes = minutes % 60; // Calculate remaining minutes

    return '${hours}:${remainingMinutes.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, dynamic>> stats = _calculateAllStats();
    // Map<String, int> stats = Map.fromEntries(
    //     _calculateAllStats().entries.toList()
    //       ..sort((a, b) => b.value.compareTo(a.value)));

    return Container(
        height: 160,
        width: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: TreenixColors.grayBackground,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(width: 20),
              for (var entry in stats.entries)
                if (entry.value["minutes"] > 0) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // SizedBox(width: 20),
                      Icon(
                        entry.value["icon"],
                        // ikoonid[entry.key],
                        color: TreenixColors.primaryPink,
                        size: 50,
                      ),
                      SizedBox(height: 10),
                      Text(
                        _formatTime(entry.value[
                            "minutes"]), // Use a helper method for formatting
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TreenixColors.lightGray,
                        ),
                      ),
                      Text(
                        "${(entry.value["meters"] / 1000).toStringAsFixed(0)} km",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TreenixColors.lightGray,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 20),
                ],
            ],
          ),
        ));
  }
}
