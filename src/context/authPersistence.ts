const STORAGE_KEY = 'Acad Flow:auth:user';

export type PersistedAuthUser = {
  id: string;
  email: string;
  name: string;
  role: 'student' | 'admin' | 'instructor' | 'secretary';
  avatar_url?: string | null;
};

export function readPersistedUser(): PersistedAuthUser | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as PersistedAuthUser;
    if (!parsed?.id || !parsed?.role) return null;
    return parsed;
  } catch {
    return null;
  }
}

export function writePersistedUser(user: PersistedAuthUser | null) {
  try {
    if (!user) {
      localStorage.removeItem(STORAGE_KEY);
      return;
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
  } catch {
    // quota / private mode
  }
}
