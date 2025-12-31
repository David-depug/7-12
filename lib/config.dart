// إعدادات SMTP و Pepper
// ملاحظة: يجب تكوين SMTP لإرسال رسائل OTP عبر البريد
// لجيميل:
// 1. قم بتمكين الوصول عبر IMAP/POP
// 2. استخدم App Password بدلاً من كلمة المرور العادية
// 3. قم بزيارة https://myaccount.google.com/apppasswords
// 4. أنشئ App Password لبريدك وادخله في SMTP_PASSWORD
//
// خطوات تكوين البريد:
// 1. قم بتمكين IMAP في إعدادات Gmail:
//    - انتقل إلى Gmail > الإعدادات > ت_FORWARDING and POP/IMAP
//    - حدد "Enable IMAP"
// 2. إنشاء App Password:
//    - انتقل إلى https://myaccount.google.com/apppasswords
//    - اختر "Mail" و"Other (Custom name)"
//    - أدخل "MindQuest" واضغط "Generate"
//    - انسخ الـ 16 حرف وأدخلها في SMTP_PASSWORD
// 3. تأكد من أن FROM_EMAIL وSMTP_USERNAME متماثلين
//
// ملاحظات إضافية:
// - استخدم بريدك الفعلي في SMTP_USERNAME وFROM_EMAIL
// - استخدم App Password (16 حرف) في SMTP_PASSWORD، وليس كلمة المرور العادية
// - إذا كنت تستخدم مزود بريد آخر، قم بتحديث SMTP_HOST وSMTP_PORT حسب الحاجة
//
// لاختبار الإعدادات:
// - استخدم بريدك الفعلي في SMTP_USERNAME وFROM_EMAIL
// - استخدم App Password (16 حرف) في SMTP_PASSWORD
// - تأكد من أن SMTP_HOST هو 'smtp.gmail.com' لجيميل
// - تأكد من أن SMTP_PORT هو 587 لـ TLS

const String SMTP_HOST = 'smtp.gmail.com';
const int SMTP_PORT = 587;
const String SMTP_USERNAME =
    ''; // أضف اسم المستخدم هنا (مثل: example@gmail.com)
const String SMTP_PASSWORD =
    ''; // استخدم App Password (16 حرف) وليس كلمة المرور العادية
const String FROM_EMAIL =
    ''; // نفس البريد المستخدم للإرسال (مثل: example@gmail.com)
const String FROM_NAME = 'MindQuest Security'; // الاسم الذي يظهر للمستلم

// Pepper ثابت لتشفير الباسورد
const String PASSWORD_PEPPER = 'D9f#7kLp2@wVx8qZrT1mY!uB4sE0jHcN';
