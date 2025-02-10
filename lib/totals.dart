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
    Map<String, int> stats = _calculateAllStats();
    return Container(
      height: 400,
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 255, 184, 251),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          for (var entry in stats.entries)
            if (entry.value > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // SizedBox(width: 20),
                  Icon(
                    ikoonid[entry.key],
                    color: Colors.pink,
                    size: 40,
                  ),
                  SizedBox(width: 20),
                  Text(
                    _formatTime(
                        entry.value), // Use a helper method for formatting
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}
