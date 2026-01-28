import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/lab_model.dart';

class LabDetailsScreen extends StatefulWidget {
  const LabDetailsScreen({super.key, required this.lab});

  final LabModel lab;

  @override
  State<LabDetailsScreen> createState() => _LabDetailsScreenState();
}

class _LabDetailsScreenState extends State<LabDetailsScreen> {
  final Map<String, bool> _expandedCategories = {};

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final phoneUri = _phoneUri();
    final mapsUri = _mapsUri();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.lab.name)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(colorScheme),
            const SizedBox(height: 16),
            _buildInfoCard(colorScheme, phoneUri, mapsUri),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF9C27B0).withValues(alpha: 0.14),
            const Color(0xFF00BCD4).withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.20),
              ),
            ),
            child: const Icon(
              Icons.biotech,
              size: 34,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lab.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.lab.rating != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.lab.rating!.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (widget.lab.ratingCount != null) ...[
                        const SizedBox(width: 6),
                        Text('(${widget.lab.ratingCount})'),
                      ],
                    ],
                  ),
                ],
                if (widget.lab.offers != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.lab.offers!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme, Uri? phoneUri, Uri? mapsUri) {
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
}
