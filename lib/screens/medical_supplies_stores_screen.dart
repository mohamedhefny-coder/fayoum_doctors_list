import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/admin_service.dart';
import '../services/medical_supplies_media_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicalSuppliesStoresScreen extends StatefulWidget {
  const MedicalSuppliesStoresScreen({super.key});

  @override
  State<MedicalSuppliesStoresScreen> createState() =>
      _MedicalSuppliesStoresScreenState();
}

class _MedicalSuppliesStoresScreenState
    extends State<MedicalSuppliesStoresScreen> {
  static const List<_StoreData> _demoStores = [
    _StoreData(
      name: 'العمدة للمستلزمات الطبية',
      address: 'الفيوم - شارع الحرية - بجوار البنك الأهلي',
      phone: '01000000000',
      hours: 'يومياً 10 ص - 10 م',
      whatsappNumber: '01000000000',
      offersAndDiscounts:
          'خصم 15% على أجهزة قياس السكر وخصم 10% على أجهزة الضغط',
      hasDeliveryService: true,
      availableContracts: 'تعاقدات مع بعض الشركات والنقابات (حسب التوفر)',
      geoLocation: '29.3084, 30.8428',
      facebookPage: 'https://facebook.com/',
      availableSupplies: [
        'أجهزة قياس السكر',
        'أجهزة قياس الضغط',
        'شاش وقطن',
        'كمامات',
        'جبائر',
      ],
    ),
  ];

  late final List<_StoreData> _stores = [..._demoStores];

  final _adminService = AdminService();

  bool _isOwnerLoggedIn() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    final meta = user.userMetadata ?? const <String, dynamic>{};
    return meta['user_type']?.toString() == 'medical_supplies_store';
  }

  Future<void> _openAddStore() async {
    var allowed = _isOwnerLoggedIn();
    if (!allowed) {
      allowed =
          (await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const _MedicalSuppliesOwnerLoginScreen(),
                ),
              )) ==
              true;
    }
    if (!mounted) return;
    if (!allowed) return;

    final store = await Navigator.of(context).push<_StoreData>(
      MaterialPageRoute(builder: (_) => const _AddMedicalSuppliesStoreScreen()),
    );
    if (!mounted) return;
    if (store == null) return;
    setState(() {
      _stores.insert(0, store);
    });
  }

  void _openDetails(_StoreData store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MedicalSuppliesStoreDetailsScreen(store: store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stores = _stores;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF0EA5E9).withValues(alpha: 0.04),
                Colors.white,
                const Color(0xFF0284C7).withValues(alpha: 0.04),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _Header(
                  onBack: () => Navigator.pop(context),
                  onAdd: _openAddStore,
                ),
                _Stats(count: stores.length),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return _StoreCard(
                        store: store,
                        onTap: () => _openDetails(store),
                      );
                    },
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

class _MedicalSuppliesOwnerLoginScreen extends StatefulWidget {
  const _MedicalSuppliesOwnerLoginScreen();

  @override
  State<_MedicalSuppliesOwnerLoginScreen> createState() =>
      _MedicalSuppliesOwnerLoginScreenState();
}

class _MedicalSuppliesOwnerLoginScreenState
    extends State<_MedicalSuppliesOwnerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _login() async {
    if (_loading) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _loading = true);
    try {
      final auth = Supabase.instance.client.auth;
      final res = await auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = res.user;
      if (user == null) {
        _showSnack('تعذر تسجيل الدخول. حاول مرة أخرى.', color: Colors.red);
        return;
      }

      final meta = user.userMetadata ?? const <String, dynamic>{};
      final userType = meta['user_type']?.toString();
      if (userType != 'medical_supplies_store') {
        await auth.signOut();
        _showSnack('هذا الحساب ليس حساب متجر مستلزمات طبية.',
            color: Colors.orange);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on AuthException catch (e) {
      _showSnack(e.message, color: Colors.red);
    } catch (_) {
      _showSnack('حدث خطأ غير متوقع أثناء تسجيل الدخول.', color: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسجيل دخول متجر المستلزمات'),
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/medical_supplies.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.healing, size: 44);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'استخدم بيانات الدخول التي أنشأها المدير للمتجر',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'أدخل البريد الإلكتروني';
                            if (!value.contains('@')) {
                              return 'أدخل بريد إلكتروني صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() => _obscure = !_obscure);
                              },
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if ((v ?? '').isEmpty) {
                              return 'أدخل كلمة المرور';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'تسجيل الدخول',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onAdd});

  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              onPressed: onBack,
              tooltip: 'رجوع',
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'متاجر المستلزمات الطبية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                Text(
                  'محافظة الفيوم',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'إضافة متجر',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/medical_supplies.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.healing,
                        color: Colors.white,
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0EA5E9).withValues(alpha: 0.12),
              const Color(0xFF0284C7).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.healing,
                color: Color(0xFF0284C7),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إجمالي المتاجر المعروضة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count متجر',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF075985),
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
}

class _StoreData {
  const _StoreData({
    required this.name,
    required this.address,
    required this.phone,
    required this.hours,
    this.whatsappNumber,
    this.coverImage,
    this.availableSupplies,
    this.galleryImages,
    this.offersAndDiscounts,
    this.hasDeliveryService,
    this.availableContracts,
    this.geoLocation,
    this.facebookPage,
  });

  final String name;
  final String address;
  final String phone;
  final String hours;

  final String? whatsappNumber;
  final String? coverImage;
  final List<String>? availableSupplies;
  final List<String>? galleryImages;
  final String? offersAndDiscounts;
  final bool? hasDeliveryService;
  final String? availableContracts;
  final String? geoLocation;
  final String? facebookPage;
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.onTap});

  final _StoreData store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront, color: Color(0xFF0284C7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      store.address,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    store.phone,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      store.hours,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
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

class _MedicalSuppliesStoreDetailsScreen extends StatelessWidget {
  const _MedicalSuppliesStoreDetailsScreen({required this.store});

  final _StoreData store;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0284C7);

    Widget infoTile({
      required IconData icon,
      required String title,
      required String value,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget section({
      required String title,
      required IconData icon,
      required Widget child,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), primary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    }

    final supplies = store.availableSupplies ?? const <String>[];
    final gallery = store.galleryImages ?? const <String>[];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF0EA5E9).withValues(alpha: 0.05),
                const Color(0xFFF1F5F9),
                const Color(0xFF0284C7).withValues(alpha: 0.04),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 20),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'رجوع',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            const Text(
                              'تفاصيل المتجر',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), primary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/medical_supplies.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.healing,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        infoTile(
                          icon: Icons.location_on_outlined,
                          title: 'العنوان',
                          value: store.address,
                        ),
                        const SizedBox(height: 12),
                        infoTile(
                          icon: Icons.phone_outlined,
                          title: 'رقم الهاتف',
                          value: store.phone,
                        ),
                        const SizedBox(height: 12),
                        infoTile(
                          icon: Icons.access_time,
                          title: 'أوقات العمل',
                          value: store.hours,
                        ),
                        if (store.whatsappNumber != null &&
                            store.whatsappNumber!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          infoTile(
                            icon: Icons.chat_outlined,
                            title: 'واتساب',
                            value: store.whatsappNumber!,
                          ),
                        ],
                        if (store.coverImage != null &&
                            store.coverImage!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          section(
                            title: 'صورة الغلاف',
                            icon: Icons.image_outlined,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _SmartImage(pathOrUrl: store.coverImage!),
                            ),
                          ),
                        ],
                        if (supplies.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          section(
                            title: 'المستلزمات المتوفرة',
                            icon: Icons.medical_services_outlined,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: supplies
                                  .map(
                                    (s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Text(
                                        s,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                        if (gallery.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          section(
                            title: 'معرض الصور',
                            icon: Icons.collections_outlined,
                            child: SizedBox(
                              height: 90,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: gallery.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: _SmartImage(
                                        pathOrUrl: gallery[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                        if (store.offersAndDiscounts != null &&
                            store.offersAndDiscounts!.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          section(
                            title: 'العروض والخصومات',
                            icon: Icons.local_offer_outlined,
                            child: Text(
                              store.offersAndDiscounts!,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        section(
                          title: 'الخدمات',
                          icon: Icons.delivery_dining_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (store.hasDeliveryService ?? false)
                                    ? 'خدمة التوصيل متاحة'
                                    : 'لا توجد خدمة توصيل',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (store.availableContracts != null &&
                                  store.availableContracts!.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'التعاقدات: ${store.availableContracts}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.3,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if ((store.geoLocation != null &&
                                store.geoLocation!.trim().isNotEmpty) ||
                            (store.facebookPage != null &&
                                store.facebookPage!.trim().isNotEmpty)) ...[
                          const SizedBox(height: 14),
                          section(
                            title: 'روابط وموقع',
                            icon: Icons.link,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (store.geoLocation != null &&
                                    store.geoLocation!.trim().isNotEmpty)
                                  Text(
                                    'الموقع الجغرافي: ${store.geoLocation}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                if (store.geoLocation != null &&
                                    store.geoLocation!.trim().isNotEmpty &&
                                    store.facebookPage != null &&
                                    store.facebookPage!.trim().isNotEmpty)
                                  const SizedBox(height: 8),
                                if (store.facebookPage != null &&
                                    store.facebookPage!.trim().isNotEmpty)
                                  Text(
                                    'فيسبوك: ${store.facebookPage}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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

class _SmartImage extends StatelessWidget {
  const _SmartImage({required this.pathOrUrl});

  final String pathOrUrl;

  @override
  Widget build(BuildContext context) {
    final v = pathOrUrl.trim();
    if (v.isEmpty) {
      return Container(
        color: Colors.grey[100],
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
      );
    }

    final isAsset = v.startsWith('assets/');
    if (isAsset) {
      return Image.asset(
        v,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }

    return Image.network(
      v,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class _AddMedicalSuppliesStoreScreen extends StatefulWidget {
  const _AddMedicalSuppliesStoreScreen();

  @override
  State<_AddMedicalSuppliesStoreScreen> createState() =>
      _AddMedicalSuppliesStoreScreenState();
}

class _AddMedicalSuppliesStoreScreenState
    extends State<_AddMedicalSuppliesStoreScreen> {
  static const primary = Color(0xFF0284C7);

  final _adminService = AdminService();
  final _mediaService = MedicalSuppliesMediaService();
  final _imagePicker = ImagePicker();
  bool _checkedOwner = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _hoursController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _newSupplyController = TextEditingController();
  final _galleryController = TextEditingController();
  final _offersController = TextEditingController();
  final _contractsController = TextEditingController();
  final _geoLocationController = TextEditingController();
  final _facebookController = TextEditingController();

  final List<String> _suppliesList = <String>[];
  bool _hasDeliveryService = false;

  bool _isUploadingCover = false;
  bool _isUploadingGallery = false;

  Future<void> _pickAndUploadCover() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      if (!mounted) return;
      setState(() => _isUploadingCover = true);

      final url = await _mediaService.uploadImage(picked, 'cover');
      if (!mounted) return;
      setState(() => _coverImageController.text = url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفع صورة الكفر بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع صورة الكفر: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickAndUploadGallery() async {
    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;

      if (!mounted) return;
      setState(() => _isUploadingGallery = true);

      final urls = <String>[];
      for (final img in picked) {
        final url = await _mediaService.uploadImage(img, 'gallery');
        urls.add(url);
      }

      if (!mounted) return;
      final existing = _splitList(_galleryController.text);
      final combined = [...existing, ...urls];
      setState(() => _galleryController.text = combined.join('\n'));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفع ${urls.length} صورة للمعرض'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع صور المعرض: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingGallery = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _guardOwner();
  }

  Future<void> _guardOwner() async {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? const <String, dynamic>{};
    final userType = meta['user_type']?.toString();

    if (!mounted) return;
    setState(() => _checkedOwner = true);

    if (user == null || userType != 'medical_supplies_store') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'غير مصرح: يلزم تسجيل الدخول ببيانات متجر المستلزمات لإضافة/تعديل البيانات',
          ),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _hoursController.dispose();
    _coverImageController.dispose();
    _newSupplyController.dispose();
    _galleryController.dispose();
    _offersController.dispose();
    _contractsController.dispose();
    _geoLocationController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  InputDecoration _deco({required String label, String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  List<String> _splitList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _addSupply() {
    final supply = _newSupplyController.text.trim();
    if (supply.isEmpty) return;
    setState(() {
      _suppliesList.add(supply);
      _newSupplyController.clear();
    });
  }

  void _removeSupply(int index) {
    setState(() {
      _suppliesList.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final gallery = _splitList(_galleryController.text);
    final cover = _coverImageController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final offers = _offersController.text.trim();
    final contracts = _contractsController.text.trim();
    final geo = _geoLocationController.text.trim();
    final facebook = _facebookController.text.trim();

    final store = _StoreData(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      hours: _hoursController.text.trim(),
      whatsappNumber: whatsapp.isEmpty ? null : whatsapp,
      coverImage: cover.isEmpty ? null : cover,
      availableSupplies: _suppliesList.isEmpty ? null : [..._suppliesList],
      galleryImages: gallery.isEmpty ? null : gallery,
      offersAndDiscounts: offers.isEmpty ? null : offers,
      hasDeliveryService: _hasDeliveryService,
      availableContracts: contracts.isEmpty ? null : contracts,
      geoLocation: geo.isEmpty ? null : geo,
      facebookPage: facebook.isEmpty ? null : facebook,
    );

    setState(() => _isSaving = true);
    try {
      await _adminService.upsertMedicalSuppliesStoreForOwner(
        data: {
          'name': store.name,
          'address': store.address,
          'phone': store.phone,
          'whatsapp': store.whatsappNumber,
          'working_hours': store.hours,
          'cover_image_url': store.coverImage,
          'available_supplies': store.availableSupplies,
          'gallery_image_urls': store.galleryImages,
          'offers_and_discounts': store.offersAndDiscounts,
          'has_delivery_service': store.hasDeliveryService,
          'available_contracts': store.availableContracts,
          'geo_location': store.geoLocation,
          'facebook_page': store.facebookPage,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ بيانات المتجر بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, store);
    } catch (e) {
      if (!mounted) return;
      var message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedOwner) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Color(0xFFF1F5F9),
          body: SafeArea(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF0EA5E9).withValues(alpha: 0.05),
                const Color(0xFFF1F5F9),
                const Color(0xFF0284C7).withValues(alpha: 0.04),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 20),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'رجوع',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إضافة متجر مستلزمات',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              'أدخل بيانات المتجر لعرضه بالقائمة',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), primary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/medical_supplies.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.healing,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _sectionCard(
                            title: 'بيانات أساسية',
                            icon: Icons.storefront_outlined,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _deco(
                                    label: 'اسم المتجر *',
                                    icon: Icons.store,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'من فضلك أدخل اسم المتجر';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: _deco(
                                    label: 'العنوان التفصيلي *',
                                    icon: Icons.location_on_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'من فضلك أدخل العنوان';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _deco(
                                    label: 'رقم الهاتف *',
                                    icon: Icons.phone_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'من فضلك أدخل رقم الهاتف';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _whatsappController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _deco(
                                    label: 'رقم واتساب (اختياري)',
                                    icon: Icons.chat_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _hoursController,
                                  decoration: _deco(
                                    label: 'أوقات العمل *',
                                    hint: 'مثال: يومياً 10 ص - 10 م',
                                    icon: Icons.access_time,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'من فضلك أدخل أوقات العمل';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            title: 'تفاصيل إضافية',
                            icon: Icons.tune,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _coverImageController,
                                  decoration: _deco(
                                    label: 'صورة الكفر (رابط/مسار) (اختياري)',
                                    hint: 'مثال: https://... أو assets/...',
                                    icon: Icons.image_outlined,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isUploadingCover ? null : _pickAndUploadCover,
                                    icon: _isUploadingCover
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.upload),
                                    label: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Text('اختيار ورفع صورة الكفر'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: BorderSide(color: primary.withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'المستلزمات المتوفرة (اختياري)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _newSupplyController,
                                        decoration: _deco(
                                          label: 'أدخل مستلزم',
                                          icon: Icons.medical_services_outlined,
                                        ),
                                        onSubmitted: (_) => _addSupply(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _addSupply,
                                      icon: const Icon(Icons.add),
                                      label: const Text('إضافة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_suppliesList.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        _suppliesList.asMap().entries.map((e) {
                                      final index = e.key;
                                      final supply = e.value;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  supply,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () =>
                                                    _removeSupply(index),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _galleryController,
                                  maxLines: 3,
                                  decoration: _deco(
                                    label:
                                        'معرض الصور (روابط/مسارات) (اختياري)',
                                    hint: 'افصل بين الروابط بسطر جديد أو فاصلة',
                                    icon: Icons.collections_outlined,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isUploadingGallery ? null : _pickAndUploadGallery,
                                    icon: _isUploadingGallery
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.collections),
                                    label: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Text('إضافة صور للمعرض (رفع من الجهاز)'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: BorderSide(color: primary.withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _offersController,
                                  maxLines: 3,
                                  decoration: _deco(
                                    label: 'العروض والخصومات (اختياري)',
                                    icon: Icons.local_offer_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primary.withValues(alpha: 0.10),
                                        const Color(0xFF0EA5E9)
                                            .withValues(alpha: 0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: SwitchListTile.adaptive(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                    title: const Text(
                                      'خدمة التوصيل متاحة',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    value: _hasDeliveryService,
                                    onChanged: (v) =>
                                        setState(() => _hasDeliveryService = v),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _contractsController,
                                  maxLines: 2,
                                  decoration: _deco(
                                    label: 'التعاقدات المتاحة (اختياري)',
                                    hint: 'مثال: تأمين/نقابات/شركات',
                                    icon: Icons.handshake_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _geoLocationController,
                                  decoration: _deco(
                                    label: 'الموقع الجغرافي (اختياري)',
                                    hint: 'مثال: 29.3084, 30.8428',
                                    icon: Icons.my_location_outlined,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _facebookController,
                                  decoration: _deco(
                                    label: 'صفحة فيسبوك (اختياري)',
                                    hint: 'https://facebook.com/...',
                                    icon: Icons.facebook,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _submit,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'حفظ المتجر',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
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
