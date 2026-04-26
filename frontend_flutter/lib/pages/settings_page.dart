import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const Color _primary = Color(0xFF1E4ED8);
  static const Color _pageBg = Color(0xFFF5F7FB);
  static const Color _cardBg = Colors.white;
  static const Color _mutedText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage your account and system preferences.",
              style: TextStyle(color: _mutedText, fontSize: 13),
            ),

            const SizedBox(height: 28),

            // Coming soon card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: _primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Settings coming soon",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Account preferences, notifications, and\nsystem configuration will appear here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Greyed out preview cards
            _sectionCard(
              icon: Icons.person_outline,
              title: "Account",
              subtitle: "Profile, password, and email preferences",
            ),
            const SizedBox(height: 12),
            _sectionCard(
              icon: Icons.notifications_outlined,
              title: "Notifications",
              subtitle: "Alerts, reminders, and email digests",
            ),
            const SizedBox(height: 12),
            _sectionCard(
              icon: Icons.security_outlined,
              title: "Security",
              subtitle: "Two-factor authentication and session management",
            ),
            const SizedBox(height: 12),
            _sectionCard(
              icon: Icons.palette_outlined,
              title: "Appearance",
              subtitle: "Theme, language, and display preferences",
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Opacity(
      opacity: 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _mutedText, size: 18),
          ],
        ),
      ),
    );
  }
}
