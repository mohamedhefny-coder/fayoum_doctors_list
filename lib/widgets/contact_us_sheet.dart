import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Update these when you have real contact details.
const String? kSupportPhoneNumber = null; // e.g. "+2010xxxxxxx"
const String? kSupportWhatsAppNumber =
    null; // e.g. "+2010xxxxxxx" or "2010xxxxxxx"
const String? kSupportFacebookUrl =
    null; // e.g. "https://facebook.com/yourpage"
const String? kSupportEmail = null; // e.g. "support@example.com"

const String kOwnerLabel = 'Owner';
const String kOwnerName = 'Dr Muhammed Hefny';
const String kOwnerImageAsset = 'assets/images/dr hefny.JPG';
const String kOwnerWhatsAppNumber = '01023386707';

Future<void> showContactUsSheet(BuildContext context) async {
  Future<void> safeLaunch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Ignore: user just won't be redirected.
    }
  }

  String normalizeWhatsApp(String raw) {
    var clean = raw.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return clean;

    if (clean.startsWith('0')) {
      clean = '20${clean.substring(1)}';
    } else if (!clean.startsWith('20') && !clean.startsWith('+')) {
      clean = '20$clean';
    }
    clean = clean.replaceAll('+', '');
    return clean;
  }

  final hasAny =
      (kSupportPhoneNumber != null && kSupportPhoneNumber!.trim().isNotEmpty) ||
      (kSupportWhatsAppNumber != null &&
          kSupportWhatsAppNumber!.trim().isNotEmpty) ||
      (kSupportFacebookUrl != null && kSupportFacebookUrl!.trim().isNotEmpty) ||
      (kSupportEmail != null && kSupportEmail!.trim().isNotEmpty);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final titleStyle = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: cs.onSurface,
      );
      final bodyStyle = TextStyle(
        fontSize: 14,
        color: Theme.of(
          ctx,
        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
        height: 1.4,
      );

      Widget tile({
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.10),
            foregroundColor: cs.primary,
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
          onTap: onTap,
        );
      }

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تواصل معنا', style: titleStyle),
              const SizedBox(height: 8),
              if (!hasAny)
                Text('سيتم إضافة بيانات الاتصال قريباً.', style: bodyStyle),
              if (hasAny) ...[
                if (kSupportPhoneNumber != null &&
                    kSupportPhoneNumber!.trim().isNotEmpty)
                  tile(
                    icon: Icons.phone,
                    title: 'اتصال',
                    subtitle: kSupportPhoneNumber!.trim(),
                    onTap: () => safeLaunch(
                      Uri(scheme: 'tel', path: kSupportPhoneNumber!.trim()),
                    ),
                  ),
                if (kSupportWhatsAppNumber != null &&
                    kSupportWhatsAppNumber!.trim().isNotEmpty)
                  tile(
                    icon: Icons.chat,
                    title: 'واتساب',
                    subtitle: kSupportWhatsAppNumber!.trim(),
                    onTap: () {
                      final wa = normalizeWhatsApp(kSupportWhatsAppNumber!);
                      if (wa.isEmpty) return;
                      safeLaunch(Uri.parse('https://wa.me/$wa'));
                    },
                  ),
                if (kSupportFacebookUrl != null &&
                    kSupportFacebookUrl!.trim().isNotEmpty)
                  tile(
                    icon: Icons.facebook,
                    title: 'فيسبوك',
                    subtitle: 'فتح الصفحة',
                    onTap: () =>
                        safeLaunch(Uri.parse(kSupportFacebookUrl!.trim())),
                  ),
                if (kSupportEmail != null && kSupportEmail!.trim().isNotEmpty)
                  tile(
                    icon: Icons.email,
                    title: 'بريد إلكتروني',
                    subtitle: kSupportEmail!.trim(),
                    onTap: () => safeLaunch(
                      Uri(scheme: 'mailto', path: kSupportEmail!.trim()),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
