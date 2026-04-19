import 'package:flutter/material.dart';
import '../models/doctor_review.dart';
import '../services/doctor_database_service.dart';

// ============================================================
// نظام التقييمات والمراجعات المتكامل
// ============================================================

class DoctorReviewsSection extends StatefulWidget {
  final String doctorId;
  final Color accentColor;
  final double? currentRating;
  final int? ratingCount;

  const DoctorReviewsSection({
    super.key,
    required this.doctorId,
    required this.accentColor,
    this.currentRating,
    this.ratingCount,
  });

  @override
  State<DoctorReviewsSection> createState() => _DoctorReviewsSectionState();
}

class _DoctorReviewsSectionState extends State<DoctorReviewsSection>
    with SingleTickerProviderStateMixin {
  final _db = DoctorDatabaseService();
  List<DoctorReview> _reviews = [];
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
    final reviews = await _db.getApprovedReviews(doctorId: widget.doctorId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _loading = false;
      });
      _animCtrl.forward();
    }
  }

  void _showWriteReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(
        doctorId: widget.doctorId,
        accentColor: widget.accentColor,
        onSubmitted: () {
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
                      'شكراً! تقييمك بانتظار موافقة الطبيب للنشر',
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
              duration: const Duration(seconds: 4),
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
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
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
                    valueColor:
                        AlwaysStoppedAnimation(Colors.amber.shade500),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 22,
                child: Text(
                  '$count',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
        // ── Header ──
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'التقييمات والمراجعات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showWriteReviewSheet,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('اكتب تقييمك'),
              style: TextButton.styleFrom(
                foregroundColor: widget.accentColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── ملخص التقييم ──
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
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // الرقم الكبير
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // توزيع النجوم
              Expanded(child: _buildRatingDistribution()),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── قائمة التقييمات ──
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reviews.isEmpty)
          _EmptyReviewsPlaceholder(
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
                child: _ReviewCard(
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

// ============================================================
// بطاقة تقييم مفرد
// ============================================================
class _ReviewCard extends StatelessWidget {
  final DoctorReview review;
  final Color accentColor;

  const _ReviewCard({required this.review, required this.accentColor});

  String _formatDate(DateTime dt) {
    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
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
          // Header
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
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // نجوم التقييم
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          // نص التقييم
          if (review.reviewText != null &&
              review.reviewText!.trim().isNotEmpty) ...[
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
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
          // نجوم مرئية
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

// ============================================================
// placeholder عندما لا توجد تقييمات
// ============================================================
class _EmptyReviewsPlaceholder extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onWriteReview;

  const _EmptyReviewsPlaceholder({
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
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined,
              size: 52, color: Colors.grey.shade400),
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
            'كن أول من يشارك تجربته مع هذا الطبيب',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

// ============================================================
// Bottom Sheet كتابة تقييم جديد
// ============================================================
class _WriteReviewSheet extends StatefulWidget {
  final String doctorId;
  final Color accentColor;
  final VoidCallback onSubmitted;

  const _WriteReviewSheet({
    required this.doctorId,
    required this.accentColor,
    required this.onSubmitted,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final _db = DoctorDatabaseService();
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
      await _db.submitDoctorReview(
        doctorId: widget.doctorId,
        reviewerName: _nameCtrl.text.trim(),
        reviewerPhone: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        rating: _selectedRating,
        reviewText:
            _reviewCtrl.text.trim().isEmpty ? null : _reviewCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                // Handle bar
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
                // العنوان
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
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // اختيار النجوم
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
                // الاسم
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
                      borderSide: BorderSide(
                          color: widget.accentColor, width: 2),
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
                // الهاتف (اختياري)
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
                      borderSide: BorderSide(
                          color: widget.accentColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // نص التقييم
                TextFormField(
                  controller: _reviewCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'تعليقك (اختياري)',
                    hintText: 'شاركنا تجربتك مع الطبيب...',
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
                      borderSide: BorderSide(
                          color: widget.accentColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ملاحظة الموافقة
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'سوف يظهر تقييمك بعد قليل',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // زر الإرسال
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

// ============================================================
// واجهة إدارة تقييمات الطبيب (في لوحة التحكم)
// ============================================================
class DoctorReviewsManagementSection extends StatefulWidget {
  final String doctorId;
  final Color accentColor;

  const DoctorReviewsManagementSection({
    super.key,
    required this.doctorId,
    required this.accentColor,
  });

  @override
  State<DoctorReviewsManagementSection> createState() =>
      _DoctorReviewsManagementSectionState();
}

class _DoctorReviewsManagementSectionState
    extends State<DoctorReviewsManagementSection>
    with SingleTickerProviderStateMixin {
  final _db = DoctorDatabaseService();
  List<DoctorReview> _reviews = [];
  bool _loading = true;
  late TabController _tabCtrl;
  static const _tabs = ['المعلقة', 'المعتمدة', 'المرفوضة'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final reviews =
        await _db.getAllDoctorReviews(doctorId: widget.doctorId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _loading = false;
      });
    }
  }

  List<DoctorReview> get _pending =>
      _reviews.where((r) => r.isPending).toList();
  List<DoctorReview> get _approved =>
      _reviews.where((r) => r.isApproved).toList();
  List<DoctorReview> get _rejected =>
      _reviews.where((r) => r.isRejected).toList();

  Future<void> _approve(DoctorReview review) async {
    try {
      await _db.approveReview(reviewId: review.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر التقييم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reject(DoctorReview review) async {
    try {
      await _db.rejectReview(reviewId: review.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض التقييم')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete(DoctorReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف التقييم'),
          content:
              const Text('هل أنت متأكد من حذف هذا التقييم نهائياً؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await _db.deleteReview(reviewId: review.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildReviewManagementCard(DoctorReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: review.isPending
              ? Colors.orange.shade200
              : review.isApproved
                  ? Colors.green.shade200
                  : Colors.red.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    widget.accentColor.withValues(alpha: 0.12),
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName[0]
                      : '؟',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (review.reviewerPhone != null)
                      Text(
                        review.reviewerPhone!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber.shade500,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (review.reviewText != null &&
              review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review.reviewText!,
                style:
                    const TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // أزرار الإجراءات
          if (review.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(review),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('رفض', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(review),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('نشر', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _delete(review),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('حذف', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<DoctorReview> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMsg,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildReviewManagementCard(list[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.reviews_outlined,
                  color: widget.accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'إدارة التقييمات',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_loading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
              ),
          ],
        ),
        // إحصائيات سريعة
        if (!_loading)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                _StatChip(
                    label: 'معلقة',
                    count: _pending.length,
                    color: Colors.orange.shade600),
                const SizedBox(width: 8),
                _StatChip(
                    label: 'منشورة',
                    count: _approved.length,
                    color: Colors.green.shade600),
                const SizedBox(width: 8),
                _StatChip(
                    label: 'مرفوضة',
                    count: _rejected.length,
                    color: Colors.red.shade600),
              ],
            ),
          ),
        const SizedBox(height: 14),
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: widget.accentColor,
            unselectedLabelColor: Colors.grey.shade600,
            indicator: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: _tabs
                .map((t) => Tab(
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                SingleChildScrollView(
                  child: _buildTabContent(
                      _pending, 'لا توجد تقييمات معلقة'),
                ),
                SingleChildScrollView(
                  child: _buildTabContent(
                      _approved, 'لا توجد تقييمات منشورة'),
                ),
                SingleChildScrollView(
                  child: _buildTabContent(
                      _rejected, 'لا توجد تقييمات مرفوضة'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Stat chip ──
class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
