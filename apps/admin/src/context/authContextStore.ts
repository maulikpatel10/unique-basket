import { createContext, useContext } from 'react';
import type { AdminUser } from '../types';

export interface AuthContextType {
  user: AdminUser | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

/** Kept separate from AuthContext.tsx so that file only exports components (fast refresh). */
export const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error(
      'useAuth must be invoked within an AuthProvider context wrapper.'
    );
  }

  return context;
};
