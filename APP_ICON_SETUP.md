# إعداد أيقونة التطبيق

## الخطوات المطلوبة:

### 1. حفظ صورة الأيقونة
احفظ الصورة التي تريد استخدامها كأيقونة في المسار التالي:
```
/home/mhefny1995/projects/fayoum_doctors_list/assets/icon/app_icon.png
```

**ملاحظات مهمة:**
- يُفضل أن تكون الصورة بحجم 1024x1024 بكسل
- يُفضل أن تكون بصيغة PNG مع خلفية شفافة أو بيضاء
- تأكد من أن الصورة واضحة وبجودة عالية

### 2. توليد الأيقونات
بعد حفظ الصورة، قم بتنفيذ الأمر التالي في Terminal:

```bash
cd /home/mhefny1995/projects/fayoum_doctors_list
flutter pub run flutter_launcher_icons
```

هذا الأمر سيقوم تلقائياً بـ:
- توليد جميع أحجام الأيقونات المطلوبة لنظام Android
- توليد جميع أحجام الأيقونات المطلوبة لنظام iOS
- وضع الأيقونات في المجلدات الصحيحة

### 3. إعادة بناء التطبيق
بعد توليد الأيقونات، قم بإعادة بناء التطبيق:

```bash
flutter clean
flutter pub get
flutter run
```

### 4. التحقق من النتيجة
- على Android: افتح التطبيق وتحقق من أيقونته في درج التطبيقات
- على iOS: افتح التطبيق وتحقق من أيقونته في الشاشة الرئيسية

## الإعدادات الحالية في pubspec.yaml:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
```

هذه الإعدادات تضمن:
- توليد أيقونات لكل من Android وiOS
- استخدام خلفية بيضاء للأيقونات التكيفية على Android
- استخدام نفس الصورة للأيقونة الأساسية والأيقونة التكيفية

## في حالة وجود مشاكل:

### إذا لم تظهر الأيقونة على Android:
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter run
```

### إذا لم تظهر الأيقونة على iOS:
```bash
flutter clean
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter run
```

## ملاحظات إضافية:
- يمكنك تغيير لون الخلفية للأيقونة التكيفية بتعديل `adaptive_icon_background` في pubspec.yaml
- إذا أردت أيقونة مختلفة للأنظمة المختلفة، يمكنك تحديد `image_path_android` و `image_path_ios` بشكل منفصل
