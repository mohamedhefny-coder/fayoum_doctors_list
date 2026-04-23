import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../deep_link_config.dart';
import '../models/lab_model.dart';
import '../services/lab_service.dart';

class LabDetailsScreen extends StatefulWidget {
  const LabDetailsScreen({super.key, required this.lab});

  final LabModel lab;

  @override
  State<LabDetailsScreen> createState() => _LabDetailsScreenState();
}

class _LabDetailsScreenState extends State<LabDetailsScreen> {
  final Map<String, bool> _expandedCategories = {};
  final _labService = LabService();

  late double _rating;
  late int _ratingCount;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  @override
  void initState() {
    super.initState();
    _rating = (widget.lab.rating ?? 0).toDouble();
    _ratingCount = widget.lab.ratingCount ?? 0;
  }

  bool _canRateLab() {
    final id = widget.lab.id.trim();
    return _uuidRegex.hasMatch(id);
  }

  Future<void> _launchExternal(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
    }
  }

  Uri? _phoneUri() {
    final phone = widget.lab.phone?.trim();
    if (phone == null || phone.isEmpty) return null;
    return Uri(scheme: 'tel', path: phone);
  }

  Uri? _mapsUri() {
    if (widget.lab.hasLocation) {
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.lab.latitude},${widget.lab.longitude}',
      );
    }

    final query = [
      widget.lab.name,
      widget.lab.address,
    ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).join(' ');

    if (query.trim().isEmpty) return null;

    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
  }

  Uri? _whatsAppUri() {
    final raw = widget.lab.whatsapp?.trim();
    if (raw == null || raw.isEmpty) return null;

    // Keep digits only, and normalize common Egypt numbers.
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '20${digits.substring(1)}';
    if (!digits.startsWith('20') && digits.length == 11) {
      // Heuristic: local 11-digit Egyptian mobile numbers.
      digits = '20$digits';
    }
    if (digits.isEmpty) return null;
    return Uri.parse('https://wa.me/$digits');
  }

  Uri? _emailUri() {
    final email = widget.lab.email?.trim();
    if (email == null || email.isEmpty) return null;
    return Uri(scheme: 'mailto', path: email);
  }

  void _openImageDialog(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                trimmed,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: Text('تعذر تحميل الصورة')),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final phoneUri = _phoneUri();
    final mapsUri = _mapsUri();
    final waUri = _whatsAppUri();
    final emailUri = _emailUri();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.lab.name)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(colorScheme),
            const SizedBox(height: 12),
            _buildRatingAndQrCard(colorScheme),
            const SizedBox(height: 16),
            _buildInfoCard(colorScheme, phoneUri, mapsUri, waUri, emailUri),
            if (widget.lab.coverImageUrl?.trim().isNotEmpty == true ||
                widget.lab.logoImageUrl?.trim().isNotEmpty == true ||
                widget.lab.galleryImageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImagesCard(colorScheme),
            ],
            if (widget.lab.offers?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _buildTextSectionCard(
                colorScheme,
                title: 'العروض',
                icon: Icons.local_offer,
                text: widget.lab.offers!.trim(),
              ),
            ],
            if (widget.lab.contracts?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _buildTextSectionCard(
                colorScheme,
                title: 'التعاقدات',
                icon: Icons.handshake_outlined,
                text: widget.lab.contracts!.trim(),
              ),
            ],
            if (widget.lab.features.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildFeaturesCard(colorScheme),
            ],
            if (widget.lab.tests.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTestsCard(colorScheme),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: phoneUri == null
                        ? null
                        : () => _launchExternal(context, phoneUri),
                    icon: const Icon(Icons.call),
                    label: const Text('اتصال'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: mapsUri == null
                        ? null
                        : () => _launchExternal(context, mapsUri),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('الموقع'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme) {
    final coverUrl = (widget.lab.coverImageUrl ?? '').trim();
    final logoUrl = (widget.lab.logoImageUrl ?? '').trim();
    final accent = const Color(0xFF9C27B0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              accent.withValues(alpha: 0.18),
                              colorScheme.primary.withValues(alpha: 0.10),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            accent.withValues(alpha: 0.18),
                            colorScheme.primary.withValues(alpha: 0.10),
                          ],
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.20),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.biotech,
                                size: 34,
                                color: Color(0xFF9C27B0),
                              ),
                            )
                          : const Icon(
                              Icons.biotech,
                              size: 34,
                              color: Color(0xFF9C27B0),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lab.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_ratingCount تقييم',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildInfoCard(
    ColorScheme colorScheme,
    Uri? phoneUri,
    Uri? mapsUri,
    Uri? waUri,
    Uri? emailUri,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(Icons.contact_phone, color: colorScheme.primary),
                const SizedBox(width: 10),
                const Text(
                  'معلومات التواصل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('العنوان'),
            subtitle: Text(
              widget.lab.address?.trim().isNotEmpty == true
                  ? widget.lab.address!.trim()
                  : 'العنوان غير متوفر',
            ),
            trailing: TextButton(
              onPressed: mapsUri == null
                  ? null
                  : () => _launchExternal(context, mapsUri),
              child: const Text('خريطة'),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.call_outlined),
            title: const Text('الهاتف'),
            subtitle: Text(
              widget.lab.phone?.trim().isNotEmpty == true
                  ? widget.lab.phone!.trim()
                  : 'غير متوفر',
            ),
            trailing: TextButton(
              onPressed: phoneUri == null
                  ? null
                  : () => _launchExternal(context, phoneUri),
              child: const Text('اتصال'),
            ),
          ),
          if (waUri != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('واتساب'),
              subtitle: Text(widget.lab.whatsapp!.trim()),
              trailing: TextButton(
                onPressed: () => _launchExternal(context, waUri),
                child: const Text('محادثة'),
              ),
            ),
          ],
          if (emailUri != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('البريد الإلكتروني'),
              subtitle: Text(widget.lab.email!.trim()),
              trailing: TextButton(
                onPressed: () => _launchExternal(context, emailUri),
                child: const Text('إرسال'),
              ),
            ),
          ],
          if (widget.lab.workingHours?.trim().isNotEmpty == true) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('ساعات العمل'),
              subtitle: Text(widget.lab.workingHours!.trim()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesCard(ColorScheme colorScheme) {
    final coverUrl = (widget.lab.coverImageUrl ?? '').trim();
    final logoUrl = (widget.lab.logoImageUrl ?? '').trim();
    final gallery = widget.lab.galleryImageUrls;
    final accent = const Color(0xFF9C27B0);

    Widget imageTile({required String title, required String url}) {
      return Expanded(
        child: InkWell(
          onTap: () => _openImageDialog(url),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.20)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: accent.withValues(alpha: 0.06),
                      child: const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                const Text(
                  'صور المعمل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    if (coverUrl.isNotEmpty) imageTile(title: 'كفر', url: coverUrl),
                    if (coverUrl.isNotEmpty && logoUrl.isNotEmpty)
                      const SizedBox(width: 12),
                    if (logoUrl.isNotEmpty) imageTile(title: 'لوجو', url: logoUrl),
                    if (coverUrl.isEmpty && logoUrl.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withValues(alpha: 0.18)),
                        ),
                        child: const Text('لا توجد صور كفر/لوجو.'),
                      ),
                  ],
                ),
                if (gallery.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: gallery.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final url = gallery[i];
                        return InkWell(
                          onTap: () => _openImageDialog(url),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accent.withValues(alpha: 0.20)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: accent.withValues(alpha: 0.06),
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSectionCard(
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required String text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(Icons.star_border, color: colorScheme.primary),
                const SizedBox(width: 10),
                const Text(
                  'المميزات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: widget.lab.features
                  .map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsCard(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Text(
                  'التحاليل المتاحة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...widget.lab.tests.entries.map((entry) {
            final isExpanded = _expandedCategories[entry.key] ?? false;
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expandedCategories[entry.key] = !isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.science,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      children: entry.value
                          .map(
                            (test) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      test,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (entry.key != widget.lab.tests.keys.last)
                  const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRatingAndQrCard(ColorScheme colorScheme) {
    final accent = const Color(0xFF9C27B0);
    final labName = widget.lab.name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openRateDialog,
                      child: Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < _rating.floor()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _openRateDialog,
                      child: const Text('قيّم'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_rating.toStringAsFixed(1)} من 5  •  $_ratingCount تقييم',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent,
                  accent.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // آخر عنصر في RTL = أقصى اليسار
          GestureDetector(
            onTap: () {
              final qrData = buildPublicLabUrl(labName: labName).toString();
              showDialog(
                context: context,
                builder: (_) => _LabQrFullDialog(
                  labName: labName,
                  qrData: qrData,
                  accentColor: accent,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: QrImageView(
                data: buildPublicLabUrl(labName: labName).toString(),
                version: QrVersions.auto,
                size: 52,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rateLab(int ratingValue) async {
    final id = widget.lab.id.trim();
    if (!_canRateLab()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تقييم هذا المعمل حالياً.')),
      );
      return;
    }

    try {
      final result = await _labService.rateLab(
        labId: id,
        ratingValue: ratingValue,
      );

      final newRating = (result['rating'] as num?)?.toDouble() ?? _rating;
      final newCount = (result['rating_count'] as num?)?.toInt() ?? _ratingCount;
      if (!mounted) return;
      setState(() {
        _rating = newRating;
        _ratingCount = newCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شكراً لتقييمك!')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إرسال التقييم حالياً.')),
      );
    }
  }

  Future<void> _openRateDialog() async {
    if (!_canRateLab()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تقييم هذا المعمل حالياً.')),
      );
      return;
    }

    int selected = 0;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('قيّم المعمل'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final value = i + 1;
                      final filled = value <= selected;
                      return IconButton(
                        tooltip: '$value',
                        onPressed: () => setLocal(() => selected = value),
                        icon: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selected == 0
                        ? 'اختر عدد النجوم'
                        : 'تقييمك: $selected من 5',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: selected == 0
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _rateLab(selected);
                        },
                  child: const Text('إرسال'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ====== نافذة QR كاملة للمعمل ======
class _LabQrFullDialog extends StatelessWidget {
  const _LabQrFullDialog({
    required this.labName,
    required this.qrData,
    required this.accentColor,
  });

  final String labName;
  final String qrData;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'امسح الكود لفتح صفحة المعمل مباشرة',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: accentColor,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              label: const Text('إغلاق'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
