import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'doctor_profile_screen.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _authService = AuthService();
  
  String? _selectedSpecialization;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> specializations = [
    'طب عام',
    'أسنان',
    'علاج طبيعي',
    'تخاطب',
    'تحاليل طبية',
    'أشعة',
    'صيدلة',
    'تمريض',
    'باطنة (أمراض باطنة)',
    'قلب وأوعية دموية',
    'صدرية (أمراض الصدر)',
    'جهاز هضمي وكبد',
    'كُلى (أمراض الكلى)',
    'غدد صماء وسكر',
    'روماتيزم ومناعة',
    'حساسية ومناعة',
    'أمراض دم',
    'أورام',
    'جلدية وتناسلية',
    'أنف وأذن وحنجرة',
    'رمد',
    'جراحة عامة',
    'جراحة عظام',
    'جراحة قلب وصدر',
    'جراحة أوعية دموية',
    'جراحة الأورام',
    'جراحة المخ والأعصاب',
    'طب المخ والأعصاب',
    'جراحة تجميل',
    'جراحة أطفال',
    'جراحة مسالك بولية',
    'نساء وتوليد',
    'أطفال وحديثي الولادة',
    'مخ وأعصاب أطفال',
    'تغذية علاجية',
    'علاج الألم',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار التخصص')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUpDoctor(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        specialization: _selectedSpecialization!,
        phone: _phoneController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DoctorProfileScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التسجيل: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد'),
          backgroundColor: const Color(0xFF00BCD4),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    // الاسم الكامل
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        hintText: 'الاسم الكامل',
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF00BCD4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال الاسم الكامل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // البريد الإلكتروني
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email, color: Color(0xFF00BCD4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني';
                        }
                        if (!value.contains('@')) {
                          return 'البريد الإلكتروني غير صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // التخصص
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpecialization,
                      hint: const Text('اختر التخصص'),
                      items: specializations.map((spec) {
                        return DropdownMenuItem(
                          value: spec,
                          child: Text(spec),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedSpecialization = value);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.medical_services, color: Color(0xFF00BCD4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // رقم الترخيص
                    TextFormField(
                      controller: _licenseNumberController,
                      decoration: InputDecoration(
                        hintText: 'رقم الترخيص الطبي',
                        prefixIcon: const Icon(Icons.badge, color: Color(0xFF00BCD4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال رقم الترخيص';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // رقم الهاتف
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'رقم الهاتف',
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF00BCD4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال رقم الهاتف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // كلمة المرور
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF00BCD4)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF00BCD4),
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // تأكيد كلمة المرور
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'تأكيد كلمة المرور',
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF00BCD4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'كلمات المرور غير متطابقة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // زر التسجيل
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'إنشاء الحساب',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // رابط تسجيل الدخول
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('لديك حساب بالفعل؟ '),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: Color(0xFF00BCD4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
