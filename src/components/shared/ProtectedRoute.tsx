import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import type { UserRole } from '../../context/AuthContext';

interface ProtectedRouteProps {
  allowedRoles?: UserRole[];
  redirectTo?: string;
}

/** Returns the home portal path for a given role. */
function portalFor(role: UserRole): string {
  if (role === 'admin')      return '/admin';
  if (role === 'instructor') return '/instructor';
  if (role === 'secretary')  return '/secretary';
  return '/student';
}

/**
 * Wraps routes that require authentication (and optionally a specific role).
 * - Shows a spinner while the session is being loaded.
 * - Redirects to /login if the user is not authenticated.
 * - Redirects to the user's OWN portal if their role is not allowed here.
 */
export default function ProtectedRoute({
  allowedRoles,
  redirectTo = '/login',
}: ProtectedRouteProps) {
  const { user, initializing } = useAuth();

  // Spinner only on first bootstrap when we have no cached user (not on TOKEN_REFRESHED).
  if (initializing && !user) {
    return (
      <div className="flex h-screen w-screen items-center justify-center bg-[#F5F5F0]">
        <div className="w-8 h-8 rounded-full border-4 border-[#1A1A1A]/10 border-t-[#DE0002] animate-spin" />
      </div>
    );
  }

  // Not authenticated → go to login
  if (!user) return <Navigate to={redirectTo} replace />;

  // Wrong role → send to their correct portal (not landing page)
  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to={portalFor(user.role)} replace />;
  }

  return <Outlet />;
}
