const fs = require('fs');
const file = 'src/pages/student/StudentDashboard.tsx';
let c = fs.readFileSync(file, 'utf8');

const replacements = [
  ['Consolidated Enrollment', 'التسجيل الموحد'],
  ['• Group ${(profile as any).group.name}', '• مجموعة ${(profile as any).group.name}'],
  ['Academic Lead', 'المدرب'],
  ['with ${(profile as any).instructor.name}', 'مع ${(profile as any).instructor.name}'],
  ['No Instructor Assigned', 'لم يُعيَّن مدرب'],
  ['Level Progress', 'تقدم المستوى'],
  ['total milestones', 'إجمالي الإنجازات'],
  ['Attendance Tracking', 'تتبع الحضور'],
  ['/ 8 Attended', '/ 8 حضور'],
  ['Your latest exam is under review — final score will appear when writing sections are graded.', 'اختبارك الأخير قيد المراجعة — ستظهر الدرجة النهائية بعد تصحيح أجزاء الكتابة.'],
  ["'Attendance'</p>", "'حضور'</p>"],
  ["'Tasks'</p>", "'واجبات'</p>"],
  ["'Exams'</p>", "'اختبارات'</p>"],
  ['View Materials', 'عرض المواد'],
  ['>Completed<', '>مكتمل<'],
  ['No Level Assigned - no instructor yet.', 'لا مستوى - لا مدرب بعد.'],
];

for (const [old, neo] of replacements) {
  c = c.split(old).join(neo);
}

fs.writeFileSync(file, c, 'utf8');
console.log('Done — replaced', replacements.length, 'strings');
