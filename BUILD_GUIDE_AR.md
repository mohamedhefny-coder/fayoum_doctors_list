# دليل البناء والرفع على Google Play

## التغييرات المطبقة

### 1. توسيع دعم الأجهزة
- تم تعيين `minSdk = 21` (Android 5.0+)
- هذا يدعم أكثر من 99% من الأجهزة النشطة

### 2. تقليل حجم التطبيق
تم تفعيل:
- **ABI Splits**: فصل الكود لكل معمارية جهاز
- **Density Splits**: فصل الصور حسب دقة الشاشة
- **Bundle Configuration**: تحسين App Bundle

## خطوات البناء والرفع

### الطريقة الموصى بها: App Bundle (AAB)

```bash
# 1. تنظيف المشروع
flutter clean

# 2. تحديث الحزم
flutter pub get

# 3. بناء App Bundle (الحجم أصغر)
flutter build appbundle --release

# 4. الملف سيكون في:
# build/app/outputs/bundle/release/app-release.aab
```

### رفع على Google Play Console

1. افتح [Google Play Console](https://play.google.com/console)
2. اختر التطبيق
3. اذهب إلى **Production** أو **Internal Testing**
4. اضغط **Create new release**
5. ارفع ملف `app-release.aab`
6. املأ التفاصيل واضغط **Review release**

### مقارنة الأحجام

| الطريقة | الحجم التقريبي |
|---------|----------------|
| APK عادي | 50-80 MB |
| App Bundle | 20-35 MB لكل جهاز |

### فوائد App Bundle:
- ✅ حجم أصغر (تقليل 40-60%)
- ✅ تحميل أسرع
- ✅ معدل تثبيت أعلى
- ✅ توزيع محسّن لكل جهاز
- ✅ توافق مع متطلبات Google Play

## بناء APK (اختياري)

إذا كنت تحتاج APK للتوزيع خارج Google Play:

```bash
# بناء APKs منفصلة لكل معمارية (أصغر)
flutter build apk --split-per-abi

# الملفات ستكون في:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

## التحقق من الحجم

```bash
# حجم App Bundle
ls -lh build/app/outputs/bundle/release/app-release.aab

# حجم APKs المنفصلة
ls -lh build/app/outputs/flutter-apk/*.apk
```

## ملاحظات مهمة

1. **App Bundle هو المطلوب**: Google Play يتطلب AAB للتطبيقات الجديدة
2. **زيادة رقم الإصدار**: تأكد من زيادة `version` في pubspec.yaml قبل كل رفع
3. **الاختبار**: اختبر على أجهزة مختلفة قبل النشر
4. **Release Notes**: اكتب ملاحظات التحديث بوضوح

## استكشاف الأخطاء

إذا ظهرت أخطاء في البناء:

```bash
# تنظيف شامل
flutter clean
cd android
./gradlew clean
cd ..

# إعادة البناء
flutter pub get
flutter build appbundle --release
```

## الخطوات التالية

1. بناء App Bundle
2. رفعه على Internal Testing أولاً
3. اختباره على أجهزة متنوعة
4. النشر على Production

---
تم التحديث: يناير 2026
