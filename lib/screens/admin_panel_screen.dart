import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/admin_realtime_notifications_service.dart';
import '../services/lab_service.dart';
import 'admin_add_doctor_screen.dart';
import 'lab_register_screen.dart';
import 'add_lab_screen.dart';
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
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, published, publish_requested, delete_requested, not_published

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
      const SnackBar(
        content: Text('إضافة صيدلية: سيتم تنفيذها لاحقاً'),
      ),
    );
  }

  Future<void> _handleAddHospital() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('إضافة مستشفى: سيتم تنفيذها لاحقاً'),
      ),
    );
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
    final publishedCount =
        _doctors.where((d) => d['is_published'] == true).length;
    final publishRequestedCount =
        _doctors.where((d) => d['publish_requested'] == true).length;
    final deleteRequestedCount =
        _doctors.where((d) => d['delete_requested'] == true).length;

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
          matchesFilter =
              !isPublished && !publishRequested && !deleteRequested;
          break;
        case 'all':
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('لوحة تحكم المدير'),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
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
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDoctors,
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // نظرة عامة سريعة وإحصائيات + بحث وفلاتر
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
                                isSelected:
                                    _statusFilter == 'publish_requested',
                                onTap: () {
                                  setState(
                                    () => _statusFilter = 'publish_requested',
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'طلب حذف',
                                isSelected:
                                    _statusFilter == 'delete_requested',
                                onTap: () {
                                  setState(
                                    () => _statusFilter = 'delete_requested',
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'غير منشور',
                                isSelected:
                                    _statusFilter == 'not_published',
                                onTap: () {
                                  setState(
                                    () => _statusFilter = 'not_published',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // قائمة الأطباء
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
                              final publishRequested =
                                  doctor['publish_requested'] == true;
                              final isPublished =
                                  doctor['is_published'] == true;
                              final deleteRequested =
                                  doctor['delete_requested'] == true;

                              // Debug: طباعة القيم للتحقق
                              if (kDebugMode &&
                                  doctor['delete_requested'] != null) {
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
                                      doctor['full_name']?.toString().substring(
                                            0,
                                            1,
                                          ) ??
                                          '؟',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        doctor['specialization'] ?? 'غير محدد',
                                      ),
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
                                            Icon(
                                              Icons.visibility,
                                              color: Colors.blueGrey,
                                            ),
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
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('موافقة على حذف الحساب'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'reject_delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.cancel,
                                                color: Colors.orange,
                                              ),
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
                                              Icon(
                                                Icons.verified,
                                                color: Colors.green,
                                              ),
                                              SizedBox(width: 8),
                                              Text('قبول طلب النشر'),
                                            ],
                                          ),
                                        ),
                                      if (!deleteRequested)
                                        const PopupMenuItem(
                                          value: 'send_message',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.mail_outline,
                                                color: Colors.blue,
                                              ),
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
                                              Icon(
                                                Icons.lock_reset,
                                                color: Colors.orange,
                                              ),
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
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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
              const Icon(
                Icons.check,
                size: 16,
                color: Color(0xFF2196F3),
              ),
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
