# إصلاح مشكلة توقف التطبيق عند الإجابة على الأسئلة

## المشكلة
عند محاولة الطبيب الإجابة على سؤال والضغط على "حفظ"، يتوقف التطبيق عن العمل.

## السبب
سياسات Row Level Security (RLS) في جدول `doctor_questions` لا تسمح للطبيب بتحديث الأسئلة لأن:
- السياسات تتحقق من `doctor_id = auth.uid()`
- لكن في بعض الحالات `doctors.id` لا يساوي `auth.uid()` مباشرة
- بدلاً من ذلك، يجب المطابقة بناءً على البريد الإلكتروني

## الحل

### الخطوة 1: تنفيذ جدول الأسئلة (إذا لم يتم بعد)
افتح Supabase Dashboard → SQL Editor وقم بتنفيذ:
```
add_doctor_questions_table.sql
```

### الخطوة 2: تحديث سياسات RLS ⚠️ **مهم جداً**
افتح Supabase Dashboard → SQL Editor وقم بتنفيذ:
```
fix_doctor_questions_rls.sql
```

هذا الملف سيقوم بـ:
- حذف السياسات القديمة
- إنشاء سياسات جديدة تعمل بطريقتين:
  1. إذا كان `doctors.id == auth.uid()` (الحالة المثالية)
  2. أو إذا كان الطبيب مسجل دخول بحساب له نفس الإيميل في جدول doctors

### الخطوة 3: التحقق من الإصلاح
1. أعد تشغيل التطبيق
2. سجل دخول كطبيب
3. انتقل إلى الملف الشخصي → قسم الأسئلة والاستفسارات
4. حاول الإجابة على سؤال
5. يجب أن يعمل الحفظ بدون توقف

## ملاحظات إضافية

### إذا استمرت المشكلة:
1. تأكد من أن الطبيب مسجل دخول (auth.uid() موجود)
2. تحقق من أن جدول `doctors` يحتوي على صف للطبيب
3. تأكد من تطابق البريد الإلكتروني بين `auth.users` و `doctors.email`

### تنظيف البيانات القديمة (اختياري):
إذا كنت قد أنشأت جدول `doctor_questions` بالسياسات القديمة، نفذ:
```sql
-- حذف السياسات القديمة فقط
DROP POLICY IF EXISTS "Doctors can see all their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can update their questions" ON public.doctor_questions;
DROP POLICY IF EXISTS "Doctors can delete their questions" ON public.doctor_questions;
```
ثم نفذ `fix_doctor_questions_rls.sql`.

## التحديثات على الكود
تم تحديث الكود التالي لمعالجة الأخطاء بشكل أفضل:

### في `doctor_database_service.dart`:
- ✅ إضافة try-catch blocks لجميع دوال Questions
- ✅ إضافة `.select()` في `answerQuestion()` للتحقق من النجاح
- ✅ رسائل خطأ واضحة باللغة العربية

### في `doctor_profile_screen.dart`:
- ✅ معالجة الأخطاء في `_answerQuestion`
- ✅ عرض رسائل واضحة للمستخدم
- ✅ عدم السماح بحفظ إجابات فارغة

## الملفات المعدلة
1. `lib/services/doctor_database_service.dart` - إضافة معالجة أخطاء
2. `add_doctor_questions_table.sql` - تحديث السياسات
3. `fix_doctor_questions_rls.sql` - **جديد** - إصلاح السياسات
