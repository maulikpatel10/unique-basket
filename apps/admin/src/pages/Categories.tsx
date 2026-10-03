import React, { useState } from 'react';
import { Pagination } from '../components/Pagination';
import { ADMIN_PAGE_SIZE, emptyPagination, type PaginationMeta } from '../utils/pagination';
import { useDebouncedValue } from '../hooks/useDebouncedValue';
import { api } from '../services/api';
import { useLoader } from '../hooks/useLoader';
import { useAuth } from '../context/authContextStore';
import {
  Plus,
  Search,
  Filter,
  Edit2,
  CheckCircle,
  XCircle,
  AlertTriangle,
  X,
  Tag,
  AlignLeft,
  Image as ImageIcon,
  Layers
} from 'lucide-react';
import { asApiError } from '../utils/apiError';
import { handleImageError } from '../utils/imageFallback';

interface Category {
  id: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  displayOrder: number;
  isActive: boolean;
  createdAt: string;
}

export const Categories: React.FC = () => {
  const { user } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);

  // Search & Filters
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearch = useDebouncedValue(searchTerm.trim());
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState<PaginationMeta>(emptyPagination);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL');

  // Modal / Drawer states
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [confirmModal, setConfirmModal] = useState<{ isOpen: boolean; category: Category | null }>({
    isOpen: false,
    category: null,
  });

  // Toasts
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Form
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    imageUrl: '',
    displayOrder: 0,
    isActive: true,
  });
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  const loadCategories = async () => {
    // Fetch categories. Passing isActive='all' to override default customer active-only return
    const params: Record<string, unknown> = { page, limit: ADMIN_PAGE_SIZE };
    if (debouncedSearch) params.search = debouncedSearch;
    if (statusFilter !== 'ALL') params.isActive = statusFilter === 'ACTIVE' ? 'true' : 'false';
    const res = await api.get('/categories', { params });
    setCategories(res.data.data.categories);
    setPagination(res.data.data.pagination);
  };

  // useLoader: loading/error derived from the latest request (no setState inside effects)
  const { loading, error, reload: fetchCategories } = useLoader(loadCategories, [page, debouncedSearch, statusFilter], {
    errorMessage: () => 'Failed to retrieve categories list. Please try again.',
  });

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: name === 'displayOrder' ? parseInt(value) || 0 : value,
    }));
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
    if (!formData.name.trim()) {
      errors.name = 'Category Name is required';
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleOpenCreateDrawer = () => {
    setEditingCategory(null);
    setFormData({
      name: '',
      description: '',
      imageUrl: '',
      displayOrder: 0,
      isActive: true,
    });
    setFormErrors({});
    setIsDrawerOpen(true);
  };

  const handleOpenEditDrawer = (cat: Category) => {
    setEditingCategory(cat);
    setFormData({
      name: cat.name,
      description: cat.description || '',
      imageUrl: cat.imageUrl || '',
      displayOrder: cat.displayOrder,
      isActive: cat.isActive,
    });
    setFormErrors({});
    setIsDrawerOpen(true);
  };

  const handleSaveCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setSubmitting(true);
    try {
      if (editingCategory) {
        await api.put(`/categories/${editingCategory.id}`, formData);
        showToast('success', 'Category details updated successfully.');
      } else {
        await api.post('/categories', formData);
        showToast('success', 'New category created successfully.');
      }
      setIsDrawerOpen(false);
      fetchCategories();
    } catch (caught: unknown) {
      const err = asApiError(caught);
      console.error('Error saving category:', err);
      const msg = err.response?.data?.message || 'Failed to save category details.';
      showToast('error', msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleStatus = async (cat: Category) => {
    if (cat.isActive) {
      // Deactivate flow – only SUPER_ADMIN allowed
      if (user?.role !== 'SUPER_ADMIN') {
        showToast('error', 'You do not have permission to deactivate categories.');
        return;
      }
      setConfirmModal({ isOpen: true, category: cat });
    } else {
      // Activate flow – only SUPER_ADMIN allowed
      if (user?.role !== 'SUPER_ADMIN') {
        showToast('error', 'You do not have permission to activate categories.');
        return;
      }
      try {
        await api.put(`/categories/${cat.id}`, { isActive: true });
        showToast('success', `Category "${cat.name}" activated successfully.`);
        fetchCategories();
      } catch {
        showToast('error', 'Failed to activate category.');
      }
    }
  };

  const handleConfirmDeactivate = async () => {
    const cat = confirmModal.category;
    if (!cat) return;

    try {
      await api.delete(`/categories/${cat.id}`);
      showToast('success', `Category "${cat.name}" deactivated successfully.`);
      setConfirmModal({ isOpen: false, category: null });
      fetchCategories();
    } catch {
      showToast('error', 'Failed to deactivate category.');
    }
  };

  // Filter Search
  const filteredCategories = categories;

  return (
    <div className="relative space-y-6">
      {/* Toast popup alerts */}
      {toast && (
        <div
          className={`fixed top-4 right-4 z-50 flex items-center gap-3 rounded-lg px-5 py-3 shadow-lg border text-sm font-semibold transition-all duration-300 animate-slide-in ${
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
          <h2 className="text-2xl font-bold text-white">Global Categories</h2>
          <p className="text-slate-400 text-sm mt-1">Organize produce catalog into structural departments.</p>
        </div>
        {user?.role === 'SUPER_ADMIN' && (
          <button
            onClick={handleOpenCreateDrawer}
            className="flex items-center justify-center gap-2 rounded-lg bg-brand-500 hover:bg-brand-600 text-white px-4 py-2.5 text-sm font-bold shadow-lg shadow-brand-500/20 hover:shadow-brand-500/30 transition-all duration-200"
          >
            <Plus className="h-4.5 w-4.5" />
            Add Category
          </button>
        )}
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4 bg-darkbg-800 border border-slate-700/50 p-4 rounded-xl shadow-md">
        <div className="relative flex-1">
          <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
            <Search className="h-4 w-4" />
          </span>
          <input
            type="text"
            placeholder="Search categories by name or description..."
            value={searchTerm}
            onChange={(e) => { setSearchTerm(e.target.value); setPage(1); }}
            className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 outline-none transition-all duration-150"
          />
        </div>

        <div className="flex items-center gap-2">
          <Filter className="h-4 w-4 text-slate-400" />
          <span className="text-xs text-slate-400 uppercase font-semibold tracking-wider">Status:</span>
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value as typeof statusFilter); setPage(1); }}
            className="rounded-lg bg-slate-900 border border-slate-700 text-slate-300 px-3 py-2 text-xs font-semibold focus:border-brand-500 outline-none"
          >
            <option value="ALL">All Categories</option>
            <option value="ACTIVE">Active Only</option>
            <option value="INACTIVE">Inactive Only</option>
          </select>
        </div>
      </div>

      {/* Table list */}
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
            onClick={fetchCategories}
            className="mt-4 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 px-4 py-2 text-xs font-bold"
          >
            Try Again
          </button>
        </div>
      ) : filteredCategories.length === 0 ? (
        <div className="text-center py-16 bg-darkbg-800 border border-slate-700/50 rounded-xl">
          <p className="text-slate-400 text-sm">No categories recorded matching the search parameters.</p>
        </div>
      ) : (
        <div className="rounded-xl bg-darkbg-800 border border-slate-700/50 overflow-hidden shadow-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-900/40 text-xs font-bold text-slate-400 uppercase border-b border-slate-700">
                <tr>
                  <th className="px-6 py-4">Image</th>
                  <th className="px-6 py-4">Category Name</th>
                  <th className="px-6 py-4">Description</th>
                  <th className="px-6 py-4">Display Order</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4">Created Date</th>
                  <th className="px-6 py-4 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {filteredCategories.map((cat) => (
                  <tr key={cat.id} className="hover:bg-slate-800/10">
                    <td className="px-6 py-4 shrink-0">
                      {cat.imageUrl ? (
                        <img
                          src={cat.imageUrl}
                          alt={cat.name}
                          className="h-10 w-12 rounded object-cover border border-slate-700"
                          onError={handleImageError}
                        />
                      ) : (
                        <div className="h-10 w-12 rounded bg-slate-900 border border-slate-850 flex items-center justify-center text-slate-500">
                          <Tag className="h-4 w-4" />
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 font-bold text-white tracking-wide">{cat.name}</td>
                    <td className="px-6 py-4 text-slate-400 text-xs max-w-xs truncate">{cat.description || '—'}</td>
                    <td className="px-6 py-4 font-mono text-slate-200">{cat.displayOrder}</td>
                    <td className="px-6 py-4">
                      {user?.role === 'SUPER_ADMIN' && (
                        <button
                          onClick={() => handleToggleStatus(cat)}
                          className={`inline-flex px-2 py-0.5 rounded text-[10px] font-bold border transition-all duration-200 hover:scale-[1.02] ${
                            cat.isActive
                              ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/25'
                              : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/25'
                          }`}
                        >
                          {cat.isActive ? 'ACTIVE' : 'INACTIVE'}
                        </button>
                      )}
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-400">
                      {new Date(cat.createdAt).toLocaleDateString('en-IN', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-center">
                        {user?.role === 'SUPER_ADMIN' && (
                          <button
                            onClick={() => handleOpenEditDrawer(cat)}
                            title="Edit Category"
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
          <Pagination pagination={pagination} itemLabel="categories" onPageChange={setPage} />
        </div>
      )}

      {/* Drawer */}
      {isDrawerOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setIsDrawerOpen(false)} />

          <div className="relative flex w-full max-w-lg flex-col bg-darkbg-800 border-l border-slate-700 text-slate-200 shadow-2xl p-6 overflow-y-auto animate-slide-in">
            <div className="flex items-center justify-between border-b border-slate-700 pb-4 mb-6">
              <h3 className="text-lg font-bold text-white">
                {editingCategory ? `Edit Category: ${editingCategory.name}` : 'Create Category'}
              </h3>
              <button
                onClick={() => setIsDrawerOpen(false)}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-700 hover:text-white"
              >
                <X className="h-5.5 w-5.5" />
              </button>
            </div>

            <form onSubmit={handleSaveCategory} className="space-y-5">
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Category Name <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Tag className="h-4 w-4" />
                  </span>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="Fresh Fruits"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                </div>
                {formErrors.name && <p className="text-red-400 text-xs mt-1 font-semibold">{formErrors.name}</p>}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Description
                </label>
                <div className="relative">
                  <span className="absolute top-3 left-3 text-slate-400">
                    <AlignLeft className="h-4 w-4" />
                  </span>
                  <textarea
                    name="description"
                    value={formData.description}
                    onChange={handleInputChange}
                    rows={3}
                    placeholder="Describe this category listing contents..."
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none resize-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Image URL
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <ImageIcon className="h-4 w-4" />
                  </span>
                  <input
                    type="text"
                    name="imageUrl"
                    value={formData.imageUrl}
                    onChange={handleInputChange}
                    placeholder="https://images.unsplash.com/..."
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Display Order
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-3 flex items-center text-slate-400">
                    <Layers className="h-4 w-4" />
                  </span>
                  <input
                    type="number"
                    name="displayOrder"
                    value={formData.displayOrder}
                    onChange={handleInputChange}
                    placeholder="0"
                    min="0"
                    className="w-full rounded-lg bg-slate-900 border border-slate-700 text-slate-200 pl-10 pr-4 py-2.5 text-sm focus:border-brand-500 outline-none"
                  />
                </div>
              </div>

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
                  ) : editingCategory ? (
                    'Save Changes'
                  ) : (
                    'Create Category'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      {confirmModal.isOpen && confirmModal.category && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setConfirmModal({ isOpen: false, category: null })} />

          <div className="relative w-full max-w-md rounded-2xl bg-darkbg-800 border border-slate-700 p-6 shadow-2xl animate-scale-in">
            <div className="flex items-center gap-3.5 text-amber-500 mb-4">
              <AlertTriangle className="h-8 w-8" />
              <div>
                <h4 className="text-md font-extrabold text-white">Deactivate Category?</h4>
                <p className="text-[10px] text-brand-400 font-semibold tracking-wider uppercase">Confirm Visibility Revoke</p>
              </div>
            </div>

            <p className="text-slate-300 text-xs leading-relaxed mb-6">
              Are you sure you want to deactivate category <strong className="text-white">"{confirmModal.category.name}"</strong>? 
              This category and its products will be hidden from customer catalogs instantly. Customers will not be allowed to place new orders for these items. Historical orders will remain unchanged.
            </p>

            <div className="flex gap-4">
              <button
                onClick={() => setConfirmModal({ isOpen: false, category: null })}
                className="flex-1 rounded-lg bg-slate-700 hover:bg-slate-650 text-slate-200 py-2.5 text-xs font-bold transition-all duration-150"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmDeactivate}
                className="flex-1 rounded-lg bg-red-500 hover:bg-red-650 text-white py-2.5 text-xs font-bold transition-all duration-150 shadow-md shadow-red-950/20"
              >
                Deactivate
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
