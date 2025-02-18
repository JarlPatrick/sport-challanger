import 'package:Treenix/_colors.dart';
import 'package:flutter/material.dart';

class Totals extends StatelessWidget {
  final List<Map<String, dynamic>>
      allActivities; // List of all activities with detailed info
  Totals({
    required this.allActivities,
  });

  Map<String, IconData> ikoonid = {
    'cycling': Icons.directions_bike,
    'running': Icons.directions_run,
    'swimming': Icons.pool,
    'skiing': Icons.downhill_skiing,
    'others': Icons.question_mark,
    'walking': Icons.directions_walk,
    'hiking': Icons.hiking_rounded,
  };

  Map<String, int> _calculateAllStats() {
    // Initialize stats for the week
    int cyclingMinutes = 0;
    int runningMinutes = 0;
    int swimmingMinutes = 0;
    int skiingMinutes = 0;
    int walkingMinutes = 0;
    int hikinggMinutes = 0;
    int othersMinutes = 0;
    for (var activity in allActivities) {
      final activityDate = DateTime.parse(activity['start_date']);
      final String type = activity['type'];
      final int duration =
          activity['moving_time'] ~/ 60; // Convert seconds to minutes
      switch (type) {
        case 'Ride':
          cyclingMinutes += duration;
          break;
        case 'VirtualRide':
          cyclingMinutes += duration;
          break;
        case 'Run':
          runningMinutes += duration;
          break;
        case 'Swim':
          swimmingMinutes += duration;
          break;
        case 'NordicSki':
          skiingMinutes += duration;
          break;
        case 'Walk':
          walkingMinutes += duration;
          break;
        case 'Hike':
          hikinggMinutes += duration;
          break;
        default:
          othersMinutes += duration;
          break;
      }
    }

    return {
      'cycling': cyclingMinutes,
      'running': runningMinutes,
      'swimming': swimmingMinutes,
      'skiing': skiingMinutes,
      'walking': walkingMinutes,
      'hiking': hikinggMinutes,
      'others': othersMinutes,
    };
  }

  String _formatTime(int minutes) {
    int hours = minutes ~/ 60; // Calculate hours
    int remainingMinutes = minutes % 60; // Calculate remaining minutes

    return '${hours}:${remainingMinutes.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    // Map<String, int> stats = _calculateAllStats();
    Map<String, int> stats = Map.fromEntries(
        _calculateAllStats().entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)));

    return Container(
        height: 160,
        width: 600,
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
                if (entry.value > 0) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // SizedBox(width: 20),
                      Icon(
                        ikoonid[entry.key],
                        color: TreenixColors.primaryPink,
                        size: 50,
                      ),
                      SizedBox(height: 10),
                      Text(
                        _formatTime(
                            entry.value), // Use a helper method for formatting
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
