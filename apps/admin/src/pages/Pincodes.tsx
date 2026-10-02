import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';
import type { SupportedPincode } from '../types';
import {
  MapPin,
  Plus,
  Search,
  Edit2,
  CheckCircle,
  XCircle,
  AlertTriangle,
  X,
  ShieldAlert,
  RefreshCw,
  Power
} from 'lucide-react';

export const Pincodes: React.FC = () => {
  const { user } = useAuth();
  const isSuperAdmin = user?.role === 'SUPER_ADMIN';

  const [pincodes, setPincodes] = useState<SupportedPincode[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Search & Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');

  // Modal / Drawer states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingPincode, setEditingPincode] = useState<SupportedPincode | null>(null);
  const [confirmModal, setConfirmModal] = useState<{ isOpen: boolean; pincode: SupportedPincode | null }>({
    isOpen: false,
    pincode: null,
  });

  // Toasts
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Form State
  const [formData, setFormData] = useState({
    pincode: '',
    city: 'Rajkot',
    state: 'Gujarat',
    isActive: true,
  });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  const fetchPincodes = async () => {
    try {
      setLoading(true);
      setError(null);
      const res = await api.get('/admin/pincodes');
      setPincodes(res.data.data || []);
    } catch (err: any) {
      console.error('Error fetching supported pincodes:', err);
      const msg = err.response?.data?.message || 'Failed to retrieve delivery pincodes.';
      setError(msg);
      showToast('error', msg);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPincodes();
  }, []);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value,
    }));
    if (formErrors[name]) {
      setFormErrors((prev) => {
        const copy = { ...prev };
        delete copy[name];
        return copy;
      });
    }
  };

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};

    const cleanPin = formData.pincode.trim();
    if (!cleanPin) {
      errors.pincode = 'PIN code is required';
    } else if (!/^\d{6}$/.test(cleanPin)) {
      errors.pincode = 'PIN code must be exactly 6 digits';
    }

    if (!formData.city.trim()) {
      errors.city = 'City is required';
    }

    if (!formData.state.trim()) {
      errors.state = 'State is required';
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const openCreateModal = () => {
    setEditingPincode(null);
    setFormData({
      pincode: '',
      city: 'Rajkot',
      state: 'Gujarat',
      isActive: true,
    });
    setFormErrors({});
    setIsModalOpen(true);
  };

  const openEditModal = (item: SupportedPincode) => {
    setEditingPincode(item);
    setFormData({
      pincode: item.pincode,
      city: item.city,
      state: item.state,
      isActive: item.isActive,
    });
    setFormErrors({});
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingPincode(null);
    setFormErrors({});
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    try {
      setSubmitting(true);
      if (editingPincode) {
        // Update
        const res = await api.put(`/admin/pincodes/${editingPincode.id}`, formData);
        showToast('success', res.data.message || `Pincode ${formData.pincode} updated successfully.`);
      } else {
        // Create
        const res = await api.post('/admin/pincodes', formData);
        showToast('success', res.data.message || `Pincode ${formData.pincode} added successfully.`);
      }
      closeModal();
      fetchPincodes();
    } catch (err: any) {
      console.error('Error saving pincode:', err);
      const msg = err.response?.data?.message || 'Failed to save pincode.';
      showToast('error', msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleStatus = async () => {
    if (!confirmModal.pincode) return;
    const target = confirmModal.pincode;

    try {
      setSubmitting(true);
      const newStatus = !target.isActive;
      const res = await api.patch(`/admin/pincodes/${target.id}/status`, {
        isActive: newStatus,
      });

      showToast(
        'success',
        res.data.message || `Pincode ${target.pincode} ${newStatus ? 'activated' : 'deactivated'} successfully.`
      );
      setConfirmModal({ isOpen: false, pincode: null });
      fetchPincodes();
    } catch (err: any) {
      console.error('Error toggling pincode status:', err);
      const msg = err.response?.data?.message || 'Failed to update pincode status.';
      showToast('error', msg);
    } finally {
      setSubmitting(false);
    }
  };

  // Filtered List
  const filteredPincodes = pincodes.filter((item) => {
    const matchesSearch =
      item.pincode.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.city.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.state.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus =
      statusFilter === 'ALL'
        ? true
        : statusFilter === 'ACTIVE'
        ? item.isActive
        : !item.isActive;

    return matchesSearch && matchesStatus;
  });

  if (!isSuperAdmin) {
    return (
      <div className="max-w-4xl mx-auto space-y-6">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-2.5">
            <MapPin className="h-6 w-6 text-brand-400" />
            <span>Delivery Pincodes</span>
          </h2>
          <p className="text-slate-400 text-sm mt-1">
            Serviceable geographic delivery zones and supported customer areas.
          </p>
        </div>

        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 p-8 shadow-md text-center space-y-4">
          <ShieldAlert className="h-12 w-12 text-amber-400 mx-auto" />
          <h3 className="text-lg font-bold text-white">Access Restricted</h3>
          <p className="text-slate-400 text-xs max-w-md mx-auto leading-relaxed">
            Pincode and serviceability configuration is restricted to Super Administrators only. Store Managers cannot modify deliverable pincodes.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Toast Alert */}
      {toast && (
        <div
          className={`fixed top-4 right-4 z-50 flex items-center gap-3 rounded-lg px-5 py-3 shadow-lg border text-sm font-semibold transition-all duration-300 ${
            toast.type === 'success'
              ? 'bg-emerald-950/90 text-emerald-400 border-emerald-500/30'
              : 'bg-red-950/90 text-red-400 border-red-500/30'
          }`}
        >
          {toast.type === 'success' ? <CheckCircle className="h-5 w-5" /> : <XCircle className="h-5 w-5" />}
          <span>{toast.message}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-2.5">
            <MapPin className="h-6 w-6 text-brand-400" />
            <span>Delivery Pincodes</span>
          </h2>
          <p className="text-slate-400 text-sm mt-1">
            Manage supported delivery postal codes. Deactivating a pincode immediately prevents new orders without code deployments.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={fetchPincodes}
            disabled={loading}
            className="flex items-center gap-2 px-3.5 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 text-xs font-semibold transition-colors disabled:opacity-50"
            title="Refresh List"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            <span>Refresh</span>
          </button>

          <button
            onClick={openCreateModal}
            className="flex items-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white px-4 py-2 text-xs font-bold transition-all shadow-lg shadow-brand-500/20"
          >
            <Plus className="h-4 w-4" />
            <span>Add Pincode</span>
          </button>
        </div>
      </div>

      {/* Search & Filter Toolbar */}
      <div className="flex flex-col sm:flex-row gap-3 bg-darkbg-800 p-4 rounded-xl border border-slate-700/50">
        <div className="relative flex-1">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search by 6-digit pincode, city or state..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-700 rounded-lg text-sm text-slate-200 placeholder-slate-500 focus:border-brand-500 outline-none"
          />
        </div>

        <div className="flex items-center gap-2">
          <div className="relative">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              className="bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-sm text-slate-200 outline-none focus:border-brand-500"
            >
              <option value="ALL">All Statuses</option>
              <option value="ACTIVE">Active Deliverable</option>
              <option value="INACTIVE">Deactivated</option>
            </select>
          </div>
        </div>
      </div>

      {/* Content Table */}
      <div className="bg-darkbg-800 border border-slate-700/50 rounded-xl overflow-hidden shadow-sm">
        {loading ? (
          <div className="p-12 text-center text-slate-400">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-brand-500 border-t-transparent" />
            <p className="mt-2 text-sm font-medium">Loading supported delivery pincodes...</p>
          </div>
        ) : error ? (
          <div className="p-12 text-center text-red-400 space-y-3">
            <AlertTriangle className="h-10 w-10 mx-auto opacity-80" />
            <p className="text-sm font-bold">{error}</p>
            <button
              onClick={fetchPincodes}
              className="px-4 py-1.5 bg-red-900/60 hover:bg-red-900 rounded border border-red-500/40 text-white text-xs font-bold transition-colors"
            >
              Retry
            </button>
          </div>
        ) : filteredPincodes.length === 0 ? (
          <div className="p-12 text-center text-slate-500 space-y-2">
            <MapPin className="h-10 w-10 mx-auto text-slate-600" />
            <p className="text-base font-bold text-slate-300">No supported pincodes found</p>
            <p className="text-xs text-slate-500">
              {searchTerm || statusFilter !== 'ALL'
                ? 'Try adjusting your search query or filter options.'
                : 'Click "Add Pincode" to configure deliverable postal areas.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/70 text-slate-400 uppercase text-[10px] tracking-wider font-bold border-b border-slate-700/60">
                <tr>
                  <th className="px-6 py-3.5">PIN Code</th>
                  <th className="px-6 py-3.5">City & State</th>
                  <th className="px-6 py-3.5">Delivery Status</th>
                  <th className="px-6 py-3.5">Last Updated</th>
                  <th className="px-6 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/40">
                {filteredPincodes.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-750/30 transition-colors">
                    <td className="px-6 py-4 font-mono font-bold text-white text-base">
                      <div className="flex items-center gap-2">
                        <MapPin className={`h-4 w-4 ${item.isActive ? 'text-brand-400' : 'text-slate-600'}`} />
                        <span>{item.pincode}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-xs font-semibold text-slate-300">
                      <div>{item.city}</div>
                      <div className="text-[10px] text-slate-500">{item.state}</div>
                    </td>
                    <td className="px-6 py-4">
                      {item.isActive ? (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                          <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                          Deliverable
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20">
                          <span className="h-1.5 w-1.5 rounded-full bg-rose-400" />
                          Inactive
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-500">
                      {new Date(item.updatedAt || item.createdAt).toLocaleDateString(undefined, {
                        year: 'numeric',
                        month: 'short',
                        day: 'numeric',
                      })}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => openEditModal(item)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-700 transition-colors"
                          title="Edit Pincode"
                        >
                          <Edit2 className="h-4 w-4" />
                        </button>

                        <button
                          onClick={() => setConfirmModal({ isOpen: true, pincode: item })}
                          className={`p-1.5 rounded-lg transition-colors ${
                            item.isActive
                              ? 'text-rose-400 hover:text-rose-300 hover:bg-rose-950/40'
                              : 'text-emerald-400 hover:text-emerald-300 hover:bg-emerald-950/40'
                          }`}
                          title={item.isActive ? 'Deactivate Pincode' : 'Activate Pincode'}
                        >
                          <Power className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Add / Edit Pincode Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
          <div className="bg-darkbg-800 border border-slate-700 rounded-2xl w-full max-w-md p-6 shadow-xl space-y-5 animate-scale-up">
            <div className="flex items-center justify-between border-b border-slate-700/60 pb-3">
              <h3 className="text-base font-bold text-white flex items-center gap-2">
                <MapPin className="h-5 w-5 text-brand-400" />
                <span>{editingPincode ? 'Edit Supported Pincode' : 'Add Supported Pincode'}</span>
              </h3>
              <button
                onClick={closeModal}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-slate-700 transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Pincode Input */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-1.5">
                  PIN Code (6 digits) <span className="text-red-400">*</span>
                </label>
                <input
                  type="text"
                  name="pincode"
                  maxLength={6}
                  required
                  placeholder="e.g. 360001"
                  value={formData.pincode}
                  onChange={handleInputChange}
                  className="w-full rounded-lg bg-slate-900 border border-slate-700 text-white font-mono text-base px-3.5 py-2.5 outline-none focus:border-brand-500"
                />
                {formErrors.pincode && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.pincode}</p>
                )}
              </div>

              {/* City */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-1.5">
                  City <span className="text-red-400">*</span>
                </label>
                <input
                  type="text"
                  name="city"
                  required
                  placeholder="e.g. Rajkot"
                  value={formData.city}
                  onChange={handleInputChange}
                  className="w-full rounded-lg bg-slate-900 border border-slate-700 text-white text-sm px-3.5 py-2.5 outline-none focus:border-brand-500"
                />
                {formErrors.city && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.city}</p>
                )}
              </div>

              {/* State */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-300 mb-1.5">
                  State <span className="text-red-400">*</span>
                </label>
                <input
                  type="text"
                  name="state"
                  required
                  placeholder="e.g. Gujarat"
                  value={formData.state}
                  onChange={handleInputChange}
                  className="w-full rounded-lg bg-slate-900 border border-slate-700 text-white text-sm px-3.5 py-2.5 outline-none focus:border-brand-500"
                />
                {formErrors.state && (
                  <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.state}</p>
                )}
              </div>

              {/* Active Deliverable Toggle */}
              <div className="flex items-center justify-between pt-2 border-t border-slate-700/50">
                <div>
                  <span className="text-xs font-bold text-white uppercase tracking-wide">Deliverable Active</span>
                  <p className="text-[10px] text-slate-400">Enable delivery serviceability for customer addresses.</p>
                </div>
                <input
                  type="checkbox"
                  name="isActive"
                  checked={formData.isActive}
                  onChange={handleInputChange}
                  className="h-4 w-4 rounded border-slate-700 text-brand-500 focus:ring-brand-400 accent-brand-500 cursor-pointer"
                />
              </div>

              {/* Modal Buttons */}
              <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-700/60">
                <button
                  type="button"
                  onClick={closeModal}
                  disabled={submitting}
                  className="px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white text-xs font-bold transition-colors shadow-lg shadow-brand-500/20 disabled:opacity-50"
                >
                  {submitting ? 'Saving...' : editingPincode ? 'Update Pincode' : 'Add Pincode'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Deactivate/Activate Confirmation Modal */}
      {confirmModal.isOpen && confirmModal.pincode && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
          <div className="bg-darkbg-800 border border-slate-700 rounded-2xl w-full max-w-sm p-6 shadow-xl space-y-4 animate-scale-up text-center">
            <AlertTriangle className={`h-12 w-12 mx-auto ${confirmModal.pincode.isActive ? 'text-amber-400' : 'text-emerald-400'}`} />
            <h3 className="text-base font-bold text-white">
              {confirmModal.pincode.isActive ? 'Deactivate Pincode?' : 'Reactivate Pincode?'}
            </h3>
            <p className="text-xs text-slate-400 leading-relaxed">
              {confirmModal.pincode.isActive
                ? `Deactivating ${confirmModal.pincode.pincode} will prevent new orders and address selections for this area. Existing historical orders and customer addresses will remain safely preserved.`
                : `Activating ${confirmModal.pincode.pincode} will allow customers to select and save delivery addresses in this area.`}
            </p>

            <div className="flex items-center justify-center gap-3 pt-2">
              <button
                type="button"
                onClick={() => setConfirmModal({ isOpen: false, pincode: null })}
                disabled={submitting}
                className="px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleToggleStatus}
                disabled={submitting}
                className={`px-5 py-2 rounded-lg text-white text-xs font-bold transition-colors shadow-md ${
                  confirmModal.pincode.isActive
                    ? 'bg-rose-600 hover:bg-rose-700'
                    : 'bg-emerald-600 hover:bg-emerald-700'
                }`}
              >
                {submitting ? 'Processing...' : confirmModal.pincode.isActive ? 'Yes, Deactivate' : 'Yes, Activate'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
