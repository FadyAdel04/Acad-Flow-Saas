import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAutoTranslate } from 'react-autolocalise';
import { Globe, ChevronDown, Check } from 'lucide-react';

export interface LanguageItem {
  code: string;
  label: string;
  flag: string;
  dir: 'ltr' | 'rtl';
}

const languages: LanguageItem[] = [
  { code: 'ar', label: 'العربية', flag: '🇸🇦', dir: 'rtl' },
  { code: 'en', label: 'English', flag: '🇺🇸', dir: 'ltr' },
];

interface LanguageSwitcherProps {
  variant?: 'light' | 'dark';
  className?: string;
}

export default function LanguageSwitcher({ variant = 'light', className = '' }: LanguageSwitcherProps) {
  const { loading } = useAutoTranslate();
  const [currentLangCode, setCurrentLangCode] = useState(
    localStorage.getItem('selected_language') || 'ar'
  );
  const [isOpen, setIsOpen] = useState(false);

  const currentLang = languages.find(l => l.code === currentLangCode) || languages[0];

  useEffect(() => {
    document.documentElement.dir = currentLang.dir;
    document.documentElement.lang = currentLang.code;
    localStorage.setItem('selected_language', currentLangCode);
    
    // Check if the applied language matches the selected one
    const appliedLang = localStorage.getItem('selected_language_applied');
    if (currentLangCode !== appliedLang) {
      localStorage.setItem('selected_language_applied', currentLangCode);
      window.location.reload(); // Force reload to apply new targetLocale in Provider
    }
  }, [currentLangCode, currentLang.dir, currentLang.code]);

  const handleLanguageChange = (code: string) => {
    if (code === currentLangCode) {
      setIsOpen(false);
      return;
    }
    setCurrentLangCode(code);
    localStorage.setItem('selected_language', code);
    localStorage.setItem('selected_language_applied', code);
    setIsOpen(false);
    window.location.reload();
  };

  const isDark = variant === 'dark';

  return (
    <div className={`relative inline-block ${className}`}>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className={`flex items-center gap-2 px-3 py-2 rounded-xl transition-all font-black text-xs uppercase tracking-wider shadow-sm group cursor-pointer ${
          isDark
            ? 'bg-white/10 hover:bg-white/15 text-white border border-white/10'
            : 'bg-white/80 hover:bg-white text-[#1A1A1A] border border-[#1A1A1A]/10'
        }`}
        title="Change language / تغيير اللغة"
      >
        <Globe className={`w-4 h-4 text-[#C62828] group-hover:rotate-12 transition-transform ${loading ? 'animate-spin' : ''}`} />
        <span className="text-sm leading-none">{currentLang.flag}</span>
        <span className="font-bold text-xs">{currentLang.label}</span>
        <ChevronDown className={`w-3.5 h-3.5 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      <AnimatePresence>
        {isOpen && (
          <>
            <div 
              className="fixed inset-0 z-40" 
              onClick={() => setIsOpen(false)} 
            />
            <motion.div
              initial={{ opacity: 0, y: 8, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 8, scale: 0.95 }}
              transition={{ duration: 0.15 }}
              className={`absolute right-0 bottom-full mb-2 sm:bottom-auto sm:top-full sm:mt-2 w-48 rounded-2xl border shadow-2xl z-50 overflow-hidden ${
                isDark
                  ? 'bg-[#1A1A1A] border-white/10 text-white'
                  : 'bg-white border-[#1A1A1A]/10 text-[#1A1A1A]'
              }`}
            >
              <div className="p-1.5 space-y-1">
                {languages.map((lang) => {
                  const isSelected = currentLangCode === lang.code;
                  return (
                    <button
                      key={lang.code}
                      type="button"
                      onClick={() => handleLanguageChange(lang.code)}
                      className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl transition-all text-xs font-bold cursor-pointer ${
                        isSelected
                          ? 'bg-[#C62828] text-white shadow-md shadow-[#C62828]/20'
                          : isDark
                          ? 'text-white/70 hover:text-white hover:bg-white/10'
                          : 'text-[#1A1A1A]/70 hover:text-[#1A1A1A] hover:bg-[#F5F5F0]'
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <span className="text-base">{lang.flag}</span>
                        <span>{lang.label}</span>
                        <span className="text-[10px] opacity-60 uppercase">({lang.code})</span>
                      </div>
                      {isSelected && <Check className="w-4 h-4 text-white shrink-0" />}
                    </button>
                  );
                })}
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
