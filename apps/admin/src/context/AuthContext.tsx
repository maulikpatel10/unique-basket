import React, { useState } from 'react';
import { api, clearAdminSession, revokeAdminSession } from '../services/api';
import type { AdminUser } from '../types';
import { asApiError } from '../utils/apiError';

import { AuthContext } from './authContextStore';

/**
 * Restores the admin session saved in localStorage. Runs once as a lazy state initializer
 * (localStorage is synchronous), so the session is known on the first render without an effect.
 * Invalid or corrupt saved values are cleared.
 */
function readSavedSession(): { token: string | null; user: AdminUser | null } {
  const savedToken = localStorage.getItem('ub_admin_token');
  const savedUserJson = localStorage.getItem('ub_admin_user');

  // No saved session
  if (!savedToken || !savedUserJson) return { token: null, user: null };

  const clear = () => {
    localStorage.removeItem('ub_admin_token');
    localStorage.removeItem('ub_admin_user');
    return { token: null, user: null };
  };

  // Protect against invalid values such as "undefined" or "null"
  if (savedUserJson === 'undefined' || savedUserJson === 'null' || savedUserJson.trim() === '') {
    console.warn('Invalid saved admin session found. Clearing session.');
    return clear();
  }

  try {
    const parsedUser: AdminUser = JSON.parse(savedUserJson);
    // Basic validation
    if (!parsedUser || typeof parsedUser !== 'object') throw new Error('Invalid admin user profile');
    return { token: savedToken, user: parsedUser };
  } catch (err) {
    console.error('Failed to parse saved admin user profile session:', err);
    return clear();
  }
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [initialSession] = useState(readSavedSession);
  const [user, setUser] = useState<AdminUser | null>(initialSession.user);
  const [token, setToken] = useState<string | null>(initialSession.token);
  // Hydration is synchronous, so the session is never "loading" (kept for the context contract).
  const loading = false;

//   const login = async (
//     email: string,
//     password: string
//   ): Promise<void> => {
//     try {
//       const response = await api.post('/admin/login', {
//         email,
//         password,
//       });

//       // console.log('Admin login response:', response.data);
//       console.log(
//   'FULL ADMIN LOGIN RESPONSE:',
//   JSON.stringify(response.data, null, 2)
// );

//       const data = response.data?.data;

//       const accessToken = data?.token;
//       const userProfile = data?.user;

//       // IMPORTANT:
//       // Never save undefined values to localStorage
//       if (!accessToken) {
//         throw new Error('Admin login response does not contain a token.');
//       }

//       // if (!userProfile) {
//       //   console.error(
//       //     'Admin login response is missing user profile:',
//       //     response.data
//       //   );

//       //   throw new Error(
//       //     'Admin login response does not contain a user profile.'
//       //   );
//       // }
      

// console.log(
//   'LOGIN DATA:',
//   JSON.stringify(data, null, 2)
// );


//       // Save valid session
//       localStorage.setItem('ub_admin_token', accessToken);
//       localStorage.setItem(
//         'ub_admin_user',
//         JSON.stringify(userProfile)
//       );

//       setToken(accessToken);
//       setUser(userProfile);
//     } catch (err: any) {
//       const message =
//         err.response?.data?.message ||
//         err.message ||
//         'Admin authentication failed.';

//       throw new Error(message);
//     }
//   };
    const login = async (email: string, password: string): Promise<void> => {
  try {
    const response = await api.post('/admin/login', {
      email,
      password,
    });

    const data = response.data?.data;

    if (!data?.admin || !data?.token) {
      throw new Error('Invalid admin login response from server.');
    }

    const adminProfile: AdminUser = data.admin;
    const accessToken: string = data.token;

    // Save session
    localStorage.setItem('ub_admin_token', accessToken);
    localStorage.setItem(
      'ub_admin_user',
      JSON.stringify(adminProfile)
    );

    // Optional: save refresh token if your frontend will use it
    if (data.refreshToken) {
      localStorage.setItem(
        'ub_admin_refresh_token',
        data.refreshToken
      );
    }

    // Update React state
    setToken(accessToken);
    setUser(adminProfile);


  } catch (caught: unknown) {
    const err = asApiError(caught);
    console.error('Admin login failed:', err);

    const message =
      err.response?.data?.message ||
      err.message ||
      'Admin authentication failed.';

    throw new Error(message, { cause: caught });
  }
};

  // const logout = (): void => {
  //   localStorage.removeItem('ub_admin_token');
  //   localStorage.removeItem('ub_admin_user');

  //   setToken(null);
  //   setUser(null);
  // };
  const logout = (): void => {
  // Revoke the server-side refresh session first (best effort), then clear local state
  revokeAdminSession();
  clearAdminSession();

  setToken(null);
  setUser(null);
};


  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        loading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
