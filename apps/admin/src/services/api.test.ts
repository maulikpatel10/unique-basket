import axios, { AxiosError, type AxiosAdapter, type InternalAxiosRequestConfig } from 'axios';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { api, SESSION_KEYS } from './api';

// P1-09: expired access tokens are refreshed once and the request retried.
const respond = (config: InternalAxiosRequestConfig, status: number, data: unknown) => {
  const response = { data, status, statusText: String(status), headers: {}, config };
  if (status >= 400) {
    return Promise.reject(new AxiosError('Request failed', String(status), config, null, response));
  }
  return Promise.resolve(response);
};

describe('admin api session handling', () => {
  let originalAdapter: typeof api.defaults.adapter;

  beforeEach(() => {
    localStorage.clear();
    originalAdapter = api.defaults.adapter;
    window.history.replaceState({}, '', '/admin/orders');
  });

  afterEach(() => {
    api.defaults.adapter = originalAdapter;
    vi.restoreAllMocks();
  });

  it('attaches the stored access token', async () => {
    localStorage.setItem(SESSION_KEYS.token, 'access-1');
    const seen: string[] = [];
    api.defaults.adapter = ((config) => {
      seen.push(String(config.headers.Authorization));
      return respond(config, 200, { ok: true });
    }) as AxiosAdapter;

    await api.get('/admin/orders');
    expect(seen).toEqual(['Bearer access-1']);
  });

  it('refreshes once on 401 and retries the request with the new token', async () => {
    localStorage.setItem(SESSION_KEYS.token, 'expired');
    localStorage.setItem(SESSION_KEYS.refreshToken, 'refresh-1');
    const refreshSpy = vi.spyOn(axios, 'post').mockResolvedValue({ data: { data: { token: 'fresh' } } });

    const seen: string[] = [];
    api.defaults.adapter = ((config) => {
      const auth = String(config.headers.Authorization);
      seen.push(auth);
      return auth === 'Bearer fresh' ? respond(config, 200, { ok: true }) : respond(config, 401, {});
    }) as AxiosAdapter;

    const res = await api.get('/admin/orders');

    expect(res.status).toBe(200);
    expect(seen).toEqual(['Bearer expired', 'Bearer fresh']);
    expect(refreshSpy).toHaveBeenCalledTimes(1);
    expect(refreshSpy.mock.calls[0][1]).toEqual({ refreshToken: 'refresh-1' });
    expect(localStorage.getItem(SESSION_KEYS.token)).toBe('fresh');
  });

  it('shares one refresh call between concurrent 401s', async () => {
    localStorage.setItem(SESSION_KEYS.token, 'expired');
    localStorage.setItem(SESSION_KEYS.refreshToken, 'refresh-1');
    const refreshSpy = vi.spyOn(axios, 'post').mockResolvedValue({ data: { data: { token: 'fresh' } } });
    api.defaults.adapter = ((config) =>
      String(config.headers.Authorization) === 'Bearer fresh'
        ? respond(config, 200, { ok: true })
        : respond(config, 401, {})) as AxiosAdapter;

    await Promise.all([api.get('/a'), api.get('/b'), api.get('/c')]);
    expect(refreshSpy).toHaveBeenCalledTimes(1);
  });

  it('clears the session when the refresh token is rejected', async () => {
    localStorage.setItem(SESSION_KEYS.token, 'expired');
    localStorage.setItem(SESSION_KEYS.refreshToken, 'revoked');
    localStorage.setItem(SESSION_KEYS.user, '{"id":"a"}');
    vi.spyOn(axios, 'post').mockRejectedValue(new Error('401'));
    api.defaults.adapter = ((config) => respond(config, 401, {})) as AxiosAdapter;

    await expect(api.get('/admin/orders')).rejects.toBeTruthy();
    expect(localStorage.getItem(SESSION_KEYS.token)).toBeNull();
    expect(localStorage.getItem(SESSION_KEYS.refreshToken)).toBeNull();
    expect(localStorage.getItem(SESSION_KEYS.user)).toBeNull();
  });

  it('does not try to refresh on a failed login', async () => {
    const refreshSpy = vi.spyOn(axios, 'post');
    api.defaults.adapter = ((config) => respond(config, 401, {})) as AxiosAdapter;

    await expect(api.post('/admin/login', { email: 'a', password: 'b' })).rejects.toBeTruthy();
    expect(refreshSpy).not.toHaveBeenCalled();
  });
});
