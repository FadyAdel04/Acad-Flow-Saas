import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import {
  Users, BookOpen, ClipboardList, Award, Bell, BarChart3,
  CheckCircle, ArrowLeft, Zap, Shield, Settings, ChevronLeft,
  GraduationCap, Briefcase, Building2, Cpu, Loader2,
} from 'lucide-react';
import TopNavBar from '../../components/layout/TopNavBar';
import Footer from '../../components/layout/Footer';
import logo from '../../assets/logo.jpg';
import background from '../../assets/background.jpg';
import { useAuth } from '../../context/AuthContext';

// ─── Animation Variants ──────────────────────────────────────────────────────

const fadeUp = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.7 } },
};

const stagger = {
  hidden: {},
  visible: { transition: { staggerChildren: 0.1 } },
};

// ─── Demo Accounts ────────────────────────────────────────────────────────────

const DEMO_ACCOUNTS = [
  {
    role: 'student' as const,
    emoji: '👨‍🎓',
    label: 'تجربة الطالب',
    desc: 'الكورسات، الواجبات، الامتحانات، النتائج',
    email: 'student.demo@leidenschaft.com',
    password: 'Demo12345!',
    path: '/student',
    color: '#C62828',
  },
  {
    role: 'instructor' as const,
    emoji: '👨‍🏫',
    label: 'تجربة المدرس',
    desc: 'المجموعات، التصحيح، الحضور، متابعة الأداء',
    email: 'instructor.demo@leidenschaft.com',
    password: 'Demo12345!',
    path: '/instructor',
    color: '#1A1A1A',
  },
  {
    role: 'secretary' as const,
    emoji: '👩‍💼',
    label: 'تجربة السكرتارية',
    desc: 'تسجيل الطلاب، الحضور، إدارة المجموعات',
    email: 'secretary.demo@leidenschaft.com',
    password: 'Demo12345!',
    path: '/secretary/attendance',
    color: '#D4A373',
  },
  {
    role: 'admin' as const,
    emoji: '👨‍💼',
    label: 'تجربة الإدارة',
    desc: 'الطلاب، المدرسين، الكورسات، التقارير، الصلاحيات',
    email: 'admin.demo@leidenschaft.com',
    password: 'Demo12345!',
    path: '/admin',
    color: '#C62828',
  },
];

// ─── Features Data ────────────────────────────────────────────────────────────

const FEATURES = [
  { icon: Users, label: 'إدارة الطلاب', desc: 'تسجيل، متابعة، وإدارة بيانات الطلاب بالكامل' },
  { icon: GraduationCap, label: 'إدارة المدرسين', desc: 'الصلاحيات، المجموعات، ومتابعة أداء المدرسين' },
  { icon: BookOpen, label: 'إدارة الكورسات والمستويات', desc: 'هرمية مرنة من البرامج والمستويات والمجموعات' },
  { icon: ClipboardList, label: 'المحتوى والمواد التعليمية', desc: 'ملفات، فيديوهات، وتسجيلات صوتية منظمة' },
  { icon: Briefcase, label: 'الواجبات والتسليمات', desc: 'إرسال، تتبع، وتصحيح واجبات الطلاب' },
  { icon: Award, label: 'الامتحانات المتقدمة', desc: 'MCQ، كتابة، قراءة، وأسئلة الاستماع' },
  { icon: CheckCircle, label: 'التصحيح التلقائي واليدوي', desc: 'درجات فورية للأسئلة الموضوعية، تصحيح يدوي للمقالي' },
  { icon: Users, label: 'الحضور والغياب', desc: 'تسجيل، تقارير، وتنبيهات الحضور لكل مجموعة' },
  { icon: BarChart3, label: 'النتائج والتقييمات', desc: 'تقارير شاملة لأداء الطلاب والمجموعات' },
  { icon: Bell, label: 'الإشعارات الفورية', desc: 'Real-time notifications للطلاب والمدرسين' },
  { icon: Zap, label: 'الفعاليات والأحداث', desc: 'جدولة الفعاليات والحجز والمتابعة' },
  { icon: Shield, label: 'إدارة الصلاحيات', desc: 'نظام أدوار مرن: طالب، مدرس، سكرتارية، إدارة' },
  { icon: Settings, label: 'تخصيص كامل', desc: 'كل جزء من النظام يُبنى حسب احتياجاتك' },
  { icon: Cpu, label: 'نظام Real-time', desc: 'تحديثات فورية بدون تحديث الصفحة' },
];

// ─── Roles Data ───────────────────────────────────────────────────────────────

const ROLES = [
  {
    icon: '👨‍🎓',
    title: 'لوحة تحكم الطالب',
    color: '#C62828',
    items: ['الكورسات والمحتوى', 'الواجبات والتسليمات', 'الامتحانات والنتائج', 'سجل الحضور', 'الإشعارات', 'الملف الشخصي'],
  },
  {
    icon: '👨‍🏫',
    title: 'لوحة تحكم المدرس',
    color: '#1A1A1A',
    items: ['مجموعاتي وطلابي', 'رفع المحتوى والواجبات', 'تصحيح الإجابات', 'تسجيل الحضور', 'إنشاء الامتحانات', 'متابعة الأداء'],
  },
  {
    icon: '👩‍💼',
    title: 'لوحة التحكم الإدارية',
    color: '#D4A373',
    items: ['تسجيل الطلاب الجدد', 'إدارة المجموعات', 'متابعة الحضور', 'توزيع المحتوى', 'إدارة الطلاب', 'المتابعة اليومية'],
  },
  {
    icon: '👨‍💼',
    title: 'لوحة تحكم الإدارة',
    color: '#C62828',
    items: ['إدارة الطلاب والمدرسين', 'الكورسات والمستويات', 'المحتوى والامتحانات', 'التقارير الكاملة', 'الإشعارات والإعلانات', 'الصلاحيات والإعدادات'],
  },
];

// ─── Pricing Data ────────────────────────────────────────────────────────────

const PRICING = [
  {
    name: 'باقة البداية',
    price: 'ابدأ من',
    highlight: false,
    features: [
      'إدارة الطلاب والمدرسين',
      'الكورسات والمجموعات',
      'المحتوى التعليمي',
      'الواجبات والتسليمات',
      'الحضور والغياب',
      'الإشعارات الأساسية',
    ],
    cta: 'تواصل معنا',
  },
  {
    name: 'الباقة المتقدمة',
    price: 'ابدأ من',
    highlight: true,
    features: [
      'كل مميزات باقة البداية',
      'الامتحانات المتعددة الأنواع',
      'التصحيح التلقائي واليدوي',
      'التقارير التفصيلية',
      'الفعاليات والحجوزات',
      'نظام Real-time كامل',
    ],
    cta: 'تواصل معنا',
  },
  {
    name: 'نظام مخصص',
    price: 'اتصل بنا',
    highlight: false,
    features: [
      'كل المميزات بدون حدود',
      'تصميم وهوية بصرية مخصصة',
      'Integrations مخصصة',
      'Features إضافية حسب طلبك',
      'دعم فني مستمر',
      'قابلية توسع كاملة',
    ],
    cta: 'اطلب نظامك',
  },
];

// ─── Component ────────────────────────────────────────────────────────────────

export default function LandingPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [demoLoading, setDemoLoading] = useState<string | null>(null);

  // If already logged in, redirect to the correct dashboard
  useEffect(() => {
    if (user) {
      if (user.role === 'admin') navigate('/admin');
      else if (user.role === 'instructor') navigate('/instructor');
      else if (user.role === 'secretary') navigate('/secretary/attendance');
      else navigate('/student');
    }
  }, [user]);

  const scrollTo = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      const offset = 80;
      const top = el.getBoundingClientRect().top + window.scrollY - offset;
      window.scrollTo({ top, behavior: 'smooth' });
    }
  };

  // Navigate to /login with the demo credentials pre-filled — no direct Supabase call here
  const handleDemoLogin = (account: typeof DEMO_ACCOUNTS[0]) => {
    setDemoLoading(account.role);
    navigate('/login', {
      state: {
        demoEmail: account.email,
        demoPassword: account.password,
        demoRole: account.role,
      },
    });
  };

  return (
    <div className="min-h-screen bg-[#F5F5F0] text-[#1A1A1A] overflow-x-hidden" dir="rtl" lang="ar">
      <TopNavBar />

      <main>

        {/* ══════════════════════════════════════════════════════════
            HERO
        ══════════════════════════════════════════════════════════ */}
        <section id="hero" className="relative pt-20 sm:pt-24 md:pt-32 min-h-screen flex flex-col items-center justify-center px-4 sm:px-6 md:px-8 overflow-hidden bg-white">
          {/* Background */}
          <div className="absolute inset-0 z-0">
            <motion.div
              initial={{ scale: 1.1 }}
              animate={{ scale: 1 }}
              transition={{ duration: 1.5 }}
              className="absolute inset-0 bg-cover bg-center opacity-100"
              style={{ backgroundImage: `url(${background})` }}
            />
            <div className="absolute inset-0 bg-gradient-to-br from-white via-white/70 to-[#F5F5F0]/90" />
            {[...Array(8)].map((_, i) => (
              <motion.div
                key={i}
                initial={{ x: `${(i / 8) * 100}%`, y: `${(i % 5) * 20}%`, scale: 0.4 }}
                animate={{ y: [null, -30, 30, -30], x: [null, 20, -20, 20] }}
                transition={{ duration: 20 + i * 2, repeat: Infinity, ease: 'easeInOut' }}
                className="absolute w-1 h-1 bg-[#C62828]/30 rounded-full"
              />
            ))}
            <div className="absolute top-[10%] right-[5%] w-[20rem] md:w-[40rem] h-80 md:h-[40rem] bg-[#C62828]/5 rounded-full blur-[120px] animate-pulse" />
            <div className="absolute bottom-[10%] left-[5%] w-[20rem] md:w-[40rem] h-80 md:h-[40rem] bg-[#D4A373]/10 rounded-full blur-[120px] animate-pulse delay-1000" />
          </div>

          {/* Content */}
          <motion.div
            initial="hidden"
            animate="visible"
            variants={stagger}
            className="z-10 text-center max-w-5xl w-full"
          >
            {/* Badge */}
            <motion.div variants={fadeUp} className="inline-flex items-center gap-2 bg-[#C62828]/10 border border-[#C62828]/20 px-4 py-2 rounded-full mb-6 sm:mb-8">
              <span className="w-2 h-2 bg-[#C62828] rounded-full animate-pulse" />
              <span className="text-[#C62828] font-black text-xs tracking-widest uppercase">النسخة التجريبية متاحة الآن</span>
            </motion.div>

            {/* Logo */}
            <motion.div
              variants={fadeUp}
              className="inline-block mb-4"
            >
              <img
                alt="AcadFlow Logo"
                className="mx-auto hover:rotate-12 transition-transform duration-500"
                src={logo}
                width={64}
                height={64}
                fetchPriority="high"
              />
            </motion.div>

            {/* Headline */}
            <motion.h1
              variants={fadeUp}
              className="text-3xl sm:text-4xl md:text-6xl lg:text-7xl font-black text-[#1A1A1A] tracking-tight leading-tight mb-4 sm:mb-6 md:mb-8"
              style={{ fontFamily: 'Cairo, sans-serif' }}
            >
              نظام إدارة تعليمي متكامل <br className="hidden sm:block" />
              <span className="text-[#C62828]">مصمم لأكاديميتك</span>
            </motion.h1>

            {/* Subheadline */}
            <motion.p
              variants={fadeUp}
              className="text-base sm:text-lg md:text-xl text-[#1A1A1A]/60 font-medium mb-4 max-w-3xl mx-auto px-2 sm:px-4 leading-relaxed"
              style={{ fontFamily: 'Cairo, sans-serif' }}
            >
              نصمم لك نظام LMS مخصص لإدارة الطلاب، المدرسين، الكورسات، المحتوى، الحضور، الواجبات والامتحانات — بما يناسب طريقة عمل مؤسستك التعليمية.
            </motion.p>

            {/* Support msg */}
            <motion.p
              variants={fadeUp}
              className="text-sm text-[#1A1A1A]/40 font-medium mb-8 sm:mb-10 max-w-2xl mx-auto px-4"
              style={{ fontFamily: 'Cairo, sans-serif' }}
            >
              استكشف النظام بنفسك من خلال النسخة التجريبية، وشاهد كيف يمكن أن تتحول إدارة أكاديميتك إلى نظام رقمي متكامل.
            </motion.p>

            {/* CTAs */}
            <motion.div variants={fadeUp} className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center px-2 w-full max-w-md mx-auto sm:max-w-none">
              <button
                onClick={() => scrollTo('demo')}
                className="w-full sm:w-auto bg-[#C62828] text-white px-8 sm:px-12 py-4 sm:py-5 rounded-2xl font-black text-base sm:text-lg hover:shadow-[0_20px_40px_rgba(198,40,40,0.25)] hover:-translate-y-1 transition-all active:scale-95 shadow-xl shadow-[#C62828]/20"
                style={{ fontFamily: 'Cairo, sans-serif' }}
              >
                جرب النظام الآن
              </button>
              <button
                onClick={() => scrollTo('contact')}
                className="w-full sm:w-auto bg-white border-2 border-[#1A1A1A] text-[#1A1A1A] px-8 sm:px-12 py-4 sm:py-5 rounded-2xl font-black text-base sm:text-lg hover:bg-[#1A1A1A] hover:text-white transition-all active:scale-95"
                style={{ fontFamily: 'Cairo, sans-serif' }}
              >
                اطلب نظامك الخاص
              </button>
            </motion.div>

            {/* Clients pills */}
            <motion.div variants={fadeUp} className="mt-12 sm:mt-16 flex flex-wrap justify-center gap-3 px-4">
              {['أكاديميات اللغات', 'مراكز التدريب', 'المدارس والمعاهد', 'برامج التدريب المهني', 'الأكاديميات التقنية', 'التعليم الإلكتروني'].map((tag) => (
                <span key={tag} className="bg-white/80 border border-[#1A1A1A]/10 text-[#1A1A1A]/60 text-xs font-black px-4 py-2 rounded-full shadow-sm" style={{ fontFamily: 'Cairo, sans-serif' }}>
                  {tag}
                </span>
              ))}
            </motion.div>
          </motion.div>

          {/* Scroll hint */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.5 }}
            className="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2"
          >
            <span className="text-[10px] font-black text-[#1A1A1A]/30 uppercase tracking-widest" style={{ fontFamily: 'Cairo, sans-serif' }}>اكتشف المميزات</span>
            <motion.div animate={{ y: [0, 8, 0] }} transition={{ duration: 1.5, repeat: Infinity }} className="w-px h-8 bg-gradient-to-b from-[#C62828] to-transparent" />
          </motion.div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            WHAT IS THE LMS?
        ══════════════════════════════════════════════════════════ */}
        <section className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-[#F5F5F0]">
          <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-24 items-center">
            {/* Left: Problem */}
            <motion.div
              initial={{ opacity: 0, x: 50 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
            >
              <h4 className="text-[#D4A373] font-black uppercase tracking-[0.3em] text-xs md:text-sm mb-4 md:mb-6">المشكلة</h4>
              <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-[#1A1A1A] tracking-tight mb-8 leading-tight" style={{ fontFamily: 'Cairo, sans-serif' }}>
                الأكاديميات بتدير كل حاجة{' '}
                <span className="text-[#C62828]">من غير نظام</span>
              </h2>
              <div className="grid grid-cols-2 gap-3 sm:gap-4">
                {[
                  { icon: '📱', label: 'WhatsApp للتواصل' },
                  { icon: '📊', label: 'Excel لتتبع الطلاب' },
                  { icon: '📝', label: 'ورق للحضور' },
                  { icon: '📁', label: 'ملفات مبعثرة' },
                  { icon: '✏️', label: 'تصحيح يدوي' },
                  { icon: '🗂️', label: 'أدوات متفرقة' },
                ].map((item, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, scale: 0.9 }}
                    whileInView={{ opacity: 1, scale: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: i * 0.08 }}
                    className="flex items-center gap-3 bg-white p-3 sm:p-4 rounded-2xl border border-[#1A1A1A]/5 shadow-sm"
                  >
                    <span className="text-xl sm:text-2xl shrink-0">{item.icon}</span>
                    <span className="text-xs sm:text-sm font-black text-[#1A1A1A]/60" style={{ fontFamily: 'Cairo, sans-serif' }}>{item.label}</span>
                  </motion.div>
                ))}
              </div>
            </motion.div>

            {/* Right: Solution */}
            <motion.div
              initial={{ opacity: 0, x: -50 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
              className="relative"
            >
              <div className="bg-[#1A1A1A] p-8 sm:p-10 md:p-14 rounded-3xl sm:rounded-4xl text-white relative overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-full opacity-10">
                  <div className="absolute -top-1/2 -right-1/4 w-full h-full bg-[#C62828] rounded-full blur-[100px]" />
                </div>
                <div className="relative z-10">
                  <span className="text-4xl mb-6 block">🚀</span>
                  <h3 className="text-2xl sm:text-3xl font-black mb-6 leading-tight" style={{ fontFamily: 'Cairo, sans-serif' }}>
                    كل حاجة في مكان واحد
                  </h3>
                  <p className="text-white/60 text-base sm:text-lg leading-relaxed mb-8" style={{ fontFamily: 'Cairo, sans-serif' }}>
                    بدل ما تشغل أدوات كتير متفرقة، نبني لك نظام LMS واحد بيدير كل العمليات التعليمية والإدارية في أكاديميتك.
                  </p>
                  <div className="space-y-4">
                    {['طلابك في مكان واحد', 'محتواك منظم وسهل الوصول', 'امتحاناتك أونلاين', 'تقاريرك بضغطة زر', 'تواصلك فوري مع الطلاب'].map((item, i) => (
                      <div key={i} className="flex items-center gap-3">
                        <CheckCircle className="w-5 h-5 text-[#C62828] shrink-0" />
                        <span className="text-sm font-black text-white/70" style={{ fontFamily: 'Cairo, sans-serif' }}>{item}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Floating badge */}
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: 0.5 }}
                className="absolute -bottom-6 -left-6 bg-[#C62828] p-5 sm:p-6 rounded-2xl text-white shadow-2xl shadow-[#C62828]/30"
              >
                <div className="text-3xl sm:text-4xl font-black">100%</div>
                <div className="text-xs font-black uppercase tracking-widest opacity-80" style={{ fontFamily: 'Cairo, sans-serif' }}>مخصص لك</div>
              </motion.div>
            </motion.div>
          </div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            FEATURES
        ══════════════════════════════════════════════════════════ */}
        <section id="features" className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-white overflow-hidden">
          <div className="max-w-7xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-center mb-12 sm:mb-16 md:mb-24"
            >
              <h4 className="text-[#D4A373] font-black uppercase tracking-[0.3em] text-xs md:text-sm mb-4">ما بيقدمه النظام</h4>
              <h2 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight text-[#1A1A1A]" style={{ fontFamily: 'Cairo, sans-serif' }}>
                مميزات <span className="text-[#C62828]">متكاملة</span>
              </h2>
              <div className="h-2 w-20 sm:w-32 bg-[#C62828] mt-4 sm:mt-8 mx-auto rounded-full" />
              <p className="text-[#1A1A1A]/50 text-base sm:text-lg mt-6 max-w-2xl mx-auto" style={{ fontFamily: 'Cairo, sans-serif' }}>
                كل مميز ممكن يتخصص حسب احتياج مؤسستك. مش بيتسلم نظام جامد — بيتبنى حسب طريقة شغلك.
              </p>
            </motion.div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-6">
              {FEATURES.map((feature, idx) => {
                const Icon = feature.icon;
                return (
                  <motion.div
                    key={idx}
                    initial={{ opacity: 0, y: 30 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    transition={{ delay: idx * 0.04 }}
                    whileHover={{ y: -6, scale: 1.02 }}
                    className="bg-[#F5F5F0] p-5 sm:p-6 rounded-2xl sm:rounded-3xl border border-[#1A1A1A]/5 group cursor-default transition-all hover:shadow-xl hover:shadow-[#C62828]/10 hover:border-[#C62828]/20"
                  >
                    <div className="w-10 h-10 sm:w-12 sm:h-12 bg-white rounded-xl sm:rounded-2xl flex items-center justify-center mb-4 group-hover:bg-[#C62828] transition-colors shadow-sm">
                      <Icon className="w-5 h-5 sm:w-6 sm:h-6 text-[#C62828] group-hover:text-white transition-colors" />
                    </div>
                    <h3 className="font-black text-[#1A1A1A] text-sm sm:text-base mb-2 leading-tight" style={{ fontFamily: 'Cairo, sans-serif' }}>
                      {feature.label}
                    </h3>
                    <p className="text-xs sm:text-sm text-[#1A1A1A]/50 leading-relaxed" style={{ fontFamily: 'Cairo, sans-serif' }}>
                      {feature.desc}
                    </p>
                  </motion.div>
                );
              })}
            </div>
          </div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            ROLE-BASED WORKSPACES
        ══════════════════════════════════════════════════════════ */}
        <section id="roles" className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-[#1A1A1A] text-white relative overflow-hidden">
          <div className="absolute inset-0 opacity-5">
            <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-[#C62828] to-[#D4A373]" />
          </div>

          <div className="max-w-7xl mx-auto relative z-10">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-center mb-12 sm:mb-16"
            >
              <h4 className="text-[#D4A373] font-black uppercase tracking-[0.3em] text-xs md:text-sm mb-4">أدوار متخصصة</h4>
              <h2 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight" style={{ fontFamily: 'Cairo, sans-serif' }}>
                لوحة تحكم <span className="text-[#C62828]">لكل دور</span>
              </h2>
              <div className="h-2 w-20 sm:w-32 bg-[#C62828] mt-4 sm:mt-8 mx-auto rounded-full" />
              <p className="text-white/50 text-base sm:text-lg mt-6 max-w-2xl mx-auto" style={{ fontFamily: 'Cairo, sans-serif' }}>
                كل مستخدم بيشوف بس اللي محتاجه. نظام أدوار مرن يضمن الخصوصية والكفاءة.
              </p>
            </motion.div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
              {ROLES.map((role, idx) => (
                <motion.div
                  key={idx}
                  initial={{ opacity: 0, y: 50 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: idx * 0.1 }}
                  whileHover={{ y: -8 }}
                  className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl sm:rounded-3xl p-6 sm:p-8 hover:bg-white/10 transition-all group"
                >
                  <div className="text-4xl sm:text-5xl mb-4 sm:mb-6">{role.icon}</div>
                  <h3
                    className="text-lg sm:text-xl font-black mb-4 sm:mb-6 group-hover:text-[#D4A373] transition-colors"
                    style={{ fontFamily: 'Cairo, sans-serif', borderRight: `3px solid ${role.color}`, paddingRight: '12px' }}
                  >
                    {role.title}
                  </h3>
                  <ul className="space-y-2 sm:space-y-3">
                    {role.items.map((item, j) => (
                      <li key={j} className="flex items-center gap-2 text-white/60 text-sm">
                        <ChevronLeft className="w-3 h-3 shrink-0" style={{ color: role.color }} />
                        <span style={{ fontFamily: 'Cairo, sans-serif' }}>{item}</span>
                      </li>
                    ))}
                  </ul>
                </motion.div>
              ))}
            </div>
          </div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            LIVE DEMO
        ══════════════════════════════════════════════════════════ */}
        <section id="demo" className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-[#F5F5F0] overflow-hidden">
          <div className="max-w-7xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-center mb-12 sm:mb-16"
            >
              {/* Badge */}
              <div className="inline-flex items-center gap-2 bg-[#C62828]/10 border border-[#C62828]/20 px-4 py-2 rounded-full mb-6">
                <span className="w-2 h-2 bg-[#C62828] rounded-full animate-pulse" />
                <span className="text-[#C62828] font-black text-xs tracking-widest uppercase" style={{ fontFamily: 'Cairo, sans-serif' }}>النسخة التجريبية</span>
              </div>
              <h2 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight text-[#1A1A1A]" style={{ fontFamily: 'Cairo, sans-serif' }}>
                جرب النظام <span className="text-[#C62828]">بنفسك</span>
              </h2>
              <div className="h-2 w-20 sm:w-32 bg-[#C62828] mt-4 sm:mt-8 mx-auto rounded-full" />
              <p className="text-[#1A1A1A]/50 text-base sm:text-lg mt-6 max-w-2xl mx-auto" style={{ fontFamily: 'Cairo, sans-serif' }}>
                مش محتاج تتخيل شكل النظام — ادخل وجربه بنفسك. اختار الدور اللي تحب تشوفه.
              </p>
            </motion.div>




            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
              {DEMO_ACCOUNTS.map((account, idx) => (
                <motion.button
                  key={account.role}
                  initial={{ opacity: 0, y: 40 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: idx * 0.1 }}
                  whileHover={{ y: -8, scale: 1.02 }}
                  onClick={() => handleDemoLogin(account)}
                  disabled={demoLoading !== null}
                  className="group relative bg-white rounded-2xl sm:rounded-3xl p-6 sm:p-8 border border-[#1A1A1A]/5 shadow-sm hover:shadow-2xl hover:shadow-[#C62828]/15 hover:border-[#C62828]/30 transition-all text-right disabled:opacity-60 disabled:cursor-not-allowed overflow-hidden"
                >
                  {/* Hover BG */}
                  <div className="absolute inset-0 bg-gradient-to-br from-[#C62828]/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />

                  <div className="relative z-10">
                    <div className="text-4xl sm:text-5xl mb-4 group-hover:scale-110 transition-transform inline-block">{account.emoji}</div>
                    <h3 className="text-lg sm:text-xl font-black text-[#1A1A1A] mb-2 group-hover:text-[#C62828] transition-colors" style={{ fontFamily: 'Cairo, sans-serif' }}>
                      {account.label}
                    </h3>
                    <p className="text-xs sm:text-sm text-[#1A1A1A]/50 mb-6 leading-relaxed" style={{ fontFamily: 'Cairo, sans-serif' }}>
                      {account.desc}
                    </p>
                    <div className="flex items-center gap-2 text-[#C62828] font-black text-xs sm:text-sm group-hover:gap-3 transition-all">
                      {demoLoading === account.role ? (
                        <>
                          <Loader2 className="w-4 h-4 animate-spin" />
                          <span style={{ fontFamily: 'Cairo, sans-serif' }}>جاري الدخول...</span>
                        </>
                      ) : (
                        <>
                          <span style={{ fontFamily: 'Cairo, sans-serif' }}>ادخل الآن</span>
                          <ArrowLeft className="w-4 h-4" />
                        </>
                      )}
                    </div>
                  </div>
                </motion.button>
              ))}
            </div>

            {/* Demo disclaimer */}
            <motion.p
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              className="text-center text-xs text-[#1A1A1A]/30 mt-8 font-black"
              style={{ fontFamily: 'Cairo, sans-serif' }}
            >
              النسخة التجريبية تحتوي على بيانات تعليمية نموذجية. الدخول مجاني وآمن بدون الحاجة لتسجيل.
            </motion.p>
          </div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            HOW IT WORKS
        ══════════════════════════════════════════════════════════ */}
        <section className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-white overflow-hidden">
          <div className="max-w-5xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-center mb-12 sm:mb-20"
            >
              <h4 className="text-[#D4A373] font-black uppercase tracking-[0.3em] text-xs md:text-sm mb-4">خطوات بسيطة</h4>
              <h2 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight text-[#1A1A1A]" style={{ fontFamily: 'Cairo, sans-serif' }}>
                ازاي <span className="text-[#C62828]">بنشتغل</span>
              </h2>
              <div className="h-2 w-20 sm:w-32 bg-[#C62828] mt-4 sm:mt-8 mx-auto rounded-full" />
            </motion.div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 sm:gap-12 relative">
              {/* Connector line (desktop) */}
              <div className="hidden md:block absolute top-16 right-[16.7%] left-[16.7%] h-px bg-gradient-to-l from-[#C62828] via-[#D4A373] to-[#C62828] opacity-30" />

              {[
                { num: '01', title: 'جرب النظام', desc: 'استكشف الـ Demo وشاهد جميع لوحات التحكم والمميزات بنفسك بدون أي التزام.' },
                { num: '02', title: 'احكيلنا عن احتياجاتك', desc: 'ناقش معنا طريقة عمل الأكاديمية والخصائص التي تحتاجها لنظامك الخاص.' },
                { num: '03', title: 'نبني لك نظامك الخاص', desc: 'نطور LMS مخصص بهوية أكاديميتك، مميزاتها، وطريقة تشغيلها بالكامل.' },
              ].map((step, idx) => (
                <motion.div
                  key={idx}
                  initial={{ opacity: 0, y: 40 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: idx * 0.2 }}
                  className="text-center relative"
                >
                  <div className="w-16 h-16 sm:w-20 sm:h-20 bg-[#C62828] rounded-2xl sm:rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-xl shadow-[#C62828]/20">
                    <span className="text-2xl sm:text-3xl font-black text-white">{step.num}</span>
                  </div>
                  <h3 className="text-xl sm:text-2xl font-black text-[#1A1A1A] mb-4" style={{ fontFamily: 'Cairo, sans-serif' }}>{step.title}</h3>
                  <p className="text-[#1A1A1A]/50 text-sm sm:text-base leading-relaxed" style={{ fontFamily: 'Cairo, sans-serif' }}>{step.desc}</p>
                </motion.div>
              ))}
            </div>
          </div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            CUSTOMIZATION
        ══════════════════════════════════════════════════════════ */}
        <section className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-[#F5F5F0]">
          <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-24 items-center">
            <motion.div
              initial={{ opacity: 0, x: 50 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
            >
              <h4 className="text-[#D4A373] font-black uppercase tracking-[0.3em] text-xs md:text-sm mb-4 md:mb-6">تخصيص كامل</h4>
              <h2 className="text-3xl sm:text-4xl md:text-5xl font-black text-[#1A1A1A] tracking-tight mb-6 sm:mb-8 leading-tight" style={{ fontFamily: 'Cairo, sans-serif' }}>
                النظام بيتبني على{' '}
                <span className="text-[#C62828]">طريقة شغلك</span>
              </h2>
              <p className="text-[#1A1A1A]/60 text-base sm:text-lg leading-relaxed mb-8 sm:mb-10" style={{ fontFamily: 'Cairo, sans-serif' }}>
                مش بنقدم نظام واحد ثابت لكل الأكاديميات. بنبني النظام حسب احتياجات وطريقة تشغيل كل مؤسسة.
              </p>
              <button
                onClick={() => scrollTo('contact')}
                className="bg-[#C62828] text-white px-8 py-4 rounded-2xl font-black text-base sm:text-lg hover:shadow-[0_20px_40px_rgba(198,40,40,0.25)] hover:-translate-y-1 transition-all active:scale-95 shadow-xl shadow-[#C62828]/20"
                style={{ fontFamily: 'Cairo, sans-serif' }}
              >
                اطلب نظامك الخاص
              </button>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: -50 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
            >
              <div className="grid grid-cols-2 gap-3 sm:gap-4">
                {[
                  'اسم الأكاديمية', 'اللوجو والهوية', 'الكورسات والمستويات', 'المجموعات وأنواعها',
                  'نظام الحضور', 'نظام التقييم', 'أنواع الامتحانات', 'التقارير والبيانات',
                  'الإشعارات والتنبيهات', 'طرق التسجيل', 'العمليات الداخلية', 'Custom Integrations',
                ].map((item, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, scale: 0.9 }}
                    whileInView={{ opacity: 1, scale: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: i * 0.05 }}
                    className="flex items-center gap-3 bg-white p-3 sm:p-4 rounded-2xl border border-[#1A1A1A]/5 shadow-sm hover:border-[#C62828]/30 hover:shadow-md transition-all group"
                  >
                    <Settings className="w-4 h-4 text-[#C62828] shrink-0 group-hover:rotate-45 transition-transform" />
                    <span className="text-xs sm:text-sm font-black text-[#1A1A1A]/70" style={{ fontFamily: 'Cairo, sans-serif' }}>{item}</span>
                  </motion.div>
                ))}
              </div>
            </motion.div>
          </div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            PRICING
        ══════════════════════════════════════════════════════════ */}
        <section id="pricing" className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-white overflow-hidden">
          <div className="max-w-7xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-center mb-12 sm:mb-16 md:mb-24"
            >
              <h4 className="text-[#D4A373] font-black uppercase tracking-[0.3em] text-xs md:text-sm mb-4">باقات التطوير</h4>
              <h2 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight text-[#1A1A1A]" style={{ fontFamily: 'Cairo, sans-serif' }}>
                <span className="text-[#C62828]">باقات</span> التنفيذ
              </h2>
              <div className="h-2 w-20 sm:w-32 bg-[#C62828] mt-4 sm:mt-8 mx-auto rounded-full" />
              <p className="text-[#1A1A1A]/50 text-sm sm:text-base mt-6 max-w-2xl mx-auto" style={{ fontFamily: 'Cairo, sans-serif' }}>
                السعر النهائي بيعتمد على عدد المميزات، التخصيص، الـ Integrations، وعدد المستخدمين.
              </p>
            </motion.div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 sm:gap-8">
              {PRICING.map((plan, idx) => (
                <motion.div
                  key={idx}
                  initial={{ opacity: 0, y: 40 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: idx * 0.1 }}
                  whileHover={{ y: -8 }}
                  className={`relative rounded-3xl p-6 sm:p-8 border-2 transition-all ${plan.highlight
                    ? 'bg-[#1A1A1A] border-[#C62828] text-white shadow-2xl shadow-[#C62828]/20'
                    : 'bg-[#F5F5F0] border-[#1A1A1A]/10 text-[#1A1A1A] hover:border-[#C62828]/30 hover:shadow-xl'
                    }`}
                >
                  {plan.highlight && (
                    <div className="absolute -top-4 right-1/2 translate-x-1/2">
                      <span className="bg-[#C62828] text-white text-[10px] font-black px-4 py-1.5 rounded-full uppercase tracking-widest whitespace-nowrap" style={{ fontFamily: 'Cairo, sans-serif' }}>
                        الأكثر طلبًا
                      </span>
                    </div>
                  )}
                  <h3
                    className={`text-xl sm:text-2xl font-black mb-2 ${plan.highlight ? 'text-white' : 'text-[#1A1A1A]'}`}
                    style={{ fontFamily: 'Cairo, sans-serif' }}
                  >
                    {plan.name}
                  </h3>
                  <p
                    className={`text-3xl sm:text-4xl font-black mb-2 ${plan.highlight ? 'text-[#C62828]' : 'text-[#C62828]'}`}
                    style={{ fontFamily: 'Cairo, sans-serif' }}
                  >
                    {plan.price}
                  </p>
                  <p className={`text-xs font-black mb-6 ${plan.highlight ? 'text-white/40' : 'text-[#1A1A1A]/40'}`} style={{ fontFamily: 'Cairo, sans-serif' }}>
                    تواصل معنا لمعرفة السعر
                  </p>
                  <ul className="space-y-3 mb-8">
                    {plan.features.map((f, i) => (
                      <li key={i} className="flex items-center gap-3">
                        <CheckCircle className={`w-4 h-4 shrink-0 ${plan.highlight ? 'text-[#C62828]' : 'text-[#C62828]'}`} />
                        <span className={`text-sm font-black ${plan.highlight ? 'text-white/70' : 'text-[#1A1A1A]/70'}`} style={{ fontFamily: 'Cairo, sans-serif' }}>
                          {f}
                        </span>
                      </li>
                    ))}
                  </ul>
                  <button
                    onClick={() => scrollTo('contact')}
                    className={`w-full py-4 rounded-2xl font-black text-sm sm:text-base transition-all hover:-translate-y-0.5 active:scale-95 ${plan.highlight
                      ? 'bg-[#C62828] text-white shadow-xl shadow-[#C62828]/30 hover:shadow-2xl'
                      : 'bg-[#1A1A1A] text-white hover:bg-[#C62828] hover:shadow-xl hover:shadow-[#C62828]/20'
                      }`}
                    style={{ fontFamily: 'Cairo, sans-serif' }}
                  >
                    {plan.cta}
                  </button>
                </motion.div>
              ))}
            </div>

            {/* Note */}
            <motion.div
              initial={{ opacity: 0 }}
              whileInView={{ opacity: 1 }}
              viewport={{ once: true }}
              className="mt-10 sm:mt-16 bg-[#F5F5F0] border border-[#1A1A1A]/10 rounded-2xl p-5 sm:p-6 flex items-start gap-4"
            >
              <Building2 className="w-6 h-6 text-[#C62828] shrink-0 mt-1" />
              <p className="text-sm text-[#1A1A1A]/60 leading-relaxed" style={{ fontFamily: 'Cairo, sans-serif' }}>
                <strong className="text-[#1A1A1A]">ملاحظة مهمة:</strong> مش بنقدم اشتراكات شهرية جاهزة. كل نظام بيتبنى من الصفر حسب احتياجات المؤسسة التعليمية. السعر بيعتمد على حجم النظام، عدد المميزات، التخصيص، والـ Integrations.
              </p>
            </motion.div>
          </div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            FINAL CTA
        ══════════════════════════════════════════════════════════ */}
        <section className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-[#1A1A1A] text-white relative overflow-hidden">
          <div className="absolute inset-0 opacity-10">
            <div className="absolute -top-1/2 -right-1/4 w-full h-full bg-[#C62828] rounded-full blur-[200px]" />
          </div>
          <div className="max-w-3xl mx-auto text-center relative z-10">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.8 }}
            >
              <h2 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight mb-6 sm:mb-8 leading-tight" style={{ fontFamily: 'Cairo, sans-serif' }}>
                عايز نظام LMS{' '}
                <span className="text-[#C62828]">مناسب لأكاديميتك؟</span>
              </h2>
              <p className="text-white/60 text-base sm:text-xl mb-8 sm:mb-12 leading-relaxed" style={{ fontFamily: 'Cairo, sans-serif' }}>
                احكيلنا عن طريقة شغلك واحتياجاتك، وإحنا نبني لك نظام تعليمي متكامل يناسب مؤسستك.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <button
                  onClick={() => scrollTo('demo')}
                  className="bg-white/10 border border-white/20 text-white px-8 sm:px-12 py-4 sm:py-5 rounded-2xl font-black text-base sm:text-lg hover:bg-white hover:text-[#1A1A1A] transition-all active:scale-95"
                  style={{ fontFamily: 'Cairo, sans-serif' }}
                >
                  جرب النظام
                </button>
                <button
                  onClick={() => scrollTo('contact')}
                  className="bg-[#C62828] text-white px-8 sm:px-12 py-4 sm:py-5 rounded-2xl font-black text-base sm:text-lg hover:shadow-[0_20px_40px_rgba(198,40,40,0.3)] hover:-translate-y-1 transition-all active:scale-95 shadow-xl shadow-[#C62828]/20"
                  style={{ fontFamily: 'Cairo, sans-serif' }}
                >
                  اطلب نظامك الخاص
                </button>
              </div>
            </motion.div>
          </div>
        </section>

        {/* ══════════════════════════════════════════════════════════
            CONTACT FORM
        ══════════════════════════════════════════════════════════ */}
        <section id="contact" className="py-16 sm:py-24 md:py-32 px-4 sm:px-6 md:px-8 bg-[#F5F5F0]">
          <div className="max-w-3xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-center mb-10 sm:mb-16"
            >
              <h4 className="text-[#D4A373] font-black uppercase tracking-[0.3em] text-xs md:text-sm mb-4">تواصل معنا</h4>
              <h2 className="text-3xl sm:text-5xl font-black tracking-tight text-[#1A1A1A]" style={{ fontFamily: 'Cairo, sans-serif' }}>
                اطلب <span className="text-[#C62828]">نظامك الخاص</span>
              </h2>
              <div className="h-2 w-20 sm:w-32 bg-[#C62828] mt-4 sm:mt-8 mx-auto rounded-full" />
              <p className="text-[#1A1A1A]/50 text-sm sm:text-base mt-6" style={{ fontFamily: 'Cairo, sans-serif' }}>
                ابعتلنا تفاصيل أكاديميتك واحتياجاتك وهنتواصل معك في أقرب وقت.
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 40 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="bg-white rounded-3xl sm:rounded-4xl p-6 sm:p-10 border border-[#1A1A1A]/5 shadow-xl"
            >
              <ContactForm />
            </motion.div>
          </div>
        </section>

      </main>

      <Footer />
    </div>
  );
}

// ─── Contact Form ─────────────────────────────────────────────────────────────

function ContactForm() {
  const [submitted, setSubmitted] = useState(false);
  const [form, setForm] = useState({
    name: '', academy: '', whatsapp: '', email: '',
    type: '', students: '', needs: '', message: '',
  });

  const inputClass = "w-full px-4 py-3.5 bg-[#F5F5F0] border border-[#1A1A1A]/10 rounded-2xl font-black text-sm text-[#1A1A1A] outline-none focus:ring-4 focus:ring-[#C62828]/10 focus:border-[#C62828]/30 transition-all placeholder:text-[#1A1A1A]/30";
  const labelClass = "block text-[9px] font-black uppercase tracking-[0.25em] text-[#D4A373] mb-2";

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setForm(prev => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
  };

  if (submitted) {
    return (
      <div className="text-center py-10 sm:py-16">
        <div className="text-5xl sm:text-6xl mb-6">🎉</div>
        <h3 className="text-2xl sm:text-3xl font-black text-[#1A1A1A] mb-4" style={{ fontFamily: 'Cairo, sans-serif' }}>شكرًا لتواصلك!</h3>
        <p className="text-[#1A1A1A]/50 text-base sm:text-lg" style={{ fontFamily: 'Cairo, sans-serif' }}>
          استلمنا بياناتك وهنتواصل معك في أقرب وقت ممكن على واتساب أو إيميل.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5 sm:space-y-6">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 sm:gap-6">
        <div>
          <label className={labelClass} style={{ fontFamily: 'Cairo, sans-serif' }}>الاسم</label>
          <input name="name" value={form.name} onChange={handleChange} required placeholder="اسمك الكامل" className={inputClass} style={{ fontFamily: 'Cairo, sans-serif' }} />
        </div>
        <div>
          <label className={labelClass} style={{ fontFamily: 'Cairo, sans-serif' }}>اسم الأكاديمية / المؤسسة</label>
          <input name="academy" value={form.academy} onChange={handleChange} required placeholder="اسم مؤسستك التعليمية" className={inputClass} style={{ fontFamily: 'Cairo, sans-serif' }} />
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 sm:gap-6">
        <div>
          <label className={labelClass} style={{ fontFamily: 'Cairo, sans-serif' }}>رقم WhatsApp</label>
          <input name="whatsapp" value={form.whatsapp} onChange={handleChange} required placeholder="+20 12 79681713" className={inputClass} dir="ltr" style={{ fontFamily: 'Cairo, sans-serif' }} />
        </div>
        <div>
          <label className={labelClass} style={{ fontFamily: 'Cairo, sans-serif' }}>البريد الإلكتروني</label>
          <input type="email" name="email" value={form.email} onChange={handleChange} placeholder="email@example.com" className={inputClass} dir="ltr" style={{ fontFamily: 'Cairo, sans-serif' }} />
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 sm:gap-6">
        <div>
          <label className={labelClass} style={{ fontFamily: 'Cairo, sans-serif' }}>نوع النشاط</label>
          <select name="type" value={form.type} onChange={handleChange} required className={inputClass} style={{ fontFamily: 'Cairo, sans-serif' }}>
            <option value="">اختار نوع مؤسستك</option>
            <option value="language">أكاديمية لغات</option>
            <option value="training">مركز تدريب</option>
            <option value="tech">أكاديمية تقنية / برمجة</option>
            <option value="school">مدرسة أو معهد</option>
            <option value="corporate">تدريب مؤسسي</option>
            <option value="online">تعليم إلكتروني</option>
            <option value="other">أخرى</option>
          </select>
        </div>
        <div>
          <label className={labelClass} style={{ fontFamily: 'Cairo, sans-serif' }}>عدد الطلاب التقريبي</label>
          <select name="students" value={form.students} onChange={handleChange} className={inputClass} style={{ fontFamily: 'Cairo, sans-serif' }}>
            <option value="">اختار التقدير</option>
            <option value="lt50">أقل من 50 طالب</option>
            <option value="50-200">50 – 200 طالب</option>
            <option value="200-500">200 – 500 طالب</option>
            <option value="500-1000">500 – 1000 طالب</option>
            <option value="gt1000">أكثر من 1000 طالب</option>
          </select>
        </div>
      </div>

      <div>
        <label className={labelClass} style={{ fontFamily: 'Cairo, sans-serif' }}>احتياجاتك من النظام</label>
        <textarea name="needs" value={form.needs} onChange={handleChange} required rows={3} placeholder="مثال: إدارة الطلاب، الامتحانات الأونلاين، الحضور التلقائي، تقارير شهرية..." className={`${inputClass} resize-none`} style={{ fontFamily: 'Cairo, sans-serif' }} />
      </div>

      <div>
        <label className={labelClass} style={{ fontFamily: 'Cairo, sans-serif' }}>رسالة إضافية (اختياري)</label>
        <textarea name="message" value={form.message} onChange={handleChange} rows={2} placeholder="أي تفاصيل إضافية تريد مشاركتها..." className={`${inputClass} resize-none`} style={{ fontFamily: 'Cairo, sans-serif' }} />
      </div>

      <button
        type="submit"
        className="w-full py-4 sm:py-5 bg-[#C62828] text-white rounded-2xl font-black text-base sm:text-lg hover:shadow-[0_20px_40px_rgba(198,40,40,0.25)] hover:-translate-y-1 transition-all active:scale-95 shadow-xl shadow-[#C62828]/20"
        style={{ fontFamily: 'Cairo, sans-serif' }}
      >
        اطلب نظامك الخاص
      </button>

      <p className="text-center text-xs text-[#1A1A1A]/30 font-black" style={{ fontFamily: 'Cairo, sans-serif' }}>
        هنتواصل معك خلال 24 ساعة على واتساب أو إيميل.
      </p>
    </form>
  );
}
