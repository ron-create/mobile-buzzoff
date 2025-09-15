import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
            _buildHeaderCard(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildFeaturesSection(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
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
                  'BuzzOffPH: Dengue Prevention and Mapping App',
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
            'BuzzOffPH is an innovative mobile and web application designed to empower communities in the fight against dengue. Through real-time case reporting, interactive maps, and AI-driven education, our app provides essential tools for prevention and awareness.',
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
        _sectionTitle('Features'),
        SizedBox(height: Responsive.vertical(context, 16)),
        Container(
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
          child: Column(
            children: [
              _buildFeatureCard(
                context,
                icon: Icons.map,
                title: 'Interactive Dengue Case Mapping',
                subtitle: 'View real-time reports of dengue cases and breeding sites near you.',
                iconColor: Colors.green,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildFeatureCard(
                context,
                icon: Icons.notifications_active,
                title: 'Real-Time Alerts',
                subtitle: 'Receive notifications for high-risk areas and emerging outbreaks.',
                iconColor: Colors.red,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildFeatureCard(
                context,
                icon: Icons.school,
                title: 'AI-Assisted Learning',
                subtitle: 'Get dengue prevention tips through an interactive chatbot.',
                iconColor: Colors.blue,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildFeatureCard(
                context,
                icon: Icons.analytics,
                title: 'Data-Driven Insights',
                subtitle: 'Local government units can access trends for better prevention strategies.',
                iconColor: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Need Assistance? Contact Us!'),
        SizedBox(height: Responsive.vertical(context, 16)),
        Container(
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
          child: Column(
            children: [
              _buildContactCard(
                context,
                icon: Icons.email,
                title: 'Email',
                subtitle: 'support@buzzoffph.com',
                iconColor: Colors.blue,
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildContactCard(
                context,
                icon: Icons.phone,
                title: 'Phone',
                subtitle: '+63 912 345 6789',
                iconColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.padding(context, 8)),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
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

  Widget _buildContactCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.padding(context, 8)),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }
}
