/**
 * Student-facing material assignment queries (student_materials table).
 */
import { supabase } from '../lib/supabase';
import type { Material } from './studentService';

export type MaterialAssignmentStatus = 'assigned' | 'revision';

function normalizeAssignmentStatus(value: unknown): MaterialAssignmentStatus {
  if (value === 'revision') return 'revision';
  // Legacy rows may still have "completed" in DB until migration is applied.
  if (value === 'completed') return 'revision';
  return 'assigned';
}

/** Whether to show the Revision tag in the student portal. */
export function materialShowsAsRevision(
  row: StudentMaterialAssignment,
  currentLevelName: string | null
): boolean {
  if (normalizeAssignmentStatus(row.status) === 'revision') return true;
  if (!currentLevelName || !row.levelName) return false;
  return row.levelName.trim() !== currentLevelName.trim();
}

export type StudentMaterialAssignment = {
  assignmentId: string;
  status: MaterialAssignmentStatus;
  /** Set when building the list — use for UI badges (status + past-level fallback). */
  displayAsRevision: boolean;
  assignedAt: string;
  assignedBy: string | null;
  notes: string | null;
  levelName: string | null;
  material: Material;
};

/** All assigned materials for the student portal (single list). */
export type GroupedStudentMaterials = {
  all: StudentMaterialAssignment[];
};

function resolveMaterialsPath(fileUrlOrPath: string): string {
  if (!fileUrlOrPath) return '';
  if (!fileUrlOrPath.startsWith('http')) return fileUrlOrPath;
  const publicMarker = '/storage/v1/object/public/materials/';
  const signMarker = '/storage/v1/object/sign/materials/';
  const rawMarker = '/storage/v1/object/materials/';
  if (fileUrlOrPath.includes(publicMarker)) {
    return fileUrlOrPath.split(publicMarker)[1]?.split('?')[0] ?? '';
  }
  if (fileUrlOrPath.includes(signMarker)) {
    return fileUrlOrPath.split(signMarker)[1]?.split('?')[0] ?? '';
  }
  if (fileUrlOrPath.includes(rawMarker)) {
    return fileUrlOrPath.split(rawMarker)[1]?.split('?')[0] ?? '';
  }
  return '';
}

async function hydrateMaterial(mat: Material): Promise<Material> {
  const path = resolveMaterialsPath(mat.file_url);
  if (!path) return mat;
  const { data: signedData } = await supabase.storage.from('materials').createSignedUrl(path, 60 * 60);
  if (!signedData?.signedUrl) return mat;
  return { ...mat, file_url: signedData.signedUrl };
}

function isMissingStudentMaterialsTable(error: { code?: string; message?: string }): boolean {
  const msg = (error.message ?? '').toLowerCase();
  return (
    error.code === '42P01' ||
    error.code === 'PGRST205' ||
    (msg.includes('student_materials') && msg.includes('does not exist'))
  );
}

export async function fetchMyAssignedMaterialRows(
  studentId: string,
  currentLevelName?: string | null
): Promise<StudentMaterialAssignment[]> {
  const { data, error } = await supabase
    .from('student_materials')
    .select(`
      id,
      status,
      assigned_at,
      assigned_by,
      notes,
      available_from,
      materials (*, levels (name))
    `)
    .eq('student_id', studentId)
    .eq('visible', true)
    .lte('available_from', new Date().toISOString())
    .order('assigned_at', { ascending: false });

  if (!error) {
    const raw = data ?? [];
    const rows = await mapStudentMaterialRows(raw, currentLevelName ?? null);
    if (rows.length > 0) return rows;
    if (raw.length === 0) return [];
    throw new Error(
      'Assigned materials could not be loaded. Run the latest student_materials_patch.sql in Supabase (materials RLS for assigned items).'
    );
  }

  if (!isMissingStudentMaterialsTable(error)) {
    throw new Error(error.message);
  }

  // Backward compatibility: legacy material_assignments (no revision status).
  {
    const { data: legacyData, error: legacyError } = await supabase
      .from('material_assignments')
      .select(`
        id,
        material_id,
        available_from,
        materials (*)
      `)
      .eq('student_id', studentId)
      .eq('visible', true)
      .lte('available_from', new Date().toISOString())
      .order('available_from', { ascending: false });

    if (legacyError) throw new Error(legacyError.message);

    const levelIds = Array.from(
      new Set(
        (legacyData ?? [])
          .map((r: Record<string, unknown>) => {
            const mat = r.materials as (Material & { level_id?: string }) | null;
            return mat?.level_id ?? null;
          })
          .filter(Boolean)
      )
    ) as string[];

    let levelNameById = new Map<string, string>();
    if (levelIds.length > 0) {
      const { data: levelRows } = await supabase
        .from('levels')
        .select('id, name')
        .in('id', levelIds);
      levelNameById = new Map(
        (levelRows ?? []).map((l) => [String((l as { id: string }).id), String((l as { name: string }).name)])
      );
    }

    const legacyRows = await Promise.all(
      (legacyData ?? []).map(async (row: Record<string, unknown>) => {
        const mat = row.materials as Material & { level_id?: string };
        if (!mat) return null;
        const levelName = mat.level_id ? levelNameById.get(mat.level_id) ?? null : null;
        const displayAsRevision = Boolean(
          currentLevelName &&
            levelName &&
            levelName.trim() !== currentLevelName.trim()
        );
        const status: MaterialAssignmentStatus = displayAsRevision ? 'revision' : 'assigned';

        return {
          assignmentId: String(row.id ?? `${studentId}-${mat.id}`),
          status,
          displayAsRevision,
          assignedAt: String(row.available_from ?? new Date().toISOString()),
          assignedBy: null,
          notes: null,
          levelName,
          material: await hydrateMaterial(mat),
        } satisfies StudentMaterialAssignment;
      })
    );

    return legacyRows.filter(Boolean) as StudentMaterialAssignment[];
  }
}

async function mapStudentMaterialRows(
  data: Record<string, unknown>[],
  currentLevelName: string | null
): Promise<StudentMaterialAssignment[]> {
  const rows = await Promise.all(
    data.map(async (row: Record<string, unknown>) => {
      const mat = row.materials as Material & { levels?: { name: string } };
      if (!mat) return null;
      const status = normalizeAssignmentStatus(row.status);
      const base: StudentMaterialAssignment = {
        assignmentId: row.id as string,
        status,
        displayAsRevision: false,
        assignedAt: row.assigned_at as string,
        assignedBy: (row.assigned_by as string) ?? null,
        notes: (row.notes as string) ?? null,
        levelName: mat.levels?.name ?? null,
        material: await hydrateMaterial(mat),
      };
      return {
        ...base,
        displayAsRevision: materialShowsAsRevision(base, currentLevelName),
      };
    })
  );

  return rows.filter(Boolean) as StudentMaterialAssignment[];
}

export async function fetchMyMaterialsGrouped(
  studentId: string,
  currentLevelName?: string | null
): Promise<GroupedStudentMaterials> {
  const level = currentLevelName ?? null;
  const rows = await fetchMyAssignedMaterialRows(studentId, level);
  const all = [...rows].sort((a, b) => {
    const aRev = a.displayAsRevision ? 1 : 0;
    const bRev = b.displayAsRevision ? 1 : 0;
    if (aRev !== bRev) return aRev - bRev;
    return new Date(b.assignedAt).getTime() - new Date(a.assignedAt).getTime();
  });

  return { all };
}
