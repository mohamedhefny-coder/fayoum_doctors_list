import 'package:flutter/material.dart';

import '../models/medical_center_review.dart';
import '../services/medical_center_reviews_service.dart';

class MedicalCenterReviewsSection extends StatefulWidget {
  final String centerId;
  final Color accentColor;
  final double? currentRating;
  final int? ratingCount;
  final ValueChanged<MedicalCenterRatingSummary>? onSummaryChanged;

  const MedicalCenterReviewsSection({
    super.key,
    required this.centerId,
    required this.accentColor,
    this.currentRating,
    this.ratingCount,
    this.onSummaryChanged,
  });

  @override
  State<MedicalCenterReviewsSection> createState() =>
      _MedicalCenterReviewsSectionState();
}

class _MedicalCenterReviewsSectionState extends State<MedicalCenterReviewsSection>
    with SingleTickerProviderStateMixin {
  final _db = MedicalCenterReviewsService();
  List<MedicalCenterReview> _reviews = [];
  bool _loading = true;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadReviews();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final reviews = await _db.getApprovedReviews(centerId: widget.centerId);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _loading = false;
    });
    _animCtrl.forward(from: 0);
  }

  void _showWriteReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteMedicalCenterReviewSheet(
        centerId: widget.centerId,
        accentColor: widget.accentColor,
        onSubmitted: (summary) {
          widget.onSummaryChanged?.call(summary);
          setState(() => _loading = true);
          _loadReviews();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'شكراً! تم إرسال تقييمك بنجاح',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingDistribution() {
    if (_reviews.isEmpty) return const SizedBox.shrink();

    final Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final key = r.rating.round().clamp(1, 5);
      dist[key] = (dist[key] ?? 0) + 1;
    }
    final max = dist.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: List.generate(5, (i) {
        final star = 5 - i;
        final count = dist[star] ?? 0;
        final pct = max > 0 ? count / max : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                child: Text(
                  '$star',
                  style:
                      const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.star, size: 12, color: Colors.amber.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.amber.shade500),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 22,
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avg = widget.currentRating ?? 0.0;
    final count = widget.ratingCount ?? _reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.accentColor,
                    widget.accentColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'التقييمات والمراجعات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showWriteReviewSheet,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('اكتب تقييمك'),
              style: TextButton.styleFrom(
                foregroundColor: widget.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                widget.accentColor.withValues(alpha: 0.08),
                widget.accentColor.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    avg > 0 ? avg.toStringAsFixed(1) : '—',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: widget.accentColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final filled = i < avg.round();
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 16,
                        color: Colors.amber.shade600,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count تقييم',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildRatingDistribution()),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviews.isEmpty)
          _EmptyCenterReviewsPlaceholder(
            accentColor: widget.accentColor,
            onWriteReview: _showWriteReviewSheet,
          )
        else
          ...List.generate(_reviews.length, (i) {
            final delay = i * 0.1;
            return AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                final t = Curves.easeOutBack
                    .transform((_animCtrl.value - delay).clamp(0.0, 1.0));
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - t)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CenterReviewCard(
                  review: _reviews[i],
                  accentColor: widget.accentColor,
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _CenterReviewCard extends StatelessWidget {
  final MedicalCenterReview review;
  final Color accentColor;

  const _CenterReviewCard({required this.review, required this.accentColor});

  String _formatDate(DateTime dt) {
    final months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName[0].toUpperCase()
                      : '؟',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        color: Colors.amber.shade600, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.reviewText != null && review.reviewText!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                review.reviewText!,
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber.shade500,
                size: 18,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EmptyCenterReviewsPlaceholder extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onWriteReview;

  const _EmptyCenterReviewsPlaceholder({
    required this.accentColor,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'لا توجد تقييمات حتى الآن',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'كن أول من يشارك تجربته مع هذا المركز',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onWriteReview,
            icon: const Icon(Icons.star_rounded, size: 18),
            label: const Text('اكتب أول تقييم'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WriteMedicalCenterReviewSheet extends StatefulWidget {
  final String centerId;
  final Color accentColor;
  final ValueChanged<MedicalCenterRatingSummary> onSubmitted;

  const _WriteMedicalCenterReviewSheet({
    required this.centerId,
    required this.accentColor,
    required this.onSubmitted,
  });

  @override
  State<_WriteMedicalCenterReviewSheet> createState() =>
      _WriteMedicalCenterReviewSheetState();
}

class _WriteMedicalCenterReviewSheetState
    extends State<_WriteMedicalCenterReviewSheet> {
  final _db = MedicalCenterReviewsService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار عدد النجوم أولاً')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await _db.submitMedicalCenterReview(
        centerId: widget.centerId,
        reviewerName: _nameCtrl.text.trim(),
        reviewerPhone:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        rating: _selectedRating,
        reviewText:
            _reviewCtrl.text.trim().isEmpty ? null : _reviewCtrl.text.trim(),
      );

      final rating = (result['rating'] as num?)?.toDouble();
      final ratingCount = (result['rating_count'] as num?)?.toInt();

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted(
        MedicalCenterRatingSummary(
          rating: rating,
          ratingCount: ratingCount,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStarSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starVal = (i + 1).toDouble();
        final filled = starVal <= _selectedRating;
        return GestureDetector(
          onTap: () => setState(() => _selectedRating = starVal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? Colors.amber.shade500 : Colors.grey.shade400,
              size: filled ? 44 : 38,
            ),
          ),
        );
      }),
    );
  }

  String _ratingLabel() {
    switch (_selectedRating.toInt()) {
      case 1:
        return 'ضعيف';
      case 2:
        return 'مقبول';
      case 3:
        return 'جيد';
      case 4:
        return 'جيد جداً';
      case 5:
        return 'ممتاز';
      default:
        return 'اختر تقييمك';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.rate_review_rounded,
                          color: widget.accentColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'شاركنا تجربتك',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'تقييمك يساعد الآخرين على الاختيار',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'تقييمك العام',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                _buildStarSelector(),
                const SizedBox(height: 8),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _ratingLabel(),
                      key: ValueKey(_selectedRating),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedRating > 0
                            ? Colors.amber.shade700
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسمك *',
                    hintText: 'مثال: أحمد محمد',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: widget.accentColor, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'يرجى إدخال اسمك';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم هاتفك (اختياري)',
                    hintText: '01xxxxxxxxx',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: widget.accentColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reviewCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'تعليقك (اختياري)',
                    hintText: 'شاركنا تجربتك مع المركز...',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.comment_outlined),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: widget.accentColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'إرسال التقييم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
}

class MedicalCenterRatingSummary {
  final double? rating;
  final int? ratingCount;

  const MedicalCenterRatingSummary({
    required this.rating,
    required this.ratingCount,
  });
}
