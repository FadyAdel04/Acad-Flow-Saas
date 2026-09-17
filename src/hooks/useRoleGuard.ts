import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import type { UserRole } from '../context/AuthContext';

/**
 * Imperative guard hook (used by layout components).
 * Redirects unauthenticated users to /login and wrong-role users to /.
 */
export function useRoleGuard(allowedRoles: UserRole[]) {
  const { user, initializing } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (initializing && !user) return;
    if (!user) {
      navigate('/login', { replace: true });
    } else if (!allowedRoles.includes(user.role)) {
      navigate('/', { replace: true });
    }
  }, [user, initializing, navigate, allowedRoles]);

  return user;
}
