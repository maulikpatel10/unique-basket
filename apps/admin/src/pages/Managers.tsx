import React, { useState, useEffect } from 'react';
import { Pagination } from '../components/Pagination';
import { ADMIN_PAGE_SIZE, emptyPagination, type PaginationMeta } from '../utils/pagination';
import { useDebouncedValue } from '../hooks/useDebouncedValue';
import { useNavigate } from 'react-router-dom';
import { api } from '../services/api';
import type { Store } from '../types';
import {
  Plus,
  Search,
  Filter,
  Eye,
  Edit2,
  CheckCircle,
  XCircle,
  AlertTriangle,
  X,
  User,
  Mail,
  Shield,
  Key
} from 'lucide-react';
import { asApiError } from '../utils/apiError';

interface ManagerListItem {
  id: string;
  name: string;
  email: string;
  role: string;
  isActive: boolean;
  createdAt: string;
  storeId: string | null;
  storeIdString: string | null;
  storeName: string | null;
}

export const Managers: React.FC = () => {
  const navigate = useNavigate();
  const [managers, setManagers] = useState<ManagerListItem[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Search & Filter controls
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearch = useDebouncedValue(searchTerm.trim());
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState<PaginationMeta>(emptyPagination);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');
  const [storeFilter, setStoreFilter] = useState('ALL');

  // Drawer / Modal state
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingManager, setEditingManager] = useState<ManagerListItem | null>(null);
  const [confirmModal, setConfirmModal] = useState<{ isOpen: boolean; manager: ManagerListItem | null }>({
    isOpen: false,
    manager: null,
  });

  // Toast alerts state
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Form states
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    storeId: '',
    isActive: true,
  });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Parallel fetch of store managers and stores list
      const params: Record<string, unknown> = { page, limit: ADMIN_PAGE_SIZE };
      if (debouncedSearch) params.search = debouncedSearch;
      if (statusFilter !== 'ALL') params.isActive = statusFilter === 'ACTIVE' ? 'true' : 'false';
      if (storeFilter !== 'ALL') params.storeId = storeFilter;
      const [managersRes, storesRes] = await Promise.all([
        api.get('/admin/managers', { params }),
        api.get('/stores'),
      ]);

      setManagers(managersRes.data.data.managers);
      setPagination(managersRes.data.data.pagination);
      setStores(storesRes.data.data);
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error fetching manager details:', err);
      setError('Failed to retrieve store managers catalog. Please refresh.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page, debouncedSearch, statusFilter, storeFilter]);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (formErrors[name]) {
      setFormErrors((prev) => {
        const copy = { ...prev };
        delete copy[name];
        return copy;
      });
    }
  };

  const validateForm = () => {
    const errors: Record<string, string> = {};
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!formData.name.trim()) errors.name = 'Manager Name is required';
    
    if (!formData.email.trim()) {
      errors.email = 'Email Address is required';
    } else if (!emailRegex.test(formData.email)) {
      errors.email = 'Please enter a valid email format';
    }

    if (!editingManager && !formData.password) {
      errors.password = 'Initial login password is required';
    } else if (formData.password && formData.password.length < 6) {
      errors.password = 'Password must be at least 6 characters';
    }

    if (!formData.storeId) {
      errors.storeId = 'Store assignment is required';
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleOpenCreateDrawer = () => {
    setEditingManager(null);
    setFormData({
      name: '',
      email: '',
      password: '',
      storeId: stores[0]?.id || '',
      isActive: true,
    });
    setFormErrors({});
    setIsDrawerOpen(true);
  };

  const handleOpenEditDrawer = (manager: ManagerListItem) => {
    setEditingManager(manager);
    setFormData({
      name: manager.name,
      email: manager.email,
      password: '',
      storeId: manager.storeId || '',
      isActive: manager.isActive,
    });
    setFormErrors({});
    setIsDrawerOpen(true);
  };

  const handleSaveManager = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setSubmitting(true);
    try {
      if (editingManager) {
        // Edit update
        await api.put(`/admin/managers/${editingManager.id}`, {
          name: formData.name,
          email: formData.email,
          password: formData.password || undefined,
          storeId: formData.storeId,
          isActive: formData.isActive,
        });
        showToast('success', 'Store Manager updated successfully.');
      } else {
        // Create new
        await api.post('/admin/managers', {
          name: formData.name,
          email: formData.email,
          password: formData.password,
          storeId: formData.storeId,
          isActive: formData.isActive,
        });
        showToast('success', 'New Store Manager created successfully.');
      }
      setIsDrawerOpen(false);
      fetchData();
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error saving manager:', err);
      const msg = err.response?.data?.message || 'Failed to save store manager profile.';
      showToast('error', msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleStatus = async (manager: ManagerListItem) => {
    if (manager.isActive) {
      setConfirmModal({ isOpen: true, manager });
    } else {
      try {
        await api.put(`/admin/managers/${manager.id}`, { isActive: true });
        showToast('success', `Manager ${manager.name} activated successfully.`);
        fetchData();
      } catch {
        showToast('error', 'Failed to activate manager.');
      }
    }
  };

  const handleConfirmDeactivate = async () => {
    const manager = confirmModal.manager;
    if (!manager) return;

    try {
      await api.put(`/admin/managers/${manager.id}`, { isActive: false });
      showToast('success', `Manager ${manager.name} deactivated successfully.`);
      setConfirmModal({ isOpen: false, manager: null });
      fetchData();
    } catch {
      showToast('error', 'Failed to deactivate manager.');
    }
  };

  // Filter search outcomes
  const filteredManagers = managers;

  return (
    <div className="relative space-y-6">
      {/* Toast Alert popups */}
      {toast && (
        <div
          className={`fixed top-4 right-4 z-50 flex items-center gap-3 rounded-lg px-5 py-3 shadow-lg border text-sm font-semibold transition-all duration-300 animate-slide-in ${
            toast.type === 'success'
              ? 'bg-emerald-950/90 text-emerald-400 border-emerald-500/30 shadow-emerald-950/20'
              : 'bg-red-950/90 text-red-400 border-red-500/30 shadow-red-950/20'
          }`}
        >
          {toast.type === 'success' ? <CheckCircle className="h-5 w-5" /> : <XCircle className="h-5 w-5" />}
          <span>{toast.message}</span>
        </div>
      )}

      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white">Store Managers Allocation</h2>
          <p className="text-slate-400 text-sm mt-1">Register branch administrators and configure store access bindings.</p>
        </div>
        <button
          onClick={handleOpenCreateDrawer}
          className="flex items-center justify-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white px-4 py-2.5 text-sm font-bold shadow-lg shadow-brand-500/20 hover:shadow-brand-500/30 transition-all duration-200"
        >
          <Plus className="h-4.5 w-4.5" />
          Register Store Manager
        </button>
      </div>

      {/* Filters & Search controls */}
      <div className="flex flex-col md:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <div className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
            <Search className="h-4 w-4" />
          </span>
          <input
            type="text"
            placeholder="Search managers by name or email..."
            value={searchTerm}
            onChange={(e) => { setSearchTerm(e.target.value); setPage(1); }}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 outline-none transition-all duration-150"
          />
        </div>

        <div className="flex flex-wrap gap-4 items-center">
          <div className="flex items-center gap-2">
            <Filter className="h-4 w-4 text-slate-400" />
            <span className="text-xs text-slate-400 uppercase font-semibold tracking-wider">Status:</span>
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value as typeof statusFilter); setPage(1); }}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Statuses</option>
              <option value="ACTIVE">Active Only</option>
              <option value="INACTIVE">Inactive Only</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-400 uppercase font-semibold tracking-wider">Store:</span>
            <select
              value={storeFilter}
              onChange={(e) => { setStoreFilter(e.target.value); setPage(1); }}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              <option value="ALL">All Stores</option>
              {stores.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name} ({s.storeId})
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Managers Table List */}
      {loading ? (
        <div className="space-y-4">
          <div className="h-10 bg-slate-800 rounded-lg animate-pulse"></div>
          {[1, 2].map((i) => (
            <div key={i} className="h-16 bg-slate-800/65 rounded-lg animate-pulse"></div>
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-red-400 text-sm font-semibold">{error}</p>
          <button
            onClick={fetchData}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Try Again
          </button>
        </div>
      ) : filteredManagers.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-slate-400 text-sm">No registered store managers match your search criteria.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-6 py-4">Manager Name</th>
                  <th className="px-6 py-4">Email</th>
                  <th className="px-6 py-4">Assigned Store ID</th>
                  <th className="px-6 py-4">Assigned Store Name</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4">Registered Date</th>
                  <th className="px-6 py-4 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {filteredManagers.map((manager) => (
                  <tr key={manager.id} className="hover:bg-slate-800/10">
                    <td className="px-6 py-4 font-bold text-white tracking-wide">{manager.name}</td>
                    <td className="px-6 py-4 text-slate-300">{manager.email}</td>
                    <td className="px-6 py-4 font-mono font-semibold text-slate-200">
                      {manager.storeIdString || <span className="text-red-400">UNASSIGNED</span>}
                    </td>
                    <td className="px-6 py-4 text-slate-400">{manager.storeName || '—'}</td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => handleToggleStatus(manager)}
                        className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border transition-all duration-200 hover:scale-[1.02] ${
                          manager.isActive
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/25'
                            : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/25'
                        }`}
                      >
                        {manager.isActive ? 'ACTIVE' : 'INACTIVE'}
                      </button>
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-400">
                      {new Date(manager.createdAt).toLocaleDateString('en-IN', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-center gap-3">
                        <button
                          onClick={() => navigate(`/admin/managers/${manager.id}`)}
                          title="View Details"
                          className="rounded p-1.5 text-slate-400 hover:bg-slate-700 hover:text-brand-400 transition-all duration-150"
                        >
                          <Eye className="h-4.5 w-4.5" />
                        </button>
                        <button
                          onClick={() => handleOpenEditDrawer(manager)}
                          title="Edit Settings"
                          className="rounded p-1.5 text-slate-400 hover:bg-slate-700 hover:text-amber-400 transition-all duration-150"
                        >
                          <Edit2 className="h-4.5 w-4.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pagination pagination={pagination} itemLabel="managers" onPageChange={setPage} />
        </div>
      )}

      {/* Slide-over Side Drawer for Add/Edit Store Manager */}
      {isDrawerOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          {/* Backdrop */}
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setIsDrawerOpen(false)} />

          {/* Drawer Panel */}
          <div className="relative flex w-full max-w-lg flex-col bg-darkbg-800 border-l border-slate-700 text-slate-200 shadow-2xl p-6 overflow-y-auto animate-slide-in">
            <div className="flex items-center justify-between border-b border-slate-700 pb-4 mb-6">
              <h3 className="text-lg font-bold text-white">
                {editingManager ? `Edit Profile: ${editingManager.name}` : 'Register Store Manager'}
              </h3>
              <button
                onClick={() => setIsDrawerOpen(false)}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-700 hover:text-white"
              >
                <X className="h-5.5 w-5.5" />
              </button>
            </div>

            <form onSubmit={handleSaveManager} className="space-y-5">
              {/* Name */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Manager Name <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <User className="h-4 w-4" />
                  </span>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="Rahul Sharma"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.name && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.name}</p>}
              </div>

              {/* Email */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Email Address <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Mail className="h-4 w-4" />
                  </span>
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    placeholder="rahul@uniquebasket.com"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.email && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.email}</p>}
              </div>

              {/* Password */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Password {editingManager ? '(Leave blank to keep unchanged)' : <span className="text-red-500">*</span>}
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Key className="h-4 w-4" />
                  </span>
                  <input
                    type="password"
                    name="password"
                    value={formData.password}
                    onChange={handleInputChange}
                    placeholder={editingManager ? '••••••••' : 'Password must be at least 6 characters'}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.password && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.password}</p>}
              </div>

              {/* Store Assignment select */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Assigned Store Outlet <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Shield className="h-4 w-4" />
                  </span>
                  <select
                    name="storeId"
                    value={formData.storeId}
                    onChange={handleInputChange}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  >
                    <option value="" disabled>Select Store Outlet...</option>
                    {stores.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.name} ({s.storeId})
                      </option>
                    ))}
                  </select>
                </div>
                {formErrors.storeId && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.storeId}</p>}
              </div>

              {/* Submit Buttons */}
              <div className="flex items-center gap-4 pt-6 border-t border-slate-700 mt-6">
                <button
                  type="button"
                  onClick={() => setIsDrawerOpen(false)}
                  className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-3 text-sm font-bold transition-all duration-150"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="flex-1 flex items-center justify-center rounded-lg bg-brand-500 hover:bg-brand-600 text-white py-3 text-sm font-bold shadow-lg shadow-brand-500/10 transition-all duration-150 disabled:opacity-50"
                >
                  {submitting ? (
                    <div className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                  ) : editingManager ? (
                    'Save Profile'
                  ) : (
                    'Register Account'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Dialog Modal for Deactivation */}
      {confirmModal.isOpen && confirmModal.manager && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          {/* Backdrop */}
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setConfirmModal({ isOpen: false, manager: null })} />

          {/* Modal Container */}
          <div className="relative w-full max-w-md rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl animate-scale-in">
            <div className="flex items-center gap-3.5 text-amber-500 mb-4">
              <AlertTriangle className="h-8 w-8" />
              <div>
                <h4 className="text-md font-extrabold text-white">Deactivate Store Manager?</h4>
                <p className="text-[10px] text-brand-400 font-semibold tracking-wider uppercase">Confirm Access Revoke</p>
              </div>
            </div>

            <p className="text-slate-300 text-xs leading-relaxed mb-6">
              Are you sure you want to deactivate <strong className="text-white">{confirmModal.manager.name}</strong>? 
              Deactivated managers will be blocked from logging in immediately, and their active auth sessions will be rejected by the server access gates. Action details and logs remain intact.
            </p>

            <div className="flex gap-4">
              <button
                onClick={() => setConfirmModal({ isOpen: false, manager: null })}
                className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2.5 text-xs font-bold transition-all duration-150"
              >
                No, Keep Active
              </button>
              <button
                onClick={handleConfirmDeactivate}
                className="flex-1 rounded-lg bg-red-500 hover:bg-red-650 text-white py-2.5 text-xs font-bold transition-all duration-150 shadow-md shadow-red-950/20"
              >
                Yes, Deactivate
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
