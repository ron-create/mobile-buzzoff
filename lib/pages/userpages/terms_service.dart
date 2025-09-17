import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
            bottom: MediaQuery.of(context).padding.bottom +
                Responsive.vertical(context, 20),
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
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: Responsive.font(context, 20),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            _buildHeaderCard(context),
            SizedBox(height: Responsive.vertical(context, 24)),

            _buildTermsSection(
              context,
              icon: Icons.info_outline,
              title: '1. Introduction',
              content:
                  'BuzzOffPH ("we", "us", "our") provides tools to report, track, and manage mosquito-related public health concerns. By using this app, you agree to these Terms and Conditions.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.perm_identity,
              title: '2. Information We Collect',
              content:
                  '• Account Information: name, email, barangay, and profile details.\n• Health-related Reports: dengue case reports, breeding site submissions.\n• Device and Usage Data: IP, browser type, pages visited, timestamps.\n• Location Data: for mapping and reporting accuracy (if permission is granted).\n• Media and Attachments: files you upload with reports or educational posts.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.security,
              title: '3. How We Use Your Information',
              content:
                  '• Provide and maintain services (mapping, reporting, notifications).\n• Verify identity and secure access (authentication, OTP, reCAPTCHA).\n• Analyze trends and improve features (predictive alerts, dashboards).\n• Communicate updates, alerts, and educational content.\n• Comply with legal obligations and public health coordination.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.group,
              title: '4. Sharing of Information',
              content:
                  '• Local Health Authorities (CHO, health centers) for public health response.\n• Service Providers (e.g., hosting, email/SMS) under data processing agreements.\n• Legal Requirements: when required by law, court order, or to protect rights.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.storage,
              title: '5. Data Retention',
              content:
                  'We retain personal data only as long as necessary for service delivery, legal, and reporting purposes. Aggregated or anonymized data may be kept for analytics and research.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.lock,
              title: '6. Data Security',
              content:
                  'We implement technical and organizational measures to protect your data, including encryption in transit, access controls, and regular reviews. No method of transmission or storage is 100% secure.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.verified_user,
              title: '7. Your Rights',
              content:
                  '• Access, correct, or delete your personal data (subject to legal limits).\n• Withdraw consent where processing is based on consent.\n• Object to or restrict certain processing activities.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.child_care,
              title: '8. Children\'s Privacy',
              content:
                  'Our services are not directed to children under 13. We do not knowingly collect personal data from children. If you believe a child has provided data, contact us to remove it.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.public,
              title: '9. International Transfers',
              content:
                  'Your data may be processed and stored in locations outside your jurisdiction with appropriate safeguards.',
            ),
            _buildTermsSection(
              context,
              icon: Icons.update,
              title: '10. Changes to This Policy',
              content:
                  'We may update these Terms periodically. Material changes will be notified via email or in-app notice. Continued use means acceptance of updates.',
            ),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  /// HEADER CARD
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
                  Icons.article,
                  color: const Color(0xFF5271FF),
                  size: Responsive.icon(context, 24),
                ),
              ),
              SizedBox(width: Responsive.padding(context, 12)),
              Expanded(
                child: Text(
                  'BuzzOff Terms & Conditions',
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
            'Effective Date: September 16, 2025\nBy using BuzzOffPH, you agree to the following terms and responsibilities for the safety and health of the community.',
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

  /// TERMS SECTIONS
  Widget _buildTermsSection(BuildContext context,
      {required IconData icon,
      required String title,
      required String content}) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.vertical(context, 20)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.padding(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF5271FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                  SizedBox(height: Responsive.vertical(context, 8)),
                  Text(
                    content,
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

  /// CONTACT SECTION
  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '11. Contact Us',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
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
                    children: const [
                      Text(
                        'For questions or requests, please contact:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'support@buzzoffph.com\n(02) 123-4567\nCity Health Office, Dasmariñas City, Cavite',
                        style: TextStyle(
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
}
