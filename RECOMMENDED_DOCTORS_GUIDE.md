# دليل ميزة الأطباء الموصى بهم (Recommended Doctors Feature)

## نظرة عامة
تتيح هذه الميزة للمدير التحكم الكامل في عرض الأطباء في شريط "الأطباء الموصى بهم" الموجود في الصفحة الرئيسية للتطبيق.

## المميزات

### 1. **تحكم في الظهور (Toggle)**
- تفعيل/إلغاء تفعيل ظهور الطبيب في شريط الأطباء الموصى بهم
- فقط الأطباء المنشورين (`is_published = true`) يمكن إضافتهم

### 2. **وزن العرض (Display Weight) - من 1 إلى 10**
- يحدد عدد مرات ظهور الطبيب في دورة العرض
- **مثال**: إذا كان الوزن = 5، سيظهر الطبيب 5 مرات في كل دورة
- القيمة الافتراضية: 1
- **استخدام عملي**:
  - وزن 1-3: أطباء جدد أو أقل شهرة
  - وزن 4-6: أطباء عاديين
  - وزن 7-10: أطباء مميزين أو أكثر شهرة

### 3. **مدة العرض (Display Duration) - من 2 إلى 12 ثانية**
- تحديد المدة الزمنية لعرض بطاقة الطبيب قبل الانتقال للتالي
- القيمة الافتراضية: 3 ثوانٍ
- **استخدام عملي**:
  - 2-4 ثواني: عرض سريع
  - 5-7 ثواني: عرض متوسط (موصى به)
  - 8-12 ثانية: عرض بطيء (لأطباء مميزين)

## خطوات الإعداد

### 1. تطبيق التغييرات على قاعدة البيانات
قم بتنفيذ السكربت SQL في Supabase:

```bash
# نسخ محتوى الملف
cat add_recommended_display_settings.sql

# ثم الذهاب إلى Supabase Dashboard → SQL Editor وتنفيذه
```

أو مباشرة عبر Supabase SQL Editor:
1. افتح Supabase Dashboard
2. اذهب إلى **SQL Editor**
3. انسخ محتوى ملف `add_recommended_display_settings.sql`
4. نفذ الأوامر

### 2. التحديث على Flutter
التغييرات المطلوبة تم تنفيذها بالفعل في:
- `lib/models/doctor_model.dart` - إضافة الحقول الجديدة
- `lib/services/doctor_database_service.dart` - إضافة `getRecommendedDoctors()`
- `lib/services/admin_service.dart` - إضافة `updateRecommendedSettings()`
- `lib/screens/admin_panel_screen.dart` - إضافة واجهة التحكم
- `lib/main.dart` - نظام العرض الدوار مع الأوزان

قم بتثبيت التبعيات:
```bash
flutter pub get
```

### 3. إعادة نشر التطبيق
```bash
# للويب (GitHub Pages)
git add .
git commit -m "إضافة ميزة التحكم في عرض الأطباء الموصى بهم"
git push origin main

# للأندرويد/iOS
flutter build apk --release
# أو
flutter build ios --release
```

## كيفية الاستخدام (للمدير)

### إضافة طبيب للقائمة الموصى بها:

1. افتح **لوحة الإدارة** (Admin Panel)
2. ابحث عن الطبيب المطلوب (يجب أن يكون منشوراً)
3. اضغط على **النقاط الثلاث** (⋮) بجانب اسم الطبيب
4. اختر **"إعدادات العرض الموصى به"**

ستظهر نافذة بها:

#### أ. **مفتاح التفعيل** (Switch):
- ✅ **مفعّل**: الطبيب سيظهر في الشريط
- ❌ **غير مفعّل**: الطبيب لن يظهر في الشريط

#### ب. **مؤشر الوزن** (Slider):
- اضبط من 1 إلى 10
- كلما زاد الرقم، زادت مرات الظهور

#### ج. **مؤشر المدة** (Slider):
- اضبط من 2 إلى 12 ثانية
- حدد كم ثانية ستظهر بطاقة الطبيب

5. اضغط **"حفظ"**

### مثال عملي:

لنفترض لديك 3 أطباء:
- **د. أحمد**: وزن 3، مدة 4 ثواني
- **د. محمد**: وزن 1، مدة 3 ثواني
- **د. فاطمة**: وزن 2، مدة 5 ثواني

**دورة العرض ستكون**:
1. د. أحمد (4 ثواني)
2. د. أحمد (4 ثواني)
3. د. أحمد (4 ثواني)
4. د. محمد (3 ثواني)
5. د. فاطمة (5 ثواني)
6. د. فاطمة (5 ثواني)
7. ← تكرار من البداية

**إجمالي**: 6 بطاقات في الدورة، د. أحمد يظهر 3 مرات (50% من الوقت!)

## آلية العمل التقنية

### التدفق (Flow):
```
المستخدم يفتح التطبيق
    ↓
يتم استدعاء getRecommendedDoctors()
    ↓
فلترة: is_recommended=true AND is_published=true
    ↓
بناء قائمة دوارة حسب الوزن
    ↓
عرض كل بطاقة لمدة durationSeconds
    ↓
الانتقال التلقائي للبطاقة التالية
    ↓
← تكرار الدورة
```

### التحديث الفوري (Realtime):
- عند تغيير إعدادات طبيب من لوحة الإدارة
- يتم استقبال التحديث فوراً عبر Supabase Realtime
- تُعاد بناء قائمة العرض تلقائياً
- التطبيقات المفتوحة (ويب/موبايل) تتحدث في نفس اللحظة

## استكشاف الأخطاء (Troubleshooting)

### المشكلة: الطبيب لا يظهر رغم التفعيل
**الحل**:
- تأكد من أن الطبيب منشور (`is_published = true`)
- تحقق من أن `is_recommended = true` في قاعدة البيانات
- أعد تشغيل التطبيق

### المشكلة: التحديثات لا تظهر فوراً
**الحل**:
- تحقق من اتصال Supabase Realtime
- تأكد من صلاحيات RLS
- أعد تحميل الصفحة

### المشكلة: خطأ في حفظ الإعدادات
**الحل**:
- تحقق من أن العمود موجود في قاعدة البيانات:
  ```sql
  SELECT column_name 
  FROM information_schema.columns 
  WHERE table_name = 'doctors' 
  AND column_name LIKE 'recommended%';
  ```
- تأكد من صلاحيات المدير (UPDATE على جدول doctors)

## استعلامات مفيدة (Useful Queries)

### عرض جميع الأطباء الموصى بهم:
```sql
SELECT 
  full_name, 
  is_recommended, 
  recommended_weight, 
  recommended_duration_seconds
FROM doctors
WHERE is_recommended = TRUE 
AND is_published = TRUE
ORDER BY recommended_weight DESC;
```

### تفعيل 5 أطباء عشوائيين كتجربة:
```sql
UPDATE doctors
SET 
  is_recommended = TRUE,
  recommended_weight = floor(random() * 5 + 1)::int, -- عشوائي 1-5
  recommended_duration_seconds = floor(random() * 6 + 4)::int, -- عشوائي 4-9
  updated_at = NOW()
WHERE is_published = TRUE
AND id IN (
  SELECT id FROM doctors 
  WHERE is_published = TRUE 
  ORDER BY RANDOM() 
  LIMIT 5
);
```

### إلغاء تفعيل جميع الأطباء الموصى بهم:
```sql
UPDATE doctors
SET is_recommended = FALSE, updated_at = NOW()
WHERE is_recommended = TRUE;
```

## ملاحظات مهمة

1. **فقط الأطباء المنشورين** يمكن إضافتهم للقائمة الموصى بها
2. **الوزن الافتراضي** = 1 (ظهور مرة واحدة في الدورة)
3. **المدة الافتراضية** = 3 ثواني
4. **التحديثات الفورية** تعمل تلقائياً عبر Supabase Realtime
5. إذا لم يوجد أطباء موصى بهم، سيظهر **شريط فارغ** أو **رسالة تنبيه** (حسب التصميم)

## الصيانة المستقبلية

### إضافة إحصائيات (اختياري):
يمكن إضافة جدول لتتبع عدد المشاهدات والنقرات:
```sql
CREATE TABLE recommended_doctor_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id UUID REFERENCES doctors(id) ON DELETE CASCADE,
  views_count INTEGER DEFAULT 0,
  clicks_count INTEGER DEFAULT 0,
  last_viewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### تحسينات محتملة:
- إضافة أيقونة نجمة ⭐ بجانب الأطباء الموصى بهم في قائمة المدير
- تصدير تقرير بالأطباء الموصى بهم وأوزانهم
- جدولة تلقائية (مثلاً: تفعيل أطباء معينين في أيام محددة)

---

**تاريخ الإنشاء**: 11 فبراير 2026  
**الإصدار**: 1.0  
**المطور**: Fayoum Doctors List Team
