import 'package:flutter/material.dart';

import '_colors.dart';
import 'home.dart';

class Yearselector extends StatefulWidget {
  final Function(int) setYearCallback;
  final int YEAR;
  final Function(TreenixView) viewStateCallback;
  final Function(bool) setSummryTypeCallback;

  const Yearselector({
    super.key,
    required this.YEAR,
    required this.setYearCallback,
    required this.viewStateCallback,
    required this.setSummryTypeCallback,
  });

  @override
  State<Yearselector> createState() => _YearselectorState();
}

class _YearselectorState extends State<Yearselector> {
  bool SummaryIsMinutes = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: TreenixColors.grayBackground,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            widget.YEAR.toString(),
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Material(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: InkWell(
                    hoverColor: TreenixColors.primaryPink,
                    onTap: () {
                      widget.setYearCallback(widget.YEAR - 1);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              if (DateTime.now().year > widget.YEAR)
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Material(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    child: InkWell(
                      hoverColor: TreenixColors.primaryPink,
                      onTap: () {
                        widget.setYearCallback(widget.YEAR + 1);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Material(
                    color: const Color.fromARGB(255, 100, 100, 100),
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        width: 50,
                        height: 50,
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                )
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                "km",
                style: TextStyle(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              Switch(
                // This bool value toggles the switch.
                value: SummaryIsMinutes,
                activeColor: TreenixColors.primaryPink,
                onChanged: (bool value) {
                  // This is called when the user toggles the switch.
                  widget.setSummryTypeCallback(value);
                  setState(() {
                    SummaryIsMinutes = value;
                  });
                },
              ),
              Text(
                "h:min",
                style: TextStyle(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ],
          )
          // ElevatedButton(
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: TreenixColors.lightGray,
          //   ),
          //   onPressed: () {
          //     viewStateCallback(TreenixView.Map);
          //   },
          //   child: Text(
          //     "Map",
          //     style: TextStyle(
          //       fontSize: 13,
          //       color: TreenixColors.primaryPink,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
