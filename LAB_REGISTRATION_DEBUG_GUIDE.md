# دليل تشخيص مشكلة تسجيل المعامل

## المشكلة
المعامل لا تظهر في جدول Supabase بعد التسجيل.

## خطوات التشخيص

### 1. تشغيل التطبيق مع Logging
تم إضافة سجلات تفصيلية (logging) في الكود لتتبع تدفق البيانات:

```bash
flutter run
```

### 2. مراقبة Console أثناء إضافة معمل
عند الضغط على "إضافة معمل" من صفحة المدير، ستظهر الرسائل التالية في console:

#### أ) من صفحة المدير:
```
👨‍💼 Admin: Opening lab registration...
```

#### ب) من صفحة تسجيل المعمل:
```
🏥 Starting registration from LabRegisterScreen...
```

#### ج) من LabService - registerLab():
```
📝 Starting lab registration...
📝 Lab name: [اسم المعمل], Email: [البريد]
📝 Auth response: [معرف المستخدم]
📝 Inserting lab data: {user_id: ..., name: ..., email: ..., is_published: false}
✅ Lab record created successfully!
```
أو في حالة الخطأ:
```
❌ Error inserting lab: [رسالة الخطأ]
❌ Auth exception: [رسالة الخطأ]
```

#### د) العودة لصفحة المدير:
```
🏥 Registration result: {success: true, message: ..., user: ...}
🏥 Returning true to open AddLabScreen...
👨‍💼 Admin: Lab registration result: true
👨‍💼 Admin: Opening AddLabScreen...
```

#### هـ) من صفحة إدخال البيانات:
```
💾 Saving lab data...
💾 Name: [اسم المعمل]
💾 Features: [قائمة المميزات]
💾 Tests: {تحاليل روتينية: [...], تحاليل متخصصة: [...]}
```

#### و) من LabService - upsertLabData():
```
🔍 Current user: [معرف المستخدم]
🔍 User email: [البريد]
🔍 Existing lab: {id: ..., name: ..., ...} أو null
📝 Updating existing lab... أو 📝 Inserting new lab...
✅ Lab updated successfully! أو ✅ Lab inserted successfully!
```

### 3. تحليل المشاكل المحتملة

#### المشكلة 1: لا يتم فتح صفحة AddLabScreen
**الأعراض:**
- ترى رسائل Admin و LabRegisterScreen
- لا ترى رسالة "Opening AddLabScreen"

**الحل:**
- تأكد من أن التسجيل نجح (result == true)
- تحقق من أن mounted == true

#### المشكلة 2: المستخدم غير مسجل دخول في AddLabScreen
**الأعراض:**
- رسالة: `❌ Error in upsertLabData: Exception: يجب تسجيل الدخول أولاً`
- Current user: null

**السبب:**
عند تسجيل حساب جديد من صفحة المدير، يتم تسجيل دخول المعمل تلقائياً (signUp يفعل ذلك)، لكن هذا يطرد جلسة المدير.

**الحل المقترح:**
استخدام Admin API لإنشاء المستخدمين بدون تسجيل دخول تلقائي.

#### المشكلة 3: خطأ في RLS Policy
**الأعراض:**
- رسالة: `❌ Error inserting lab: [policy violation]`

**الحل:**
تحقق من أن RLS policies في Supabase تسمح بالإدخال:
```sql
-- تحقق من الـ policies
SELECT * FROM pg_policies WHERE tablename = 'labs';
```

يجب أن يكون هناك policy:
```sql
CREATE POLICY "Lab owners can insert their own labs"
  ON labs FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

#### المشكلة 4: البيانات موجودة لكن غير مرئية
**الأعراض:**
- الرسائل تشير إلى نجاح العملية
- لكن لا تظهر في Supabase Dashboard

**السبب:**
قد تكون البيانات موجودة لكن RLS يمنع المدير من رؤيتها.

**الحل:**
- افتح Supabase Dashboard
- اذهب إلى Table Editor → labs
- انقر على "Turn off RLS" مؤقتاً للتحقق من البيانات
- أو استخدم SQL Editor:
```sql
-- عرض جميع المعامل (يتطلب صلاحيات admin)
SELECT * FROM labs;
```

### 4. الحل النهائي المقترح

#### خيار 1: استخدام Admin API (موصى به)
تعديل `registerLab()` لاستخدام Admin API:

```dart
Future<Map<String, dynamic>> registerLab({
  required String labName,
  required String email,
  required String password,
}) async {
  try {
    // استخدام Admin API لإنشاء المستخدم بدون تسجيل دخول
    final response = await _supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
        userMetadata: {'user_type': 'lab', 'lab_name': labName},
      ),
    );

    if (response.user == null) {
      throw Exception('فشل إنشاء الحساب');
    }

    // إنشاء سجل المعمل
    final labData = {
      'user_id': response.user!.id,
      'name': labName,
      'email': email,
      'is_published': false,
    };

    await _supabase.from('labs').insert(labData);

    return {
      'success': true,
      'message': 'تم إنشاء حساب المعمل بنجاح',
      'user': response.user,
    };
  } catch (e) {
    throw Exception('حدث خطأ: $e');
  }
}
```

**ملاحظة:** يتطلب هذا تمكين Service Role Key في Supabase.

#### خيار 2: إعادة تسجيل دخول المدير
بعد إنشاء حساب المعمل، إعادة تسجيل دخول المدير:

```dart
Future<void> _handleAddLab() async {
  // حفظ بيانات المدير
  final adminEmail = _adminService.getCurrentUser()?.email;
  final adminPassword = /* احفظها مؤقتاً */;

  final result = await Navigator.push(...LabRegisterScreen);
  
  if (result == true) {
    // إعادة تسجيل دخول المدير
    await _adminService.signOut();
    await _adminService.signInWithPassword(adminEmail, adminPassword);
    
    // ثم تسجيل دخول المعمل
    // ... إلخ
  }
}
```

#### خيار 3: تعطيل RLS مؤقتاً (للاختبار فقط)
```sql
ALTER TABLE labs DISABLE ROW LEVEL SECURITY;
```

⚠️ **تحذير:** لا تستخدم هذا في الإنتاج!

### 5. التحقق من نجاح العملية

بعد تطبيق الحل، تحقق من:

1. **في Console:**
   - جميع الرسائل تظهر بدون أخطاء
   - ترى "✅ Lab record created successfully"
   - ترى "✅ Lab updated successfully"

2. **في Supabase Dashboard:**
   - افتح Table Editor → labs
   - تأكد من ظهور السجل الجديد
   - تحقق من أن جميع الحقول محفوظة بشكل صحيح

3. **في التطبيق:**
   - اذهب إلى صفحة المعامل
   - يجب أن يظهر المعمل الجديد (إذا كان is_published = true)

## الخلاصة

المشكلة الرئيسية على الأرجح هي أن `signUp` يسجل دخول المستخدم الجديد تلقائياً، مما يطرد جلسة المدير. الحل الأمثل هو استخدام Admin API لإنشاء المستخدمين بدون تسجيل دخول تلقائي.

استخدم الـ logging المضاف لتحديد أين بالضبط تفشل العملية، ثم طبق الحل المناسب.
