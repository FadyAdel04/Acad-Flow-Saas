import { Link } from 'react-router-dom';
import {
  FiInstagram,
  FiArrowUpRight,
  FiMail,
  FiPhone,
  FiMapPin,
  FiFacebook
} from 'react-icons/fi';
import { RiDoubleQuotesR, RiTiktokFill } from 'react-icons/ri';

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-[#1A1A1A] text-white pt-20 md:pt-32 pb-12 px-6 md:px-10 relative overflow-hidden" dir="rtl">
      {/* Decorative Gradient */}
      <div className="absolute top-0 left-0 w-full h-px bg-linear-to-r from-transparent via-[#C62828] to-transparent opacity-50"></div>

      <div className="max-w-[1440px] mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-16 md:gap-20 mb-20 md:mb-32">
          {/* Brand Vision */}
          <div className="lg:col-span-5 space-y-12">
            <div className="space-y-4">
              <span className="text-[#C62828] text-4xl font-black tracking-tighter block uppercase">AcadFlow LMS</span>
              <p className="text-[10px] font-black uppercase tracking-[0.5em] text-[#D4A373]">نبني النظام التعليمي المناسب لمؤسستك</p>
            </div>

            <div className="relative">
              <RiDoubleQuotesR className="absolute -top-6 -right-4 md:-right-8 text-white/5 text-6xl md:text-8xl" />
              <p className="text-xl md:text-2xl font-black text-white/40 leading-tight italic max-w-sm md:max-w-md relative z-10 px-2 md:px-0" style={{ fontFamily: 'Cairo, sans-serif' }}>
                "مش بنقدم نظام واحد لكل الأكاديميات — بنبني النظام حسب طريقة شغلك."
              </p>
            </div>

            <div className="flex gap-4 md:gap-6">
              {[
                { icon: FiInstagram, link: 'https://www.instagram.com/Acad Flow.klub', label: 'Instagram' },
                { icon: FiFacebook, link: 'https://www.facebook.com/Acad Flow.klub', label: 'Facebook' },
                { icon: RiTiktokFill, link: 'https://www.tiktok.com/@Acad Flow.klub', label: 'TikTok' },
              ].map((social, i) => (
                <a
                  key={i}
                  href={social.link}
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label={social.label}
                  className="w-12 h-12 md:w-14 md:h-14 rounded-2xl bg-white/5 flex items-center justify-center hover:bg-[#C62828] hover:shadow-[0_20px_40px_rgba(198,40,40,0.3)] hover:-translate-y-1 transition-all group"
                >
                  <social.icon className="w-5 h-5 md:w-6 md:h-6 text-white/40 group-hover:text-white transition-colors" />
                </a>
              ))}
            </div>
          </div>

          {/* Links */}
          <div className="lg:col-span-7 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-12 md:gap-16">
            <div className="space-y-6 md:space-y-8">
              <h4 className="text-[10px] font-black uppercase tracking-[0.4em] text-[#D4A373]">الصفحة الرئيسية</h4>
              <ul className="space-y-4">
                {[
                  { label: 'الرئيسية', to: '/#hero' },
                  { label: 'المميزات', to: '/#features' },
                  { label: 'لوحات التحكم', to: '/#roles' },
                  { label: 'جرب النظام', to: '/#demo' },
                  { label: 'الأسعار', to: '/#pricing' },
                  { label: 'تواصل معنا', to: '/#contact' },
                ].map((item) => (
                  <li key={item.label}>
                    <Link to={item.to} className="text-sm font-black text-white/40 hover:text-white flex items-center gap-2 group transition-all">
                      <FiArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-all group-hover:translate-x-1 group-hover:-translate-y-1 shrink-0" />
                      {item.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            <div className="space-y-8">
              <h4 className="text-[10px] font-black uppercase tracking-[0.4em] text-[#D4A373]">النظام</h4>
              <ul className="space-y-4">
                {[
                  { label: 'لوحة الطالب', to: '/student' },
                  { label: 'لوحة المدرس', to: '/instructor' },
                  { label: 'لوحة السكرتارية', to: '/secretary/attendance' },
                  { label: 'لوحة الإدارة', to: '/admin' },
                  { label: 'تسجيل الدخول', to: '/login' },
                ].map((item) => (
                  <li key={item.label}>
                    <Link to={item.to} className="text-sm font-black text-white/40 hover:text-white flex items-center gap-2 group transition-all">
                      <FiArrowUpRight className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-all group-hover:translate-x-1 group-hover:-translate-y-1 shrink-0" />
                      {item.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>

            <div className="space-y-8 col-span-2 md:col-span-1">
              <h4 className="text-[10px] font-black uppercase tracking-[0.4em] text-[#D4A373]">تواصل معنا</h4>
              <div className="space-y-6">
                <div className="flex items-start gap-4 group cursor-pointer">
                  <FiMapPin className="text-[#C62828] w-5 h-5 mt-1 transition-transform group-hover:scale-110 shrink-0" />
                  <p className="text-sm font-black text-white/40 leading-relaxed" style={{ fontFamily: 'Cairo, sans-serif' }}>
                    الإسكندرية، مصر
                  </p>
                </div>
                <div className="flex items-center gap-4 group cursor-pointer">
                  <FiMail className="text-[#C62828] w-5 h-5 transition-transform group-hover:scale-110 shrink-0" />
                  <span className="text-sm font-black text-white/40">Acad Flowklub@gmail.com</span>
                </div>
                <div className="flex items-center gap-4 group cursor-pointer">
                  <FiPhone className="text-[#C62828] w-5 h-5 transition-transform group-hover:scale-110 shrink-0" />
                  <span className="text-sm font-black text-white/40">+20 12 79681713</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Legal */}
        <div className="pt-12 border-t border-white/5 flex flex-col md:flex-row justify-between items-center gap-10">
          <div className="text-center md:text-right">
            <p className="text-[10px] font-black uppercase tracking-[0.3em] text-white/20">
              © {currentYear} AcadFlow LMS. جميع الحقوق محفوظة. نبني أنظمة تعليمية مخصصة.
            </p>
          </div>
          <div className="flex flex-col sm:flex-row gap-6 sm:gap-10">
            <Link to="/about#privacy" className="text-[10px] font-black uppercase tracking-[0.4em] text-white/10 hover:text-[#C62828] transition-colors text-center">
              سياسة الخصوصية
            </Link>
            <Link to="/about#terms" className="text-[10px] font-black uppercase tracking-[0.4em] text-white/10 hover:text-[#C62828] transition-colors text-center">
              الشروط والأحكام
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
