import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminAddDoctorScreen extends StatefulWidget {
  const AdminAddDoctorScreen({super.key});

  @override
  State<AdminAddDoctorScreen> createState() => _AdminAddDoctorScreenState();
}

class _AdminAddDoctorScreenState extends State<AdminAddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  bool _isLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _specializationsController = TextEditingController();
  List<String> _selectedSpecializations = [];

  final List<String> specializations = [
    'طب عام',
    'أسنان',
    'علاج طبيعي',
    'طب الأسرة',
    'باطنة (أمراض باطنة)',
    'قلب وأوعية دموية',
    'صدرية (أمراض الصدر)',
    'جهاز هضمي وكبد',
    'كُلى (أمراض الكلى)',
    'غدد صماء وسكر',
    'روماتيزم ومناعة',
    'أمراض دم',
    'طب الأورام',
    'حساسية ومناعة',
    'طب المخ والأعصاب',
    'نفسية (طب نفسي)',
    'جلدية وتناسلية',
    'أنف وأذن وحنجرة',
    'رمد',
    'جراحة عامة',
    'جراحة عظام',
    'جراحة قلب وصدر',
    'جراحة أوعية دموية',
    'جراحة الأورام',
    'جراحة المخ والأعصاب',
    'جراحة تجميل',
    'جراحات السمنة',
    'جراحة الوجه والفكين',
    'جراحة أطفال',
    'جراحة مسالك بولية',
    'ذكورة وعقم',
    'نساء وتوليد',
    'أطفال وحديثي الولادة',
    'مخ وأعصاب أطفال',
    'تغذية علاجية',
    'علاج الألم',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _specializationsController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final specializationValue = _selectedSpecializations.join('، ');

      final result = await _adminService.createDoctorAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        specialization: specializationValue,
      );

      if (mounted) {
        // عرض رسالة نجاح مع البيانات
        showDialog(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تم إنشاء الحساب بنجاح ✅'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تم إنشاء حساب الطبيب. قم بإعطاء الطبيب البيانات التالية:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SelectableText('البريد الإلكتروني:\n${result['email']}'),
                  const SizedBox(height: 8),
                  SelectableText('كلمة المرور:\n${_passwordController.text}'),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ تأكد من حفظ هذه البيانات وإرسالها للطبيب',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true); // العودة مع تحديث
                  },
                  child: const Text('حسناً'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSpecialtiesSelector() async {
    final currentSelection = Set<String>.from(_selectedSpecializations);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        final tempSelected = Set<String>.from(currentSelection);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('اختر التخصصات'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: specializations.map((spec) {
                        return CheckboxListTile(
                          value: tempSelected.contains(spec),
                          onChanged: (v) {
                            setStateDialog(() {
                              if (v == true) {
                                tempSelected.add(spec);
                              } else {
                                tempSelected.remove(spec);
                              }
                            });
                          },
                          title: Text(spec),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(tempSelected.toList()),
                    child: const Text('تم'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      // ترتيب التخصصات المختارة طبقاً لترتيب القائمة الأصلية
      final ordered = specializations
          .where((spec) => result.contains(spec))
          .toList(growable: false);

      setState(() {
        _selectedSpecializations = ordered;
        _specializationsController.text =
            ordered.isEmpty ? '' : ordered.join('، ');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('إضافة طبيب جديد'),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الاسم الكامل
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم الكامل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // البريد الإلكتروني
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني *',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return 'الرجاء إدخال بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور *',
                    prefixIcon: const Icon(Icons.lock),
                    hintText: 'كلمة مرور قوية للطبيب',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // التخصصات (اختيار متعدد)
                TextFormField(
                  controller: _specializationsController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'التخصصات *',
                    prefixIcon: const Icon(Icons.medical_services),
                    hintText: 'اضغط لاختيار تخصص أو أكثر',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  onTap: _showSpecialtiesSelector,
                  validator: (value) {
                    if (_selectedSpecializations.isEmpty) {
                      return 'الرجاء اختيار تخصص واحد على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // زر الإضافة
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateDoctor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle),
                              SizedBox(width: 8),
                              Text(
                                'إنشاء حساب الطبيب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
