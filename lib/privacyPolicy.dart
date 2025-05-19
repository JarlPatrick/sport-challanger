import 'package:flutter/material.dart';

import '_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TreenixColors.lightGray,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Material(
              color: TreenixColors.grayBackground,
              // appBar: AppBar(
              //   backgroundColor: TreenixColors.lightGray,
              //   title: const Text('Privacy Policy'),
              // ),
              child: Container(
                width: 800,
                // height: 800,
                child: const SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: TreenixColors.darkPink,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Effective Date: 19. May 2025',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('1. Introduction'),
                      _Text(
                        'Welcome to Treenix.ee, operated by Berserker Legion OÜ, an Estonian company. '
                        'We are committed to protecting your privacy and ensuring that your personal data is handled securely '
                        'and in accordance with applicable data protection laws, including the EU General Data Protection Regulation (GDPR).',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('2. What Data We Collect'),
                      SizedBox(height: 8),
                      _SubSectionTitle('2.1 Personal Information'),
                      SizedBox(height: 4),
                      _Text('- Name\n'
                          '- Email address'),
                      SizedBox(height: 4),
                      _SubSectionTitle('2.2 Strava Activity Data'),
                      SizedBox(height: 4),
                      _Text('- Activity date, type, name, length and duration\n'
                          '- GPS data (location, time, routes)'
                          // '- Heart rate and other biometric metrics\n'
                          // '- Activity time and date\n'
                          // '- Other metrics Garmin provides and you permit us to access',
                          ),
                      // _SubSectionTitle(
                      //     '2.2 Garmin Activity Data (via Garmin Connect API)'),
                      // _Text(
                      //   '- Activity type and duration\n'
                      //   '- GPS data (location, routes)\n'
                      //   '- Heart rate and other biometric metrics\n'
                      //   '- Activity time and date\n'
                      //   '- Other metrics Garmin provides and you permit us to access',
                      // ),
                      SizedBox(height: 16),
                      _SectionTitle('3. How We Use Your Data'),
                      _Text(
                        'We use your data to:\n'
                        '- Analyze and visualize your activities to you\n'
                        '- Personalize your experience\n'
                        '- Communicate with you about updates or issues\n'
                        '- Provide and improve Treenix features (e.g., activity tracking and overview, gamification)\n'
                        '- Fulfill legal obligations\n\n'
                        'We do not sell or any other way give away your personal data to any third parties.',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('4. Data Storage'),
                      _Text(
                        'Your data is stored securely in Amazon Web Services (AWS), using PostgreSQL databases and Amazon S3. '
                        // 'Data may be retained for a long period unless you request deletion.'
                        'Your data is stored as long as you have an account (You have the right to request deletion of your data at any time).',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('5. Your Rights'),
                      _Text(
                        'Under GDPR, you have the right to:\n'
                        '- Access your data\n'
                        '- Correct inaccuracies\n'
                        '- Delete all your data\n'
                        '- Withdraw consent and disconnect Strava\n'
                        // '- Withdraw consent and disconnect Garmin\n'
                        '- Object to certain processing\n'
                        '- File a complaint with the Estonian Data Protection Inspectorate or your local authority',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('6. Deleting Your Data'),
                      _Text(
                        'You can delete your account and all associated data at any time. '
                        'You may also disconnect Strava to stop further data syncing.',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('7. Data Sharing'),
                      _Text(
                        'We do not share your data except:\n'
                        // '- To comply with legal obligations\n'
                        // '- With service providers under strict agreements\n'
                        '- With your explicit consent',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('8. International Data Transfers'),
                      _Text(
                        'While servers are hosted in the EU, data may be processed elsewhere by providers. '
                        'We use safeguards such as Standard Contractual Clauses.',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('9. Cookies and Tracking'),
                      _Text(
                        'Treenix.ee currently does not use cookies or tracking technologies. This may change in the future.',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('10. Changes to This Policy'),
                      _Text(
                        'We may update this policy as needed. Check this page for updates. The effective date will be updated accordingly.',
                      ),
                      SizedBox(height: 16),
                      _SectionTitle('11. Contact Us'),
                      _Text(
                        'Berserker Legion OÜ\n'
                        'Email: treenixapp@gmail.com\n'
                        'Address:  Uus tn 60, Tartu, Estonia',
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _SubSectionTitle extends StatelessWidget {
  final String text;
  const _SubSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        // fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class _Text extends StatelessWidget {
  final String text;
  const _Text(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        // fontSize: 18,
        // fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
    );
  }
}
