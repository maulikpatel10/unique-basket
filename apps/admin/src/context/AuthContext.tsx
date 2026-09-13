import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../services/api';
import type { AdminUser } from '../types';

interface AuthContextType {
  user: AdminUser | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  // Hydrate session on app mount
  useEffect(() => {
    const savedToken = localStorage.getItem('ub_admin_token');
    const savedUserJson = localStorage.getItem('ub_admin_user');

    // No saved session
    if (!savedToken || !savedUserJson) {
      setLoading(false);
      return;
    }

    // Protect against invalid values such as "undefined" or "null"
    if (
      savedUserJson === 'undefined' ||
      savedUserJson === 'null' ||
      savedUserJson.trim() === ''
    ) {
      console.warn('Invalid saved admin session found. Clearing session.');

      localStorage.removeItem('ub_admin_token');
      localStorage.removeItem('ub_admin_user');

      setToken(null);
      setUser(null);
      setLoading(false);
      return;
    }

    try {
      const parsedUser: AdminUser = JSON.parse(savedUserJson);

      // Basic validation
      if (!parsedUser || typeof parsedUser !== 'object') {
        throw new Error('Invalid admin user profile');
      }

      setToken(savedToken);
      setUser(parsedUser);
    } catch (err) {
      console.error(
        'Failed to parse saved admin user profile session:',
        err
      );

      localStorage.removeItem('ub_admin_token');
      localStorage.removeItem('ub_admin_user');

      setToken(null);
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

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

    console.log('FULL ADMIN LOGIN RESPONSE:', response.data);

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

    console.log('Admin logged in successfully:', adminProfile);

  } catch (err: any) {
    console.error('Admin login failed:', err);

    const message =
      err.response?.data?.message ||
      err.message ||
      'Admin authentication failed.';

    throw new Error(message);
  }
};

  // const logout = (): void => {
  //   localStorage.removeItem('ub_admin_token');
  //   localStorage.removeItem('ub_admin_user');

  //   setToken(null);
  //   setUser(null);
  // };
  const logout = (): void => {
  localStorage.removeItem('ub_admin_token');
  localStorage.removeItem('ub_admin_user');
  localStorage.removeItem('ub_admin_refresh_token');

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

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error(
      'useAuth must be invoked within an AuthProvider context wrapper.'
    );
  }

  return context;
};