import { useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import {
  Search,
  User,
  BookOpen,
  Loader,
  CheckCircle,
  AlertCircle,
  Trash2,
  History,
  Layers,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import AdminSidebar from '../../components/shared/AdminSidebar';
import SecretarySidebar from '../../components/shared/SecretarySidebar';
import {
  fetchAllMaterials,
  fetchAllLevels,
  fetchAllStudents,
  type Material,
  type Level,
  type Profile,
} from '../../services/adminService';
import {
  fetchStudentAssignments,
  bulkAssignMaterials,
  removeMaterialAssignment,
  type StudentMaterialRow,
  type MaterialAssignmentStatus,
} from '../../services/materialAssignmentService';

type Props = {
  portal: 'admin' | 'secretary';
};

const cv = { hidden: { opacity: 0 }, visible: { opacity: 1, transition: { staggerChildren: 0.06 } } };
const ci = { hidden: { opacity: 0, y: 12 }, visible: { opacity: 1, y: 0 } };

function AssignmentHistoryTable({
  title,
  rows,
  loading,
  emptyMessage,
  onRemove,
  revision = false,
}: {
  title: string;
  rows: StudentMaterialRow[];
  loading: boolean;
  emptyMessage: string;
  onRemove: (id: string) => void;
  revision?: boolean;
}) {
  return (
    <div className="bg-white rounded-3xl border border-[#1A1A1A]/10 p-5">
      <h3 className="font-black uppercase text-sm mb-4 flex items-center gap-2">
        <History className={`w-4 h-4 ${revision ? 'text-[#D4A373]' : 'text-[#1A1A1A]'}`} />
        {title}
      </h3>
      {loading ? (
        <Loader className="w-6 h-6 animate-spin text-[#F97316] mx-auto" />
      ) : rows.length === 0 ? (
        <p className="text-sm text-[#1A1A1A]/40 font-bold">{emptyMessage}</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-[#1A1A1A]/10 text-[9px] font-black uppercase tracking-widest text-[#1A1A1A]/40">
                <th className="py-2 pr-4">Material</th>
                <th className="py-2 pr-4">Level</th>
                <th className="py-2 pr-4">Status</th>
                <th className="py-2 pr-4">Assigned</th>
                <th className="py-2 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1A1A1A]/5">
              {rows.map((a) => (
                <tr key={a.id}>
                  <td className="py-3 pr-4 font-bold">{a.materials?.title ?? '—'}</td>
                  <td className="py-3 pr-4 text-[#1A1A1A]/60">
                    {(a.materials as Material & { levels?: { name: string } })?.levels?.name ?? '—'}
                  </td>
                  <td className="py-3 pr-4">
                    <span
                      className={`text-[10px] font-black uppercase px-2 py-1 rounded-lg ${
                        a.status === 'revision'
                          ? 'bg-[#D4A373]/15 text-[#8B6914]'
                          : 'bg-[#F5F5F0] text-[#1A1A1A]'
                      }`}
                    >
                      {a.status}
                    </span>
                  </td>
                  <td className="py-3 pr-4 text-xs text-[#1A1A1A]/50">
                    {new Date(a.assigned_at).toLocaleString()}
                  </td>
                  <td className="py-3 text-right">
                    <button
                      type="button"
                      onClick={() => void onRemove(a.id)}
                      className="p-2 rounded-lg hover:bg-red-50 text-red-500"
                      title="Remove assignment"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default function MaterialAssignmentCenter({ portal }: Props) {
  const { user } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const [students, setStudents] = useState<Profile[]>([]);
  const [levels, setLevels] = useState<Level[]>([]);
  const [materials, setMaterials] = useState<(Material & { levels?: { name: string } })[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [studentSearch, setStudentSearch] = useState('');
  const [levelFilter, setLevelFilter] = useState('');
  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(null);
  const [assignments, setAssignments] = useState<StudentMaterialRow[]>([]);
  const [assignmentsLoading, setAssignmentsLoading] = useState(false);

  const [selectedCurrentMaterialIds, setSelectedCurrentMaterialIds] = useState<string[]>([]);
  const [selectedRevisionMaterialIds, setSelectedRevisionMaterialIds] = useState<string[]>([]);
  const [assignNotes, setAssignNotes] = useState('');
  const [bulkWorking, setBulkWorking] = useState(false);

  const selectedStudent = students.find((s) => s.id === selectedStudentId) ?? null;
  const assignmentByMaterialId = useMemo(() => {
    const map = new Map<string, StudentMaterialRow>();
    for (const row of assignments) map.set(row.material_id, row);
    return map;
  }, [assignments]);

  const filteredStudents = useMemo(() => {
    const q = studentSearch.trim().toLowerCase();
    return students.filter((s) => {
      const matchSearch =
        !q ||
        s.name.toLowerCase().includes(q) ||
        s.email.toLowerCase().includes(q);
      const matchLevel = !levelFilter || s.current_level === levelFilter;
      return matchSearch && matchLevel;
    });
  }, [students, studentSearch, levelFilter]);

  const currentAssignments = useMemo(
    () => assignments.filter((a) => a.status === 'assigned'),
    [assignments]
  );

  const revisionAssignments = useMemo(
    () => assignments.filter((a) => a.status === 'revision'),
    [assignments]
  );

  const materialsForLevel = useMemo(() => {
    if (!selectedStudent) return materials;
    const lvl = levels.find((l) => l.name === selectedStudent.current_level);
    if (!lvl) return materials;
    return materials.filter((m) => {
      if (m.level_id !== lvl.id) return false;
      return assignmentByMaterialId.get(m.id)?.status !== 'revision';
    });
  }, [materials, levels, selectedStudent, assignmentByMaterialId]);

  const revisionMaterials = useMemo(() => {
    if (!selectedStudent) return [];
    return materials.filter((m) => {
      const existing = assignmentByMaterialId.get(m.id);
      if (existing?.status === 'revision') return true;
      const lvlName = (m as Material & { levels?: { name: string } }).levels?.name;
      if (!lvlName) return false;
      return lvlName !== selectedStudent.current_level;
    });
  }, [materials, selectedStudent, assignmentByMaterialId]);

  async function loadBase() {
    setLoading(true);
    setError('');
    try {
      const [s, l, m] = await Promise.all([
        fetchAllStudents(),
        fetchAllLevels(),
        fetchAllMaterials(),
      ]);
      setStudents(s);
      setLevels(l);
      setMaterials(m);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load data');
    } finally {
      setLoading(false);
    }
  }

  async function loadAssignments(studentId: string) {
    setAssignmentsLoading(true);
    try {
      const rows = await fetchStudentAssignments(studentId);
      setAssignments(rows);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load assignments');
    } finally {
      setAssignmentsLoading(false);
    }
  }

  useEffect(() => {
    void loadBase();
  }, []);

  useEffect(() => {
    if (!selectedStudentId) {
      setAssignments([]);
      setSelectedCurrentMaterialIds([]);
      setSelectedRevisionMaterialIds([]);
      return;
    }
    setSelectedCurrentMaterialIds([]);
    setSelectedRevisionMaterialIds([]);
    void loadAssignments(selectedStudentId);
  }, [selectedStudentId]);

  const handleBulkAssign = async (status: MaterialAssignmentStatus, materialIds: string[]) => {
    if (!selectedStudentId || materialIds.length === 0) return;
    setBulkWorking(true);
    setError('');
    try {
      const result = await bulkAssignMaterials({
        studentIds: [selectedStudentId],
        materialIds,
        assignedBy: user?.id ?? null,
        status,
        notes: assignNotes.trim() || null,
        notify: true,
      });
      const parts: string[] = [];
      if (result.created) parts.push(`${result.created} new`);
      if (result.promoted) parts.push(`${result.promoted} moved to revision`);
      if (result.skipped) parts.push(`${result.skipped} unchanged`);
      setSuccess(parts.length ? parts.join(', ') : 'No changes made.');
      setSelectedCurrentMaterialIds([]);
      setSelectedRevisionMaterialIds([]);
      setAssignNotes('');
      await loadAssignments(selectedStudentId);
      setTimeout(() => setSuccess(''), 4000);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Bulk assign failed');
    } finally {
      setBulkWorking(false);
    }
  };

  const handleRemove = async (assignmentId: string) => {
    if (!selectedStudentId) return;
    try {
      await removeMaterialAssignment(assignmentId);
      await loadAssignments(selectedStudentId);
      setSuccess('Assignment removed.');
      setTimeout(() => setSuccess(''), 3000);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Remove failed');
    }
  };

  const toggleCurrentMaterial = (id: string) => {
    setSelectedCurrentMaterialIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  const toggleRevisionMaterial = (id: string) => {
    setSelectedRevisionMaterialIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  return (
    <motion.div initial="hidden" animate="visible" variants={cv} className="min-h-screen bg-[#F5F5F0] lg:flex">
      {portal === 'admin' ? (
        <AdminSidebar />
      ) : (
        <SecretarySidebar
          open={sidebarOpen}
          onClose={() => setSidebarOpen(false)}
          onToggle={() => setSidebarOpen((p) => !p)}
        />
      )}

      <main
        className={`flex-1 p-4 sm:p-6 md:p-10 lg:p-14 relative overflow-hidden ${
          portal === 'admin' ? 'lg:ml-80 pt-14 lg:pt-0' : 'pt-20 lg:pt-0 lg:ml-80'
        }`}
      >
        <motion.header variants={ci} className="mb-8 relative z-10">
          <p className="text-[10px] font-black uppercase tracking-[0.4em] text-[#D4A373] mb-2">
            {portal === 'admin' ? 'Admin' : 'Secretary'}
          </p>
          <h1 className="text-3xl sm:text-4xl font-black tracking-tighter text-[#1A1A1A] uppercase">
            Material Assignment <span className="text-[#F97316]">Center</span>
          </h1>
          <p className="text-sm text-[#1A1A1A]/50 mt-2 font-medium max-w-2xl">
            Assign study materials to students. Secretaries can assign and remove assignments but cannot upload or edit materials.
          </p>
        </motion.header>

        {error && (
          <div className="mb-4 flex items-center gap-2 bg-red-50 border border-red-200 rounded-2xl p-4 text-sm font-bold text-red-700">
            <AlertCircle className="w-4 h-4 shrink-0" />
            {error}
          </div>
        )}
        {success && (
          <div className="mb-4 flex items-center gap-2 bg-green-50 border border-green-200 rounded-2xl p-4 text-sm font-bold text-green-700">
            <CheckCircle className="w-4 h-4 shrink-0" />
            {success}
          </div>
        )}

        {loading ? (
          <div className="flex justify-center py-24">
            <Loader className="w-8 h-8 animate-spin text-[#F97316]" />
          </div>
        ) : (
          <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 relative z-10">
            {/* Student picker */}
            <section className="xl:col-span-4 bg-white rounded-3xl border border-[#1A1A1A]/10 p-5 shadow-sm">
              <h2 className="font-black uppercase text-sm text-[#1A1A1A] mb-4 flex items-center gap-2">
                <User className="w-4 h-4 text-[#F97316]" />
                Students
              </h2>
              <div className="relative mb-3">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#1A1A1A]/30" />
                <input
                  value={studentSearch}
                  onChange={(e) => setStudentSearch(e.target.value)}
                  placeholder="Search student…"
                  className="w-full pl-10 pr-3 py-2.5 rounded-xl bg-[#F5F5F0] text-sm font-bold outline-none"
                />
              </div>
              <select
                value={levelFilter}
                onChange={(e) => setLevelFilter(e.target.value)}
                className="w-full mb-3 px-3 py-2.5 rounded-xl bg-[#F5F5F0] text-sm font-bold outline-none"
              >
                <option value="">All levels</option>
                {levels.map((l) => (
                  <option key={l.id} value={l.name}>
                    {l.name}
                  </option>
                ))}
              </select>
              <div className="max-h-[420px] overflow-y-auto space-y-1">
                {filteredStudents.map((s) => (
                  <button
                    key={s.id}
                    type="button"
                    onClick={() => setSelectedStudentId(s.id)}
                    className={`w-full text-left px-4 py-3 rounded-xl transition-all ${
                      selectedStudentId === s.id
                        ? 'bg-[#F97316] text-white'
                        : 'hover:bg-[#F5F5F0] text-[#1A1A1A]'
                    }`}
                  >
                    <p className="font-black text-sm truncate">{s.name}</p>
                    <p className="text-[10px] uppercase tracking-widest opacity-70">
                      {s.current_level} · {s.email}
                    </p>
                  </button>
                ))}
              </div>
            </section>

            {/* Assignment panel */}
            <section className="xl:col-span-8 space-y-6">
              {!selectedStudent ? (
                <div className="bg-white rounded-3xl border border-[#1A1A1A]/10 p-12 text-center text-[#1A1A1A]/40 font-black uppercase tracking-widest text-sm">
                  Select a student to manage assignments
                </div>
              ) : (
                <>
                  <div className="bg-white rounded-3xl border border-[#1A1A1A]/10 p-6 shadow-sm">
                    <p className="text-[10px] font-black uppercase tracking-widest text-[#D4A373]">Selected</p>
                    <h3 className="text-xl font-black text-[#1A1A1A] mt-1">{selectedStudent.name}</h3>
                    <p className="text-sm text-[#1A1A1A]/50">Level {selectedStudent.current_level}</p>

                    <div className="mt-4 flex flex-wrap gap-3 items-end">
                      <input
                        value={assignNotes}
                        onChange={(e) => setAssignNotes(e.target.value)}
                        placeholder="Optional notes"
                        className="flex-1 min-w-[160px] px-3 py-2 rounded-xl bg-[#F5F5F0] text-sm font-bold"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <div className="bg-white rounded-3xl border border-[#1A1A1A]/10 p-5">
                      <h3 className="font-black uppercase text-sm mb-3 flex items-center gap-2">
                        <Layers className="w-4 h-4 text-[#F97316]" />
                        Current level materials
                      </h3>
                      <div className="max-h-64 overflow-y-auto space-y-2">
                        {materialsForLevel.map((m) => (
                          <label
                            key={m.id}
                            className={`flex items-center gap-3 p-3 rounded-xl ${
                              assignmentByMaterialId.has(m.id)
                                ? 'bg-green-50 border border-green-100'
                                : 'bg-[#F5F5F0] cursor-pointer'
                            }`}
                          >
                            <input
                              type="checkbox"
                              checked={selectedCurrentMaterialIds.includes(m.id)}
                              disabled={assignmentByMaterialId.get(m.id)?.status === 'assigned'}
                              onChange={() => toggleCurrentMaterial(m.id)}
                            />
                            <span className="text-sm font-bold text-[#1A1A1A] truncate">
                              {m.title}
                              {assignmentByMaterialId.get(m.id)?.status === 'assigned'
                                ? ' (already assigned)'
                                : ''}
                            </span>
                          </label>
                        ))}
                      </div>
                      <div className="mt-3">
                        <button
                          type="button"
                          disabled={bulkWorking || selectedCurrentMaterialIds.length === 0}
                          onClick={() => void handleBulkAssign('assigned', selectedCurrentMaterialIds)}
                          className="w-full px-4 py-2 rounded-xl bg-[#1A1A1A] text-white text-xs font-black uppercase tracking-widest disabled:opacity-50"
                        >
                          {bulkWorking ? 'Working…' : 'Assign as current level'}
                        </button>
                      </div>
                    </div>

                    <div className="bg-white rounded-3xl border border-[#1A1A1A]/10 p-5">
                      <h3 className="font-black uppercase text-sm mb-3 flex items-center gap-2">
                        <BookOpen className="w-4 h-4 text-[#D4A373]" />
                        Revision materials (previous levels)
                      </h3>
                      <div className="max-h-64 overflow-y-auto overflow-x-hidden space-y-2">
                        {revisionAssignments.length > 0 && (
                          <div className="mb-3 pb-3 border-b border-[#1A1A1A]/10 space-y-2">
                            <p className="text-[9px] font-black uppercase tracking-widest text-[#D4A373]">
                              In revision ({revisionAssignments.length})
                            </p>
                            {revisionAssignments.map((a) => (
                              <div
                                key={a.id}
                                className="flex items-center gap-3 p-3 rounded-xl bg-green-50 border border-green-100 min-w-0"
                              >
                                <CheckCircle className="w-4 h-4 text-green-600 shrink-0" />
                                <div className="min-w-0 flex-1 overflow-x-auto overscroll-x-contain">
                                  <span className="text-sm font-bold text-[#1A1A1A] whitespace-nowrap inline-block pr-2">
                                    {(a.materials as Material & { levels?: { name: string } })?.levels?.name
                                      ? `Past level ${(a.materials as Material & { levels?: { name: string } }).levels?.name} — `
                                      : ''}
                                    {a.materials?.title ?? 'Material'}
                                  </span>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}
                        {revisionMaterials.filter(
                          (m) => assignmentByMaterialId.get(m.id)?.status !== 'revision'
                        ).length === 0 && revisionAssignments.length === 0 ? (
                          <p className="text-xs text-[#1A1A1A]/40 font-bold">No materials from other levels.</p>
                        ) : (
                          revisionMaterials
                            .filter((m) => assignmentByMaterialId.get(m.id)?.status !== 'revision')
                            .map((m) => {
                            const existing = assignmentByMaterialId.get(m.id);
                            const alreadyRevision = existing?.status === 'revision';
                            return (
                            <label
                              key={m.id}
                              className={`flex items-center gap-3 p-3 rounded-xl min-w-0 ${
                                alreadyRevision
                                  ? 'bg-green-50 border border-green-100 opacity-70'
                                  : existing?.status === 'assigned'
                                    ? 'bg-amber-50 border border-amber-100 cursor-pointer'
                                    : 'bg-[#F5F5F0] cursor-pointer'
                              }`}
                            >
                              <input
                                type="checkbox"
                                checked={selectedRevisionMaterialIds.includes(m.id)}
                                disabled={alreadyRevision}
                                onChange={() => toggleRevisionMaterial(m.id)}
                                className="shrink-0"
                              />
                              <div className="min-w-0 flex-1 overflow-x-auto overscroll-x-contain">
                                <span className="text-sm font-bold text-[#1A1A1A] whitespace-nowrap inline-block pr-2">
                                  Past level {(m as Material & { levels?: { name: string } }).levels?.name} — {m.title}
                                  {alreadyRevision
                                    ? ' (already revision)'
                                    : existing?.status === 'assigned'
                                      ? ' (move to revision)'
                                      : ''}
                                </span>
                              </div>
                            </label>
                            );
                          })
                        )}
                      </div>
                      <div className="mt-3">
                        <button
                          type="button"
                          disabled={bulkWorking || selectedRevisionMaterialIds.length === 0}
                          onClick={() => void handleBulkAssign('revision', selectedRevisionMaterialIds)}
                          className="w-full px-4 py-2 rounded-xl bg-[#D4A373] text-white text-xs font-black uppercase tracking-widest disabled:opacity-50"
                        >
                          {bulkWorking ? 'Working…' : 'Assign as revision'}
                        </button>
                      </div>
                    </div>
                  </div>

                  <AssignmentHistoryTable
                    title="Current level assignments"
                    rows={currentAssignments}
                    loading={assignmentsLoading}
                    emptyMessage="No current-level assignments."
                    onRemove={handleRemove}
                  />
                  <AssignmentHistoryTable
                    title="Revision assignments"
                    rows={revisionAssignments}
                    loading={assignmentsLoading}
                    emptyMessage="No revision assignments yet. Use “Assign as revision” above."
                    onRemove={handleRemove}
                    revision
                  />
                </>
              )}
            </section>
          </div>
        )}
      </main>
    </motion.div>
  );
}
