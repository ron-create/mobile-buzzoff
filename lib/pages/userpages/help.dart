import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../theme/app_theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            left: Responsive.padding(context, 20),
            right: Responsive.padding(context, 20),
            top: Responsive.vertical(context, 16),
            bottom: MediaQuery.of(context).padding.bottom + Responsive.vertical(context, 20),
          ),
          children: [
            // Back Button and Title
            Padding(
              padding: EdgeInsets.only(bottom: Responsive.vertical(context, 16)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Help',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 20),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            _buildWelcomeCard(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildFeaturesSection(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildHowToUseSection(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.padding(context, 8)),
                decoration: BoxDecoration(
                  color: const Color(0xFF5271FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: const Color(0xFF5271FF),
                  size: Responsive.icon(context, 24),
                ),
              ),
              SizedBox(width: Responsive.padding(context, 12)),
              Expanded(
                child: Text(
                  'Welcome to BuzzOff!',
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.vertical(context, 12)),
          Text(
            'BuzzOff is a community-driven app designed to help you and your neighbors fight mosquito-borne diseases like dengue.',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Main Features'),
        SizedBox(height: Responsive.vertical(context, 16)),
        _buildFeatureCard(
          context,
          icon: Icons.report,
          title: 'Report Dengue Cases',
          subtitle: 'Notify your local health authorities about suspected or confirmed dengue cases in your area.',
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        _buildFeatureCard(
          context,
          icon: Icons.water_drop,
          title: 'Report Breeding Sites',
          subtitle: 'Help eliminate mosquito breeding grounds by reporting stagnant water or potential breeding sites.',
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        _buildFeatureCard(
          context,
          icon: Icons.visibility,
          title: 'View Reports',
          subtitle: 'Track dengue cases and breeding site reports in your barangay.',
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        _buildFeatureCard(
          context,
          icon: Icons.notifications_active,
          title: 'Receive Alerts',
          subtitle: 'Get notified about dengue outbreaks and important health reminders.',
        ),
      ],
    );
  }

  Widget _buildHowToUseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'How to Use'),
        SizedBox(height: Responsive.vertical(context, 16)),
        _buildStepCard(
          context,
          step: '1',
          icon: Icons.login,
          title: 'Register or log in to your account.',
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        _buildStepCard(
          context,
          step: '2',
          icon: Icons.add_circle_outline,
          title: 'Use the "+" button to submit a new dengue case or breeding site report.',
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        _buildStepCard(
          context,
          step: '3',
          icon: Icons.edit_note,
          title: 'Fill out the required details and submit.',
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        _buildStepCard(
          context,
          step: '4',
          icon: Icons.assignment_turned_in,
          title: 'Check the "Your Reports" section to view the status of your submissions.',
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        _buildStepCard(
          context,
          step: '5',
          icon: Icons.notifications,
          title: 'Stay updated with alerts and notifications from your barangay.',
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Need More Help?'),
        SizedBox(height: Responsive.vertical(context, 16)),
        _buildContactCard(
          context,
          icon: Icons.email,
          title: 'Contact our support team',
          subtitle: 'support@buzzoff.com',
          onTap: () {
            // Add email functionality here
          },
        ),
        SizedBox(height: Responsive.vertical(context, 12)),
        _buildContactCard(
          context,
          icon: Icons.location_city,
          title: 'Visit your local barangay office',
          subtitle: 'For in-person assistance and support.',
          onTap: () {
            // Add location functionality here
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.padding(context, 8)),
            decoration: BoxDecoration(
              color: const Color(0xFF5271FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5271FF),
              size: Responsive.icon(context, 20),
            ),
          ),
          SizedBox(width: Responsive.padding(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: Responsive.vertical(context, 4)),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, {
    required String step,
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF5271FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.padding(context, 12)),
          Icon(
            icon,
            color: const Color(0xFF5271FF),
            size: Responsive.icon(context, 20),
          ),
          SizedBox(width: Responsive.padding(context, 12)),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(Responsive.padding(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.padding(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF5271FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF5271FF),
                size: Responsive.icon(context, 20),
              ),
            ),
            SizedBox(width: Responsive.padding(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: Responsive.vertical(context, 4)),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF333333),
      ),
    );
  }
} 