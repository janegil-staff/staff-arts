// lib/screens/auth/legal_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum LegalType { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalType type;
  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == LegalType.privacy;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPrivacy ? 'Privacy Policy' : 'Terms of Service',
          style: const TextStyle(fontWeight: FontWeight.w300),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: isPrivacy ? const _PrivacyContent() : const _TermsContent(),
      ),
    );
  }
}

// ─── Privacy Policy ───────────────────────────────────────────────────────────

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return const _LegalBody(
      title: 'Privacy Policy',
      lastUpdated: 'January 2025',
      sections: [
        _Section(
          title: '1. Information We Collect',
          body:
              'We collect information you provide directly, such as your name, email address, and profile information when you create an account. We also collect content you upload, including artwork images and descriptions.',
        ),
        _Section(
          title: '2. How We Use Your Information',
          body:
              'We use your information to provide and improve STAFF Arts services, communicate with you about your account, display your artwork and profile to other users, and process transactions.',
        ),
        _Section(
          title: '3. Information Sharing',
          body:
              'Your public profile and artworks are visible to other users. We do not sell your personal information to third parties. We may share information with service providers who help us operate the platform, such as cloud storage and payment processors.',
        ),
        _Section(
          title: '4. Data Storage',
          body:
              'Your data is stored securely on servers in the European Economic Area. Images are stored via Cloudinary. We retain your data for as long as your account is active.',
        ),
        _Section(
          title: '5. Your Rights',
          body:
              'You have the right to access, correct, or delete your personal data. You may request deletion of your account and associated data at any time by contacting us.',
        ),
        _Section(
          title: '6. Cookies',
          body:
              'Our app does not use cookies. We use secure tokens stored locally on your device for authentication purposes.',
        ),
        _Section(
          title: '7. Contact',
          body:
              'For privacy-related inquiries, please contact us at privacy@staffarts.com.',
        ),
      ],
    );
  }
}

// ─── Terms of Service ─────────────────────────────────────────────────────────

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return const _LegalBody(
      title: 'Terms of Service',
      lastUpdated: 'January 2025',
      sections: [
        _Section(
          title: '1. Acceptance of Terms',
          body:
              'By creating an account and using STAFF Arts, you agree to these Terms of Service. If you do not agree, please do not use the platform.',
        ),
        _Section(
          title: '2. User Accounts',
          body:
              'You must be at least 18 years old to create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.',
        ),
        _Section(
          title: '3. Content Ownership',
          body:
              'You retain ownership of all artwork and content you upload. By uploading content, you grant STAFF Arts a non-exclusive license to display and promote your work on the platform.',
        ),
        _Section(
          title: '4. Prohibited Content',
          body:
              'You may not upload content that is illegal, infringes on third-party intellectual property rights, is hateful or discriminatory, or misrepresents the authenticity of artwork.',
        ),
        _Section(
          title: '5. Transactions',
          body:
              'STAFF Arts facilitates transactions between buyers and sellers. We are not responsible for disputes between users. Payments are processed securely via Stripe.',
        ),
        _Section(
          title: '6. Termination',
          body:
              'We reserve the right to suspend or terminate accounts that violate these terms. You may delete your account at any time from the profile settings.',
        ),
        _Section(
          title: '7. Limitation of Liability',
          body:
              'STAFF Arts is provided "as is". We are not liable for any indirect, incidental, or consequential damages arising from your use of the platform.',
        ),
        _Section(
          title: '8. Changes to Terms',
          body:
              'We may update these terms from time to time. Continued use of the platform after changes constitutes acceptance of the updated terms.',
        ),
        _Section(
          title: '9. Contact',
          body:
              'For questions about these terms, contact us at legal@staffarts.com.',
        ),
      ],
    );
  }
}

// ─── Shared layout ────────────────────────────────────────────────────────────

class _LegalBody extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<_Section> sections;

  const _LegalBody({
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSize.xxl,
            fontWeight: FontWeight.w300,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Last updated: $lastUpdated',
          style: const TextStyle(
              fontSize: AppFontSize.xs, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        ...sections.map((s) => _buildSection(s)),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSection(_Section section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            section.body,
            style: const TextStyle(
              fontSize: AppFontSize.sm,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}
