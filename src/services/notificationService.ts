import { supabase } from '../lib/supabase';

export type NotificationType =
  | 'material'
  | 'assignment'
  | 'exam'
  | 'review'
  | 'submission'
  | 'announcement'
  | 'reminder'
  | 'alert'
  | 'event';

export type NotificationPriority = 'low' | 'medium' | 'high';

export type NotificationTargetLevel = 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2' | 'all';

export type AppNotification = {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  message: string;
  related_id: string | null;
  is_read: boolean;
  announcement_id?: string | null;
  target_level?: NotificationTargetLevel | string | null;
  priority?: NotificationPriority | null;
  expires_at?: string | null;
  is_active?: boolean | null;
  created_by?: string | null;
  created_at: string;
};

const ALLOWED_TYPES: NotificationType[] = [
  'material',
  'assignment',
  'exam',
  'review',
  'submission',
  'announcement',
  'reminder',
  'alert',
  'event',
];

async function notifyUserRpc(payload: {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  relatedId?: string | null;
  priority?: NotificationPriority;
  createdBy?: string | null;
}): Promise<{ ok: boolean; error: Error | null }> {
  const { error } = await supabase.rpc('notify_user', {
    p_user_id: payload.userId,
    p_type: payload.type,
    p_title: payload.title,
    p_message: payload.message,
    p_related_id: payload.relatedId ?? null,
    p_priority: payload.priority ?? 'medium',
    p_created_by: payload.createdBy ?? null,
  });
  if (!error) return { ok: true, error: null };
  return { ok: false, error: new Error(error.message) };
}

function buildRestRow(payload: {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  relatedId?: string | null;
  announcementId?: string;
  targetLevel?: NotificationTargetLevel | string;
  priority?: NotificationPriority;
  expiresAt?: string | null;
  isActive?: boolean;
  createdBy?: string | null;
}): Record<string, unknown> {
  const row: Record<string, unknown> = {
    user_id: payload.userId,
    type: payload.type,
    title: payload.title,
    message: payload.message,
    related_id: payload.relatedId ?? null,
    target_level: payload.targetLevel ?? 'all',
    priority: payload.priority ?? 'medium',
    is_active: payload.isActive ?? true,
  };
  if (payload.announcementId) row.announcement_id = payload.announcementId;
  if (typeof payload.expiresAt !== 'undefined') row.expires_at = payload.expiresAt;
  if (payload.createdBy) row.created_by = payload.createdBy;
  return row;
}

export async function fetchNotifications(userId: string, limit = 30): Promise<AppNotification[]> {
  const { data, error } = await supabase
    .from('notifications')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(error.message);

  const now = Date.now();
  return (data ?? []).filter((n: AppNotification) => {
    const isActive = n.is_active ?? true;
    if (!isActive) return false;
    const exp = n.expires_at ? new Date(n.expires_at).getTime() : null;
    if (exp !== null && exp <= now) return false;
    return true;
  }) as AppNotification[];
}

export async function fetchUnreadCount(userId: string): Promise<number> {
  const nowIso = new Date().toISOString();
  const { count, error } = await supabase
    .from('notifications')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('is_read', false)
    .eq('is_active', true)
    .or(`expires_at.is.null,expires_at.gt.${nowIso}`);
  if (error) throw new Error(error.message);
  return count ?? 0;
}

export async function markNotificationRead(notificationId: string): Promise<void> {
  const { error } = await supabase.from('notifications').update({ is_read: true }).eq('id', notificationId);
  if (error) throw new Error(error.message);
}

export async function markAllNotificationsRead(userId: string): Promise<void> {
  const { error } = await supabase
    .from('notifications')
    .update({ is_read: true })
    .eq('user_id', userId)
    .eq('is_read', false);
  if (error) throw new Error(error.message);
}

/** Notify a student (materials, assignments). Uses RPC first to avoid RLS/400 issues. */
export async function insertNotification(payload: {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  relatedId?: string | null;
  announcementId?: string;
  targetLevel?: NotificationTargetLevel | string;
  priority?: NotificationPriority;
  expiresAt?: string | null;
  isActive?: boolean;
  createdBy?: string | null;
}): Promise<void> {
  if (!ALLOWED_TYPES.includes(payload.type)) {
    throw new Error(`Invalid notification type: ${payload.type}`);
  }

  const needsRestOnly = Boolean(payload.announcementId);

  if (!needsRestOnly) {
    const rpc = await notifyUserRpc(payload);
    if (rpc.ok) return;
    // RPC missing or failed — fall through to REST with full row
  }

  const { error } = await supabase.from('notifications').insert(buildRestRow(payload));
  if (!error) return;

  if (!needsRestOnly) {
    const rpc = await notifyUserRpc(payload);
    if (rpc.ok) return;
    throw new Error(rpc.error?.message ?? error.message);
  }

  throw new Error(error.message);
}

export async function insertNotificationsBatch(
  rows: Array<{
    userId: string;
    type: NotificationType;
    title: string;
    message: string;
    relatedId?: string | null;
    announcementId?: string;
    targetLevel?: NotificationTargetLevel | string;
    priority?: NotificationPriority;
    expiresAt?: string | null;
    isActive?: boolean;
    createdBy?: string | null;
  }>
): Promise<void> {
  if (!rows.length) return;

  const mapped = rows.map((r) => buildRestRow(r));

  const { error } = await supabase.from('notifications').insert(mapped);
  if (!error) return;

  for (const r of rows) {
    if (r.announcementId) {
      const { error: restError } = await supabase.from('notifications').insert(buildRestRow(r));
      if (restError) throw new Error(restError.message);
      continue;
    }
    const rpc = await notifyUserRpc(r);
    if (!rpc.ok) throw new Error(rpc.error?.message ?? error.message);
  }
}
