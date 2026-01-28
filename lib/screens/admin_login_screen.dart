import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_service.dart';
import 'admin_panel_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminService = AdminService();
  final _localAuth = LocalAuthentication();
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _biometricAvailable = false;
  bool _biometricBusy = false;

  bool get _hasSavedSession =>
      Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!mounted) return;
      setState(() {
        _biometricAvailable = isSupported && canCheck;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _biometricAvailable = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _localAuthErrorText(LocalAuthException e) {
    if (e.description != null && e.description!.trim().isNotEmpty) {
      return e.description!.trim();
    }

    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return 'لا توجد بصمات/وجه مُسجلة على الجهاز';
      case LocalAuthExceptionCode.noBiometricHardware:
        return 'الجهاز لا يدعم البصمة/الوجه';
      case LocalAuthExceptionCode.noCredentialsSet:
        return 'لا توجد وسيلة قفل شاشة مُفعّلة على الجهاز';
      case LocalAuthExceptionCode.userCanceled:
        return 'تم إلغاء العملية';
      case LocalAuthExceptionCode.timeout:
        return 'انتهت مهلة المصادقة';
      case LocalAuthExceptionCode.temporaryLockout:
        return 'تم قفل البصمة مؤقتاً بسبب محاولات فاشلة';
      case LocalAuthExceptionCode.biometricLockout:
        return 'تم قفل البصمة حتى يتم فتح الجهاز بطريقة أخرى';
      case LocalAuthExceptionCode.authInProgress:
        return 'هناك عملية مصادقة قيد التنفيذ بالفعل';
      case LocalAuthExceptionCode.uiUnavailable:
        return 'تعذر عرض واجهة المصادقة';
      case LocalAuthExceptionCode.systemCanceled:
        return 'تم إلغاء المصادقة بواسطة النظام';
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return 'مستشعر البصمة غير متاح حالياً';
      case LocalAuthExceptionCode.userRequestedFallback:
        return 'تم اختيار خيار بديل للمصادقة';
      case LocalAuthExceptionCode.deviceError:
        return 'حدث خطأ بالجهاز أثناء المصادقة';
      case LocalAuthExceptionCode.unknownError:
        return 'حدث خطأ غير متوقع أثناء المصادقة';
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.signInAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الدخول: ${e.toString()}'),
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

  Future<void> _handleBiometricLogin() async {
    if (_biometricBusy || _isLoading) return;

    if (!_hasSavedSession) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجّل الدخول مرة واحدة أولاً ثم استخدم البصمة لاحقاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _biometricBusy = true);
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'تأكيد هويتك للدخول إلى لوحة تحكم المدير',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!didAuth) return;

      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!mounted) return;

      if (!isAdmin) {
        await _adminService.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الحساب الحالي ليس حساب مدير'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
      );
    } on LocalAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر استخدام البصمة: ${_localAuthErrorText(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر استخدام البصمة: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر استخدام البصمة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _biometricBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة المدير
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2196F3,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // العنوان
                    const Text(
                      'لوحة تحكم المدير',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تسجيل الدخول للمديرين فقط',
                      style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 48),
                    // حقل البريد الإلكتروني
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!value.contains('@')) {
                          return 'الرجاء إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // حقل كلمة المرور
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
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
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
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
                            : const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // زر الدخول بالبصمة
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: (_biometricAvailable && _hasSavedSession)
                            ? _handleBiometricLogin
                            : null,
                        icon: _biometricBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fingerprint),
                        label: const Text(
                          'الدخول بالبصمة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2196F3),
                          side: const BorderSide(color: Color(0xFF2196F3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // رابط العودة
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'العودة للصفحة الرئيسية',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
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
