/**
 * Student material assignments (student_materials table).
 */
import { supabase } from '../lib/supabase';
import type { Material, Profile } from './studentService';
import { insertNotification } from './notificationService';
import { invalidateStudentCache } from './studentService';

function clearStudentMaterialCache() {
  invalidateStudentCache();
}

export type MaterialAssignmentStatus = 'assigned' | 'revision';

export type StudentMaterialRow = {
  id: string;
  student_id: string;
  material_id: string;
  assigned_by: string | null;
  assigned_at: string;
  available_from: string;
  visible: boolean;
  status: MaterialAssignmentStatus;
  notes: string | null;
  materials?: Material & { levels?: { id: string; name: string } };
  profiles?: { name: string; email: string };
  assigner?: { name: string } | null;
};

const CEFR_ORDER = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

export function levelSortKey(name: string): number {
  const token = name.match(/^(A1|A2|B1|B2|C1|C2)/i)?.[1]?.toUpperCase() ?? name.toUpperCase();
  const idx = CEFR_ORDER.indexOf(token);
  if (idx >= 0) return idx * 1000 + name.length;
  return 9999 + name.charCodeAt(0);
}

export function compareLevelNames(a: string, b: string): number {
  return levelSortKey(a) - levelSortKey(b);
}

export function isLevelBelow(levelName: string, currentLevelName: string): boolean {
  return levelSortKey(levelName) < levelSortKey(currentLevelName);
}

export async function fetchAllStudentsForAssignment(): Promise<Profile[]> {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('role', 'student')
    .order('name', { ascending: true });
  if (error) throw new Error(error.message);
  return (data ?? []) as Profile[];
}

export async function fetchStudentAssignments(studentId: string): Promise<StudentMaterialRow[]> {
  const { data, error } = await supabase
    .from('student_materials')
    .select(`
      *,
      materials (*, levels (id, name))
    `)
    .eq('student_id', studentId)
    .order('assigned_at', { ascending: false });
  if (error) throw new Error(error.message);
  return (data ?? []) as StudentMaterialRow[];
}

export async function fetchAssignmentsForMaterial(materialId: string): Promise<string[]> {
  const { data, error } = await supabase
    .from('student_materials')
    .select('student_id')
    .eq('material_id', materialId);
  if (error) throw new Error(error.message);
  return (data ?? []).map((r) => r.student_id as string);
}

export async function assignMaterialToStudent(payload: {
  studentId: string;
  materialId: string;
  assignedBy: string | null;
  status?: MaterialAssignmentStatus;
  availableFrom?: string;
  visible?: boolean;
  notes?: string | null;
  notify?: boolean;
  notificationTitle?: string;
  notificationMessage?: string;
}): Promise<StudentMaterialRow | null> {
  const status = payload.status ?? 'assigned';
  const availableFrom = payload.availableFrom ?? new Date().toISOString();

  const { data: existing } = await supabase
    .from('student_materials')
    .select('id, status')
    .eq('student_id', payload.studentId)
    .eq('material_id', payload.materialId)
    .maybeSingle();

  if (existing) {
    if (existing.status !== status) {
      const { data: updated, error: updateError } = await supabase
        .from('student_materials')
        .update({
          status,
          notes: payload.notes ?? null,
          visible: payload.visible ?? true,
          available_from: availableFrom,
        })
        .eq('id', existing.id)
        .select()
        .single();
      if (updateError) throw new Error(updateError.message);
      clearStudentMaterialCache();
      return updated as StudentMaterialRow;
    }
    return null;
  }

  const { data, error } = await supabase
    .from('student_materials')
    .insert({
      student_id: payload.studentId,
      material_id: payload.materialId,
      assigned_by: payload.assignedBy,
      status,
      available_from: availableFrom,
      visible: payload.visible ?? true,
      notes: payload.notes ?? null,
    })
    .select()
    .single();

  if (error) throw new Error(error.message);
  clearStudentMaterialCache();

  if (payload.notify !== false) {
    try {
      const { data: mat } = await supabase
        .from('materials')
        .select('title')
        .eq('id', payload.materialId)
        .maybeSingle();
      await insertNotification({
        userId: payload.studentId,
        type: 'material',
        title: payload.notificationTitle ?? 'New material assigned',
        message:
          payload.notificationMessage ??
          `You have been assigned: ${(mat as { title?: string })?.title ?? 'new material'}.`,
        relatedId: payload.materialId,
        priority: 'medium',
        isActive: true,
        createdBy: payload.assignedBy,
      });
    } catch {
      // non-blocking
    }
  }

  return data as StudentMaterialRow;
}

export async function removeMaterialAssignment(assignmentId: string): Promise<void> {
  const { error } = await supabase.from('student_materials').delete().eq('id', assignmentId);
  if (error) throw new Error(error.message);
  clearStudentMaterialCache();
}

export async function removeAssignmentByMaterialStudent(
  materialId: string,
  studentId: string
): Promise<void> {
  const { error } = await supabase
    .from('student_materials')
    .delete()
    .eq('material_id', materialId)
    .eq('student_id', studentId);
  if (error) throw new Error(error.message);
}

export async function updateAssignmentStatus(
  assignmentId: string,
  status: MaterialAssignmentStatus,
  notes?: string | null
): Promise<void> {
  const { error } = await supabase
    .from('student_materials')
    .update({ status, notes: notes ?? null })
    .eq('id', assignmentId);
  if (error) throw new Error(error.message);
}

export async function syncMaterialAssignments(payload: {
  materialId: string;
  studentIds: string[];
  assignedBy: string | null;
  availableFrom: string;
  visible: boolean;
  status?: MaterialAssignmentStatus;
}): Promise<void> {
  const status = payload.status ?? 'assigned';
  const current = await fetchAssignmentsForMaterial(payload.materialId);
  const toRemove = current.filter((id) => !payload.studentIds.includes(id));
  const toAdd = payload.studentIds.filter((id) => !current.includes(id));

  for (const studentId of toRemove) {
    await removeAssignmentByMaterialStudent(payload.materialId, studentId);
  }

  for (const studentId of toAdd) {
    await assignMaterialToStudent({
      studentId,
      materialId: payload.materialId,
      assignedBy: payload.assignedBy,
      status,
      availableFrom: payload.availableFrom,
      visible: payload.visible,
    });
  }

  if (payload.studentIds.length > 0) {
    const { error } = await supabase
      .from('student_materials')
      .update({
        available_from: payload.availableFrom,
        visible: payload.visible,
      })
      .eq('material_id', payload.materialId)
      .in('student_id', payload.studentIds);
    if (error) throw new Error(error.message);
  }
}

async function notifyStudentMaterialsUpdate(
  studentId: string,
  status: MaterialAssignmentStatus,
  assignedBy: string | null,
  count: number
): Promise<void> {
  if (count <= 0) return;
  const isRevision = status === 'revision';
  try {
    await insertNotification({
      userId: studentId,
      type: 'material',
      title: isRevision ? 'Revision materials updated' : 'New materials assigned',
      message: isRevision
        ? `${count} revision material(s) from previous levels have been added to your account.`
        : `${count} new study material(s) have been added to your account.`,
      priority: 'medium',
      isActive: true,
      createdBy: assignedBy ?? undefined,
    });
  } catch {
    // notifications must not block assignments
  }
}

export async function bulkAssignMaterials(payload: {
  studentIds: string[];
  materialIds: string[];
  assignedBy: string | null;
  status?: MaterialAssignmentStatus;
  availableFrom?: string;
  notes?: string | null;
  notify?: boolean;
}): Promise<{ created: number; promoted: number; skipped: number }> {
  const status = payload.status ?? 'assigned';
  let created = 0;
  let skipped = 0;
  let promoted = 0;
  const perStudentChanges = new Map<string, number>();

  for (const studentId of payload.studentIds) {
    let studentChanges = 0;

    for (const materialId of payload.materialIds) {
      const { data: existing, error: existingError } = await supabase
        .from('student_materials')
        .select('id, status')
        .eq('student_id', studentId)
        .eq('material_id', materialId)
        .maybeSingle();

      if (existingError) throw new Error(existingError.message);

      if (existing) {
        if (status === 'revision' && existing.status !== 'revision') {
          const { error: promoteError } = await supabase
            .from('student_materials')
            .update({
              status: 'revision',
              notes: payload.notes ?? null,
            })
            .eq('id', existing.id);
          if (promoteError) throw new Error(promoteError.message);
          promoted += 1;
          studentChanges += 1;
          continue;
        }
        skipped += 1;
        continue;
      }

      const row = await assignMaterialToStudent({
        studentId,
        materialId,
        assignedBy: payload.assignedBy,
        status,
        availableFrom: payload.availableFrom,
        notes: payload.notes,
        notify: false,
      });
      if (row) {
        created += 1;
        studentChanges += 1;
      } else {
        skipped += 1;
      }
    }

    if (studentChanges > 0) perStudentChanges.set(studentId, studentChanges);
  }

  if (payload.notify !== false) {
    for (const [studentId, count] of perStudentChanges) {
      await notifyStudentMaterialsUpdate(studentId, status, payload.assignedBy, count);
    }
  }

  clearStudentMaterialCache();
  return { created, promoted, skipped };
}

export async function assignPreviousLevelMaterials(
  studentId: string,
  currentLevelName: string,
  assignedBy: string | null
): Promise<{ created: number; skipped: number }> {
  const { data: levels, error: levelsError } = await supabase.from('levels').select('id, name');
  if (levelsError) throw new Error(levelsError.message);

  const previousLevelIds = (levels ?? [])
    .filter((l) => isLevelBelow((l as { name: string }).name, currentLevelName))
    .map((l) => (l as { id: string }).id);

  if (previousLevelIds.length === 0) return { created: 0, skipped: 0 };

  const { data: materials, error: matError } = await supabase
    .from('materials')
    .select('id')
    .in('level_id', previousLevelIds);
  if (matError) throw new Error(matError.message);

  const materialIds = (materials ?? []).map((m) => (m as { id: string }).id);
  if (materialIds.length === 0) return { created: 0, skipped: 0 };

  const result = await bulkAssignMaterials({
    studentIds: [studentId],
    materialIds,
    assignedBy,
    status: 'revision',
    notify: true,
  });

  return {
    created: result.created + result.promoted,
    skipped: result.skipped,
  };
}

export async function assignCurrentLevelMaterialsAsAssigned(
  studentId: string,
  levelId: string,
  assignedBy: string | null
): Promise<{ created: number; skipped: number }> {
  const { data: materials, error } = await supabase
    .from('materials')
    .select('id')
    .eq('level_id', levelId);
  if (error) throw new Error(error.message);
  const materialIds = (materials ?? []).map((m) => (m as { id: string }).id);
  if (!materialIds.length) return { created: 0, skipped: 0 };
  return bulkAssignMaterials({
    studentIds: [studentId],
    materialIds,
    assignedBy,
    status: 'assigned',
    notify: false,
  });
}
