import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';
import {
  Image as ImageIcon,
  Plus,
  Search,
  Filter,
  CheckCircle,
  XCircle,
  Edit2,
  ChevronLeft,
  ChevronRight,
  ExternalLink,
  X,
  AlertCircle
} from 'lucide-react';

interface BannerItem {
  id: string;
  title: string | null;
  imageUrl: string;
  displayOrder: number;
  isActive: boolean;
  createdAt: string;
}

interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export const Banners: React.FC = () => {
  const { user } = useAuth();
  const [banners, setBanners] = useState<BannerItem[]>([]);
  const [pagination, setPagination] = useState<PaginationMeta>({
    total: 0,
    page: 1,
    limit: 10,
    totalPages: 1,
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Create / Edit Modal
  const [modalState, setModalState] = useState<{
    isOpen: boolean;
    mode: 'create' | 'edit';
    bannerId?: string;
  }>({
    isOpen: false,
    mode: 'create',
  });

  const [formData, setFormData] = useState({
    title: '',
    imageUrl: '',
    displayOrder: 0,
    isActive: true,
  });
  const [formSubmitting, setFormSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Status toggle confirmation modal
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    banner: BannerItem | null;
  }>({
    isOpen: false,
    banner: null,
  });
  const [confirmSubmitting, setConfirmSubmitting] = useState(false);

  // Toast
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchBanners = async (page: number = 1) => {
    try {
      setLoading(true);
      setError(null);

      const params: any = {
        page,
        limit: 10,
      };

      if (searchTerm.trim()) params.search = searchTerm.trim();
      if (statusFilter !== 'ALL') params.status = statusFilter;

      const res = await api.get('/admin/banners', { params });
      setBanners(res.data.data.banners);
      setPagination(res.data.data.pagination);
    } catch (err: any) {
      console.error('Error fetching banners:', err);
      setError(err.response?.data?.message || 'Failed to load marketing banners.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBanners(1);
  }, [statusFilter]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchBanners(1);
  };

  const handleOpenCreate = () => {
    setFormData({
      title: '',
      imageUrl: '',
      displayOrder: banners.length > 0 ? Math.max(...banners.map((b) => b.displayOrder)) + 1 : 0,
      isActive: true,
    });
    setFormError(null);
    setModalState({ isOpen: true, mode: 'create' });
  };

  const handleOpenEdit = (b: BannerItem) => {
    setFormData({
      title: b.title || '',
      imageUrl: b.imageUrl,
      displayOrder: b.displayOrder,
      isActive: b.isActive,
    });
    setFormError(null);
    setModalState({ isOpen: true, mode: 'edit', bannerId: b.id });
  };

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.imageUrl.trim()) {
      setFormError('Image URL is required.');
      return;
    }

    try {
      setFormSubmitting(true);
      setFormError(null);

      if (modalState.mode === 'create') {
        await api.post('/admin/banners', formData);
        showToast('success', 'Marketing banner created successfully.');
      } else if (modalState.bannerId) {
        await api.put(`/admin/banners/${modalState.bannerId}`, formData);
        showToast('success', 'Marketing banner updated successfully.');
      }

      setModalState({ isOpen: false, mode: 'create' });
      fetchBanners(pagination.page);
    } catch (err: any) {
      console.error('Error saving banner:', err);
      setFormError(err.response?.data?.message || 'Failed to save marketing banner.');
    } finally {
      setFormSubmitting(false);
    }
  };

  const handleToggleStatus = async () => {
    if (!confirmModal.banner) return;
    try {
      setConfirmSubmitting(true);
      if (confirmModal.banner.isActive) {
        // Deactivate using DELETE endpoint (soft-delete / isActive=false)
        await api.delete(`/admin/banners/${confirmModal.banner.id}`);
        showToast('success', 'Banner deactivated successfully.');
      } else {
        // Activate using PUT endpoint with { isActive: true }
        await api.put(`/admin/banners/${confirmModal.banner.id}`, {
          isActive: true,
        });
        showToast('success', 'Banner activated successfully.');
      }

      setConfirmModal({ isOpen: false, banner: null });
      fetchBanners(pagination.page);
    } catch (err: any) {
      console.error('Error modifying banner status:', err);
      showToast('error', err.response?.data?.message || 'Failed to update banner.');
    } finally {
      setConfirmSubmitting(false);
    }
  };

  return (
    <div className="relative space-y-6">
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

      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-2.5">
            <ImageIcon className="h-6 w-6 text-brand-400" />
            <span>Marketing Banners</span>
          </h2>
          <p className="text-slate-400 text-sm mt-1">
            Configure promotional banners, seasonal advertisements, and app campaign carousels.
          </p>
        </div>

        {user?.role === 'SUPER_ADMIN' && (
          <button
            onClick={handleOpenCreate}
            className="flex items-center justify-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white px-4 py-2.5 text-xs font-bold transition-colors shadow-md shadow-brand-500/10"
          >
            <Plus className="h-4 w-4" />
            <span>Add New Banner</span>
          </button>
        )}
      </div>

      {/* Search & Filter Bar */}
      <div className="flex flex-col md:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <form onSubmit={handleSearchSubmit} className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
            <Search className="h-4 w-4" />
          </span>
          <input
            type="text"
            placeholder="Search banner title..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
          />
        </form>

        <div className="flex items-center gap-3">
          <Filter className="h-4 w-4 text-slate-400" />
          <span className="text-xs text-slate-400 uppercase font-semibold">Status:</span>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as any)}
            className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
          >
            <option value="ALL">All Banners</option>
            <option value="ACTIVE">Active Banners</option>
            <option value="INACTIVE">Deactivated Banners</option>
          </select>
        </div>
      </div>

      {/* Banners Listing */}
      {loading ? (
        <div className="space-y-4">
          <div className="h-10 bg-slate-800 rounded-lg animate-pulse" />
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-20 bg-slate-800/60 rounded-lg animate-pulse" />
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-red-400 text-sm font-semibold">{error}</p>
          <button
            onClick={() => fetchBanners(1)}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Retry
          </button>
        </div>
      ) : banners.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <ImageIcon className="h-10 w-10 text-slate-600 mx-auto mb-3" />
          <p className="text-slate-400 text-sm font-medium">No marketing banners found.</p>
          {user?.role === 'SUPER_ADMIN' && (
            <button
              onClick={handleOpenCreate}
              className="mt-4 inline-flex items-center gap-2 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
            >
              <Plus className="h-4 w-4" />
              <span>Create First Banner</span>
            </button>
          )}
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-5 py-4">Preview</th>
                  <th className="px-5 py-4">Title & Link</th>
                  <th className="px-5 py-4 text-center">Display Order</th>
                  <th className="px-5 py-4">Status</th>
                  <th className="px-5 py-4">Created Date</th>
                  <th className="px-5 py-4 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {banners.map((b) => (
                  <tr key={b.id} className="hover:bg-slate-800/10 transition-colors">
                    <td className="px-5 py-4">
                      <div className="h-14 w-28 rounded-lg overflow-hidden bg-slate-900 border border-slate-700 shrink-0">
                        <img
                          src={b.imageUrl}
                          alt={b.title || 'Banner'}
                          className="h-full w-full object-cover"
                          onError={(e) => {
                            (e.target as HTMLElement).style.display = 'none';
                          }}
                        />
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <div>
                        <p className="font-bold text-white text-sm">{b.title || 'Untitled Banner'}</p>
                        <a
                          href={b.imageUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center gap-1 text-[11px] font-mono text-cyan-400 hover:underline mt-0.5 truncate max-w-xs"
                        >
                          <span className="truncate">{b.imageUrl}</span>
                          <ExternalLink className="h-3 w-3 shrink-0" />
                        </a>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-center">
                      <span className="inline-flex px-2.5 py-1 rounded bg-slate-900 border border-slate-700 font-mono font-bold text-xs text-slate-200">
                        {b.displayOrder}
                      </span>
                    </td>
                    <td className="px-5 py-4">
                      {user?.role === 'SUPER_ADMIN' ? (
                        <button
                          onClick={() =>
                            setConfirmModal({
                              isOpen: true,
                              banner: b,
                            })
                          }
                          title={b.isActive ? 'Click to deactivate banner' : 'Click to activate banner'}
                          className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border transition-all duration-200 hover:scale-[1.02] cursor-pointer ${
                            b.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/25'
                              : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/25'
                          }`}
                        >
                          {b.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </button>
                      ) : (
                        <span
                          className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border ${
                            b.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                              : 'bg-red-500/10 text-red-400 border-red-500/20'
                          }`}
                        >
                          {b.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </span>
                      )}
                    </td>
                    <td className="px-5 py-4 text-xs font-mono text-slate-400 whitespace-nowrap">
                      {new Date(b.createdAt).toLocaleDateString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </td>
                    <td className="px-5 py-4 text-center">
                      <div className="flex items-center justify-center gap-2">
                        {user?.role === 'SUPER_ADMIN' && (
                          <button
                            onClick={() => handleOpenEdit(b)}
                            title="Edit Banner"
                            className="p-1.5 text-slate-400 hover:text-cyan-400 hover:bg-slate-700/50 rounded transition-colors"
                          >
                            <Edit2 className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="flex items-center justify-between px-5 py-4 bg-slate-900/40 border-t border-slate-800 text-xs text-slate-400">
            <div>
              Showing page <strong className="text-slate-200">{pagination.page}</strong> of{' '}
              <strong className="text-slate-200">{pagination.totalPages}</strong> ({pagination.total} total banners)
            </div>

            <div className="flex items-center gap-2">
              <button
                disabled={pagination.page <= 1}
                onClick={() => fetchBanners(pagination.page - 1)}
                className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <button
                disabled={pagination.page >= pagination.totalPages}
                onClick={() => fetchBanners(pagination.page + 1)}
                className="p-1.5 rounded bg-slate-800 hover:bg-slate-750 text-slate-300 disabled:opacity-40"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create / Edit Banner Modal */}
      {modalState.isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div
            className="fixed inset-0 bg-black/60 backdrop-blur-xs"
            onClick={() => setModalState({ isOpen: false, mode: 'create' })}
          />

          <div className="relative w-full max-w-md rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-700 pb-3">
              <h3 className="text-base font-bold text-white">
                {modalState.mode === 'create' ? 'Add New Marketing Banner' : 'Edit Marketing Banner'}
              </h3>
              <button
                onClick={() => setModalState({ isOpen: false, mode: 'create' })}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-slate-700"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <form onSubmit={handleFormSubmit} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold uppercase tracking-wider text-slate-300 mb-1.5">
                  Banner Title (Optional)
                </label>
                <input
                  type="text"
                  placeholder="e.g. Summer Grocery Festival"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3.5 py-2.5 focus:border-brand-500 outline-none"
                />
              </div>

              <div>
                <label className="block font-bold uppercase tracking-wider text-slate-300 mb-1.5">
                  Banner Image URL <span className="text-red-400">*</span>
                </label>
                <input
                  type="url"
                  required
                  placeholder="https://images.unsplash.com/..."
                  value={formData.imageUrl}
                  onChange={(e) => setFormData({ ...formData, imageUrl: e.target.value })}
                  className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3.5 py-2.5 font-mono focus:border-brand-500 outline-none"
                />
              </div>

              {formData.imageUrl && (
                <div className="space-y-1">
                  <span className="text-[10px] text-slate-400 font-semibold">Image Preview:</span>
                  <div className="h-28 w-full rounded-xl overflow-hidden bg-slate-900 border border-slate-700">
                    <img
                      src={formData.imageUrl}
                      alt="Banner Preview"
                      className="h-full w-full object-cover"
                      onError={(e) => {
                        (e.target as HTMLElement).style.display = 'none';
                      }}
                    />
                  </div>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block font-bold uppercase tracking-wider text-slate-300 mb-1.5">
                    Display Order
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={formData.displayOrder}
                    onChange={(e) => setFormData({ ...formData, displayOrder: parseInt(e.target.value) || 0 })}
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 px-3.5 py-2.5 font-mono focus:border-brand-500 outline-none"
                  />
                </div>

                <div className="flex flex-col justify-end">
                  <label className="flex items-center gap-2 cursor-pointer pb-2.5">
                    <input
                      type="checkbox"
                      checked={formData.isActive}
                      onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                      className="rounded border-slate-700 text-brand-500 focus:ring-0 h-4 w-4"
                    />
                    <span className="font-bold text-slate-200">Active Banner</span>
                  </label>
                </div>
              </div>

              {formError && (
                <div className="flex items-center gap-2 p-3 rounded-lg bg-red-950/40 border border-red-500/30 text-red-400 text-xs font-semibold">
                  <AlertCircle className="h-4 w-4 shrink-0" />
                  <span>{formError}</span>
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setModalState({ isOpen: false, mode: 'create' })}
                  className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2.5 font-bold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={formSubmitting || !formData.imageUrl.trim()}
                  className="flex-1 flex items-center justify-center rounded-lg bg-brand-500 hover:bg-brand-600 text-white py-2.5 font-bold disabled:opacity-50"
                >
                  {formSubmitting ? (
                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                  ) : modalState.mode === 'create' ? (
                    'Create Banner'
                  ) : (
                    'Save Changes'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      {confirmModal.isOpen && confirmModal.banner && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div
            className="fixed inset-0 bg-black/60 backdrop-blur-xs"
            onClick={() => setConfirmModal({ isOpen: false, banner: null })}
          />

          <div className="relative w-full max-w-sm rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-bold text-white">
              {confirmModal.banner.isActive ? 'Deactivate Marketing Banner?' : 'Activate Marketing Banner?'}
            </h3>

            <p className="text-xs text-slate-400 leading-relaxed">
              {confirmModal.banner.isActive
                ? `Deactivating "${confirmModal.banner.title || 'this banner'}" will immediately hide it from customer applications.`
                : `Activating "${confirmModal.banner.title || 'this banner'}" will make it visible in the customer application banner carousel.`}
            </p>

            <div className="flex gap-3 pt-2">
              <button
                type="button"
                onClick={() => setConfirmModal({ isOpen: false, banner: null })}
                className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2 text-xs font-bold"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={confirmSubmitting}
                onClick={handleToggleStatus}
                className={`flex-1 flex items-center justify-center rounded-lg py-2 text-xs font-bold text-white ${
                  confirmModal.banner.isActive ? 'bg-red-600 hover:bg-red-700' : 'bg-emerald-600 hover:bg-emerald-700'
                }`}
              >
                {confirmSubmitting ? (
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                ) : confirmModal.banner.isActive ? (
                  'Deactivate'
                ) : (
                  'Activate'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
