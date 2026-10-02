import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { AuthProvider } from '../context/AuthContext';
import { SESSION_KEYS } from '../services/api';
import { PrivateRoute } from './PrivateRoute';

// P1-19: route guard behaviour for admin roles.
(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;

describe('PrivateRoute', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    localStorage.clear();
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    act(() => root.unmount());
    container.remove();
  });

  const renderAt = (path: string, allowedRoles?: string[]) =>
    act(() => {
      root.render(
        <AuthProvider>
          <MemoryRouter initialEntries={[path]}>
            <Routes>
              <Route path="/login" element={<p>LOGIN PAGE</p>} />
              <Route path="/admin/dashboard" element={<p>DASHBOARD</p>} />
              <Route
                path="/admin/managers"
                element={
                  <PrivateRoute allowedRoles={allowedRoles}>
                    <p>MANAGERS PAGE</p>
                  </PrivateRoute>
                }
              />
            </Routes>
          </MemoryRouter>
        </AuthProvider>
      );
    });

  const signIn = (role: string) => {
    localStorage.setItem(SESSION_KEYS.token, 'token');
    localStorage.setItem(SESSION_KEYS.user, JSON.stringify({ id: 'u1', email: 'a@b.c', name: 'A', role }));
  };

  it('redirects to /login without a session', async () => {
    await renderAt('/admin/managers', ['SUPER_ADMIN']);
    expect(container.textContent).toContain('LOGIN PAGE');
  });

  it('renders the page for an allowed role', async () => {
    signIn('SUPER_ADMIN');
    await renderAt('/admin/managers', ['SUPER_ADMIN']);
    expect(container.textContent).toContain('MANAGERS PAGE');
  });

  it('sends a disallowed role to the dashboard', async () => {
    signIn('STORE_MANAGER');
    await renderAt('/admin/managers', ['SUPER_ADMIN']);
    expect(container.textContent).toContain('DASHBOARD');
    expect(container.textContent).not.toContain('MANAGERS PAGE');
  });
});
