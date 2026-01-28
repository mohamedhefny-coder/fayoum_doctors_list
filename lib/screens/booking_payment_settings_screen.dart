import 'package:flutter/material.dart';

import '../models/doctor_model.dart';
import '../services/doctor_database_service.dart';

class BookingPaymentSettingsScreen extends StatefulWidget {
  const BookingPaymentSettingsScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<BookingPaymentSettingsScreen> createState() =>
      _BookingPaymentSettingsScreenState();
}

class _BookingPaymentSettingsScreenState
    extends State<BookingPaymentSettingsScreen> {
  final _dbService = DoctorDatabaseService();

  late bool _payAtBooking;
  late bool _cancelBookingAtPayment;
  late bool _useVodafoneCash;
  late bool _useInstaPay;
  late TextEditingController _vodafoneCashController;
  late TextEditingController _instaPayController;

  @override
  void initState() {
    super.initState();
    _payAtBooking = widget.doctor.isPayAtBookingEnabled;
    _cancelBookingAtPayment = widget.doctor.isCancelBookingEnabledAtPayment;

    // تحليل طريقة الدفع الحالية
    final currentMethods = (widget.doctor.paymentMethod ?? '').split(',');
    final currentAccounts = (widget.doctor.paymentAccount ?? '').split(',');

    _useVodafoneCash = currentMethods.contains('vodafone_cash');
    _useInstaPay = currentMethods.contains('instapay');

    String vodafoneAccount = '';
    String instaPayAccount = '';

    for (int i = 0; i < currentMethods.length; i++) {
      if (i < currentAccounts.length) {
        if (currentMethods[i] == 'vodafone_cash') {
          vodafoneAccount = currentAccounts[i];
        } else if (currentMethods[i] == 'instapay') {
          instaPayAccount = currentAccounts[i];
        }
      }
    }

    _vodafoneCashController = TextEditingController(text: vodafoneAccount);
    _instaPayController = TextEditingController(text: instaPayAccount);
  }

  @override
  void dispose() {
    _vodafoneCashController.dispose();
    _instaPayController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final vodafoneAccount = _vodafoneCashController.text.trim();
      final instaPayAccount = _instaPayController.text.trim();

      // التحقق من إدخال البيانات
      if (_useVodafoneCash && vodafoneAccount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال رقم فودافون كاش.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_useInstaPay && instaPayAccount.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال رقم/معرف انستا باي.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // إنشاء قائمة الطرق والحسابات
      final methods = <String>[];
      final accounts = <String>[];

      if (_useVodafoneCash && vodafoneAccount.isNotEmpty) {
        methods.add('vodafone_cash');
        accounts.add(vodafoneAccount);
      }

      if (_useInstaPay && instaPayAccount.isNotEmpty) {
        methods.add('instapay');
        accounts.add(instaPayAccount);
      }

      final paymentMethod = methods.isEmpty ? null : methods.join(',');
      final paymentAccount = accounts.isEmpty ? null : accounts.join(',');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('جاري الحفظ...'),
            ],
          ),
          duration: Duration(minutes: 1),
        ),
      );

      await _dbService.updateDoctorProfile(
        doctorId: widget.doctor.id,
        isPayAtBookingEnabled: _payAtBooking,
        isCancelBookingEnabledAtPayment: _cancelBookingAtPayment,
        paymentMethod: paymentMethod,
        paymentAccount: paymentAccount,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ تم حفظ الإعدادات'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحفظ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('إعدادات الحجز والدفع'),
          backgroundColor: const Color(0xFF4FC3F7),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text(
                'حفظ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'الدفع عند الحجز',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Switch(
                    value: _payAtBooking,
                    onChanged: (v) => setState(() {
                      _payAtBooking = v;
                      if (!v) {
                        // إعادة تعيين بيانات الدفع عند إلغاء التفعيل
                        _useVodafoneCash = false;
                        _useInstaPay = false;
                        _vodafoneCashController.text = '';
                        _instaPayController.text = '';
                      }
                    }),
                    activeThumbColor: const Color(0xFF4FC3F7),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            if (_payAtBooking) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'طرق الدفع المتاحة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // فودافون كاش
                    Row(
                      children: [
                        Checkbox(
                          value: _useVodafoneCash,
                          onChanged: (v) {
                            setState(() {
                              _useVodafoneCash = v ?? false;
                              if (!_useVodafoneCash) {
                                _vodafoneCashController.text = '';
                              }
                            });
                          },
                          activeColor: const Color(0xFF4FC3F7),
                        ),
                        const Text(
                          'فودافون كاش',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (_useVodafoneCash) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _vodafoneCashController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFD700),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFD700),
                              width: 1.5,
                            ),
                          ),
                          labelText: 'رقم فودافون كاش',
                          hintText: 'مثال: 01XXXXXXXXX',
                          prefixIcon: const Icon(Icons.phone_android),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // انستا باي
                    Row(
                      children: [
                        Checkbox(
                          value: _useInstaPay,
                          onChanged: (v) {
                            setState(() {
                              _useInstaPay = v ?? false;
                              if (!_useInstaPay) {
                                _instaPayController.text = '';
                              }
                            });
                          },
                          activeColor: const Color(0xFF4FC3F7),
                        ),
                        const Text(
                          'انستا باي',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (_useInstaPay) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _instaPayController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFD700),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFD700),
                              width: 1.5,
                            ),
                          ),
                          labelText: 'معرف/رقم انستا باي',
                          hintText: 'مثال: 01XXXXXXXXX أو معرف InstaPay',
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
