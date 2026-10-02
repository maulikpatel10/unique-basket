import axios, { type InternalAxiosRequestConfig } from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5001/api/v1';

/** localStorage keys for the admin session. */
export const SESSION_KEYS = {
  token: 'ub_admin_token',
  refreshToken: 'ub_admin_refresh_token',
  user: 'ub_admin_user',
} as const;

export const clearAdminSession = (): void => {
  localStorage.removeItem(SESSION_KEYS.token);
  localStorage.removeItem(SESSION_KEYS.refreshToken);
  localStorage.removeItem(SESSION_KEYS.user);
};

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Automatically inject JWT tokens into all outbound requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem(SESSION_KEYS.token);
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Single-flight refresh shared by concurrent 401 responses (P1-09)
let refreshInFlight: Promise<string | null> | null = null;

/**
 * Exchanges the stored refresh token for a new access token.
 * Uses plain axios (not `api`) so the refresh call is never intercepted recursively.
 */
export const refreshAccessToken = (): Promise<string | null> => {
  if (!refreshInFlight) {
    refreshInFlight = (async () => {
      const refreshToken = localStorage.getItem(SESSION_KEYS.refreshToken);
      if (!refreshToken) return null;
      try {
        const res = await axios.post(`${API_BASE_URL}/auth/refresh`, { refreshToken });
        const newToken: unknown = res.data?.data?.token;
        if (typeof newToken === 'string' && newToken) {
          localStorage.setItem(SESSION_KEYS.token, newToken);
          return newToken;
        }
        return null;
      } catch {
        return null;
      }
    })().finally(() => {
      refreshInFlight = null;
    });
  }
  return refreshInFlight;
};

/** Best-effort server-side revocation of the refresh session on logout (backend P1-08). */
export const revokeAdminSession = (): void => {
  const refreshToken = localStorage.getItem(SESSION_KEYS.refreshToken);
  if (!refreshToken) return;
  axios.post(`${API_BASE_URL}/auth/logout`, { refreshToken }).catch(() => undefined);
};

type RetriableConfig = InternalAxiosRequestConfig & { _authRetried?: boolean };

const isAuthEndpoint = (url?: string): boolean =>
  !!url && (url.includes('/admin/login') || url.includes('/auth/refresh'));

// Refresh expired access tokens once, then retry; log out only when refresh fails
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config as RetriableConfig | undefined;
    const status = error.response?.status;

    if (status === 401 && original && !original._authRetried && !isAuthEndpoint(original.url)) {
      original._authRetried = true;
      const newToken = await refreshAccessToken();
      if (newToken) {
        original.headers.Authorization = `Bearer ${newToken}`;
        return api(original);
      }
    }

    if (status === 401 && !isAuthEndpoint(original?.url)) {
      clearAdminSession();
      // Force page refresh to redirect to login route
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);
