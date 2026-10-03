import React, { useState } from 'react';
import { Pagination } from '../components/Pagination';
import { ADMIN_PAGE_SIZE, emptyPagination, type PaginationMeta } from '../utils/pagination';
import { useDebouncedValue } from '../hooks/useDebouncedValue';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/authContextStore';
import { api } from '../services/api';
import { useLoader } from '../hooks/useLoader';
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
  X
} from 'lucide-react';
import { asApiError } from '../utils/apiError';

export const Stores: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [stores, setStores] = useState<Store[]>([]);

  // Search & Filter state
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearch = useDebouncedValue(searchTerm.trim());
  const [page, setPage] = useState(1);
  const [cityOptions, setCityOptions] = useState<string[]>([]);
  const [pagination, setPagination] = useState<PaginationMeta>(emptyPagination);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');
  const [cityFilter, setCityFilter] = useState('ALL');

  // Modal / Drawer state
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingStore, setEditingStore] = useState<Store | null>(null);
  const [confirmModal, setConfirmModal] = useState<{ isOpen: boolean; store: Store | null }>({
    isOpen: false,
    store: null,
  });

  // Toast notification state
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Form inputs state
  const [formData, setFormData] = useState({
    storeId: '',
    name: '',
    address: '',
    city: '',
    state: '',
    pincode: '',
    latitude: '',
    longitude: '',
    deliveryRadiusKm: '10',
    phone: '',
    email: '',
    openingTime: '08:00',
    closingTime: '22:00',
    isActive: true,
  });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  const loadStores = async () => {
    const params: Record<string, unknown> = { page, limit: ADMIN_PAGE_SIZE };
    if (debouncedSearch) params.search = debouncedSearch;
    if (statusFilter !== 'ALL') params.isActive = statusFilter === 'ACTIVE' ? 'true' : 'false';
    if (cityFilter !== 'ALL') params.city = cityFilter;
    const res = await api.get('/admin/stores', { params });
    setStores(res.data.data.stores);
    setPagination(res.data.data.pagination);
    setCityOptions(res.data.data.cities ?? []);
  };

  // useLoader: loading/error derived from the latest request (no setState inside effects)
  const { loading, error, reload: fetchStores } = useLoader(loadStores, [page, debouncedSearch, statusFilter, cityFilter], {
    errorMessage: (caught) =>
      asApiError(caught).response?.status === 403
        ? 'You do not have permission to view stores.'
        : 'Failed to retrieve stores. Please refresh.',
  });

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  // Unique city list extraction
  const cities = ['ALL', ...cityOptions];

  // Input Change handler
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
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

  // Form validation rules
  const validateForm = () => {
    const errors: Record<string, string> = {};
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const phoneRegex = /^\+?[1-9]\d{1,14}$/; // E.164 compliance
    const numericRegex = /^-?\d+(\.\d+)?$/;

    if (!editingStore && !formData.storeId) {
      errors.storeId = 'Store ID is required (e.g. STORE-001)';
    } else if (!editingStore && !/^STORE-\d+$/.test(formData.storeId)) {
      errors.storeId = 'Format must match: STORE-XXX (digits)';
    }

    if (!formData.name) errors.name = 'Store Name is required';
    if (!formData.address) errors.address = 'Street Address is required';
    if (!formData.city) errors.city = 'City is required';
    if (!formData.state) errors.state = 'State is required';
    
    if (!formData.pincode) {
      errors.pincode = 'Pincode is required';
    } else if (!/^\d{6}$/.test(formData.pincode)) {
      errors.pincode = 'Pincode must be exactly 6 digits';
    }

    if (!formData.phone) {
      errors.phone = 'Phone number is required';
    } else if (!phoneRegex.test(formData.phone.replace(/[\s-()]/g, ''))) {
      errors.phone = 'Please enter a valid phone number';
    }

    if (formData.email && !emailRegex.test(formData.email)) {
      errors.email = 'Please enter a valid email format';
    }

    if (!formData.latitude || !numericRegex.test(formData.latitude)) {
      errors.latitude = 'Valid numerical latitude is required';
    } else {
      const latVal = parseFloat(formData.latitude);
      if (latVal < -90 || latVal > 90) errors.latitude = 'Latitude must be between -90 and 90';
    }

    if (!formData.longitude || !numericRegex.test(formData.longitude)) {
      errors.longitude = 'Valid numerical longitude is required';
    } else {
      const lngVal = parseFloat(formData.longitude);
      if (lngVal < -180 || lngVal > 180) errors.longitude = 'Longitude must be between -180 and 180';
    }

    if (!formData.deliveryRadiusKm || !numericRegex.test(formData.deliveryRadiusKm)) {
      errors.deliveryRadiusKm = 'Numerical radius value is required';
    } else {
      const rad = parseFloat(formData.deliveryRadiusKm);
      if (rad <= 0) errors.deliveryRadiusKm = 'Radius must be greater than 0';
    }

    if (!formData.openingTime) errors.openingTime = 'Opening time required';
    if (!formData.closingTime) errors.closingTime = 'Closing time required';

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleOpenCreateDrawer = () => {
    setEditingStore(null);
    setFormData({
      storeId: '',
      name: '',
      address: '',
      city: '',
      state: '',
      pincode: '',
      latitude: '',
      longitude: '',
      deliveryRadiusKm: '10',
      phone: '',
      email: '',
      openingTime: '08:00',
      closingTime: '22:00',
      isActive: true,
    });
    setFormErrors({});
    setIsDrawerOpen(true);
  };

  const handleOpenEditDrawer = (store: Store) => {
    setEditingStore(store);
    setFormData({
      storeId: store.storeId,
      name: store.name,
      address: store.address,
      city: store.city,
      state: store.state,
      pincode: store.pincode,
      latitude: String(store.latitude),
      longitude: String(store.longitude),
      deliveryRadiusKm: String(store.deliveryRadiusKm),
      phone: store.phone,
      email: store.email || '',
      openingTime: store.openingTime,
      closingTime: store.closingTime,
      isActive: store.isActive,
    });
    setFormErrors({});
    setIsDrawerOpen(true);
  };

  const handleSaveStore = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setSubmitting(true);
    try {
      if (editingStore) {
        // Edit update
        await api.put(`/admin/stores/${editingStore.id}`, {
          name: formData.name,
          address: formData.address,
          city: formData.city,
          state: formData.state,
          pincode: formData.pincode,
          latitude: formData.latitude,
          longitude: formData.longitude,
          deliveryRadiusKm: formData.deliveryRadiusKm,
          phone: formData.phone,
          email: formData.email || null,
          openingTime: formData.openingTime,
          closingTime: formData.closingTime,
        });
        showToast('success', 'Store branch updated successfully.');
      } else {
        // Create new
        await api.post('/admin/stores', {
          storeId: formData.storeId,
          name: formData.name,
          address: formData.address,
          city: formData.city,
          state: formData.state,
          pincode: formData.pincode,
          latitude: formData.latitude,
          longitude: formData.longitude,
          deliveryRadiusKm: formData.deliveryRadiusKm,
          phone: formData.phone,
          email: formData.email || null,
          openingTime: formData.openingTime,
          closingTime: formData.closingTime,
        });
        showToast('success', 'New store outlet created successfully.');
      }
      setIsDrawerOpen(false);
      fetchStores();
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error saving store:', err);
      const errorCode = err.response?.data?.errorCode;
      let msg = err.response?.data?.message || 'Failed to save store configurations.';
      if (errorCode === 'DUPLICATE_STORE_ID') {
        msg = 'Store ID already exists. Please use a different Store ID.';
      }
      showToast('error', msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleStatus = async (store: Store) => {
    if (user?.role !== 'SUPER_ADMIN') {
      showToast('error', 'You do not have permission for this action.');
      return;
    }

    // If activating, activate directly. If deactivating, confirm first.
    if (store.isActive) {
      setConfirmModal({ isOpen: true, store });
    } else {
      try {
        await api.put(`/admin/stores/${store.id}`, { isActive: true });
        showToast('success', `Store ${store.storeId} activated successfully.`);
        fetchStores();
      } catch {
        showToast('error', 'Failed to activate store.');
      }
    }
  };

  const handleConfirmDeactivate = async () => {
    if (user?.role !== 'SUPER_ADMIN') {
      showToast('error', 'You do not have permission to deactivate stores.');
      setConfirmModal({ isOpen: false, store: null });
      return;
    }
    const store = confirmModal.store;
    if (!store) return;

    try {
      await api.delete(`/admin/stores/${store.id}`);
      showToast('success', `Store ${store.storeId} deactivated successfully.`);
      setConfirmModal({ isOpen: false, store: null });
      fetchStores();
    } catch {
      showToast('error', 'Failed to deactivate store.');
    }
  };

  // Filtering search outcomes
  const filteredStores = stores;

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
          <h2 className="text-2xl font-bold text-white">Store Outlets Management</h2>
          <p className="text-slate-400 text-sm mt-1">Configure and adjust active branches, locations, and delivery boundaries.</p>
        </div>
        {user?.role === 'SUPER_ADMIN' && (
          <button
            onClick={handleOpenCreateDrawer}
            className="flex items-center justify-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white px-4 py-2.5 text-sm font-bold shadow-lg shadow-brand-500/20 hover:shadow-brand-500/30 transition-all duration-200"
          >
            <Plus className="h-4.5 w-4.5" />
            Create New Store
          </button>
        )}
      </div>

      {/* Search and Filters Controls */}
      <div className="flex flex-col md:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <div className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
            <Search className="h-4 w-4" />
          </span>
          <input
            type="text"
            placeholder="Search stores by ID, name, or pincode..."
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
              <option value="ACTIVE">Active</option>
              <option value="INACTIVE">Inactive</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-400 uppercase font-semibold tracking-wider">City:</span>
            <select
              value={cityFilter}
              onChange={(e) => { setCityFilter(e.target.value); setPage(1); }}
              className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
            >
              {cities.map((city) => (
                <option key={city} value={city}>
                  {city === 'ALL' ? 'All Cities' : city}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Main Stores Table List */}
      {loading ? (
        <div className="space-y-4">
          <div className="h-10 bg-slate-800 rounded-lg animate-pulse"></div>
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-16 bg-slate-800/65 rounded-lg animate-pulse"></div>
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-red-400 text-sm font-semibold">{error}</p>
          <button
            onClick={fetchStores}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-600 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Try Again
          </button>
        </div>
      ) : filteredStores.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-slate-400 text-sm">No registered stores match your filter criteria.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-6 py-4">Store ID</th>
                  <th className="px-6 py-4">Store Name</th>
                  <th className="px-6 py-4">City</th>
                  <th className="px-6 py-4">Pincode</th>
                  <th className="px-6 py-4">Phone</th>
                  <th className="px-6 py-4">Radius</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4">Created At</th>
                  <th className="px-6 py-4 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {filteredStores.map((store) => (
                  <tr key={store.id} className="hover:bg-slate-800/10">
                    <td className="px-6 py-4 font-bold text-white tracking-wide">{store.storeId}</td>
                    <td className="px-6 py-4 font-semibold text-slate-200">{store.name}</td>
                    <td className="px-6 py-4">{store.city}</td>
                    <td className="px-6 py-4 font-mono">{store.pincode}</td>
                    <td className="px-6 py-4 text-slate-400">{store.phone}</td>
                    <td className="px-6 py-4 font-semibold text-white">{Number(store.deliveryRadiusKm)} km</td>
                    <td className="px-6 py-4">
                      {user?.role === 'SUPER_ADMIN' ? (
                        <button
                          onClick={() => handleToggleStatus(store)}
                          title={store.isActive ? 'Click to deactivate store' : 'Click to activate store'}
                          className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border transition-all duration-200 hover:scale-[1.02] cursor-pointer ${
                            store.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/25'
                              : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/25'
                          }`}
                        >
                          {store.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </button>
                      ) : (
                        <span
                          className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border ${
                            store.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                              : 'bg-red-500/10 text-red-400 border-red-500/20'
                          }`}
                        >
                          {store.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-400">
                      {new Date(store.createdAt).toLocaleDateString('en-IN', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-center gap-3">
                        <button
                          onClick={() => navigate(`/admin/stores/${store.id}`)}
                          title="View Details"
                          className="rounded p-1.5 text-slate-400 hover:bg-slate-700 hover:text-brand-400 transition-all duration-150"
                        >
                          <Eye className="h-4.5 w-4.5" />
                        </button>
                        {user?.role === 'SUPER_ADMIN' && (
                          <button
                            onClick={() => handleOpenEditDrawer(store)}
                            title="Edit Settings"
                            className="rounded p-1.5 text-slate-400 hover:bg-slate-700 hover:text-amber-400 transition-all duration-150"
                          >
                            <Edit2 className="h-4.5 w-4.5" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pagination pagination={pagination} itemLabel="stores" onPageChange={setPage} />
        </div>
      )}

      {/* Slide-over Side Drawer for Add/Edit Store */}
      {isDrawerOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          {/* Backdrop */}
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setIsDrawerOpen(false)} />

          {/* Drawer Panel */}
          <div className="relative flex w-full max-w-lg flex-col bg-darkbg-800 border-l border-slate-700 text-slate-200 shadow-2xl p-6 overflow-y-auto animate-slide-in">
            <div className="flex items-center justify-between border-b border-slate-700 pb-4 mb-6">
              <h3 className="text-lg font-bold text-white">
                {editingStore ? `Edit Store: ${editingStore.storeId}` : 'Create New Store Branch'}
              </h3>
              <button
                onClick={() => setIsDrawerOpen(false)}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-700 hover:text-white"
              >
                <X className="h-5.5 w-5.5" />
              </button>
            </div>

            <form onSubmit={handleSaveStore} className="space-y-4">
              {/* Store ID input (Create Only) */}
              {!editingStore && (
                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Store ID <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="storeId"
                    value={formData.storeId}
                    onChange={handleInputChange}
                    placeholder="STORE-004"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                  {formErrors.storeId && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.storeId}</p>}
                </div>
              )}

              {/* Name */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Store Name <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleInputChange}
                  placeholder="North Bangalore Outlet"
                  className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                />
                {formErrors.name && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.name}</p>}
              </div>

              {/* Address */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Street Address <span className="text-red-500">*</span>
                </label>
                <textarea
                  name="address"
                  value={formData.address}
                  onChange={handleInputChange}
                  placeholder="Door No, building name, landmark address..."
                  rows={2}
                  className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-4 py-2.5 text-sm focus:border-brand-500 outline-none resize-none"
                />
                {formErrors.address && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.address}</p>}
              </div>

              {/* Location details row */}
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    City <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="city"
                    value={formData.city}
                    onChange={handleInputChange}
                    placeholder="Bangalore"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                  {formErrors.city && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.city}</p>}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    State <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="state"
                    value={formData.state}
                    onChange={handleInputChange}
                    placeholder="Karnataka"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                  {formErrors.state && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.state}</p>}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Pincode <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="pincode"
                    value={formData.pincode}
                    onChange={handleInputChange}
                    placeholder="560001"
                    maxLength={6}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2.5 text-sm focus:border-brand-500 outline-none font-mono"
                  />
                  {formErrors.pincode && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.pincode}</p>}
                </div>
              </div>

              {/* Coordinates row */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Latitude <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="latitude"
                    value={formData.latitude}
                    onChange={handleInputChange}
                    placeholder="12.971598"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-4 py-2.5 text-sm focus:border-brand-500 outline-none font-mono"
                  />
                  {formErrors.latitude && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.latitude}</p>}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Longitude <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="longitude"
                    value={formData.longitude}
                    onChange={handleInputChange}
                    placeholder="77.594562"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-4 py-2.5 text-sm focus:border-brand-500 outline-none font-mono"
                  />
                  {formErrors.longitude && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.longitude}</p>}
                </div>
              </div>

              {/* Contacts row */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Phone <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="phone"
                    value={formData.phone}
                    onChange={handleInputChange}
                    placeholder="+919876543210"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                  {formErrors.phone && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.phone}</p>}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Email Address
                  </label>
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    placeholder="store001@uniquebasket.com"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                  {formErrors.email && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.email}</p>}
                </div>
              </div>

              {/* Delivery Radius & Timings row */}
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Radius (KM) <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    name="deliveryRadiusKm"
                    value={formData.deliveryRadiusKm}
                    onChange={handleInputChange}
                    placeholder="10.0"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2.5 text-sm focus:border-brand-500 outline-none font-mono"
                  />
                  {formErrors.deliveryRadiusKm && (
                    <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.deliveryRadiusKm}</p>
                  )}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Opens At <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="time"
                    name="openingTime"
                    value={formData.openingTime}
                    onChange={handleInputChange}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                  {formErrors.openingTime && (
                    <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.openingTime}</p>
                  )}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                    Closes At <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="time"
                    name="closingTime"
                    value={formData.closingTime}
                    onChange={handleInputChange}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                  {formErrors.closingTime && (
                    <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.closingTime}</p>
                  )}
                </div>
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
                  ) : editingStore ? (
                    'Save Changes'
                  ) : (
                    'Create Store'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Dialog Modal for Deactivation */}
      {confirmModal.isOpen && confirmModal.store && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          {/* Backdrop */}
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setConfirmModal({ isOpen: false, store: null })} />

          {/* Modal Container */}
          <div className="relative w-full max-w-md rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl animate-scale-in">
            <div className="flex items-center gap-3.5 text-amber-500 mb-4">
              <AlertTriangle className="h-8 w-8" />
              <div>
                <h4 className="text-md font-extrabold text-white">Deactivate Store Branch?</h4>
                <p className="text-[10px] text-brand-400 font-semibold tracking-wider uppercase">Confirm Store Exclusion</p>
              </div>
            </div>

            <p className="text-slate-300 text-xs leading-relaxed mb-6">
              Are you sure you want to deactivate <strong className="text-white">{confirmModal.store.name} ({confirmModal.store.storeId})</strong>? 
              Deactivated stores are excluded from automatic delivery routing, cannot receive new orders, and won't appear as options for Store Pickup. Historical order data will remain preserved.
            </p>

            <div className="flex gap-4">
              <button
                onClick={() => setConfirmModal({ isOpen: false, store: null })}
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
