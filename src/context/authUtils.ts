import type { Session } from '@supabase/supabase-js';
import type { AppUser } from './AuthContext';

export function usersEqual(a: AppUser | null, b: AppUser | null): boolean {
  if (a === b) return true;
  if (!a || !b) return false;
  return (
    a.id === b.id &&
    a.email === b.email &&
    a.name === b.name &&
    a.role === b.role &&
    (a.avatar_url ?? null) === (b.avatar_url ?? null)
  );
}

export function sessionsEqual(a: Session | null, b: Session | null): boolean {
  if (a === b) return true;
  if (!a || !b) return false;
  return a.access_token === b.access_token && a.user?.id === b.user?.id;
}
