import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 20),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            _buildHeaderCard(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildInformationCollectionSection(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildInformationUsageSection(context),
            SizedBox(height: Responsive.vertical(context, 24)),
            _buildImportantNoticeSection(context),
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
                  Icons.privacy_tip,
                  color: const Color(0xFF5271FF),
                  size: Responsive.icon(context, 24),
                ),
              ),
              SizedBox(width: Responsive.padding(context, 12)),
              Expanded(
                child: Text(
                  'BuzzOff Privacy Policy',
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
            'BuzzOff is committed to protecting your privacy. This app helps users report, track, and receive information about mosquito-related incidents and public health concerns in your community.',
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

  Widget _buildInformationCollectionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Information We Collect'),
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
              _buildInfoCard(
                context,
                icon: Icons.person,
                title: 'Personal Information',
                subtitle: 'Name, email, phone number, and date of birth when you create or update your profile.',
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildInfoCard(
                context,
                icon: Icons.location_on,
                title: 'Location Data',
                subtitle: 'To help identify and map mosquito-prone areas (only with your permission).',
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildInfoCard(
                context,
                icon: Icons.feedback,
                title: 'Reports and Feedback',
                subtitle: 'Reports and feedback you submit through the app.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformationUsageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('How We Use Your Information'),
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
              _buildUsageCard(
                context,
                icon: Icons.app_settings_alt,
                title: 'To provide and improve app features and services.',
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildUsageCard(
                context,
                icon: Icons.notifications,
                title: 'To notify you about mosquito-related alerts and updates.',
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildUsageCard(
                context,
                icon: Icons.analytics,
                title: 'To analyze trends and help public health efforts in your area.',
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildUsageCard(
                context,
                icon: Icons.block,
                title: 'We do not sell your personal information to third parties.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportantNoticeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Important Notice on False Reports'),
        SizedBox(height: Responsive.vertical(context, 16)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.padding(context, 8)),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: Responsive.icon(context, 24),
                  ),
                ),
                SizedBox(width: Responsive.padding(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Users are strictly prohibited from sending false reports or false alarms.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: Responsive.vertical(context, 8)),
                      Text(
                        'Submitting fake information or malicious reports is a violation of Republic Act No. 10175 (Anti-Cybercrime Law) and may result in legal consequences, including criminal liability. Please use this app responsibly and report only accurate and truthful information to help protect public health and safety.',
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
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Contact Us'),
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
          child: Container(
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.padding(context, 8)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5271FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.email,
                    color: const Color(0xFF5271FF),
                    size: Responsive.icon(context, 24),
                  ),
                ),
                SizedBox(width: Responsive.padding(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'If you have questions or concerns about your privacy, please contact our support team.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: Responsive.vertical(context, 4)),
                      Text(
                        'support@buzzoff.com',
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
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
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

  Widget _buildUsageCard(BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.padding(context, 16)),
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