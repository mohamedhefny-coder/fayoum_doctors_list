import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/admin_realtime_notifications_service.dart';
import '../services/lab_service.dart';
import '../services/radiology_service.dart';
import 'admin_add_doctor_screen.dart';
import 'lab_register_screen.dart';
import 'add_lab_screen.dart';
import 'radiology_screen.dart';
import 'radiology_register_screen.dart';
import '../models/doctor_model.dart';
import 'doctor_detail_screen.dart';
import 'admin_replies_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _radiologyCenters = [];
  List<Map<String, dynamic>> _medicalSuppliesStores = [];
  bool _isLoading = true;
  bool _isLoadingRadiology = true;
  bool _isLoadingSupplies = true;
  String _searchQuery = '';
  String _statusFilter =
      'all'; // all, published, publish_requested, delete_requested, not_published

  String _radiologySearchQuery = '';
  String _radiologyStatusFilter = 'all'; // all, published, not_published

  String _suppliesSearchQuery = '';
  String _suppliesStatusFilter = 'all'; // all, published, not_published

  Future<void> _handlePreviewDoctor(String doctorId, Color cardColor) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('جاري تحميل صفحة الطبيب للمعاينة...'),
          duration: Duration(seconds: 2),
        ),
      );

      final Doctor doctor = await _adminService.getDoctorByIdForAdmin(doctorId);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              DoctorDetailScreen(doctor: doctor, cardColor: cardColor),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذر فتح المعاينة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadRadiologyCenters();
    _loadMedicalSuppliesStores();
    AdminRealtimeNotificationsService.startForCurrentAdmin();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final doctors = await _adminService.getAllDoctors();
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
      }
    }
  }

  Future<void> _loadRadiologyCenters() async {
    if (!mounted) return;
    setState(() => _isLoadingRadiology = true);
    try {
      final centers = await _adminService.getAllRadiologyCenters();
      if (!mounted) return;
      setState(() {
        _radiologyCenters = centers;
        _isLoadingRadiology = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRadiology = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل مراكز الأشعة: $e')),
      );
    }
  }

  Future<void> _loadMedicalSuppliesStores() async {
    if (!mounted) return;
    setState(() => _isLoadingSupplies = true);
    try {
      final stores = await _adminService.getAllMedicalSuppliesStores();
      if (!mounted) return;
      setState(() {
        _medicalSuppliesStores = stores;
        _isLoadingSupplies = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSupplies = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل متاجر المستلزمات: $e')),
      );
    }
  }

  Future<void> _handleAddMedicalSuppliesStore() async {
    final storeNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    try {
      if (!mounted) return;

      String? createdUserId;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          bool obscurePassword = true;
          bool isSaving = false;

          return StatefulBuilder(
            builder: (context, setLocalState) {
              Future<void> createAccount() async {
                final storeName = storeNameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text;

                if (storeName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال اسم المتجر')),
                  );
                  return;
                }
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال اليوزر (البريد الإلكتروني)')),
                  );
                  return;
                }
                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل')),
                  );
                  return;
                }

                setLocalState(() => isSaving = true);
                try {
                  final userId = await _adminService.createMedicalSuppliesStoreOwnerAccount(
                    storeName: storeName,
                    email: email,
                    password: password,
                  );
                  createdUserId = userId;
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                  );
                  setLocalState(() => isSaving = false);
                }
              }

              return Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('إنشاء حساب لصاحب المتجر'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'سيستخدم صاحب المتجر هذه البيانات لتسجيل الدخول ثم إنشاء متجره وملء بياناته.',
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: storeNameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المتجر *',
                            prefixIcon: Icon(Icons.storefront),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'اليوزر (البريد الإلكتروني) *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () => setLocalState(
                                        () => obscurePassword = !obscurePassword,
                                      ),
                              icon: Icon(
                                obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: isSaving ? null : createAccount,
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إنشاء الحساب'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      if (!mounted) return;

      if (createdUserId != null) {
        await showDialog<void>(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تم إنشاء الحساب بنجاح'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اسم المتجر: ${storeNameController.text.trim()}'),
                  Text('اليوزر: ${emailController.text.trim()}'),
                  Text('الباسورد: ${passwordController.text}'),
                  const SizedBox(height: 8),
                  const Text(
                    'ملاحظة: سلّم هذه البيانات لصاحب المتجر ليستخدمها في تسجيل الدخول.',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('تم'),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      storeNameController.dispose();
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _handleToggleSuppliesPublished(Map<String, dynamic> store) async {
    final current = store['is_published'] == true;
    final name = (store['name'] ?? '').toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(current ? 'إلغاء النشر' : 'نشر المتجر'),
          content: Text(
            current
                ? 'هل تريد إلغاء نشر "$name"؟'
                : 'هل تريد نشر "$name" ليظهر للمستخدمين؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(current ? 'إلغاء النشر' : 'نشر'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.updateMedicalSuppliesStoreSettings(
          storeId: store['id'],
          isPublished: !current,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!current ? 'تم نشر المتجر' : 'تم إلغاء نشر المتجر'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMedicalSuppliesStores();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDeleteSuppliesStore(
    String storeId,
    String storeName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف متجر "$storeName"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteMedicalSuppliesStore(storeId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المتجر بنجاح')),
        );
        _loadMedicalSuppliesStores();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDeleteRadiologyCenter(
    String centerId,
    String centerName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف مركز الأشعة "$centerName"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteRadiologyCenter(centerId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف مركز الأشعة بنجاح')),
        );
        _loadRadiologyCenters();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleToggleRadiologyPublished(
    Map<String, dynamic> center,
  ) async {
    final current = center['is_published'] == true;
    final name = (center['name'] ?? '').toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(current ? 'إلغاء النشر' : 'نشر المركز'),
          content: Text(
            current
                ? 'هل تريد إلغاء نشر "$name"؟'
                : 'هل تريد نشر "$name" ليظهر للمستخدمين؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(current ? 'إلغاء النشر' : 'نشر'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.updateRadiologyCenterSettings(
          centerId: center['id'],
          isPublished: !current,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!current ? 'تم نشر المركز' : 'تم إلغاء نشر المركز'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRadiologyCenters();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleToggleRadiologyBooking(
    Map<String, dynamic> center,
  ) async {
    final current = center['has_booking'] == true;
    try {
      await _adminService.updateRadiologyCenterSettings(
        centerId: center['id'],
        hasBooking: !current,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!current ? 'تم تفعيل الحجز' : 'تم إيقاف الحجز'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRadiologyCenters();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handlePreviewRadiologyCenter(Map<String, dynamic> center) {
    final name = (center['name'] ?? '').toString();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RadiologyScreen(initialCenterName: name),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await AdminRealtimeNotificationsService.stop();
    await _adminService.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleAddDoctor() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminAddDoctorScreen()),
    );
    if (result == true) {
      _loadDoctors(); // إعادة تحميل القائمة
    }
  }

  Future<void> _handleAddPharmacy() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('إضافة صيدلية: سيتم تنفيذها لاحقاً')),
    );
  }

  Future<void> _handleAddHospital() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('إضافة مستشفى: سيتم تنفيذها لاحقاً')),
    );
  }

  Future<void> _handleAddRadiology() async {
    debugPrint('👨‍💼 Admin: Opening radiology center registration...');
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const RadiologyRegisterScreen(),
      ),
    );

    if (result is Map<String, dynamic> && result['success'] == true) {
      if (!mounted) return;

      try {
        // تسجيل خروج المدير مؤقتاً
        await _adminService.signOut();

        // تسجيل دخول مركز الأشعة
        await RadiologyService().loginCenter(
          email: result['email'],
          password: result['password'],
        );

        if (!mounted) return;

        // فتح صفحة إضافة بيانات المركز
        final centerDataResult = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const AddRadiologyCenterScreen(),
          ),
        );

        // تسجيل خروج مركز الأشعة
        await RadiologyService().signOut();

        if (!mounted) return;

        if (centerDataResult == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم إضافة مركز الأشعة بنجاح. الرجاء تسجيل الدخول مرة أخرى',
              ),
            ),
          );
        }

        // العودة إلى صفحة تسجيل الدخول
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        debugPrint('👨‍💼 Admin: Error during radiology center flow: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleAddLab() async {
    debugPrint('👨‍💼 Admin: Opening lab registration...');
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LabRegisterScreen()));

    debugPrint('👨‍💼 Admin: Lab registration result: $result');

    // التحقق من أن result هو Map يحتوي على بيانات التسجيل
    if (result is Map<String, dynamic> && result['success'] == true) {
      if (!mounted) return;

      try {
        // تسجيل خروج المدير مؤقتاً
        debugPrint('👨‍💼 Admin: Logging out admin temporarily...');
        await _adminService.signOut();

        // تسجيل دخول المعمل
        debugPrint('👨‍💼 Admin: Logging in lab...');
        await LabService().loginLab(
          email: result['email'],
          password: result['password'],
        );

        if (!mounted) return;

        // فتح صفحة إضافة بيانات المعمل
        debugPrint('👨‍💼 Admin: Opening AddLabScreen...');
        final labDataResult = await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const AddLabScreen()));

        debugPrint('👨‍💼 Admin: AddLabScreen result: $labDataResult');

        // تسجيل خروج المعمل
        debugPrint('👨‍💼 Admin: Logging out lab...');
        await LabService().signOut();

        if (!mounted) return;

        // إعادة تسجيل دخول المدير (يجب أن يسجل المدير دخوله مرة أخرى يدوياً)
        debugPrint('👨‍💼 Admin: Please login again.');

        if (labDataResult == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم إضافة المعمل بنجاح. الرجاء تسجيل الدخول مرة أخرى',
              ),
            ),
          );
        }

        // العودة إلى صفحة تسجيل الدخول
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        debugPrint('👨‍💼 Admin: Error during lab login/data entry: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      debugPrint('👨‍💼 Admin: Lab registration cancelled or failed');
    }
  }

  Future<void> _handleDeleteDoctor(String doctorId, String doctorName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف الطبيب "$doctorName"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteDoctor(doctorId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف الطبيب بنجاح')));
          _loadDoctors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الحذف: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResetPassword(String doctorId, String doctorName) async {
    final passwordController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إعادة تعيين كلمة المرور\n$doctorName'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              hintText: 'أدخل كلمة مرور جديدة',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && passwordController.text.isNotEmpty) {
      try {
        await _adminService.resetDoctorPassword(
          doctorId: doctorId,
          newPassword: passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تغيير كلمة المرور إلى: ${passwordController.text}',
              ),
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
  }

  Future<void> _handleApprovePublish(String doctorId, String doctorName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('قبول طلب النشر'),
          content: Text('هل تريد نشر صفحة الطبيب "$doctorName"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('نشر'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.approvePublishRequest(doctorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نشر صفحة الطبيب بنجاح')),
          );
          _loadDoctors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showSendMessageDialog(
    BuildContext context,
    String doctorId,
    String doctorName,
  ) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إرسال رسالة إلى $doctorName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الرسالة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'نص الرسالة',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      if (titleController.text.isEmpty || messageController.text.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال عنوان الرسالة ونص الرسالة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await _adminService.sendMessageToDoctor(
          doctorId: doctorId,
          title: titleController.text,
          message: messageController.text,
        );
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الرسالة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الرسالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRecommendedSettingsDialog(
    BuildContext context,
    Map<String, dynamic> doctor,
  ) async {
    bool isRecommended = doctor['is_recommended'] == true;
    int weight = doctor['recommended_weight'] ?? 1;
    int durationSeconds = doctor['recommended_duration_seconds'] ?? 3;

    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.star, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'إعدادات العرض الموصى به\n${doctor['full_name'] ?? ''}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle switch
                  SwitchListTile(
                    title: const Text(
                      'عرض في الأطباء الموصى بهم',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'تفعيل ظهور هذا الطبيب في شريط الأطباء الموصى بهم',
                    ),
                    value: isRecommended,
                    activeTrackColor: Colors.purple,
                    onChanged: (value) {
                      setState(() => isRecommended = value);
                    },
                  ),
                  const Divider(height: 32),
                  // Weight slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'وزن العرض (التكرار)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$weight',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'كلما زاد الوزن، زادت عدد مرات ظهور الطبيب في الشريط',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Slider(
                        value: weight.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: weight.toString(),
                        activeColor: Colors.purple,
                        onChanged: (value) {
                          setState(() => weight = value.toInt());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'قليل (1)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'عادي (5)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'كثير (10)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Duration slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'مدة العرض',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$durationSeconds ث',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'المدة الزمنية لعرض بطاقة الطبيب قبل الانتقال للتالي',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Slider(
                        value: durationSeconds.toDouble(),
                        min: 2,
                        max: 12,
                        divisions: 10,
                        label: '$durationSeconds ثانية',
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() => durationSeconds = value.toInt());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'سريع (2ث)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'متوسط (7ث)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'بطيء (12ث)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop({
                  'isRecommended': isRecommended,
                  'weight': weight,
                  'durationSeconds': durationSeconds,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        await _adminService.updateRecommendedSettings(
          doctorId: doctor['id'],
          isRecommended: result['isRecommended']!,
          weight: result['weight']!,
          durationSeconds: result['durationSeconds']!,
        );

        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم تحديث إعدادات العرض الموصى به بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDoctors();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleApproveDeleteRequest(
    String doctorId,
    String doctorName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('تأكيد حذف الحساب'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الطبيب "$doctorName" طلب حذف حسابه.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('هل تريد الموافقة على الطلب وحذف الحساب نهائياً؟'),
              const SizedBox(height: 8),
              const Text(
                'تحذير: لا يمكن التراجع عن هذه العملية!',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('موافقة وحذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteDoctor(doctorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف حساب الطبيب بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDoctors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الحذف: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRejectDeleteRequest(
    String doctorId,
    String doctorName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رفض طلب الحذف'),
          content: Text('هل تريد رفض طلب حذف حساب الطبيب "$doctorName"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('رفض الطلب'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.rejectDeleteRequest(doctorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض طلب حذف الحساب'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDoctors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDoctors = _doctors.length;
    final publishedCount = _doctors
        .where((d) => d['is_published'] == true)
        .length;
    final publishRequestedCount = _doctors
        .where((d) => d['publish_requested'] == true)
        .length;
    final deleteRequestedCount = _doctors
        .where((d) => d['delete_requested'] == true)
        .length;

    final filteredDoctors = _doctors.where((doctor) {
      final query = _searchQuery.trim().toLowerCase();
      final name = (doctor['full_name'] ?? '').toString().toLowerCase();
      final email = (doctor['email'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query) || email.contains(query);

      final publishRequested = doctor['publish_requested'] == true;
      final isPublished = doctor['is_published'] == true;
      final deleteRequested = doctor['delete_requested'] == true;

      bool matchesFilter;
      switch (_statusFilter) {
        case 'published':
          matchesFilter = isPublished;
          break;
        case 'publish_requested':
          matchesFilter = publishRequested;
          break;
        case 'delete_requested':
          matchesFilter = deleteRequested;
          break;
        case 'not_published':
          matchesFilter = !isPublished && !publishRequested && !deleteRequested;
          break;
        case 'all':
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    final totalCenters = _radiologyCenters.length;
    final publishedCenters = _radiologyCenters
        .where((c) => c['is_published'] == true)
        .length;

    final filteredCenters = _radiologyCenters.where((center) {
      final query = _radiologySearchQuery.trim().toLowerCase();
      final name = (center['name'] ?? '').toString().toLowerCase();
      final phone = (center['phone'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query) || phone.contains(query);

      final isPublished = center['is_published'] == true;
      final matchesFilter = _radiologyStatusFilter == 'all'
          ? true
          : (_radiologyStatusFilter == 'published' ? isPublished : !isPublished);

      return matchesSearch && matchesFilter;
    }).toList();

    final totalStores = _medicalSuppliesStores.length;
    final publishedStores = _medicalSuppliesStores
        .where((s) => s['is_published'] == true)
        .length;

    final filteredStores = _medicalSuppliesStores.where((store) {
      final query = _suppliesSearchQuery.trim().toLowerCase();
      final name = (store['name'] ?? '').toString().toLowerCase();
      final phone = (store['phone'] ?? '').toString().toLowerCase();
      final whatsapp = (store['whatsapp'] ?? '').toString().toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          phone.contains(query) ||
          whatsapp.contains(query);

      final isPublished = store['is_published'] == true;
      final matchesFilter = _suppliesStatusFilter == 'all'
          ? true
          : (_suppliesStatusFilter == 'published' ? isPublished : !isPublished);

      return matchesSearch && matchesFilter;
    }).toList();

    return DefaultTabController(
      length: 3,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
          title: const Text('لوحة تحكم المدير'),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الأطباء'),
              Tab(text: 'مراكز أشعة'),
              Tab(text: 'مستلزمات طبية'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.add),
              tooltip: 'إضافة',
              onSelected: (value) {
                switch (value) {
                  case 'add_doctor':
                    _handleAddDoctor();
                    break;
                  case 'add_lab':
                    _handleAddLab();
                    break;
                  case 'add_pharmacy':
                    _handleAddPharmacy();
                    break;
                  case 'add_hospital':
                    _handleAddHospital();
                    break;
                  case 'add_radiology':
                    _handleAddRadiology();
                    break;
                  case 'add_supplies_store':
                    _handleAddMedicalSuppliesStore();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'add_doctor',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: Color(0xFF4CAF50)),
                      SizedBox(width: 8),
                      Text('إضافة طبيب'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add_lab',
                  child: Row(
                    children: [
                      Icon(Icons.biotech, color: Color(0xFF9C27B0)),
                      SizedBox(width: 8),
                      Text('إضافة معمل'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add_pharmacy',
                  child: Row(
                    children: [
                      Icon(Icons.local_pharmacy, color: Color(0xFF00BCD4)),
                      SizedBox(width: 8),
                      Text('إضافة صيدلية'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add_hospital',
                  child: Row(
                    children: [
                      Icon(Icons.local_hospital, color: Color(0xFFFF5722)),
                      SizedBox(width: 8),
                      Text('إضافة مستشفى'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add_radiology',
                  child: Row(
                    children: [
                      Icon(Icons.medical_information, color: Color(0xFF9C27B0)),
                      SizedBox(width: 8),
                      Text('إضافة مركز أشعة'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add_supplies_store',
                  child: Row(
                    children: [
                      Icon(Icons.storefront, color: Color(0xFF2196F3)),
                      SizedBox(width: 8),
                      Text('إضافة متجر مستلزمات'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadDoctors();
                _loadRadiologyCenters();
                _loadMedicalSuppliesStores();
              },
              tooltip: 'تحديث',
            ),
            IconButton(
              icon: const Icon(Icons.mark_email_unread),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminRepliesScreen(),
                  ),
                );
              },
              tooltip: 'ردود الأطباء',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'تسجيل الخروج',
            ),
          ],
        ),
          body: TabBarView(
            children: [
              // ====== Doctors tab (existing UI) ======
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'إجمالي الأطباء',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalDoctors',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _StatusPill(
                                          label: 'منشور',
                                          color: Colors.green,
                                          count: publishedCount,
                                        ),
                                        _StatusPill(
                                          label: 'طلب نشر',
                                          color: Colors.orange,
                                          count: publishRequestedCount,
                                        ),
                                        _StatusPill(
                                          label: 'طلب حذف',
                                          color: Colors.red,
                                          count: deleteRequestedCount,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'بحث باسم الطبيب أو البريد الإلكتروني...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FilterChip(
                                      label: 'الكل',
                                      isSelected: _statusFilter == 'all',
                                      onTap: () {
                                        setState(() => _statusFilter = 'all');
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                      label: 'منشور',
                                      isSelected: _statusFilter == 'published',
                                      onTap: () {
                                        setState(() => _statusFilter = 'published');
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                      label: 'طلب نشر',
                                      isSelected: _statusFilter == 'publish_requested',
                                      onTap: () {
                                        setState(() => _statusFilter = 'publish_requested');
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                      label: 'طلب حذف',
                                      isSelected: _statusFilter == 'delete_requested',
                                      onTap: () {
                                        setState(() => _statusFilter = 'delete_requested');
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                      label: 'غير منشور',
                                      isSelected: _statusFilter == 'not_published',
                                      onTap: () {
                                        setState(() => _statusFilter = 'not_published');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filteredDoctors.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لا توجد نتائج مطابقة',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filteredDoctors.length,
                                  itemBuilder: (context, index) {
                                    final doctor = filteredDoctors[index];
                                    final publishRequested = doctor['publish_requested'] == true;
                                    final isPublished = doctor['is_published'] == true;
                                    final deleteRequested = doctor['delete_requested'] == true;

                                    if (kDebugMode && doctor['delete_requested'] != null) {
                                      debugPrint(
                                        'DEBUG: Doctor ${doctor['full_name']} - delete_requested: ${doctor['delete_requested']}',
                                      );
                                    }

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: CircleAvatar(
                                          radius: 30,
                                          backgroundColor: const Color(0xFF2196F3),
                                          child: Text(
                                            doctor['full_name']?.toString().substring(0, 1) ?? '؟',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          doctor['full_name'] ?? 'غير محدد',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(doctor['specialization'] ?? 'غير محدد'),
                                            if (deleteRequested)
                                              const Text(
                                                '⚠️ طلب حذف الحساب',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else if (publishRequested)
                                              const Text(
                                                'الحالة: طلب نشر',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else if (isPublished)
                                              const Text(
                                                'الحالة: منشور',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else
                                              const Text(
                                                'الحالة: غير منشور',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            Text(
                                              doctor['email'] ?? '',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'رقم الهاتف: ${doctor['phone'] ?? ''}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'preview_profile') {
                                              _handlePreviewDoctor(
                                                doctor['id'],
                                                const Color(0xFF246BCE),
                                              );
                                            } else if (value == 'approve_delete') {
                                              _handleApproveDeleteRequest(
                                                doctor['id'],
                                                doctor['full_name'] ?? '',
                                              );
                                            } else if (value == 'reject_delete') {
                                              _handleRejectDeleteRequest(
                                                doctor['id'],
                                                doctor['full_name'] ?? '',
                                              );
                                            } else if (value == 'approve_publish') {
                                              _handleApprovePublish(
                                                doctor['id'],
                                                doctor['full_name'] ?? '',
                                              );
                                            } else if (value == 'recommended_settings') {
                                              _showRecommendedSettingsDialog(context, doctor);
                                            } else if (value == 'send_message') {
                                              _showSendMessageDialog(
                                                context,
                                                doctor['id'],
                                                doctor['full_name'] ?? '',
                                              );
                                            } else if (value == 'reset_password') {
                                              _handleResetPassword(
                                                doctor['id'],
                                                doctor['full_name'] ?? '',
                                              );
                                            } else if (value == 'delete') {
                                              _handleDeleteDoctor(
                                                doctor['id'],
                                                doctor['full_name'] ?? '',
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'preview_profile',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.visibility, color: Colors.blueGrey),
                                                  SizedBox(width: 8),
                                                  Text('معاينة صفحة الطبيب'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            if (deleteRequested) ...[
                                              const PopupMenuItem(
                                                value: 'approve_delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.check_circle, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('موافقة على حذف الحساب'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'reject_delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.cancel, color: Colors.orange),
                                                    SizedBox(width: 8),
                                                    Text('رفض طلب الحذف'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            if (publishRequested)
                                              const PopupMenuItem(
                                                value: 'approve_publish',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.verified, color: Colors.green),
                                                    SizedBox(width: 8),
                                                    Text('قبول طلب النشر'),
                                                  ],
                                                ),
                                              ),
                                            if (!deleteRequested && isPublished)
                                              const PopupMenuItem(
                                                value: 'recommended_settings',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.star_border, color: Colors.purple),
                                                    SizedBox(width: 8),
                                                    Text('إعدادات العرض الموصى به'),
                                                  ],
                                                ),
                                              ),
                                            if (!deleteRequested)
                                              const PopupMenuItem(
                                                value: 'send_message',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.mail_outline, color: Colors.blue),
                                                    SizedBox(width: 8),
                                                    Text('إرسال رسالة'),
                                                  ],
                                                ),
                                              ),
                                            if (!deleteRequested)
                                              const PopupMenuItem(
                                                value: 'reset_password',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.lock_reset, color: Colors.orange),
                                                    SizedBox(width: 8),
                                                    Text('إعادة تعيين كلمة المرور'),
                                                  ],
                                                ),
                                              ),
                                            if (!deleteRequested)
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('حذف الطبيب'),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),

              // ====== Radiology centers tab ======
              _isLoadingRadiology
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'إجمالي مراكز الأشعة',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalCenters',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9C27B0),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _StatusPill(
                                          label: 'منشور',
                                          color: Colors.green,
                                          count: publishedCenters,
                                        ),
                                        _StatusPill(
                                          label: 'غير منشور',
                                          color: Colors.grey,
                                          count: totalCenters - publishedCenters,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'بحث باسم المركز أو رقم الهاتف...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() => _radiologySearchQuery = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FilterChip(
                                      label: 'الكل',
                                      isSelected: _radiologyStatusFilter == 'all',
                                      onTap: () => setState(() => _radiologyStatusFilter = 'all'),
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                      label: 'منشور',
                                      isSelected: _radiologyStatusFilter == 'published',
                                      onTap: () => setState(() => _radiologyStatusFilter = 'published'),
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                      label: 'غير منشور',
                                      isSelected: _radiologyStatusFilter == 'not_published',
                                      onTap: () => setState(() => _radiologyStatusFilter = 'not_published'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filteredCenters.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لا توجد نتائج مطابقة',
                                    style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filteredCenters.length,
                                  itemBuilder: (context, index) {
                                    final center = filteredCenters[index];
                                    final isPublished = center['is_published'] == true;
                                    final hasBooking = center['has_booking'] == true;
                                    final name = (center['name'] ?? 'غير محدد').toString();

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: const CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Color(0xFF9C27B0),
                                          child: Icon(Icons.medical_information, color: Colors.white),
                                        ),
                                        title: Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              isPublished ? 'الحالة: منشور' : 'الحالة: غير منشور',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isPublished ? Colors.green : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              hasBooking ? 'الحجز: مُفعّل' : 'الحجز: غير مُفعّل',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: hasBooking ? Colors.blue : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'الهاتف: ${(center['phone'] ?? '').toString()}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'preview') {
                                              _handlePreviewRadiologyCenter(center);
                                            } else if (value == 'toggle_publish') {
                                              _handleToggleRadiologyPublished(center);
                                            } else if (value == 'toggle_booking') {
                                              _handleToggleRadiologyBooking(center);
                                            } else if (value == 'delete') {
                                              _handleDeleteRadiologyCenter(center['id'], name);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'preview',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.visibility, color: Colors.blueGrey),
                                                  SizedBox(width: 8),
                                                  Text('معاينة الصفحة'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            PopupMenuItem(
                                              value: 'toggle_publish',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.verified,
                                                    color: Colors.green,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(isPublished ? 'إلغاء النشر' : 'نشر'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'toggle_booking',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.event_available, color: Colors.blue),
                                                  const SizedBox(width: 8),
                                                  Text(hasBooking ? 'إيقاف الحجز' : 'تفعيل الحجز'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('حذف المركز'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),

              // ====== Medical supplies stores tab ======
              _isLoadingSupplies
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'إجمالي متاجر المستلزمات',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalStores',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _StatusPill(
                                          label: 'منشور',
                                          color: Colors.green,
                                          count: publishedStores,
                                        ),
                                        _StatusPill(
                                          label: 'غير منشور',
                                          color: Colors.grey,
                                          count: totalStores - publishedStores,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'بحث باسم المتجر أو رقم الهاتف أو واتساب...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() => _suppliesSearchQuery = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FilterChip(
                                      label: 'الكل',
                                      isSelected: _suppliesStatusFilter == 'all',
                                      onTap: () => setState(() => _suppliesStatusFilter = 'all'),
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                      label: 'منشور',
                                      isSelected: _suppliesStatusFilter == 'published',
                                      onTap: () => setState(() => _suppliesStatusFilter = 'published'),
                                    ),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                      label: 'غير منشور',
                                      isSelected: _suppliesStatusFilter == 'not_published',
                                      onTap: () => setState(() => _suppliesStatusFilter = 'not_published'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filteredStores.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لا توجد نتائج مطابقة',
                                    style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filteredStores.length,
                                  itemBuilder: (context, index) {
                                    final store = filteredStores[index];
                                    final isPublished = store['is_published'] == true;
                                    final name = (store['name'] ?? 'غير محدد').toString();
                                    final phone = (store['phone'] ?? '').toString();
                                    final whatsapp = (store['whatsapp'] ?? '').toString();

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: const CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Color(0xFF2196F3),
                                          child: Icon(Icons.storefront, color: Colors.white),
                                        ),
                                        title: Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              isPublished ? 'الحالة: منشور' : 'الحالة: غير منشور',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isPublished ? Colors.green : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (phone.isNotEmpty)
                                              Text(
                                                'الهاتف: $phone',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            if (whatsapp.isNotEmpty)
                                              Text(
                                                'واتساب: $whatsapp',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'toggle_publish') {
                                              _handleToggleSuppliesPublished(store);
                                            } else if (value == 'delete') {
                                              _handleDeleteSuppliesStore(store['id'], name);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'toggle_publish',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.verified, color: Colors.green),
                                                  const SizedBox(width: 8),
                                                  Text(isPublished ? 'إلغاء النشر' : 'نشر'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('حذف المتجر'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.count,
  });

  final String label;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3).withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196F3)
                : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Color(0xFF2196F3)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
