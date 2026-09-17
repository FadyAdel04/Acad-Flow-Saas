import { motion } from 'framer-motion';
import { useState, useEffect, useMemo } from 'react';
import { BookOpen, Search, AlertCircle, PlayCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import StudentSidebar from '../../components/shared/StudentSidebar';
import MaterialPreviewModal from '../../components/shared/MaterialPreviewModal';
import { fetchProfile, type Profile } from '../../services/studentService';
import {
  fetchMyMaterialsGrouped,
  type StudentMaterialAssignment,
} from '../../services/studentMaterialsService';

const cv = { hidden: { opacity: 0 }, visible: { opacity: 1, transition: { staggerChildren: 0.07, delayChildren: 0.1 } } };
const ci = { hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } };

function MaterialGrid({
  items,
  onPreview,
}: {
  items: StudentMaterialAssignment[];
  onPreview: (m: StudentMaterialAssignment) => void;
}) {
  const getType = (url: string) => {
    const clean = url.split('?')[0].toLowerCase();
    if (clean.endsWith('.pdf')) return 'PDF';
    if (clean.endsWith('.mp4') || clean.endsWith('.webm')) return 'Video';
    if (clean.endsWith('.mp3') || clean.endsWith('.wav')) return 'Audio';
    return 'file';
  };

  if (items.length === 0) {
    return (
      <p className="text-sm text-[#1A1A1A]/40 font-bold italic py-8 text-center">No materials assigned yet.</p>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
      {items.map((row) => {
        const isRevision = row.displayAsRevision;
        return (
          <motion.div
            key={row.assignmentId}
            whileHover={{ y: -6 }}
            className={`bg-white rounded-[2rem] p-8 border shadow-sm hover:shadow-2xl transition-all group relative overflow-hidden ${
              isRevision ? 'border-[#D4A373]/30' : 'border-[#1A1A1A]/5'
            }`}
          >
            <div className="absolute top-0 right-0 w-24 h-24 bg-[#F97316]/[0.03] rounded-full -translate-y-1/2 translate-x-1/2 group-hover:bg-[#F97316]/10 transition-all" />
            <div className="relative z-10">
              <div className="flex flex-wrap items-center gap-2 mb-2">
                {row.levelName && (
                  <p className="text-[9px] font-black uppercase tracking-widest text-[#D4A373]">{row.levelName}</p>
                )}
                {isRevision && (
                  <span className="text-[8px] font-black uppercase tracking-widest px-2 py-0.5 rounded-md bg-[#D4A373]/15 text-[#8B6914] border border-[#D4A373]/25">
                    Revision
                  </span>
                )}
              </div>
              <h3 className="text-lg font-black text-[#1A1A1A] tracking-tight uppercase leading-tight mb-4 group-hover:text-[#F97316] transition-colors line-clamp-2">
                {row.material.title}
              </h3>
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-black uppercase tracking-widest text-[#1A1A1A]/30">
                  {getType(row.material.file_url)}
                </span>
                <button
                  type="button"
                  onClick={() => onPreview(row)}
                  className="flex items-center gap-2 px-4 py-2 rounded-xl bg-[#1A1A1A] text-white text-[10px] font-black uppercase tracking-widest hover:bg-[#F97316] transition-all"
                >
                  <PlayCircle className="w-3.5 h-3.5" />
                  Open
                </button>
              </div>
            </div>
          </motion.div>
        );
      })}
    </div>
  );
}

export default function StudentCourses() {
  const { user } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [materials, setMaterials] = useState<StudentMaterialAssignment[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [previewOpen, setPreviewOpen] = useState(false);
  const [selectedRow, setSelectedRow] = useState<StudentMaterialAssignment | null>(null);

  useEffect(() => {
    document.body.style.overflow = sidebarOpen ? 'hidden' : '';
    return () => { document.body.style.overflow = ''; };
  }, [sidebarOpen]);

  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    async function load() {
      try {
        const prof = await fetchProfile(user!.id);
        if (cancelled) return;
        setProfile(prof);
        const grouped = await fetchMyMaterialsGrouped(user!.id, prof.current_level ?? null);
        if (cancelled) return;
        setMaterials(grouped.all);
      } catch (e: unknown) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'Failed to load materials');
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    load();
    return () => { cancelled = true; };
  }, [user]);

  const filteredList = useMemo(() => {
    const q = search.toLowerCase();
    if (!q) return materials;
    return materials.filter(
      (r) =>
        r.material.title.toLowerCase().includes(q) ||
        (r.levelName?.toLowerCase().includes(q) ?? false)
    );
  }, [materials, search]);

  const revisionCount = materials.filter((r) => r.displayAsRevision).length;

  return (
    <motion.div initial="hidden" animate="visible" variants={cv} className="min-h-screen bg-[#F5F5F0] lg:flex">
      <StudentSidebar profile={profile} open={sidebarOpen} onClose={() => setSidebarOpen(false)} onToggle={() => setSidebarOpen(p => !p)} />

      <main className="pt-14 lg:pt-0 lg:mr-80 flex-1 p-4 sm:p-6 md:p-10 lg:p-16 xl:p-20 relative overflow-hidden">
        <motion.header variants={ci} className="mb-10 lg:mb-16 flex flex-col sm:flex-row justify-between items-start sm:items-end gap-6 relative z-10">
          <div className="space-y-3">
            <span className="text-[#F97316] font-black tracking-[0.5em] text-[10px] uppercase italic">
              Level {profile?.current_level ?? '—'} Curriculum
            </span>
            <h1 className="text-4xl sm:text-5xl md:text-6xl font-black tracking-tighter text-[#1A1A1A] leading-none uppercase">
              My<br /><span className="text-[#F97316]">Materials.</span>
            </h1>
            {materials.length > 0 && (
              <p className="text-[10px] font-black uppercase tracking-widest text-[#1A1A1A]/40">
                {materials.length} material{materials.length !== 1 ? 's' : ''}
                {revisionCount > 0 ? ` · ${revisionCount} revision` : ''}
              </p>
            )}
          </div>
          <div className="relative w-full sm:w-80">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-[#1A1A1A]/20 w-4 h-4" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search materials…"
              className="w-full pl-11 pr-4 py-3.5 bg-white border border-[#1A1A1A]/5 rounded-2xl font-black text-sm outline-none focus:ring-4 focus:ring-[#F97316]/10 shadow-sm"
            />
          </div>
        </motion.header>

        {error && (
          <motion.div variants={ci} className="mb-8 flex items-center gap-3 bg-red-50 border border-red-200 rounded-2xl p-4">
            <AlertCircle className="w-5 h-5 text-[#F97316] shrink-0" />
            <p className="text-sm font-bold text-[#F97316]">{error}</p>
          </motion.div>
        )}

        <div className="relative z-10">
          {loading ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-52 bg-white rounded-[2rem] border animate-pulse" />
              ))}
            </div>
          ) : materials.length === 0 ? (
            <div className="flex flex-col items-center py-32 text-center">
              <BookOpen className="w-10 h-10 text-[#1A1A1A]/20 mb-4" />
              <p className="text-xl font-black text-[#1A1A1A]/30 uppercase">No materials assigned yet.</p>
            </div>
          ) : (
            <MaterialGrid
              items={filteredList}
              onPreview={(row) => {
                setSelectedRow(row);
                setPreviewOpen(true);
              }}
            />
          )}
        </div>
      </main>

      <MaterialPreviewModal
        open={previewOpen}
        material={selectedRow?.material ?? null}
        onClose={() => {
          setPreviewOpen(false);
          setSelectedRow(null);
        }}
      />
    </motion.div>
  );
}
