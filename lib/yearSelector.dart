import 'package:flutter/material.dart';

import '_colors.dart';
import 'home.dart';

class Yearselector extends StatelessWidget {
  final Function(int) setYearCallback;
  final int YEAR;
  final Function(TreenixView) viewStateCallback;

  const Yearselector({
    super.key,
    required this.YEAR,
    required this.setYearCallback,
    required this.viewStateCallback,
  });

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
            YEAR.toString(),
            style: TextStyle(
              fontSize: 40,
              color: TreenixColors.primaryPink,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                width: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TreenixColors.lightGray,
                  ),
                  onPressed: () {
                    setYearCallback(YEAR - 1);
                  },
                  child: Text(
                    "-",
                    style: TextStyle(
                      fontSize: 20,
                      color: TreenixColors.primaryPink,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              SizedBox(
                width: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TreenixColors.lightGray,
                  ),
                  onPressed: () {
                    setYearCallback(YEAR + 1);
                  },
                  child: Text(
                    "+",
                    style: TextStyle(
                      fontSize: 20,
                      color: TreenixColors.primaryPink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TreenixColors.lightGray,
            ),
            onPressed: () {
              viewStateCallback(TreenixView.Map);
            },
            child: Text(
              "Map",
              style: TextStyle(
                fontSize: 13,
                color: TreenixColors.primaryPink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
