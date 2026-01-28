import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/contact_us_sheet.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const _primaryBlue = Color(0xFF00BCD4);
  static const _primaryBlueDark = Color(0xFF0097A7);
  static const _green = Color(0xFF22C55E);
  static const _deepGreen = Color(0xFF16A34A);
  static const _ownerEmail = 'mhefny1995@gmail.com';

  Future<void> _safeLaunch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerWhatsApp = kOwnerWhatsAppNumber.trim();
    final hasOwnerWhatsApp = ownerWhatsApp.isNotEmpty;
    const hasOwnerEmail = _ownerEmail != '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(
            'تواصل معنا',
            style: GoogleFonts.almarai(fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF3E0), Color(0xFFF1F5F9)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // بطاقة المالك
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [_primaryBlue, _primaryBlueDark],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryBlue.withValues(alpha: 0.30),
                                  blurRadius: 22,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -30,
                                  left: -30,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -40,
                                  right: -40,
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  textDirection: TextDirection.ltr,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              kOwnerLabel.toUpperCase(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.6,
                                                color: Colors.white.withValues(
                                                  alpha: 0.92,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                kOwnerName,
                                                maxLines: 1,
                                                softWrap: false,
                                                style:
                                                    GoogleFonts.montserrat(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors.white,
                                                    ).copyWith(
                                                      fontFamily: 'Andalus',
                                                      fontFamilyFallback:
                                                          const [
                                                            'Montserrat',
                                                            'Poppins',
                                                            'Almarai',
                                                          ],
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'يسعدني تواصلك في أي وقت',
                                              style: GoogleFonts.almarai(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white.withValues(
                                                  alpha: 0.90,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 144,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: Container(
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                          child:
                                              kOwnerImageAsset.trim().isNotEmpty
                                              ? FutureBuilder<double>(
                                                  future: _assetAspectRatio(
                                                    kOwnerImageAsset,
                                                  ),
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData ||
                                                        snapshot.data == null ||
                                                        snapshot.data! <= 0 ||
                                                        !snapshot
                                                            .data!
                                                            .isFinite) {
                                                      return const SizedBox(
                                                        height: 144,
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.person,
                                                            color:
                                                                _primaryBlueDark,
                                                            size: 48,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    return AspectRatio(
                                                      aspectRatio:
                                                          snapshot.data!,
                                                      child: Image.asset(
                                                        kOwnerImageAsset,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return const Center(
                                                                child: Icon(
                                                                  Icons.person,
                                                                  color:
                                                                      _primaryBlueDark,
                                                                  size: 48,
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                    );
                                                  },
                                                )
                                              : const SizedBox(
                                                  height: 144,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.person,
                                                      color: _primaryBlueDark,
                                                      size: 48,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // بطاقة البريد الإلكتروني (بدون عرض الإيميل)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [_primaryBlue, _primaryBlueDark],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryBlue.withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.email,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Email',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hasOwnerEmail
                                            ? 'راسلني عبر البريد الإلكتروني'
                                            : 'لم يتم ضبط البريد الإلكتروني بعد',
                                        style: GoogleFonts.almarai(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: hasOwnerEmail
                                      ? () => _safeLaunch(
                                          Uri(
                                            scheme: 'mailto',
                                            path: _ownerEmail,
                                          ),
                                        )
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _primaryBlueDark,
                                    disabledBackgroundColor: Colors.white
                                        .withValues(alpha: 0.70),
                                    disabledForegroundColor: _primaryBlueDark
                                        .withValues(alpha: 0.70),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'فتح',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // بطاقة واتساب
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [_green, _deepGreen],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: _green.withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                  child: const Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'WhatsApp',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hasOwnerWhatsApp
                                            ? 'رد سريع داخل واتساب'
                                            : 'لم يتم ضبط رقم الواتساب بعد',
                                        style: GoogleFonts.almarai(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: hasOwnerWhatsApp
                                      ? () {
                                          final wa = _normalizeWhatsApp(
                                            ownerWhatsApp,
                                          );
                                          if (wa.isEmpty) return;
                                          _safeLaunch(
                                            Uri.parse('https://wa.me/$wa'),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _deepGreen,
                                    disabledBackgroundColor: Colors.white
                                        .withValues(alpha: 0.70),
                                    disabledForegroundColor: _deepGreen
                                        .withValues(alpha: 0.70),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'فتح',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: 10),

                          // اسكربت الملكية (مثبت أسفل الصفحة)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Center(
                              child: Text(
                                '© ${DateTime.now().year} $kOwnerName — جميع الحقوق محفوظة',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.almarai(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _normalizeWhatsApp(String raw) {
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

Future<double> _assetAspectRatio(String assetPath) async {
  final completer = Completer<ImageInfo>();
  final stream = AssetImage(assetPath).resolve(const ImageConfiguration());

  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      completer.complete(info);
      stream.removeListener(listener);
    },
    onError: (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      stream.removeListener(listener);
    },
  );

  stream.addListener(listener);
  final info = await completer.future;
  final w = info.image.width.toDouble();
  final h = info.image.height.toDouble();
  if (h <= 0) return 1.0;
  return w / h;
}
