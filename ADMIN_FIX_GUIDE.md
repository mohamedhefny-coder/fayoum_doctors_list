# دليل إصلاح مشكلة إضافة الأطباء من لوحة المدير

## ⚠️ المشكلة
عند محاولة المدير إضافة طبيب جديد، تفشل العملية.

## 🔍 السبب
المشكلة تحدث لأن Supabase يتطلب تأكيد البريد الإلكتروني للحسابات الجديدة بشكل افتراضي.

## ✅ الحلول

### الحل الأول: تعطيل تأكيد البريد الإلكتروني (موصى به للتطوير)

1. افتح **Supabase Dashboard**
2. اذهب إلى **Authentication** > **Settings**
3. ابحث عن **Email Confirmation**
4. قم بتعطيل الخيار **Enable email confirmations**

⚠️ **ملاحظة**: هذا الحل مناسب للتطوير والتجربة، لكن في الإنتاج يفضل استخدام الحل الثاني.

---

### الحل الثاني: استخدام Supabase Admin API (الأفضل للإنتاج)

تحتاج لإنشاء **Edge Function** في Supabase لإنشاء المستخدمين باستخدام Admin API.

#### خطوات الإعداد:

1. **إنشاء Edge Function جديدة**:
   ```bash
   supabase functions new create-doctor
   ```

2. **كود Edge Function** (`supabase/functions/create-doctor/index.ts`):
   ```typescript
   import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

   serve(async (req) => {
     try {
       // التحقق من أن المستخدم مدير
       const authHeader = req.headers.get('Authorization')!
       const supabaseClient = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_ANON_KEY') ?? '',
         { global: { headers: { Authorization: authHeader } } }
       )

       const { data: { user } } = await supabaseClient.auth.getUser()
       
       if (!user) {
         return new Response(JSON.stringify({ error: 'Unauthorized' }), {
           status: 401,
         })
       }

       // التحقق من أن المستخدم في جدول admins
       const { data: admin } = await supabaseClient
         .from('admins')
         .select('id')
         .eq('id', user.id)
         .single()

       if (!admin) {
         return new Response(JSON.stringify({ error: 'Not an admin' }), {
           status: 403,
         })
       }

       // قراءة البيانات من الطلب
       const { email, password, fullName, specialization, phone, licenseNumber } = await req.json()

       // إنشاء المستخدم باستخدام Admin API
       const supabaseAdmin = createClient(
         Deno.env.get('SUPABASE_URL') ?? '',
         Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
       )

       const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
         email: email,
         password: password,
         email_confirm: true, // تأكيد البريد تلقائياً
       })

       if (createError) {
         throw createError
       }

       // إضافة بيانات الطبيب
       const { error: insertError } = await supabaseAdmin
         .from('doctors')
         .insert({
           id: newUser.user.id,
           email: email,
           full_name: fullName,
           specialization: specialization,
           phone: phone,
           license_number: licenseNumber,
         })

       if (insertError) {
         // حذف المستخدم في حالة الفشل
         await supabaseAdmin.auth.admin.deleteUser(newUser.user.id)
         throw insertError
       }

       return new Response(
         JSON.stringify({ success: true, userId: newUser.user.id, email: email }),
         { headers: { "Content-Type": "application/json" } }
       )

     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { status: 400, headers: { "Content-Type": "application/json" } }
       )
     }
   })
   ```

3. **رفع Edge Function إلى Supabase**:
   ```bash
   supabase functions deploy create-doctor
   ```

4. **تعديل AdminService في Flutter**:
   ```dart
   Future<Map<String, dynamic>> createDoctorAccount({
     required String email,
     required String password,
     required String fullName,
     required String specialization,
     required String phone,
     required String licenseNumber,
   }) async {
     try {
       final response = await _supabase.functions.invoke(
         'create-doctor',
         body: {
           'email': email,
           'password': password,
           'fullName': fullName,
           'specialization': specialization,
           'phone': phone,
           'licenseNumber': licenseNumber,
         },
       );

       if (response.data == null || response.data['error'] != null) {
         throw Exception(response.data['error'] ?? 'فشل إنشاء الحساب');
       }

       return response.data;
     } catch (e) {
       throw Exception('فشل إنشاء حساب الطبيب: ${e.toString()}');
     }
   }
   ```

---

### الحل الثالث: حل مؤقت - تأكيد البريد يدوياً

إذا كنت تريد حل سريع ومؤقت:

1. بعد إنشاء الحساب، اذهب إلى **Supabase Dashboard**
2. **Authentication** > **Users**
3. ابحث عن المستخدم الجديد
4. انقر على الثلاث نقاط (...) بجانب اسمه
5. اختر **Send confirmation email** أو **Confirm email**

---

## 🎯 التوصية

- **للتطوير والتجربة**: استخدم الحل الأول (تعطيل Email Confirmation)
- **للإنتاج**: استخدم الحل الثاني (Edge Function مع Admin API)

---

## 🐛 تشخيص المشكلة

إذا كنت لا تزال تواجه مشاكل، افحص:

1. **رسالة الخطأ في التطبيق**: ماذا تقول بالضبط؟
2. **Logs في Supabase**:
   - اذهب إلى **Logs** في Dashboard
   - افحص **Auth Logs** و **Postgres Logs**
3. **RLS Policies**: تأكد من أن السياسات تسمح للمدير بالإضافة في جدول `doctors`

---

## 📝 ملاحظات إضافية

- تأكد من أن جدول `doctors` يحتوي على RLS Policy تسمح بالإضافة
- تأكد من أن المدير مسجل دخول بشكل صحيح
- تحقق من أن البريد الإلكتروني المدخل ليس مستخدماً من قبل
