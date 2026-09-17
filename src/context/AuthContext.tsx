import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import type { ReactNode } from 'react';
import type { AuthChangeEvent, Session, User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import { readPersistedUser, writePersistedUser } from './authPersistence';
import {
  bumpAuthProviderRender,
  logAuthEvent,
  logAuthStateChange,
} from './authDebug';
import { sessionsEqual, usersEqual } from './authUtils';

// ─── Types ────────────────────────────────────────────────────────────────────

export type UserRole = 'student' | 'admin' | 'instructor' | 'secretary';

export interface AppUser {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  avatar_url?: string | null;
}

interface AuthContextType {
  user: AppUser | null;
  session: Session | null;
  /** True only during first auth bootstrap — never flips on TOKEN_REFRESHED. */
  loading: boolean;
  /** Alias of `loading` for clarity in route guards. */
  initializing: boolean;
  login: (email: string, password: string) => Promise<AppUser>;
  register: (name: string, email: string, password: string, phone: string, role: UserRole) => Promise<void>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// ─── Helpers ──────────────────────────────────────────────────────────────────

function mapUser(supabaseUser: User): AppUser {
  const meta = supabaseUser.user_metadata ?? {};
  return {
    id: supabaseUser.id,
    email: supabaseUser.email ?? '',
    name: (meta.name as string) ?? (meta.full_name as string) ?? supabaseUser.email ?? '',
    role: (meta.role as UserRole) ?? 'student',
    avatar_url: (meta.avatar_url as string) ?? null,
  };
}

async function mapUserFromProfile(supabaseUser: User): Promise<AppUser> {
  const fallback = mapUser(supabaseUser);
  const { data } = await supabase
    .from('profiles')
    .select('name, role, avatar_url')
    .eq('id', supabaseUser.id)
    .maybeSingle();

  const dbRole = data?.role as UserRole | undefined;
  const role: UserRole =
    dbRole === 'admin' ||
    dbRole === 'student' ||
    dbRole === 'instructor' ||
    dbRole === 'secretary'
      ? dbRole
      : fallback.role;
  const name = data?.name || fallback.name;
  let avatarUrl = data?.avatar_url || fallback.avatar_url;

  if (avatarUrl && !avatarUrl.startsWith('http')) {
    const { data: signed } = await supabase.storage
      .from('avatars')
      .createSignedUrl(avatarUrl, 60 * 60);
    avatarUrl = signed?.signedUrl ?? avatarUrl;
  }

  return {
    ...fallback,
    name,
    role,
    avatar_url: avatarUrl,
  };
}

function shouldFullyHydrate(event: AuthChangeEvent): boolean {
  return event === 'SIGNED_IN' || event === 'USER_UPDATED';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

export function AuthProvider({ children }: { children: ReactNode }) {
  bumpAuthProviderRender();

  const persisted = readPersistedUser();
  const [user, setUser] = useState<AppUser | null>(persisted);
  const [session, setSession] = useState<Session | null>(null);
  const [initializing, setInitializing] = useState(true);

  const userRef = useRef(user);
  const sessionRef = useRef(session);
  const bootstrapDoneRef = useRef(false);
  const hydrateInFlightRef = useRef(false);

  useEffect(() => {
    userRef.current = user;
    logAuthStateChange('user state', { userId: user?.id ?? null, role: user?.role ?? null });
  }, [user]);

  useEffect(() => {
    sessionRef.current = session;
    logAuthStateChange('session state', {
      hasSession: Boolean(session),
      tokenPrefix: session?.access_token?.slice(0, 8) ?? null,
    });
  }, [session]);

  useEffect(() => {
    logAuthStateChange('initializing', { initializing });
  }, [initializing]);

  const applyUser = useCallback((next: AppUser | null) => {
    setUser((prev) => {
      if (usersEqual(prev, next)) return prev;
      writePersistedUser(next);
      return next;
    });
  }, []);

  const applySession = useCallback((next: Session | null) => {
    setSession((prev) => {
      if (sessionsEqual(prev, next)) return prev;
      return next;
    });
  }, []);

  const hydrateUserFromSession = useCallback(
    async (activeSession: Session | null): Promise<AppUser | null> => {
      if (!activeSession?.user) {
        applyUser(null);
        return null;
      }

      try {
        const hydrated = await mapUserFromProfile(activeSession.user);
        applyUser(hydrated);
        return hydrated;
      } catch {
        const fallback = mapUser(activeSession.user);
        applyUser(fallback);
        return fallback;
      }
    },
    [applyUser]
  );

  const hydrateInBackground = useCallback(
    async (activeSession: Session | null) => {
      if (!activeSession?.user || hydrateInFlightRef.current) return;
      hydrateInFlightRef.current = true;
      try {
        await hydrateUserFromSession(activeSession);
      } finally {
        hydrateInFlightRef.current = false;
      }
    },
    [hydrateUserFromSession]
  );

  useEffect(() => {
    let cancelled = false;

    async function bootstrap() {
      try {
        const { data } = await supabase.auth.getSession();
        if (cancelled) return;

        applySession(data.session);

        if (data.session?.user) {
          // Background sync — UI already has persisted user if available.
          await hydrateUserFromSession(data.session);
        } else {
          applyUser(null);
        }
      } catch {
        if (!cancelled) {
          applySession(null);
          if (!userRef.current) applyUser(null);
        }
      } finally {
        if (!cancelled) {
          bootstrapDoneRef.current = true;
          setInitializing(false);
        }
      }
    }

    void bootstrap();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, newSession) => {
      if (cancelled) return;

      logAuthEvent(event, {
        hasSession: Boolean(newSession),
        userId: newSession?.user?.id ?? null,
      });

      if (event === 'SIGNED_OUT' || !newSession?.user) {
        applySession(null);
        applyUser(null);
        setInitializing(false);
        return;
      }

      // Silent path: token refresh / duplicate initial session after bootstrap.
      if (event === 'TOKEN_REFRESHED') {
        applySession(newSession);
        return;
      }

      if (event === 'INITIAL_SESSION') {
        applySession(newSession);
        if (bootstrapDoneRef.current) {
          void hydrateInBackground(newSession);
        }
        return;
      }

      applySession(newSession);

      if (shouldFullyHydrate(event)) {
        void hydrateInBackground(newSession);
      }
    });

    return () => {
      cancelled = true;
      subscription.unsubscribe();
    };
  }, [applySession, applyUser, hydrateInBackground, hydrateUserFromSession]);

  const login = useCallback(async (email: string, password: string): Promise<AppUser> => {
    const {
      data: { user: supabaseUser, session: newSession },
      error,
    } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw new Error(error.message);
    if (!supabaseUser) throw new Error('Identity verification failed.');

    if (newSession) applySession(newSession);
    const hydrated = await mapUserFromProfile(supabaseUser);
    applyUser(hydrated);
    return hydrated;
  }, [applySession, applyUser]);

  const register = useCallback(
    async (
      name: string,
      email: string,
      password: string,
      phone: string,
      role: UserRole = 'student'
    ) => {
      const phoneTrim = phone.trim();
      const phoneNorm = phoneTrim.replace(/[\s\-().]/g, '');
      if (!phoneNorm || phoneNorm.length < 8) {
        throw new Error('Enter a valid phone number (at least 8 digits).');
      }

      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { name, role, phone: phoneTrim },
        },
      });
      if (error) throw new Error(error.message);
    },
    []
  );

  const logout = useCallback(async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw new Error(error.message);
    applySession(null);
    applyUser(null);
  }, [applySession, applyUser]);

  const refreshUser = useCallback(async () => {
    const { data } = await supabase.auth.getSession();
    if (data.session?.user) {
      await hydrateUserFromSession(data.session);
    }
  }, [hydrateUserFromSession]);

  const contextValue = useMemo<AuthContextType>(
    () => ({
      user,
      session,
      loading: initializing,
      initializing,
      login,
      register,
      logout,
      refreshUser,
    }),
    [user, session, initializing, login, register, logout, refreshUser]
  );

  return (
    <AuthContext.Provider value={contextValue}>{children}</AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
