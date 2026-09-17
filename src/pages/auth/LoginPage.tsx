import { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import { Mail, Lock, ArrowRight, Shield, Check, AlertCircle, Loader2 } from 'lucide-react';
import TopNavBar from '../../components/layout/TopNavBar';
import Footer from '../../components/layout/Footer';
import { useAuth } from '../../context/AuthContext';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1, delayChildren: 0.2 },
  },
};

const DEMO_ACCOUNTS = [
  { emoji: '👨‍🎓', label: 'طالب', role: 'student', email: 'student.demo@leidenschaft.com', password: 'Demo12345!', path: '/student' },
  { emoji: '👨‍🏫', label: 'مدرس', role: 'instructor', email: 'instructor.demo@leidenschaft.com', password: 'Demo12345!', path: '/instructor' },
  { emoji: '👩‍💼', label: 'سكرتارية', role: 'secretary', email: 'secretary.demo@leidenschaft.com', password: 'Demo12345!', path: '/secretary/attendance' },
  { emoji: '👨‍💼', label: 'إدارة', role: 'admin', email: 'admin.demo@leidenschaft.com', password: 'Demo12345!', path: '/admin' },
];

interface LocationState {
  demoEmail?: string;
  demoPassword?: string;
  demoRole?: string;
}

export default function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuth();

  const locationState = (location.state ?? {}) as LocationState;

  const [email, setEmail] = useState(locationState.demoEmail ?? '');
  const [password, setPassword] = useState(locationState.demoPassword ?? '');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [demoLoading, setDemoLoading] = useState<string | null>(null);

  // If demo credentials were passed via navigation state, auto-submit immediately
  useEffect(() => {
    if (locationState.demoEmail && locationState.demoPassword) {
      void handleLoginWithCredentials(locationState.demoEmail, locationState.demoPassword);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleLoginWithCredentials = async (emailVal: string, passwordVal: string) => {
    setError('');
    setLoading(true);
    try {
      const user = await login(emailVal, passwordVal);
      if (user.role === 'admin') navigate('/admin');
      else if (user.role === 'instructor') navigate('/instructor');
      else if (user.role === 'secretary') navigate('/secretary/attendance');
      else navigate('/student');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'فشل تسجيل الدخول. حاول مرة أخرى.');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await handleLoginWithCredentials(email, password);
  };

  const handleDemoLogin = async (account: typeof DEMO_ACCOUNTS[0]) => {
    setDemoLoading(account.role);
    setError('');
    setEmail(account.email);
    setPassword(account.password);
    try {
      const user = await login(account.email, account.password);
      if (user.role === 'admin') navigate('/admin');
      else if (user.role === 'instructor') navigate('/instructor');
      else if (user.role === 'secretary') navigate('/secretary/attendance');
      else navigate('/student');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'فشل تسجيل الدخول. تأكد من بيانات الدخول.');
    } finally {
      setDemoLoading(null);
    }
  };

  // Determine which demo role was highlighted from navigation state
  const highlightedRole = locationState.demoRole ?? null;

  return (
    <div className="min-h-screen bg-[#F5F5F0] flex flex-col">
      <TopNavBar />

      <main className="flex-1 flex flex-col lg:flex-row relative overflow-hidden bg-white pt-20 lg:pt-16">
        {/* Background Particles */}
        <div className="absolute inset-0 z-0 pointer-events-none">
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              initial={{ x: `${(i / 6) * 100}%`, y: `${(i % 3) * 33}%`, scale: 0.4 }}
              animate={{ y: [null, -30, 30, -30], x: [null, 20, -20, 20] }}
              transition={{ duration: 20 + i * 3, repeat: Infinity, ease: 'easeInOut' }}
              className="absolute w-1 h-1 bg-[#C62828]/20 rounded-full"
            />
          ))}
        </div>

        {/* Visual Side */}
        <div className="hidden lg:flex lg:w-1/2 bg-[#1A1A1A] relative overflow-hidden group items-center justify-center p-16">
          <motion.div
            initial={{ scale: 1.1 }}
            animate={{ scale: 1 }}
            transition={{ duration: 1.5 }}
            className="absolute inset-0 bg-cover bg-center opacity-30 grayscale group-hover:grayscale-0 transition-all duration-1000"
            style={{ backgroundImage: "url('https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&t=crop&q=80')" }}
          />
          <div className="absolute inset-0 bg-gradient-to-br from-[#1A1A1A] via-[#1A1A1A]/80 to-transparent" />

          <div className="relative z-10 space-y-8 max-w-md" dir="rtl">
            <motion.div initial={{ opacity: 0, x: 30 }} animate={{ opacity: 1, x: 0 }} className="space-y-4">
              <div className="flex items-center gap-3 bg-white/5 backdrop-blur-md px-4 py-1.5 rounded-full w-fit border border-white/10">
                <Shield className="w-3 h-3 text-[#D4A373]" />
                <span className="text-[8px] font-black uppercase tracking-[0.3em] text-white/60" style={{ fontFamily: 'Cairo, sans-serif' }}>وصول آمن للمنصة</span>
              </div>
              <p role="heading" aria-level={2} className="text-5xl font-black text-white leading-[0.9] tracking-tighter uppercase underline decoration-[#C62828] decoration-4 underline-offset-4">
                نظام<br />الإدارة التعليمية.
              </p>
            </motion.div>
            <p className="text-sm font-medium text-white/40 leading-relaxed italic" style={{ fontFamily: 'Cairo, sans-serif' }}>
              "نظام إدارة تعليمي متكامل — ادخل وجرب النسخة التجريبية."
            </p>
          </div>
        </div>

        {/* Form Side */}
        <div className="flex-1 p-6 md:p-8 lg:p-6 flex flex-col justify-center items-center relative z-10" dir="rtl">
          <motion.div
            initial="hidden"
            animate="visible"
            variants={containerVariants}
            className="w-full max-w-md"
          >
            {/* Loading overlay when auto-logging in from demo */}
            {loading && locationState.demoEmail && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="mb-6 bg-[#C62828]/5 border border-[#C62828]/20 rounded-2xl p-4 flex items-center gap-3"
              >
                <Loader2 className="w-5 h-5 text-[#C62828] animate-spin shrink-0" />
                <p className="text-sm font-black text-[#C62828]" style={{ fontFamily: 'Cairo, sans-serif' }}>
                  جارٍ تسجيل الدخول بحساب {
                    DEMO_ACCOUNTS.find(a => a.role === highlightedRole)?.label ?? 'التجريبي'
                  }...
                </p>
              </motion.div>
            )}

            {/* Main Login Form */}
            <div className="bg-white p-8 md:p-10 rounded-2xl shadow-[0_20px_40px_-12px_rgba(26,26,26,0.1)] border border-[#1A1A1A]/5 relative overflow-hidden mb-6">
              <div className="space-y-8">
                <motion.div variants={containerVariants} className="space-y-2 md:space-y-3">
                  <h1 className="text-3xl md:text-4xl font-black text-[#1A1A1A] tracking-tighter leading-none" style={{ fontFamily: 'Cairo, sans-serif' }}>
                    تسجيل <span className="text-[#C62828]">الدخول</span>
                  </h1>
                  <p className="text-xs md:text-sm text-[#1A1A1A]/40 font-medium leading-relaxed" style={{ fontFamily: 'Cairo, sans-serif' }}>
                    ادخل بياناتك للوصول لمنصة الإدارة التعليمية.
                  </p>
                </motion.div>

                {/* Error */}
                {error && (
                  <motion.div
                    initial={{ opacity: 0, y: -8 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="flex items-center gap-3 bg-red-50 border border-red-200 rounded-xl p-3"
                  >
                    <AlertCircle className="w-4 h-4 text-[#C62828] shrink-0" />
                    <p className="text-xs font-bold text-[#C62828]">{error}</p>
                  </motion.div>
                )}

                <form className="space-y-6" onSubmit={handleSubmit}>
                  <motion.div variants={containerVariants} className="space-y-5">
                    {/* Email */}
                    <div className="space-y-2">
                      <label className="block text-[9px] font-black uppercase tracking-[0.3em] text-[#D4A373] mr-3" style={{ fontFamily: 'Cairo, sans-serif' }}>
                        البريد الإلكتروني
                      </label>
                      <div className="relative group">
                        <Mail className="absolute right-4 top-1/2 -translate-y-1/2 text-[#1A1A1A]/20 w-4 h-4 group-focus-within:text-[#C62828] transition-colors" />
                        <input
                          type="email"
                          value={email}
                          onChange={e => setEmail(e.target.value)}
                          className="w-full pr-12 pl-4 py-3.5 bg-[#F5F5F0] border-none rounded-xl focus:ring-4 focus:ring-[#C62828]/10 transition-all text-[#1A1A1A] placeholder:text-[#1A1A1A]/20 outline-none text-sm font-black tracking-tight"
                          placeholder="البريد@example.com"
                          required
                          disabled={loading || demoLoading !== null}
                          dir="ltr"
                        />
                      </div>
                    </div>

                    {/* Password */}
                    <div className="space-y-2">
                      <div className="flex justify-between items-center px-3">
                        <Link to="/forgot-password" className="text-[8px] font-black uppercase tracking-[0.2em] text-[#1A1A1A]/40 hover:text-[#C62828] transition-colors" style={{ fontFamily: 'Cairo, sans-serif' }}>
                          نسيت كلمة السر؟
                        </Link>
                        <label className="text-[9px] font-black uppercase tracking-[0.3em] text-[#D4A373]" style={{ fontFamily: 'Cairo, sans-serif' }}>كلمة المرور</label>
                      </div>
                      <div className="relative group">
                        <Lock className="absolute right-4 top-1/2 -translate-y-1/2 text-[#1A1A1A]/20 w-4 h-4 group-focus-within:text-[#C62828] transition-colors" />
                        <input
                          type="password"
                          value={password}
                          onChange={e => setPassword(e.target.value)}
                          className="w-full pr-12 pl-4 py-3.5 bg-[#F5F5F0] border-none rounded-xl focus:ring-4 focus:ring-[#C62828]/10 transition-all text-[#1A1A1A] placeholder:text-[#1A1A1A]/20 outline-none text-sm font-black tracking-tight"
                          placeholder="••••••••"
                          required
                          disabled={loading || demoLoading !== null}
                        />
                      </div>
                    </div>
                  </motion.div>

                  {/* Remember me */}
                  <motion.div variants={containerVariants} className="flex items-center gap-3 px-3">
                    <div className="relative w-4 h-4 flex items-center justify-center cursor-pointer group">
                      <input type="checkbox" className="peer absolute inset-0 opacity-0 cursor-pointer z-10" />
                      <div className="w-4 h-4 bg-[#F5F5F0] border border-[#1A1A1A]/10 rounded peer-checked:bg-[#C62828] peer-checked:border-[#C62828] transition-all" />
                      <Check className="absolute text-white w-3 h-3 opacity-0 peer-checked:opacity-100 transition-opacity z-20 pointer-events-none" />
                    </div>
                    <span className="text-[9px] font-black text-[#1A1A1A]/30 uppercase tracking-widest leading-none" style={{ fontFamily: 'Cairo, sans-serif' }}>تذكرني</span>
                  </motion.div>

                  <motion.button
                    variants={containerVariants}
                    type="submit"
                    disabled={loading || demoLoading !== null}
                    className="w-full py-4 bg-[#C62828] text-white rounded-xl font-black text-base hover:shadow-[0_20px_40px_rgba(198,40,40,0.2)] hover:-translate-y-1 active:scale-95 transition-all shadow-md uppercase tracking-wider group disabled:opacity-70 disabled:cursor-not-allowed disabled:hover:translate-y-0"
                    style={{ fontFamily: 'Cairo, sans-serif' }}
                  >
                    {loading ? (
                      <Loader2 className="inline-block w-5 h-5 animate-spin" />
                    ) : (
                      <>
                        دخول
                        <ArrowRight className="inline-block mr-2 w-4 h-4 group-hover:-translate-x-1 transition-transform" />
                      </>
                    )}
                  </motion.button>
                </form>
              </div>
            </div>

            {/* Demo Quick Login */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              className="bg-[#1A1A1A] rounded-2xl p-5 sm:p-6 border border-white/5"
            >
              <p className="text-[9px] font-black uppercase tracking-[0.3em] text-[#D4A373] mb-4 text-center" style={{ fontFamily: 'Cairo, sans-serif' }}>
                النسخة التجريبية — دخول سريع
              </p>
              <div className="grid grid-cols-2 gap-2 sm:gap-3">
                {DEMO_ACCOUNTS.map((account) => (
                  <button
                    key={account.role}
                    onClick={() => handleDemoLogin(account)}
                    disabled={loading || demoLoading !== null}
                    className={`flex items-center gap-2 border px-3 py-2.5 rounded-xl transition-all group disabled:opacity-60 disabled:cursor-not-allowed ${highlightedRole === account.role
                      ? 'bg-[#C62828] border-[#C62828] shadow-lg shadow-[#C62828]/30'
                      : 'bg-white/5 border-white/10 hover:bg-[#C62828] hover:border-[#C62828]'
                      }`}
                  >
                    {demoLoading === account.role ? (
                      <Loader2 className="w-4 h-4 animate-spin text-white shrink-0" />
                    ) : (
                      <span className="text-base shrink-0">{account.emoji}</span>
                    )}
                    <span className="text-xs font-black text-white/70 group-hover:text-white transition-colors" style={{ fontFamily: 'Cairo, sans-serif' }}>
                      {account.label}
                    </span>
                  </button>
                ))}
              </div>
              <p className="text-[8px] font-black text-white/20 text-center mt-3 uppercase tracking-widest" style={{ fontFamily: 'Cairo, sans-serif' }}>
                بيانات تجريبية — لا يوجد تسجيل مطلوب
              </p>
            </motion.div>
          </motion.div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
